param(
    [string]$ProjectRoot = $PSScriptRoot,
    [switch]$SkipTests
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
        [switch]$AllowFailure,
        [string]$LogFile = ""
    )
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ([string]::IsNullOrWhiteSpace($LogFile)) {
            & $Command 2>&1 | Out-Host
        } else {
            & $Command 2>&1 | Tee-Object -FilePath $LogFile | Out-Host
        }
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
$logs = Join-Path $ProjectRoot "BUILD_LOGS"
New-Item -ItemType Directory -Force -Path $logs | Out-Null

if (-not (Test-Path -LiteralPath (Join-Path $app "pubspec.yaml"))) {
    throw "Flutter project not found: $app"
}

$configFile = Join-Path $ProjectRoot "BUILD_DEFINES.ps1"
if (Test-Path -LiteralPath $configFile) {
    . $configFile
}

$domain = if ($env:QR_AJN_DOMAIN) { $env:QR_AJN_DOMAIN } else { "https://qrajn.online" }
$banner = if ($env:ADMOB_BANNER_ID) { $env:ADMOB_BANNER_ID } else { "ca-app-pub-3940256099942544/6300978111" }
$interstitial = if ($env:ADMOB_INTERSTITIAL_ID) { $env:ADMOB_INTERSTITIAL_ID } else { "ca-app-pub-3940256099942544/1033173712" }
$rewarded = if ($env:ADMOB_REWARDED_ID) { $env:ADMOB_REWARDED_ID } else { "ca-app-pub-3940256099942544/5224354917" }
$proMonthly = if ($env:PREMIUM_MONTHLY_ID) { $env:PREMIUM_MONTHLY_ID } else { "qrajn_pro_monthly" }
$proYearly = if ($env:PREMIUM_YEARLY_ID) { $env:PREMIUM_YEARLY_ID } else { "qrajn_pro_yearly" }
$businessMonthly = if ($env:BUSINESS_MONTHLY_ID) { $env:BUSINESS_MONTHLY_ID } else { "qrajn_business_monthly" }
$businessYearly = if ($env:BUSINESS_YEARLY_ID) { $env:BUSINESS_YEARLY_ID } else { "qrajn_business_yearly" }
$testAds = $banner.StartsWith("ca-app-pub-3940256099942544")

$defines = @(
    "--dart-define=QR_AJN_DOMAIN=$domain",
    "--dart-define=ADS_ENABLED=true",
    "--dart-define=USE_TEST_ADS=$($testAds.ToString().ToLowerInvariant())",
    "--dart-define=ADMOB_BANNER_ID=$banner",
    "--dart-define=ADMOB_INTERSTITIAL_ID=$interstitial",
    "--dart-define=ADMOB_REWARDED_ID=$rewarded",
    "--dart-define=PREMIUM_MONTHLY_ID=$proMonthly",
    "--dart-define=PREMIUM_YEARLY_ID=$proYearly",
    "--dart-define=BUSINESS_MONTHLY_ID=$businessMonthly",
    "--dart-define=BUSINESS_YEARLY_ID=$businessYearly"
)

Write-Step "Repairing the Android Gradle project"
& (Join-Path $ProjectRoot "00_REPAIR_ANDROID_PROJECT.ps1") -ProjectRoot $ProjectRoot

$jbr = Join-Path $env:ProgramFiles "Android\Android Studio\jbr"
if (Test-Path -LiteralPath (Join-Path $jbr "bin\java.exe")) {
    $env:JAVA_HOME = $jbr
    $env:Path = "$(Join-Path $jbr 'bin');$env:Path"
    [void](Invoke-Native -Command {
        flutter config --jdk-dir="$jbr"
    } -FailureMessage "Flutter JDK configuration failed.")
}

Set-Location $app

Write-Step "Cleaning and resolving Flutter packages"
[void](Invoke-Native -Command { flutter clean } -FailureMessage "flutter clean failed.")
if (Test-Path -LiteralPath (Join-Path $app ".dart_tool")) {
    Remove-Item -LiteralPath (Join-Path $app ".dart_tool") -Recurse -Force -ErrorAction SilentlyContinue
}
[void](Invoke-Native -Command { flutter pub get } -FailureMessage "flutter pub get failed.")

Write-Step "Formatting QR AJN source"
[void](Invoke-Native -Command {
    dart format lib test integration_test
} -FailureMessage "Dart formatting failed.")

Write-Step "Running analyzer"
[void](Invoke-Native -Command {
    flutter analyze --no-fatal-infos --no-fatal-warnings
} -FailureMessage "Flutter analyzer found real source errors." -LogFile (Join-Path $logs "flutter_analyze.log"))

if (-not $SkipTests) {
    Write-Step "Running Flutter tests"
    [void](Invoke-Native -Command {
        flutter test
    } -FailureMessage "Flutter tests failed." -LogFile (Join-Path $logs "flutter_test.log"))
}

Write-Step "Building QR AJN V5 debug APK"
[void](Invoke-Native -Command {
    flutter build apk `
        --debug `
        --build-name=5.0.0 `
        --build-number=50 `
        @defines
} -FailureMessage "QR AJN debug APK build failed." -LogFile (Join-Path $logs "debug_apk_build.log"))

$apk = Join-Path $app "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path -LiteralPath $apk)) {
    throw "Debug APK was not created: $apk"
}

Write-Step "Installing and opening QR AJN on Android"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $adb)) {
    throw "ADB not found: $adb"
}
[void](Invoke-Native -Command { & $adb start-server } -FailureMessage "ADB could not start.")

$serial = (
    & $adb devices |
    Select-String "`tdevice$" |
    ForEach-Object { ($_ -split "`t")[0].Trim() } |
    Select-Object -First 1
)
if ([string]::IsNullOrWhiteSpace($serial)) {
    throw "No authorised Android phone detected. Unlock the phone, enable USB debugging and approve this computer."
}

$install = Invoke-Native -Command {
    & $adb -s $serial install -r -d $apk
} -FailureMessage "APK update failed." -AllowFailure

if ($install -ne 0) {
    Write-Host "Existing app signature differs. Reinstalling com.qr.ajn. Local app data will be removed." -ForegroundColor Yellow
    [void](Invoke-Native -Command {
        & $adb -s $serial uninstall com.qr.ajn
    } -AllowFailure)
    [void](Invoke-Native -Command {
        & $adb -s $serial install $apk
    } -FailureMessage "Clean APK installation failed.")
}

[void](Invoke-Native -Command {
    & $adb -s $serial shell am force-stop com.qr.ajn
} -AllowFailure)

$launch = Invoke-Native -Command {
    & $adb -s $serial shell am start -n "com.qr.ajn/com.qr.ajn.MainActivity"
} -AllowFailure

if ($launch -ne 0) {
    [void](Invoke-Native -Command {
        & $adb -s $serial shell monkey -p com.qr.ajn -c android.intent.category.LAUNCHER 1
    } -FailureMessage "QR AJN could not be opened.")
}

$status = @"
QR AJN V5 ANDROID STATUS

Version:
5.0.0+50

Package:
com.qr.ajn

APK:
$apk

Device:
$serial

Result:
BUILT, INSTALLED AND OPENED

Ads:
$(if ($testAds) { "Google test IDs" } else { "Configured production IDs" })

Logs:
$logs
"@
$status | Set-Content -LiteralPath (Join-Path $ProjectRoot "FINAL_ANDROID_STATUS.txt") -Encoding UTF8

Write-Host "`nQR AJN V5 is running on Android." -ForegroundColor Green
Write-Host "APK: $apk" -ForegroundColor Green
