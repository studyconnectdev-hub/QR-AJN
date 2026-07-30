param(
    [Parameter(Mandatory=$true)][string]$FirebaseProjectId,
    [string]$GitHubRepository = "",
    [string]$Domain = "qrajn.online",
    [string]$AdMobAppId = "ca-app-pub-3940256099942544~3347511713",
    [string]$BannerAdUnitId = "ca-app-pub-3940256099942544/6300978111",
    [string]$InterstitialAdUnitId = "ca-app-pub-3940256099942544/1033173712",
    [string]$RewardedAdUnitId = "ca-app-pub-3940256099942544/5224354917",
    [string]$PremiumMonthlyId = "qrajn_pro_monthly",
    [string]$PremiumYearlyId = "qrajn_pro_yearly",
    [string]$BusinessMonthlyId = "qrajn_business_monthly",
    [switch]$SkipFirebaseDeploy,
    [switch]$SkipGit,
    [switch]$SkipBuild,
    [switch]$SkipTests
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

Write-Host "QR AJN V4 COMPLETE PRODUCTION SETUP" -ForegroundColor Cyan

& (Join-Path $Root "00_CHECK_PREREQUISITES.ps1") -InstallMissingCliTools

& (Join-Path $Root "02_CONFIGURE_ADS_PREMIUM.ps1") `
  -AdMobAppId $AdMobAppId `
  -BannerAdUnitId $BannerAdUnitId `
  -InterstitialAdUnitId $InterstitialAdUnitId `
  -RewardedAdUnitId $RewardedAdUnitId `
  -PremiumMonthlyId $PremiumMonthlyId `
  -PremiumYearlyId $PremiumYearlyId `
  -BusinessMonthlyId $BusinessMonthlyId

& (Join-Path $Root "01_CONNECT_FIREBASE.ps1") `
  -FirebaseProjectId $FirebaseProjectId `
  -SkipDeploy:$SkipFirebaseDeploy

if (-not $SkipFirebaseDeploy) {
    & (Join-Path $Root "03_DEPLOY_WEBSITE_DOMAIN.ps1") `
      -FirebaseProjectId $FirebaseProjectId `
      -Domain $Domain
}

if (-not $SkipGit -and -not [string]::IsNullOrWhiteSpace($GitHubRepository)) {
    & (Join-Path $Root "04_PUSH_GITHUB.ps1") -Repository $GitHubRepository
}

if (-not $SkipBuild) {
    & (Join-Path $Root "05_BUILD_SIGNED_AAB.ps1") -SkipTests:$SkipTests
}

Write-Host "QR AJN automated setup completed." -ForegroundColor Green
Write-Host "Complete the manual console items in documentation\MANUAL_CONSOLE_ACTIONS.md." -ForegroundColor Yellow
