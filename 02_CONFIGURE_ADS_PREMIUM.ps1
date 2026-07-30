param(
    [string]$AdMobAppId = "ca-app-pub-3940256099942544~3347511713",
    [string]$BannerAdUnitId = "ca-app-pub-3940256099942544/6300978111",
    [string]$InterstitialAdUnitId = "ca-app-pub-3940256099942544/1033173712",
    [string]$RewardedAdUnitId = "ca-app-pub-3940256099942544/5224354917",
    [string]$PremiumMonthlyId = "qrajn_pro_monthly",
    [string]$PremiumYearlyId = "qrajn_pro_yearly",
    [string]$BusinessMonthlyId = "qrajn_business_monthly"
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Strings = Join-Path $Root "flutter_app\android\app\src\main\res\values\strings.xml"

if (-not (Test-Path $Strings)) { throw "Android strings.xml was not found." }

$text = Get-Content $Strings -Raw
if ($text -match '<string name="admob_app_id">.*?</string>') {
    $text = [regex]::Replace($text, '<string name="admob_app_id">.*?</string>', "<string name=`"admob_app_id`">$AdMobAppId</string>")
} else {
    $text = $text.Replace('</resources>', "    <string name=`"admob_app_id`">$AdMobAppId</string>`r`n</resources>")
}
[System.IO.File]::WriteAllText($Strings, $text, (New-Object System.Text.UTF8Encoding($false)))

$useTestAds = $AdMobAppId.StartsWith("ca-app-pub-3940256099942544")
$testAdsLiteral = if ($useTestAds) { '$true' } else { '$false' }
$config = @"
`$QrAjnProductionConfig = @{
  Domain = "https://qrajn.online"
  AdsEnabled = `$true
  UseTestAds = $testAdsLiteral
  BannerAdUnitId = "$BannerAdUnitId"
  InterstitialAdUnitId = "$InterstitialAdUnitId"
  RewardedAdUnitId = "$RewardedAdUnitId"
  PremiumMonthlyId = "$PremiumMonthlyId"
  PremiumYearlyId = "$PremiumYearlyId"
  BusinessMonthlyId = "$BusinessMonthlyId"
}
"@
[System.IO.File]::WriteAllText((Join-Path $Root "PRODUCTION_CONFIG.ps1"), $config, (New-Object System.Text.UTF8Encoding($true)))

$productGuide = @"
QR AJN PLAY PRODUCTS

Package: com.qr.ajn

Create and activate:
- $PremiumMonthlyId
- $PremiumYearlyId
- $BusinessMonthlyId

Add base plans, regional prices, benefits and license testers.
Use an internal test track before testing purchases.
"@
[System.IO.File]::WriteAllText((Join-Path $Root "PLAY_CONSOLE_PRODUCT_SETUP.txt"), $productGuide, (New-Object System.Text.UTF8Encoding($true)))

Write-Host "Ads and premium IDs configured." -ForegroundColor Green
if ($useTestAds) {
    Write-Host "Google test ad IDs are active. Replace them before uploading a revenue-enabled production release." -ForegroundColor Yellow
}
Start-Process "https://apps.admob.com/" -ErrorAction SilentlyContinue
