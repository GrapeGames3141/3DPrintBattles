param(
    [string]$TemplateZip = "E:\CodexCache\godot-android-4.7.1\templates.tpz",
    [string]$JdkHome = "E:\CodexCache\godot-android-4.7.1\jdk\jdk-17.0.20+8",
    [string]$AndroidSdkRoot = "E:\CodexCache\godot-android-4.7.1\android-sdk",
    [string]$GradleUserHome = "E:\AI Projects\games\3d print battler\build\m4-admob-gradle-user-home"
)

$ErrorActionPreference = "Stop"
$pluginRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $pluginRoot "..\..")
$godotAar = Join-Path $pluginRoot "godot-lib.template_debug.aar"
$builtAar = Join-Path $pluginRoot "admob-banner\build\outputs\aar\admob-banner-release.aar"
$runtimeAar = Join-Path $projectRoot "addons\admob_banner\bin\printforge-admob-banner.aar"

foreach ($path in @($TemplateZip, $JdkHome, $AndroidSdkRoot)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required Android build input is missing: $path" }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$outerZip = [System.IO.Compression.ZipFile]::OpenRead($TemplateZip)
try {
    $androidSourceEntry = $outerZip.Entries | Where-Object FullName -eq "templates/android_source.zip"
    if ($null -eq $androidSourceEntry) { throw "Godot Android source template is missing from: $TemplateZip" }
    # Keep this large temporary nested template on E:, alongside the ignored Gradle cache.
    New-Item -ItemType Directory -Force -Path $GradleUserHome | Out-Null
    $nestedZipPath = Join-Path $GradleUserHome "printforge-godot-android-source-4.7.1.zip"
    $input = $androidSourceEntry.Open()
    try {
        $output = [System.IO.File]::Open($nestedZipPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        try { $input.CopyTo($output) } finally { $output.Dispose() }
    } finally { $input.Dispose() }
} finally { $outerZip.Dispose() }
$innerZip = [System.IO.Compression.ZipFile]::OpenRead($nestedZipPath)
try {
    $entry = $innerZip.Entries | Where-Object FullName -eq "libs/debug/godot-lib.template_debug.aar"
    if ($null -eq $entry) { throw "Godot 4.7.1 debug library AAR is missing from Android source template" }
    $input = $entry.Open()
    try {
        $output = [System.IO.File]::Open($godotAar, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        try { $input.CopyTo($output) } finally { $output.Dispose() }
    } finally { $input.Dispose() }
} finally { $innerZip.Dispose(); Remove-Item -LiteralPath $nestedZipPath -Force -ErrorAction SilentlyContinue }

$env:JAVA_HOME = $JdkHome
$env:ANDROID_HOME = $AndroidSdkRoot
$env:ANDROID_SDK_ROOT = $AndroidSdkRoot
$env:GRADLE_USER_HOME = $GradleUserHome
$env:ANDROID_USER_HOME = Join-Path $GradleUserHome "android-user-home"
$env:JAVA_TOOL_OPTIONS = ("$($env:JAVA_TOOL_OPTIONS) -Duser.home=`"$GradleUserHome`"").Trim()
New-Item -ItemType Directory -Force -Path $GradleUserHome | Out-Null
New-Item -ItemType Directory -Force -Path $env:ANDROID_USER_HOME | Out-Null
Push-Location $pluginRoot
try {
    & (Join-Path $pluginRoot "gradlew.bat") ":admob-banner:assembleRelease"
    if ($LASTEXITCODE -ne 0) { throw "Gradle plugin build failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
Copy-Item -LiteralPath $builtAar -Destination $runtimeAar -Force
Write-Output "Built $runtimeAar"
