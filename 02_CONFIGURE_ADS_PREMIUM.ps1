param(
    [string]$ProjectRoot = $PSScriptRoot,
    [string]$Domain = "qrajn.online",
    [string]$AdMobAppId = "ca-app-pub-3940256099942544~3347511713",
    [string]$BannerId = "ca-app-pub-3940256099942544/6300978111",
    [string]$InterstitialId = "ca-app-pub-3940256099942544/1033173712",
    [string]$RewardedId = "ca-app-pub-3940256099942544/5224354917",
    [string]$PremiumMonthlyId = "qrajn_pro_monthly",
    [string]$PremiumYearlyId = "qrajn_pro_yearly",
    [string]$BusinessMonthlyId = "qrajn_business_monthly",
    [string]$BusinessYearlyId = "qrajn_business_yearly"
)

$ErrorActionPreference = "Stop"

$app = Join-Path $ProjectRoot "flutter_app"
$stringsFile = Join-Path $app "android\app\src\main\res\values\strings.xml"
if (-not (Test-Path -LiteralPath $stringsFile)) {
    throw "Android strings.xml not found: $stringsFile"
}

$strings = Get-Content -LiteralPath $stringsFile -Raw
if ($strings -match '<string name="admob_app_id">.*?</string>') {
    $strings = [regex]::Replace(
        $strings,
        '<string name="admob_app_id">.*?</string>',
        "<string name=`"admob_app_id`">$AdMobAppId</string>"
    )
} else {
    $strings = $strings.Replace(
        '</resources>',
        "    <string name=`"admob_app_id`">$AdMobAppId</string>`r`n</resources>"
    )
}
[System.IO.File]::WriteAllText(
    $stringsFile,
    $strings,
    [System.Text.UTF8Encoding]::new($false)
)

$config = @"
# Generated locally by QR AJN V5. Do not commit this file.
`$env:QR_AJN_DOMAIN = "https://$Domain"
`$env:ADMOB_APP_ID = "$AdMobAppId"
`$env:ADMOB_BANNER_ID = "$BannerId"
`$env:ADMOB_INTERSTITIAL_ID = "$InterstitialId"
`$env:ADMOB_REWARDED_ID = "$RewardedId"
`$env:PREMIUM_MONTHLY_ID = "$PremiumMonthlyId"
`$env:PREMIUM_YEARLY_ID = "$PremiumYearlyId"
`$env:BUSINESS_MONTHLY_ID = "$BusinessMonthlyId"
`$env:BUSINESS_YEARLY_ID = "$BusinessYearlyId"
"@
$config | Set-Content -LiteralPath (Join-Path $ProjectRoot "BUILD_DEFINES.ps1") -Encoding UTF8

$products = @"
QR AJN GOOGLE PLAY PRODUCT SETUP

Android package:
com.qr.ajn

Create these subscription product IDs exactly:

1. $PremiumMonthlyId
   Name: QR AJN Pro Monthly
   Benefits: No ads, advanced QR design, PNG/SVG/PDF/high-resolution exports.

2. $PremiumYearlyId
   Name: QR AJN Pro Yearly
   Benefits: Same Pro benefits billed yearly.

3. $BusinessMonthlyId
   Name: QR AJN Business Monthly
   Benefits: Public profiles, dynamic QR, business templates, leads and analytics.

4. $BusinessYearlyId
   Name: QR AJN Business Yearly
   Benefits: Same Business benefits billed yearly.

Play Console steps:
Monetize with Play > Products > Subscriptions
Create each product, add an active base plan, configure India pricing and activate it.

IMPORTANT:
- Google test ad IDs are safe only for development.
- Replace them with real QR AJN AdMob IDs before publishing a revenue-enabled release.
- Complete the AdMob privacy/message setup and Play Data Safety declaration.
- Server verification requires the optional Blaze backend and Android Publisher API access.
"@
$products | Set-Content -LiteralPath (Join-Path $ProjectRoot "PLAY_CONSOLE_PRODUCT_SETUP.txt") -Encoding UTF8

$isTest = $AdMobAppId -eq "ca-app-pub-3940256099942544~3347511713"
Write-Host "Ads and premium product identifiers configured." -ForegroundColor Green
if ($isTest) {
    Write-Host "Google test ad IDs remain active for safe development." -ForegroundColor Yellow
} else {
    Write-Host "Real AdMob application ID configured." -ForegroundColor Green
}
