param(
    [Parameter(Mandatory = $true)][string]$Apk,
    [Parameter(Mandatory = $true)][string]$EvidenceRoot,
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sdk = 'E:\CodexCache\godot-android-4.7.1\android-sdk\build-tools\36.1.0'
$java = 'E:\CodexCache\godot-android-4.7.1\jdk\jdk-17.0.20+8\bin\java.exe'
$template = 'E:\CodexCache\godot-android-4.7.1\godot\editor_data\export_templates\4.7.1.stable\android_debug.apk'
$expectedPackage = 'com.tak.printforge.legends.playtest'
$expectedVersion = '0.9.0-team-prototype'
$expectedCode = 108
$expectedCertificate = 'c26373b2320fa530be93f5b6d255a4c8e10e6aa4476e430dedb6106a4de865dc'

if (-not (Test-Path -LiteralPath $Apk)) { throw "APK is missing: $Apk" }
if (-not (Test-Path -LiteralPath $template)) { throw "Android debug template is missing: $template" }
if (Test-Path -LiteralPath (Join-Path $EvidenceRoot 'apk-audit.json')) { throw "Refusing existing audit receipt in $EvidenceRoot" }
New-Item -ItemType Directory -Force -Path $EvidenceRoot | Out-Null

$badging = & (Join-Path $sdk 'aapt2.exe') dump badging $Apk 2> (Join-Path $EvidenceRoot 'aapt2-badging-stderr.txt')
if ($LASTEXITCODE -ne 0) { throw 'aapt2 badging failed' }
$badging | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'aapt-badging.txt') -Encoding utf8
$manifest = & (Join-Path $sdk 'aapt.exe') dump xmltree $Apk AndroidManifest.xml
if ($LASTEXITCODE -ne 0) { throw 'aapt manifest failed' }
$manifest | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'aapt-manifest.txt') -Encoding utf8
$resources = & (Join-Path $sdk 'aapt.exe') dump resources $Apk
if ($LASTEXITCODE -ne 0) { throw 'aapt resources failed' }
$resources | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'aapt-resources.txt') -Encoding utf8
$cert = & $java -jar (Join-Path $sdk 'lib\apksigner.jar') verify --verbose --print-certs $Apk
if ($LASTEXITCODE -ne 0) { throw 'APK signing verification failed' }
$cert | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'apksigner-verify.txt') -Encoding utf8
$alignment = & (Join-Path $sdk 'zipalign.exe') -c -P 16 -v 4 $Apk
if ($LASTEXITCODE -ne 0) { throw 'APK 16KB ZIP alignment failed' }
$alignment | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'zipalign-check.txt') -Encoding utf8

$python = 'C:\Users\Tak\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$launchOutput = & $python -B (Join-Path $PSScriptRoot 'inspect_godot_apk_launch.py') --apk $Apk
if ($LASTEXITCODE -ne 0) { throw 'Compiled prototype launch path audit failed.' }
$launchAudit = ($launchOutput -join [Environment]::NewLine) | ConvertFrom-Json
$launchOutput | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'launch-path-audit.json') -Encoding utf8
$expectedName = 'PrintForge-Legends-' + $expectedVersion + '-arm64-' + $SourceCommit.Substring(0,12) + '.apk'
if ([IO.Path]::GetFileName($Apk) -cne $expectedName) { throw 'APK filename does not identify the requested source commit.' }

$failures = [Collections.Generic.List[string]]::new()
if (($badging -join [Environment]::NewLine) -notmatch "(?m)^application-label:'PrintForge'\r?$") { $failures.Add('Android launcher label mismatch') }
$expectedIdentity = "package: name='$expectedPackage' versionCode='$expectedCode' versionName='$expectedVersion'"
if (($badging -join "`n") -notmatch [regex]::Escape($expectedIdentity)) { $failures.Add('Package/version identity mismatch') }
$manifestText = $manifest -join "`n"
$aliases = @([regex]::Matches($manifestText, '(?ms)^      E: activity-alias .*?(?=^      E: |\z)') | ForEach-Object { $_.Value })
$launchAliases = @($aliases | Where-Object { $_ -match 'android:name[^\n]*="com.godot.game.GodotAppLauncher"' -and $_ -match 'android:targetActivity[^\n]*="com.godot.game.GodotApp"' -and $_ -match 'android:exported[^\n]*0xffffffff' -and $_ -match 'android.intent.action.MAIN' -and $_ -match 'android.intent.category.LAUNCHER' })
$activities = @([regex]::Matches($manifestText, '(?ms)^      E: activity .*?(?=^      E: |\z)') | ForEach-Object { $_.Value })
$portrait = @($activities | Where-Object { $_ -match 'android:name[^\n]*="com.godot.game.GodotApp"' -and $_ -match 'screenOrientation[^\n]*0x1' })
if ($launchAliases.Count -ne 1 -or $portrait.Count -ne 1) { $failures.Add('Portrait MAIN/LAUNCHER alias-target contract missing') }
if (($cert -join "`n") -notmatch $expectedCertificate) { $failures.Add('Signing certificate changed') }
foreach ($scheme in @('v2', 'v3')) { if (($cert -join "`n") -notmatch ('Verified using ' + $scheme + ' scheme .*true')) { $failures.Add("Missing $scheme signature scheme") } }

$adPattern = 'ca-app-pub-|com[/.]google[/.]android[/.]gms[/.]ads|com[/.]google[/.]ads|com[/.]google[/.]android[/.]ump|com[/.]applovin|com[/.]unity3d[/.]ads|com[/.]ironsource|com[/.]facebook[/.]ads|com[/.]vungle|com[/.]adcolony|com[/.]android[/.]adservices|android[/.]permission[/.]AD_ID|ACCESS_ADSERVICES_'
$adRegex = [regex]::new($adPattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase, [TimeSpan]::FromSeconds(30))
foreach ($dump in @('aapt-badging.txt', 'aapt-manifest.txt', 'aapt-resources.txt')) { if ($adRegex.IsMatch((Get-Content -LiteralPath (Join-Path $EvidenceRoot $dump) -Raw))) { $failures.Add("Advertising token in $dump") } }
function Get-EntryHash($entry) {
    $stream = $entry.Open(); $hasher = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-', '') } finally { $stream.Dispose(); $hasher.Dispose() }
}

$zip = [IO.Compression.ZipFile]::OpenRead($Apk)
$stock = [IO.Compression.ZipFile]::OpenRead($template)
$scanCount = 0; $stockCount = 0; $adHits = [Collections.Generic.List[string]]::new(); $required = [Collections.Generic.List[string]]::new()
try {
    $names = @($zip.Entries | Select-Object -ExpandProperty FullName)
    $names | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'apk-entries.txt') -Encoding utf8
    $excluded = @($names | Where-Object { $_ -match '^assets/(tests|docs|tools|build|backend|art-source|addons|android-plugins|\.codex[^/]*|\.agents)/|(^|/)(AGENTS\.md|README\.md)$|\.(keystore|jks|pem|p12|log)$|m8_print_idle_576x1024_M8-R5-m8-print-idle-576x1024|onboarding_576x1024|full_suit_raw_print_alpha_v2' })
    if ($excluded.Count) { $failures.Add('Excluded artifact paths packaged: ' + ($excluded -join ', ')) }
    $abis = @($names | Where-Object { $_ -like 'lib/*' } | ForEach-Object { ($_ -split '/')[1] } | Sort-Object -Unique)
    if ($abis.Count -ne 1 -or $abis[0] -ne 'arm64-v8a') { $failures.Add('APK is not arm64 only') }
    foreach ($path in @(
        'assets/assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png.import',
        'assets/assets/ui/physical_ui/forge-continuity/carriage-guide-v1.png.import',
        'assets/assets/ui/physical_ui/forge-continuity/carriage-head-v1.png.import',
        'assets/assets/ui/team_prototype/TM-R1-team-support-workbench-text-free-v1.png.import',
        'assets/assets/ui/team_prototype/BA-R1-team-autobattle-chassis-text-free-v1.png.import',
        'assets/assets/ui/physical_ui/team-prototype/EQ-R1-quadruped-armor-alpha-v1.png.import',
        'assets/assets/ui/physical_ui/m11/iron_gem-raw-alpha-v1.png.import',
        'assets/assets/ui/physical_ui/m11/iron-gem-completed-transparent-imagegen-v1.png.import',
        'assets/assets/ui/physical_ui/title-backplate-text-free-v2.png.import',
        'assets/assets/creatures/2d/blueprints/v2/manifest-v2.json',
		'assets/assets/creatures/2d/battle-facing/voltwig_battle_facing_2x1.png.import',
		'assets/scripts/ui/battle_facing_sprite_cache.gdc',
		'assets/scripts/team_ui/team_prototype_shell.gdc',
        'assets/scripts/team_ui/team_prototype_print_compositor.gdc',
        'assets/scripts/team_runtime/team_prototype_runtime.gdc',
        'assets/scripts/team_runtime/team_match_session.gdc',
        'assets/scripts/team_battle/team_battle_rules.gdc',
        'assets/assets/ui/branding/android/branding-app-icon-v1.png.import',
        'assets/scenes/team_prototype.tscn.remap',
        'assets/project.binary'
    )) {
        if ($path -notin $names) { $failures.Add("Required runtime entry missing: $path") } else { $required.Add($path) }
        if ($path.EndsWith('.png.import')) {
            $textureName = [IO.Path]::GetFileName($path.Substring(0, $path.Length - '.import'.Length))
            $texturePattern = '^assets/\.godot/imported/' + [regex]::Escape($textureName) + '-[^/]+\.ctex$'
            if (-not ($names -match $texturePattern)) { $failures.Add("Required compiled texture missing: $textureName") }
        }
    }
	foreach ($id in @('aquafin','aurorawing','brambleowl','cinderpaw','coalgriffin','coralisk','frostling','galehopper','glassdrake','ironmaw','miragefox','mossmunk','pyraxis','runestag','skyforge','sparkotter','starloom','stoneback','thunderelk','tidewhale','verdantitan','voidmanta','worldcoil')) {
		$import = "assets/assets/creatures/2d/battle-facing/$id`_battle_facing_4x2.png.import"
		$compiled = "^assets/\.godot/imported/$id`_battle_facing_4x2\.png-.*\.ctex$"
		if ($import -notin $names -or -not ($names -match $compiled)) { $failures.Add("Missing compiled directional facing resource: $id") }
	}
    $voltwigImport = 'assets/assets/creatures/2d/battle-facing/voltwig_battle_facing_2x1.png.import'
    if ($voltwigImport -notin $names -or -not ($names -match '^assets/\.godot/imported/voltwig_battle_facing_2x1\.png-.*\.ctex$')) { $failures.Add('Missing compiled Voltwig front/rear resource') }
    foreach ($entry in $zip.Entries) {
        $name = $entry.FullName
        if ($adRegex.IsMatch($name)) { $adHits.Add($name) }
        if ($name -match '^classes\d*\.dex$|^lib/.*\.so$|\.(jar|aar)$') {
            $stockEntry = $stock.GetEntry($name)
            if ($null -eq $stockEntry -or (Get-EntryHash $entry) -ne (Get-EntryHash $stockEntry)) { $failures.Add("Non-stock executable dependency: $name") }
            $stockCount++
        }
        if ($entry.Length -eq 0 -or $name -match '\.(png|jpg|jpeg|webp|ctex|stex|ttf|otf|ogg|mp3|wav)$') { continue }
        $stream = $entry.Open(); $memory = [IO.MemoryStream]::new()
        try {
            $stream.CopyTo($memory); $bytes = $memory.ToArray(); $text = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
            if ($adRegex.IsMatch($text)) { $adHits.Add($name) }
            $scanCount++
        } finally { $stream.Dispose(); $memory.Dispose() }
    }
    if ($adHits.Count) { $failures.Add('Advertising identifiers present: ' + ($adHits -join ', ')) }
} finally {
    $zip.Dispose(); $stock.Dispose()
}
$receipt = [ordered]@{ source_commit = $SourceCommit; launch_path = $launchAudit; apk = $Apk; bytes = (Get-Item -LiteralPath $Apk).Length; sha256 = (Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash; package = $expectedPackage; version = $expectedVersion; code = $expectedCode; abis = $abis; scanned_nonmedia_entries = $scanCount; stock_dex_native_dependencies = $stockCount; advertising_hits = @($adHits); required_entries = @($required); failures = @($failures); passed = ($failures.Count -eq 0); audited_at = (Get-Date).ToString('o') }
$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'apk-audit.json') -Encoding utf8
$receipt | ConvertTo-Json -Depth 8 | Write-Output
if ($failures.Count) { throw 'APK audit requires review' }
