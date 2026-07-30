param(
    [switch]$SkipAnalyze,
    [switch]$SkipTests,
    [switch]$AllowTestAds
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$App = Join-Path $Root "flutter_app"
$Out = Join-Path $Root "PLAY_STORE_UPLOAD"
$ConfigFile = Join-Path $Root "PRODUCTION_CONFIG.ps1"

if (-not (Test-Path (Join-Path $App "pubspec.yaml"))) { throw "Flutter project not found." }

if (Test-Path $ConfigFile) {
    . $ConfigFile
} else {
    $QrAjnProductionConfig = @{
      Domain = "https://qrajn.online"
      AdsEnabled = $true
      UseTestAds = $true
      BannerAdUnitId = "ca-app-pub-3940256099942544/6300978111"
      InterstitialAdUnitId = "ca-app-pub-3940256099942544/1033173712"
      RewardedAdUnitId = "ca-app-pub-3940256099942544/5224354917"
      PremiumMonthlyId = "qrajn_pro_monthly"
      PremiumYearlyId = "qrajn_pro_yearly"
      BusinessMonthlyId = "qrajn_business_monthly"
    }
}

if ($QrAjnProductionConfig.UseTestAds -and -not $AllowTestAds) {
    Write-Host "WARNING: Google test ad IDs are configured. Use real AdMob IDs before production submission." -ForegroundColor Yellow
}

$jbrCandidates = @(
    "$env:ProgramFiles\Android\Android Studio\jbr",
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr",
    $env:JAVA_HOME
) | Where-Object { $_ -and (Test-Path (Join-Path $_ "bin\java.exe")) }

if (@($jbrCandidates).Count -gt 0) {
    $env:JAVA_HOME = @($jbrCandidates)[0]
    $env:Path = "$($env:JAVA_HOME)\bin;$env:Path"
}

& (Join-Path $Root "ENSURE_ANDROID_WRAPPER.ps1")

if (-not (Test-Path (Join-Path $App "secure_keys\qr-ajn-upload.jks")) -or
    -not (Test-Path (Join-Path $App "android\key.properties"))) {
    & (Join-Path $Root "CREATE_UPLOAD_KEYSTORE.ps1")
}

$gradleFile = Join-Path $App "android\app\build.gradle.kts"
$gradle = Get-Content $gradleFile -Raw
if ($gradle -notmatch 'applicationId\s*=\s*"com\.qr\.ajn"') { throw "applicationId must be com.qr.ajn." }
if ($gradle -notmatch 'namespace\s*=\s*"com\.qr\.ajn"') { throw "namespace must be com.qr.ajn." }

$googleServices = Join-Path $App "android\app\google-services.json"
if (Test-Path $googleServices) {
    $googleText = Get-Content $googleServices -Raw
    if ($googleText -notmatch '"package_name"\s*:\s*"com\.qr\.ajn"') {
        throw "google-services.json is for a different Android package."
    }
}

Set-Location $App
flutter clean
if ($LASTEXITCODE -ne 0) { throw "flutter clean failed." }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

if (-not $SkipAnalyze) {
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed." }
}
if (-not $SkipTests) {
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "flutter tests failed." }
}

New-Item -ItemType Directory -Force -Path $Out | Out-Null

$defines = @(
    "--dart-define=QR_AJN_DOMAIN=$($QrAjnProductionConfig.Domain)",
    "--dart-define=ADS_ENABLED=$($QrAjnProductionConfig.AdsEnabled.ToString().ToLower())",
    "--dart-define=USE_TEST_ADS=$($QrAjnProductionConfig.UseTestAds.ToString().ToLower())",
    "--dart-define=ADMOB_BANNER_ID=$($QrAjnProductionConfig.BannerAdUnitId)",
    "--dart-define=ADMOB_INTERSTITIAL_ID=$($QrAjnProductionConfig.InterstitialAdUnitId)",
    "--dart-define=ADMOB_REWARDED_ID=$($QrAjnProductionConfig.RewardedAdUnitId)",
    "--dart-define=PREMIUM_MONTHLY_ID=$($QrAjnProductionConfig.PremiumMonthlyId)",
    "--dart-define=PREMIUM_YEARLY_ID=$($QrAjnProductionConfig.PremiumYearlyId)",
    "--dart-define=BUSINESS_MONTHLY_ID=$($QrAjnProductionConfig.BusinessMonthlyId)"
)

$arguments = @(
    "build", "appbundle", "--release",
    "--build-name=4.0.0", "--build-number=40",
    "--obfuscate", "--split-debug-info=$Out\symbols"
) + $defines

& flutter @arguments
if ($LASTEXITCODE -ne 0) { throw "Signed AAB build failed." }

$sourceAab = Join-Path $App "build\app\outputs\bundle\release\app-release.aab"
$finalAab = Join-Path $Out "QR_AJN_V4_BUILD_40_com.qr.ajn_SIGNED.aab"
if (-not (Test-Path $sourceAab)) { throw "Built AAB was not found." }
Copy-Item $sourceAab $finalAab -Force

$jarsigner = Get-Command jarsigner -ErrorAction SilentlyContinue
if ($jarsigner) {
    & $jarsigner.Source -verify -verbose -certs $finalAab | Out-File (Join-Path $Out "AAB_SIGNATURE_VERIFY.txt") -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw "AAB signature verification failed." }
}

$hash = (Get-FileHash $finalAab -Algorithm SHA256).Hash
[System.IO.File]::WriteAllText("$finalAab.sha256.txt", $hash + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Host "SIGNED PLAY STORE AAB CREATED:" -ForegroundColor Green
Write-Host $finalAab -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "/select,`"$finalAab`"" -ErrorAction SilentlyContinue
