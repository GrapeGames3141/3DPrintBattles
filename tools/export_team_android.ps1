param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit
)

$ErrorActionPreference = 'Stop'
# Library mode starts no engine. Export uses the same observed process identities,
# isolated save manifest and finally cleanup as the already-audited test harness.
. (Join-Path $PSScriptRoot 'run_team_battle_tests.ps1') -Suite library
$sdk = 'E:\CodexCache\godot-android-4.7.1\android-sdk\build-tools\36.1.0'
$java = 'E:\CodexCache\godot-android-4.7.1\jdk\jdk-17.0.20+8\bin\java.exe'
$settingsPath = 'E:\CodexCache\godot-android-4.7.1\godot\editor_data\editor_settings-4.7.tres'
$shortCommit = $SourceCommit.Substring(0, 12)
$apk = Join-Path $projectRoot "build\android\PrintForge-Legends-0.9.0-team-prototype-arm64-$shortCommit.apk"

function Confirm-CleanSource {
    $actual = & git -C $projectRoot rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $actual.Trim() -cne $SourceCommit) { throw 'Source commit differs from HEAD.' }
    & git -C $projectRoot diff --quiet --exit-code
    if ($LASTEXITCODE -ne 0) { throw 'Tracked working source is dirty.' }
    & git -C $projectRoot diff --cached --quiet --exit-code
    if ($LASTEXITCODE -ne 0) { throw 'Staged source is dirty.' }
    $untrackedRuntime = @(& git -C $projectRoot ls-files --others --exclude-standard -- assets scripts scenes shaders data | Where-Object { $_ -notmatch '\.(import|uid)$' })
    if ($LASTEXITCODE -ne 0 -or $untrackedRuntime.Count -gt 0) { throw 'Uncommitted runtime files would make source attribution incomplete.' }
}

Confirm-CleanSource
if (Test-Path -LiteralPath $apk) { throw 'Refusing to overwrite a versioned APK.' }
foreach ($required in @($java, $settingsPath, (Join-Path $sdk 'zipalign.exe'), (Join-Path $sdk 'lib\apksigner.jar'))) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw 'A required configured Android tool is unavailable.' }
}
$projectConfig = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'project.godot')
$exportConfig = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'export_presets.cfg')
if ($projectConfig -notmatch '(?m)^run/main_scene="res://scenes/team_prototype\.tscn"\r?$') { throw 'Default launch does not select the Team prototype.' }
if ($exportConfig -notmatch '(?m)^custom_features="team_prototype"\r?$' -or
    $exportConfig -notmatch '(?m)^version/code=108\r?$' -or
    $exportConfig -notmatch '(?m)^version/name="0\.9\.0-team-prototype"\r?$') { throw 'Team prototype export identity has not been finalized.' }

Invoke-TeamTest -Scene 'android-team-export' -Marker '' -ExportOnly $true
$aligned = Join-Path $script:LastTeamExportRoot 'aligned.apk'
& (Join-Path $sdk 'zipalign.exe') -P 16 4 $script:LastTeamExportUnsigned $aligned
if ($LASTEXITCODE -ne 0) { throw 'APK alignment failed.' }

$secretName = 'PRINTFORGE_TEAM_REVIEW_SIGN_PASSWORD'
$priorSecret = [Environment]::GetEnvironmentVariable($secretName, 'Process')
try {
    $privateSettings = Get-Content -Raw -LiteralPath $settingsPath
    $keyPath = [regex]::Match($privateSettings, 'export/android/debug_keystore = "([^"]+)"').Groups[1].Value
    $keyAlias = [regex]::Match($privateSettings, 'export/android/debug_keystore_user = "([^"]+)"').Groups[1].Value
    $keyPassword = [regex]::Match($privateSettings, 'export/android/debug_keystore_pass = "([^"]+)"').Groups[1].Value
    if (-not $keyAlias) { $keyAlias = 'androiddebugkey' }
    if (-not $keyPath -or -not $keyPassword) { throw 'Configured review signing identity is incomplete.' }
    [Environment]::SetEnvironmentVariable($secretName, $keyPassword, 'Process')
    New-Item -ItemType Directory -Path (Split-Path -Parent $apk) -Force | Out-Null
    # The password is inherited privately by Java, never placed on its command line.
    & $java -jar (Join-Path $sdk 'lib\apksigner.jar') sign --ks $keyPath --ks-key-alias $keyAlias --ks-pass "env:$secretName" --key-pass "env:$secretName" --out $apk $aligned
    if ($LASTEXITCODE -ne 0) { throw 'APK signing failed; candidate must not be delivered.' }
} finally {
    [Environment]::SetEnvironmentVariable($secretName, $priorSecret, 'Process')
    $privateSettings = $null
    $keyPassword = $null
}
Confirm-CleanSource
$receipt = [ordered]@{
    source_commit = $SourceCommit
    apk = $apk
    bytes = (Get-Item -LiteralPath $apk).Length
    sha256 = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash
    engine_evidence = $script:LastTeamExportRoot
    status = 'Signed candidate; independent APK audit required before delivery'
}
Write-Ledger (Join-Path $script:LastTeamExportRoot 'signed-candidate.json') $receipt
$receipt | ConvertTo-Json -Depth 4 | Write-Output
