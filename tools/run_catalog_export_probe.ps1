param(
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [Parameter(Mandatory = $true)][string]$EvidenceRoot,
    [string]$EnginePath = "E:\CodexCache\godot-android-4.7.1\godot\Godot_v4.7.1-stable_win64.exe",
    [string]$SourceProjectPath = "",
    [int]$TimeoutSeconds = 60,
    [switch]$RunDeckInput
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
if ([string]::IsNullOrWhiteSpace($SourceProjectPath)) { $SourceProjectPath = Split-Path -Parent $PSScriptRoot }

function Require-Path([string]$Path, [string]$Message) {
    if (-not (Test-Path -LiteralPath $Path)) { throw $Message }
}

function Assert-Contained([string]$Root, [string]$Candidate, [string]$Message) {
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $candidateFull = [IO.Path]::GetFullPath($Candidate)
    if (-not $candidateFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) { throw $Message }
    return $candidateFull
}

function Write-Json([string]$Path, [object]$Value) {
    $Value | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Extract-ApkAssets([string]$ArchivePath, [string]$Destination) {
    $seen = @{}
    $ledger = @()
    $zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        foreach ($entry in $zip.Entries) {
            if (-not $entry.FullName.StartsWith("assets/", [StringComparison]::Ordinal)) { continue }
            if ([string]::IsNullOrEmpty($entry.Name)) { continue }
            $relative = $entry.FullName.Substring(7).Replace('/', [IO.Path]::DirectorySeparatorChar)
            if ([string]::IsNullOrEmpty($relative) -or $relative.Contains("..")) { throw "APK asset entry is unsafe: $($entry.FullName)" }
            if ($seen.ContainsKey($relative)) { throw "APK has duplicate asset entry: $relative" }
            $seen[$relative] = $true
            $target = Assert-Contained $Destination (Join-Path $Destination $relative) "APK asset escaped extraction root: $($entry.FullName)"
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
            $input = $entry.Open()
            $output = [IO.File]::Open($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            $sha = [Security.Cryptography.SHA256]::Create()
            $bytes = [int64]0
            try {
                $buffer = New-Object byte[] 65536
                while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    [void]$sha.TransformBlock($buffer, 0, $read, $buffer, 0)
                    $output.Write($buffer, 0, $read)
                    $bytes += $read
                }
                [void]$sha.TransformFinalBlock([byte[]]@(), 0, 0)
            } finally {
                $output.Dispose()
                $input.Dispose()
            }
            $streamHash = ([BitConverter]::ToString($sha.Hash)).Replace('-', '')
            $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
            if ($entry.Length -ne $bytes -or (Get-Item -LiteralPath $target).Length -ne $bytes -or $targetHash -ne $streamHash) { throw "APK asset byte/hash verification failed: $relative" }
            $ledger += [pscustomobject]@{ apk_entry = $entry.FullName; extracted_relative_path = $relative; bytes = $bytes; sha256 = $targetHash }
            $sha.Dispose()
        }
    } catch {
        $failure = $_.Exception.Message
        throw
    } finally {
        $zip.Dispose()
    }
    if ($ledger.Count -eq 0) { throw "APK contains no runtime assets/ entries." }
    return $ledger
}

function Invoke-CatalogProbe([string]$Name, [string]$ProjectPath, [string]$ScenePath, [string]$RunRoot, [string]$SuccessMarker, [bool]$Headless = $true, [int]$Width = 0, [int]$Height = 0) {
    New-Item -ItemType Directory -Path $RunRoot | Out-Null
    $qaRoot = Join-Path $RunRoot "qa-save"
    $engineLog = Join-Path $RunRoot "engine.log"
    $stdoutLog = Join-Path $RunRoot "stdout.log"
    $stderrLog = Join-Path $RunRoot "stderr.log"
    $arguments = @("--path", $ProjectPath, "--rendering-method", "mobile")
    if ($Headless) { $arguments += "--headless" }
    $arguments += @("--log-file", $engineLog, $ScenePath, "--", "--qa-save-root=$qaRoot")
    if ($Width -gt 0) { $arguments += "--qa-width=$Width" }
    if ($Height -gt 0) { $arguments += "--qa-height=$Height" }
    $argumentString = (($arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join " ")
    $start = Get-Date
    $process = $null
    $runResult = [pscustomobject]@{ exit_code = -999 }
    $failure = ""
    $recordPath = Join-Path $RunRoot "process.json"
    try {
        # One quoted argument string preserves paths with spaces while direct file
        # redirection prevents stdout/stderr pipe backpressure from deadlocking Godot.
        $process = Start-Process -FilePath $engineFull -ArgumentList $argumentString -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        Write-Json $recordPath ([ordered]@{ kind = "catalog-export-probe"; name = $Name; console_pid = "N/A (direct engine launch)"; engine_pid = $process.Id; engine = $engineFull; arguments = $arguments; started = $start.ToString("o"); ended = $null; exit_code = $null; cleanup = "running"; log_file = $engineLog })
        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        while (-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
            Start-Sleep -Milliseconds 200
            $process.Refresh()
        }
        if (-not $process.HasExited) {
            $process.Kill($true)
            $process.WaitForExit()
            $failure = "$Name probe timed out after $TimeoutSeconds seconds; only task-owned engine PID $($process.Id) was stopped."
        }
		$process.WaitForExit()
		$process.Refresh()
        $runResult.exit_code = [int]$process.ExitCode
    } catch {
        $failure = $_.Exception.Message
    } finally {
        if ($null -ne $process -and -not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        $end = Get-Date
        if ($null -ne $process) {
            $cleanup = if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) { "FAILED: task-owned process still exists" } else { "confirmed exited; no task-owned engine survivor" }
            Write-Json $recordPath ([ordered]@{ kind = "catalog-export-probe"; name = $Name; console_pid = "N/A (direct engine launch)"; engine_pid = $process.Id; engine = $engineFull; arguments = $arguments; started = $start.ToString("o"); ended = $end.ToString("o"); exit_code = $runResult.exit_code; cleanup = $cleanup; failure = $failure; log_file = $engineLog })
            $process.Dispose()
        }
    }
    if (-not [string]::IsNullOrEmpty($failure)) { throw $failure }
    if ($runResult.exit_code -ne 0) { throw "$Name catalog probe failed with exit $($runResult.exit_code). See $RunRoot" }
    $combinedLog = ((Get-Content -LiteralPath $engineLog -Raw) + "`n" + (Get-Content -LiteralPath $stdoutLog -Raw) + "`n" + (Get-Content -LiteralPath $stderrLog -Raw))
    if ($combinedLog -match "SCRIPT ERROR:|Parse Error:|Failed to load script") { throw "$Name emitted a script/parse load error despite exit 0. See $RunRoot" }
    if (-not $combinedLog.Contains($SuccessMarker)) { throw "$Name did not emit the required success marker '$SuccessMarker'. See $RunRoot" }
}

$sourceFull = [IO.Path]::GetFullPath($SourceProjectPath)
$evidenceFull = [IO.Path]::GetFullPath($EvidenceRoot)
$apkFull = [IO.Path]::GetFullPath($ApkPath)
$engineFull = [IO.Path]::GetFullPath($EnginePath)
$allowedEvidence = [IO.Path]::GetFullPath((Join-Path $sourceFull "build\evidence")).TrimEnd([IO.Path]::DirectorySeparatorChar)

Require-Path $engineFull "Godot engine was not found: $engineFull"
Require-Path $apkFull "APK was not found: $apkFull"
Require-Path (Join-Path $sourceFull "tests\catalog_export_probe.gd") "Tracked catalog probe script is missing."
Require-Path (Join-Path $sourceFull "tests\catalog_export_probe.tscn") "Tracked source catalog probe scene is missing."
Require-Path (Join-Path $sourceFull "tests\catalog_export_probe_extracted.tscn") "Tracked extracted catalog probe scene is missing."
if ($RunDeckInput) {
    Require-Path (Join-Path $sourceFull "tests\test_deck_export_input.gd") "Tracked Deck export input script is missing."
    Require-Path (Join-Path $sourceFull "tests\test_deck_export_input.tscn") "Tracked source Deck export input scene is missing."
    Require-Path (Join-Path $sourceFull "tests\test_deck_export_input_extracted.tscn") "Tracked extracted Deck export input scene is missing."
}
if (-not $evidenceFull.StartsWith($allowedEvidence + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "EvidenceRoot must be a fresh child of $allowedEvidence" }
if (Test-Path -LiteralPath $evidenceFull) { throw "EvidenceRoot already exists; refusing to overwrite evidence: $evidenceFull" }

New-Item -ItemType Directory -Path $evidenceFull | Out-Null
$shippedRoot = Join-Path $evidenceFull "shipped-assets"
New-Item -ItemType Directory -Path $shippedRoot | Out-Null
$runtimeEntries = Extract-ApkAssets $apkFull $shippedRoot
$runtimeBytes = [int64]0
foreach ($runtimeEntry in $runtimeEntries) { $runtimeBytes += [int64]$runtimeEntry.bytes }
Write-Json (Join-Path $evidenceFull "runtime-entry-ledger.json") ([ordered]@{ entry_count = $runtimeEntries.Count; total_bytes = $runtimeBytes; entries = $runtimeEntries })
Require-Path (Join-Path $shippedRoot "project.binary") "APK extraction is missing project.binary."
Require-Path (Join-Path $shippedRoot "scripts\core\v3_catalog.gdc") "APK extraction is missing compiled v3 catalog."
if (Test-Path -LiteralPath (Join-Path $shippedRoot "scripts\core\v3_catalog.gd")) { throw "APK extraction unexpectedly contains raw v3_catalog.gd." }
if (Test-Path -LiteralPath (Join-Path $shippedRoot "assets\cards\v3\filament_ring_art_v1.png")) { throw "APK extraction unexpectedly contains loose Filament Ring PNG; export parity was not preserved." }

$probeRoot = Join-Path $shippedRoot "build\evidence\catalog-export-probe"
New-Item -ItemType Directory -Path $probeRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceFull "tests\catalog_export_probe.gd") -Destination (Join-Path $probeRoot "catalog_export_probe.gd")
Copy-Item -LiteralPath (Join-Path $sourceFull "tests\catalog_export_probe_extracted.tscn") -Destination (Join-Path $probeRoot "catalog_export_probe.tscn")
if ($RunDeckInput) {
    $deckProbeRoot = Join-Path $shippedRoot "build\evidence\deck-export-input"
    New-Item -ItemType Directory -Path $deckProbeRoot | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceFull "tests\test_deck_export_input.gd") -Destination (Join-Path $deckProbeRoot "test_deck_export_input.gd")
    Copy-Item -LiteralPath (Join-Path $sourceFull "tests\test_deck_export_input_extracted.tscn") -Destination (Join-Path $deckProbeRoot "test_deck_export_input.tscn")
}

Write-Json (Join-Path $evidenceFull "provenance.json") ([ordered]@{ apk_path = $apkFull; apk_sha256 = (Get-FileHash -LiteralPath $apkFull -Algorithm SHA256).Hash; source_project = $sourceFull; engine = $engineFull; runtime_entry_count = $runtimeEntries.Count; note = "Runtime entries were extracted directly from APK assets/. Only the tracked QA probe script and scene were then added under extracted build/evidence/." })
Invoke-CatalogProbe "source" $sourceFull "res://tests/catalog_export_probe.tscn" (Join-Path $evidenceFull "source") "PASS: catalog export probe"
Invoke-CatalogProbe "shipped" $shippedRoot "res://build/evidence/catalog-export-probe/catalog_export_probe.tscn" (Join-Path $probeRoot "shipped") "PASS: catalog export probe"
if ($RunDeckInput) {
    foreach ($viewport in @(@{ width = 576; height = 1024 }, @{ width = 720; height = 1280 })) {
        $label = "$($viewport.width)x$($viewport.height)"
        Invoke-CatalogProbe "deck-source-$label" $sourceFull "res://tests/test_deck_export_input.tscn" (Join-Path $evidenceFull "deck-source-$label") "PASS: deck export rendered input, save/reload, and bot opening multiset" $false $viewport.width $viewport.height
        Invoke-CatalogProbe "deck-shipped-$label" $shippedRoot "res://build/evidence/deck-export-input/test_deck_export_input.tscn" (Join-Path $deckProbeRoot "deck-shipped-$label") "PASS: deck export rendered input, save/reload, and bot opening multiset" $false $viewport.width $viewport.height
    }
}
Write-Output "PASS: source and APK-extracted compiled catalog probes passed. Evidence: $evidenceFull"
