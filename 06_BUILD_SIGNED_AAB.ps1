param(
    [string]$ProjectRoot = $PSScriptRoot,
    [switch]$SkipAnalyze,
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
$output = Join-Path $ProjectRoot "PLAY_STORE_UPLOAD"
$logs = Join-Path $ProjectRoot "BUILD_LOGS"
$keyProperties = Join-Path $app "android\key.properties"
$keystore = Join-Path $app "secure_keys\qr-ajn-upload.jks"

New-Item -ItemType Directory -Force -Path $output | Out-Null
New-Item -ItemType Directory -Force -Path $logs | Out-Null

if (-not (Test-Path -LiteralPath $keyProperties) -or -not (Test-Path -LiteralPath $keystore)) {
    Write-Host "Upload signing files are missing." -ForegroundColor Yellow
    & (Join-Path $ProjectRoot "CREATE_OR_IMPORT_UPLOAD_KEY.ps1") -ProjectRoot $ProjectRoot
}
if (-not (Test-Path -LiteralPath $keyProperties) -or -not (Test-Path -LiteralPath $keystore)) {
    throw "A release upload key is required."
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

Write-Step "Repairing Android build files"
& (Join-Path $ProjectRoot "00_REPAIR_ANDROID_PROJECT.ps1") -ProjectRoot $ProjectRoot

$jbr = Join-Path $env:ProgramFiles "Android\Android Studio\jbr"
if (Test-Path -LiteralPath (Join-Path $jbr "bin\java.exe")) {
    $env:JAVA_HOME = $jbr
    $env:Path = "$(Join-Path $jbr 'bin');$env:Path"
    [void](Invoke-Native -Command {
        flutter config --jdk-dir="$jbr"
    } -FailureMessage "Flutter JDK setup failed.")
}

Set-Location $app

Write-Step "Resolving packages"
[void](Invoke-Native -Command { flutter clean } -FailureMessage "flutter clean failed.")
[void](Invoke-Native -Command { flutter pub get } -FailureMessage "flutter pub get failed.")
[void](Invoke-Native -Command { dart format lib test integration_test } -FailureMessage "Dart format failed.")

if (-not $SkipAnalyze) {
    Write-Step "Running analyzer"
    [void](Invoke-Native -Command {
        flutter analyze --no-fatal-infos --no-fatal-warnings
    } -FailureMessage "Flutter analyzer found real source errors." -LogFile (Join-Path $logs "release_analyze.log"))
}

if (-not $SkipTests) {
    Write-Step "Running tests"
    [void](Invoke-Native -Command {
        flutter test
    } -FailureMessage "Flutter tests failed." -LogFile (Join-Path $logs "release_tests.log"))
}

if ($testAds) {
    Write-Host "WARNING: Google test ad IDs are active. This AAB is for internal testing, not a revenue-enabled production rollout." -ForegroundColor Yellow
}

Write-Step "Building signed QR AJN V5 AAB"
$symbols = Join-Path $output "symbols_build_50"
New-Item -ItemType Directory -Force -Path $symbols | Out-Null

[void](Invoke-Native -Command {
    flutter build appbundle `
        --release `
        --build-name=5.0.0 `
        --build-number=50 `
        --obfuscate `
        --split-debug-info="$symbols" `
        @defines
} -FailureMessage "Signed Android App Bundle build failed." -LogFile (Join-Path $logs "release_aab_build.log"))

$sourceAab = Join-Path $app "build\app\outputs\bundle\release\app-release.aab"
$finalAab = Join-Path $output "QR_AJN_V5_0_0_BUILD_50_com.qr.ajn_SIGNED.aab"
if (-not (Test-Path -LiteralPath $sourceAab)) {
    throw "Release AAB not found: $sourceAab"
}
Copy-Item -LiteralPath $sourceAab -Destination $finalAab -Force

$jarsigner = Join-Path $env:JAVA_HOME "bin\jarsigner.exe"
if (Test-Path -LiteralPath $jarsigner) {
    [void](Invoke-Native -Command {
        & $jarsigner -verify -verbose -certs $finalAab
    } -FailureMessage "AAB signature verification failed." -LogFile (Join-Path $logs "aab_signature_verify.log"))
}

$hash = (Get-FileHash -LiteralPath $finalAab -Algorithm SHA256).Hash
"$hash  $([System.IO.Path]::GetFileName($finalAab))" |
    Set-Content -LiteralPath "$finalAab.sha256.txt" -Encoding ASCII

$status = @"
QR AJN V5 PLAY STORE STATUS

Version:
5.0.0+50

Package:
com.qr.ajn

Signed AAB:
$finalAab

SHA-256:
$hash

Ads:
$(if ($testAds) { "TEST IDS - INTERNAL TESTING ONLY" } else { "Configured production IDs" })

Symbols:
$symbols
"@
$status | Set-Content -LiteralPath (Join-Path $ProjectRoot "FINAL_PLAY_STORE_STATUS.txt") -Encoding UTF8

Write-Host "`nSigned AAB created and verified." -ForegroundColor Green
Write-Host $finalAab -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "/select,`"$finalAab`"" -ErrorAction SilentlyContinue
