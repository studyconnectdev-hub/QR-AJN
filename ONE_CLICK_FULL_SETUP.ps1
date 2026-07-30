param(
    [string]$ProjectRoot = $PSScriptRoot,
    [string]$FirebaseProjectId = "",
    [string]$RepositoryUrl = "https://github.com/studyconnectdev-hub/QR-AJN.git",
    [string]$Domain = "qrajn.online",
    [switch]$SkipFirebase,
    [switch]$SkipGit,
    [switch]$SkipAndroidRun,
    [switch]$BuildSignedAab
)

$ErrorActionPreference = "Stop"

function Ask([string]$Message, [string]$Default = "") {
    $suffix = if ([string]::IsNullOrWhiteSpace($Default)) { "" } else { " [$Default]" }
    $answer = Read-Host "$Message$suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $Default
    }
    return $answer.Trim()
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "flutter_app\pubspec.yaml"))) {
    throw "QR AJN V5 project not found: $ProjectRoot"
}

Write-Host @"

============================================================
QR AJN V5 COMPLETE PRODUCTION SETUP
============================================================
Package: com.qr.ajn
Version: 5.0.0+50
Domain: $Domain
Firebase + Android + Website + GitHub + Ads + Premium
============================================================

"@ -ForegroundColor Cyan

if (-not $SkipFirebase -and [string]::IsNullOrWhiteSpace($FirebaseProjectId)) {
    $FirebaseProjectId = Ask "Enter the Firebase Project ID you created"
}
if (-not $SkipGit) {
    $RepositoryUrl = Ask "Enter the GitHub repository URL" $RepositoryUrl
}
$Domain = Ask "Enter the public domain" $Domain

$useRealAds = Ask "Do you have real QR AJN AdMob IDs now? Type YES to enter them" "NO"
$adMobAppId = "ca-app-pub-3940256099942544~3347511713"
$bannerId = "ca-app-pub-3940256099942544/6300978111"
$interstitialId = "ca-app-pub-3940256099942544/1033173712"
$rewardedId = "ca-app-pub-3940256099942544/5224354917"

if ($useRealAds -eq "YES") {
    $adMobAppId = Ask "AdMob Android App ID"
    $bannerId = Ask "AdMob Banner Ad Unit ID"
    $interstitialId = Ask "AdMob Interstitial Ad Unit ID"
    $rewardedId = Ask "AdMob Rewarded Ad Unit ID"
}

$buildSignedNow = $BuildSignedAab
if (-not $buildSignedNow) {
    $buildSignedNow = (Ask "Build the signed Play Store AAB after Android testing? Type YES" "NO") -eq "YES"
}

$deployBlazeNow = $false
$blazeAdminKey = ""
if (-not $SkipFirebase) {
    $deployBlazeNow = (Ask "Did you upgrade this Firebase project to Blaze and want to deploy the optional production backend? Type YES" "NO") -eq "YES"
    if ($deployBlazeNow) {
        $blazeAdminKey = Ask "Create or paste a private admin API key with at least 32 characters"
        if ($blazeAdminKey.Length -lt 32) {
            throw "Blaze backend admin API key must contain at least 32 characters."
        }
    }
}

$config = @"
`$FirebaseProjectId = "$FirebaseProjectId"
`$RepositoryUrl = "$RepositoryUrl"
`$Domain = "$Domain"
"@
$config | Set-Content -LiteralPath (Join-Path $ProjectRoot "PRODUCTION_CONFIG.ps1") -Encoding UTF8

& (Join-Path $ProjectRoot "00_CHECK_PREREQUISITES.ps1") -ProjectRoot $ProjectRoot
& (Join-Path $ProjectRoot "00_REPAIR_ANDROID_PROJECT.ps1") -ProjectRoot $ProjectRoot

& (Join-Path $ProjectRoot "02_CONFIGURE_ADS_PREMIUM.ps1") `
    -ProjectRoot $ProjectRoot `
    -Domain $Domain `
    -AdMobAppId $adMobAppId `
    -BannerId $bannerId `
    -InterstitialId $interstitialId `
    -RewardedId $rewardedId

if (-not $SkipFirebase) {
    if ([string]::IsNullOrWhiteSpace($FirebaseProjectId)) {
        throw "Firebase Project ID is required."
    }
    & (Join-Path $ProjectRoot "01_CONNECT_FIREBASE.ps1") `
        -ProjectId $FirebaseProjectId `
        -Domain $Domain `
        -ProjectRoot $ProjectRoot

    & (Join-Path $ProjectRoot "03_DEPLOY_FIREBASE_DOMAIN.ps1") `
        -ProjectId $FirebaseProjectId `
        -Domain $Domain `
        -ProjectRoot $ProjectRoot
}

if (-not $SkipGit) {
    & (Join-Path $ProjectRoot "04_PUSH_GITHUB.ps1") `
        -RepositoryUrl $RepositoryUrl `
        -ProjectRoot $ProjectRoot
}

if (-not $SkipAndroidRun) {
    & (Join-Path $ProjectRoot "05_BUILD_RUN_ANDROID.ps1") `
        -ProjectRoot $ProjectRoot
}

if ($buildSignedNow) {
    & (Join-Path $ProjectRoot "06_BUILD_SIGNED_AAB.ps1") `
        -ProjectRoot $ProjectRoot
}

if ($deployBlazeNow) {
    & (Join-Path $ProjectRoot "DEPLOY_BLAZE_BACKEND.ps1") `
        -ProjectId $FirebaseProjectId `
        -AdminApiKey $blazeAdminKey `
        -AllowedOrigin "https://$Domain" `
        -ProjectRoot $ProjectRoot
}

$status = @"
QR AJN V5 ONE-CLICK STATUS

Project:
$ProjectRoot

Firebase:
$(if ($SkipFirebase) { "SKIPPED" } else { $FirebaseProjectId })

Domain:
$Domain

GitHub:
$(if ($SkipGit) { "SKIPPED" } else { $RepositoryUrl })

Android run:
$(if ($SkipAndroidRun) { "SKIPPED" } else { "REQUESTED" })

Signed AAB:
$(if ($buildSignedNow) { "REQUESTED" } else { "SKIPPED - run 06_BUILD_SIGNED_AAB.ps1 later" })

Optional Blaze backend:
$(if ($deployBlazeNow) { "REQUESTED" } else { "SKIPPED - Spark-first setup" })

Next manual actions:
- Enable Email/Password and Google Auth providers.
- Register Play Integrity App Check.
- Add Firebase Hosting DNS records shown in Console.
- Replace test AdMob IDs if still active.
- Create and activate the four Play subscription products.
- Use the original upload key for an existing Play listing.
"@
$status | Set-Content -LiteralPath (Join-Path $ProjectRoot "FINAL_PRODUCTION_SETUP_STATUS.txt") -Encoding UTF8

Write-Host "`nQR AJN V5 setup workflow completed." -ForegroundColor Green
Write-Host "Read FINAL_PRODUCTION_SETUP_STATUS.txt and the generated manual-action files." -ForegroundColor Green
