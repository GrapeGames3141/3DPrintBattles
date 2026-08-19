param(
    [Parameter(Mandatory = $true)][string]$ExePath,
    [Parameter(Mandatory = $true)][string]$LogDirectory,
    [string]$UserDataRoot = "E:\CodexCache\printforge-export-smoke",
    [int]$StartupTimeoutSeconds = 12
)

$ErrorActionPreference = "Stop"
$exe = Get-Item -LiteralPath $ExePath
$pck = Join-Path $exe.DirectoryName ($exe.BaseName + ".pck")
if (-not (Test-Path -LiteralPath $pck)) { throw "Export smoke requires the matching PCK: $pck" }
New-Item -ItemType Directory -Force -Path $LogDirectory, $UserDataRoot, (Join-Path $UserDataRoot "appdata"), (Join-Path $UserDataRoot "localappdata") | Out-Null

$outLog = Join-Path $LogDirectory "launch.out.log"
$errLog = Join-Path $LogDirectory "launch.err.log"
$command = Join-Path $LogDirectory "run_export_smoke.cmd"
@(
    "@echo off",
    ('set "APPDATA=' + $UserDataRoot + '\appdata"'),
    ('set "LOCALAPPDATA=' + $UserDataRoot + '\localappdata"'),
    ('"' + $exe.FullName + '" 1>"' + $outLog + '" 2>"' + $errLog + '"')
) | Set-Content -LiteralPath $command -Encoding ASCII

function Get-OwnedGameProcesses {
    $results = @()
    foreach ($process in @(Get-Process -Name $exe.BaseName -ErrorAction SilentlyContinue)) {
        try {
            if ($process.Path -eq $exe.FullName) { $results += $process }
        } catch {
            # A process whose image path cannot be inspected is never owned by
            # this smoke test and must not be selected for termination.
        }
    }
    return @($results)
}
$before = @(Get-OwnedGameProcesses | Select-Object -ExpandProperty Id)
$start = [Diagnostics.ProcessStartInfo]::new()
$start.FileName = $env:ComSpec
$start.Arguments = '/d /c ""' + $command + '""'
$start.UseShellExecute = $false
$wrapper = [Diagnostics.Process]::Start($start)
$started = @()
$log = ""
try {
    $deadline = [DateTime]::UtcNow.AddSeconds($StartupTimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 250
        $started = @(Get-OwnedGameProcesses | Where-Object { $_.Id -notin $before })
        $log = [string](Get-Content -LiteralPath $outLog -Raw -ErrorAction SilentlyContinue) + [string](Get-Content -LiteralPath $errLog -Raw -ErrorAction SilentlyContinue)
        if ($started.Count -gt 0 -and $log.Contains("PRINTFORGE_STARTUP marker=first_frame")) { break }
    } while ([DateTime]::UtcNow -lt $deadline)
    if ($started.Count -eq 0) { throw "Exported game process was not alive during the startup window." }
    if ($log.Contains("SCRIPT ERROR:")) { throw "Exported game wrote a SCRIPT ERROR; see $errLog" }
    if (-not $log.Contains("PRINTFORGE_STARTUP marker=first_frame")) { throw "Exported game never reached the main scene first frame; see $outLog and $errLog" }
    [PSCustomObject]@{ WrapperPid = $wrapper.Id; GamePids = ($started.Id -join ","); Stdout = $outLog; Stderr = $errLog; Verified = $true }
} finally {
    foreach ($process in $started) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
    }
    if (-not $wrapper.HasExited) { Stop-Process -Id $wrapper.Id -Force -ErrorAction SilentlyContinue }
}
