[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $ApkPath,
    [ValidateSet("clean", "upgrade")] [string] $Mode = "clean",
    [string] $PriorApkPath = "",
    [string] $SdkRoot = "E:\Android\Sdk",
    [string] $ArtifactRoot = "E:\CodexCache\printforge-android-smoke",
    [string] $PackageName = "com.tak.printforge.legends.review"
)

$ErrorActionPreference = "Stop"
$adb = Join-Path $SdkRoot "platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $adb)) { throw "adb.exe was not found under SdkRoot: $SdkRoot" }
if (-not (Test-Path -LiteralPath $ApkPath)) { throw "APK was not found: $ApkPath" }
if ($Mode -eq "upgrade" -and -not (Test-Path -LiteralPath $PriorApkPath)) { throw "upgrade mode requires a valid PriorApkPath" }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $ArtifactRoot "$stamp-$Mode"
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null

function Invoke-Adb {
    param([Parameter(Mandatory = $true)] [string[]] $Arguments)
    $output = & $adb @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "adb $($Arguments -join ' ') failed with exit code $LASTEXITCODE`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

function Save-AndroidScreenshot {
    param([Parameter(Mandatory = $true)] [string] $Path)
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $adb
    $process.StartInfo.Arguments = "exec-out screencap -p"
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    [void] $process.Start()
    $file = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    try { $process.StandardOutput.BaseStream.CopyTo($file) } finally { $file.Dispose() }
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "adb exec-out screencap failed with exit code $($process.ExitCode): $stderr" }
    if ((Get-Item -LiteralPath $Path).Length -eq 0) { throw "adb exec-out screencap produced an empty PNG." }
}

Invoke-Adb @("start-server") | Set-Content -LiteralPath (Join-Path $runRoot "adb-start-server.txt")
$devices = Invoke-Adb @("devices")
$devices | Set-Content -LiteralPath (Join-Path $runRoot "adb-devices.txt")
if (($devices | Select-String -SimpleMatch "`tdevice").Count -ne 1) { throw "Connect exactly one authorized Android device before running this smoke test." }

Invoke-Adb @("logcat", "-c") | Out-Null
if ($Mode -eq "clean") {
    # An absent package is already clean. Retain the package query and uninstall
    # response so a failed clean-install run remains fully diagnosable.
    $installedPackages = Invoke-Adb @("shell", "pm", "list", "packages", $PackageName)
    $installedPackages | Set-Content -LiteralPath (Join-Path $runRoot "installed-packages.txt")
    if (($installedPackages -join [Environment]::NewLine) -match [regex]::Escape("package:$PackageName")) {
        Invoke-Adb @("uninstall", $PackageName) | Set-Content -LiteralPath (Join-Path $runRoot "uninstall.txt")
    } else {
        "Package was not installed; clean state already satisfied." | Set-Content -LiteralPath (Join-Path $runRoot "uninstall.txt")
    }
} else {
    Invoke-Adb @("install", "-r", $PriorApkPath) | Set-Content -LiteralPath (Join-Path $runRoot "install-prior.txt")
}
Invoke-Adb @("install", "-r", $ApkPath) | Set-Content -LiteralPath (Join-Path $runRoot "install-review.txt")

Invoke-Adb @("shell", "am", "force-stop", $PackageName) | Out-Null
$resolved = Invoke-Adb @("shell", "cmd", "package", "resolve-activity", "--brief", $PackageName)
$component = ($resolved | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1).Trim()
if ([string]::IsNullOrWhiteSpace($component)) { throw "Android did not resolve a launcher activity for $PackageName." }
$component | Set-Content -LiteralPath (Join-Path $runRoot "resolved-launcher.txt")
Invoke-Adb @("shell", "am", "start", "-W", "-n", $component) | Set-Content -LiteralPath (Join-Path $runRoot "am-start-W.txt")
Start-Sleep -Seconds 8
$logcat = Invoke-Adb @("logcat", "-d", "-v", "threadtime")
$logcat | Set-Content -LiteralPath (Join-Path $runRoot "logcat-raw.txt")
Invoke-Adb @("shell", "dumpsys", "activity", "activities") | Set-Content -LiteralPath (Join-Path $runRoot "activity-state.txt")
$processState = & $adb shell pidof $PackageName 2>&1
$processState | Set-Content -LiteralPath (Join-Path $runRoot "process-state.txt")
if ($LASTEXITCODE -gt 1) { throw "adb shell pidof failed with exit code $LASTEXITCODE`n$($processState -join [Environment]::NewLine)" }
Save-AndroidScreenshot -Path (Join-Path $runRoot "first-frame.png")
$markers = $logcat | Select-String -SimpleMatch "PRINTFORGE_STARTUP"
$markers | Set-Content -LiteralPath (Join-Path $runRoot "startup-markers.txt")

$failures = @()
if ([string]::IsNullOrWhiteSpace(($processState -join "").Trim())) { $failures += "The review process was not alive after the 8-second launch window." }
if (($markers | Select-String -SimpleMatch "marker=first_frame").Count -eq 0) { $failures += "No PRINTFORGE_STARTUP marker=first_frame was present in captured logcat." }
if ($failures.Count -gt 0) {
    ($failures -join [Environment]::NewLine) | Set-Content -LiteralPath (Join-Path $runRoot "smoke-failure.txt")
    throw "Android smoke failed; evidence was retained in $runRoot`n$($failures -join [Environment]::NewLine)"
}

Write-Host "Android smoke evidence: $runRoot"
Write-Host "Inspect first-frame.png, logcat-raw.txt, activity-state.txt, process-state.txt, and startup-markers.txt before accepting the build."
