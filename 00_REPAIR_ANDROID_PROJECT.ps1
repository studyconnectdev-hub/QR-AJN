param(
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Command,
        [string]$FailureMessage = "Command failed.",
        [switch]$AllowFailure
    )
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command 2>&1 | Out-Host
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $old
    }
    if (-not $AllowFailure -and $code -ne 0) {
        throw "$FailureMessage Exit code: $code"
    }
    return $code
}

$app = Join-Path $ProjectRoot "flutter_app"
$android = Join-Path $app "android"
$templates = Join-Path $ProjectRoot "production_templates\android"

foreach ($required in @(
    (Join-Path $app "pubspec.yaml"),
    (Join-Path $templates "settings.gradle.kts"),
    (Join-Path $templates "app\build.gradle.kts")
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required source/template is missing: $required"
    }
}

Write-Step "Backing up the current Android project"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $ProjectRoot "ANDROID_ROLLBACK_$stamp"
if (Test-Path -LiteralPath $android) {
    Copy-Item -LiteralPath $android -Destination $backup -Recurse -Force
}
Write-Host "Rollback: $backup" -ForegroundColor Green

Write-Step "Generating a clean Flutter Gradle wrapper"
$temp = Join-Path $env:TEMP "QR_AJN_WRAPPER_$stamp"
if (Test-Path -LiteralPath $temp) {
    Remove-Item -LiteralPath $temp -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $temp | Out-Null
Push-Location $temp
try {
    [void](Invoke-Native -Command {
        flutter create --platforms=android --org com.qr --project-name qr_ajn_wrapper .
    } -FailureMessage "Temporary Flutter wrapper generation failed.")
} finally {
    Pop-Location
}

New-Item -ItemType Directory -Force -Path (Join-Path $android "gradle\wrapper") | Out-Null
Copy-Item -LiteralPath (Join-Path $temp "android\gradlew") -Destination (Join-Path $android "gradlew") -Force
Copy-Item -LiteralPath (Join-Path $temp "android\gradlew.bat") -Destination (Join-Path $android "gradlew.bat") -Force
Copy-Item -LiteralPath (Join-Path $temp "android\gradle\wrapper\gradle-wrapper.jar") -Destination (Join-Path $android "gradle\wrapper\gradle-wrapper.jar") -Force

Write-Step "Applying the tested QR AJN Android configuration"
Copy-Item -LiteralPath (Join-Path $templates "settings.gradle.kts") -Destination (Join-Path $android "settings.gradle.kts") -Force
Copy-Item -LiteralPath (Join-Path $templates "build.gradle.kts") -Destination (Join-Path $android "build.gradle.kts") -Force
Copy-Item -LiteralPath (Join-Path $templates "gradle.properties") -Destination (Join-Path $android "gradle.properties") -Force
Copy-Item -LiteralPath (Join-Path $templates "app\build.gradle.kts") -Destination (Join-Path $android "app\build.gradle.kts") -Force
Copy-Item -LiteralPath (Join-Path $templates "app\proguard-rules.pro") -Destination (Join-Path $android "app\proguard-rules.pro") -Force
Copy-Item -LiteralPath (Join-Path $templates "gradle\wrapper\gradle-wrapper.properties") -Destination (Join-Path $android "gradle\wrapper\gradle-wrapper.properties") -Force

$localProperties = Join-Path $android "local.properties"
$androidSdk = (Join-Path $env:LOCALAPPDATA "Android\Sdk").Replace("\", "\\")
$flutterCommand = Get-Command flutter -ErrorAction Stop
$flutterSdk = (Split-Path -Parent (Split-Path -Parent $flutterCommand.Source)).Replace("\", "\\")
@"
sdk.dir=$androidSdk
flutter.sdk=$flutterSdk
flutter.buildMode=debug
flutter.versionName=5.0.0
flutter.versionCode=50
"@ | Set-Content -LiteralPath $localProperties -Encoding ASCII

Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue

Write-Step "Verifying Android package and SDK values"
$buildText = Get-Content -LiteralPath (Join-Path $android "app\build.gradle.kts") -Raw
foreach ($marker in @(
    'applicationId = "com.qr.ajn"',
    'namespace = "com.qr.ajn"',
    'minSdk = 24',
    'targetSdk = 36',
    'JvmTarget.JVM_17'
)) {
    if (-not $buildText.Contains($marker)) {
        throw "Android production marker missing: $marker"
    }
}
Write-Host "PASS: Android project repaired for com.qr.ajn" -ForegroundColor Green
