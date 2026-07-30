$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Android = Join-Path $Root "flutter_app\android"
$WrapperJar = Join-Path $Android "gradle\wrapper\gradle-wrapper.jar"
$GradlewBat = Join-Path $Android "gradlew.bat"
if ((Test-Path $WrapperJar) -and (Test-Path $GradlewBat)) { Write-Host "Android Gradle wrapper is present." -ForegroundColor Green; return }
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter is required to generate the Gradle wrapper." }
$Temp = Join-Path $env:TEMP ("qr_ajn_wrapper_" + [guid]::NewGuid().ToString("N"))
try {
    flutter create --platforms=android --org com.qr --project-name qr_ajn $Temp | Out-Host
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $WrapperJar) | Out-Null
    Copy-Item (Join-Path $Temp "android\gradlew.bat") $GradlewBat -Force
    Copy-Item (Join-Path $Temp "android\gradle\wrapper\gradle-wrapper.jar") $WrapperJar -Force
    Write-Host "Android Gradle wrapper created." -ForegroundColor Green
} finally {
    if (Test-Path $Temp) { cmd /c "rd /s /q `"$Temp`"" | Out-Null }
}
