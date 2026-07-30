param(
    [Parameter(Mandatory=$true)][string]$FirebaseProjectId,
    [string]$FirestoreLocation = "asia-south1",
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$App = Join-Path $Root "flutter_app"
$PubCacheBin = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"
if (Test-Path $PubCacheBin) { $env:Path = "$PubCacheBin;$env:Path" }

function Invoke-NativeSafe {
    param(
        [Parameter(Mandatory=$true)][scriptblock]$Command,
        [string]$FailureMessage = "External command failed.",
        [switch]$AllowFailure,
        [switch]$Capture
    )
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ($Capture) { $output = (& $Command | Out-String) }
        else { & $Command | Out-Host; $output = "" }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if (-not $AllowFailure -and $code -ne 0) { throw "$FailureMessage Exit code: $code" }
    return [pscustomobject]@{ Output = $output; ExitCode = $code }
}

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Invoke-NativeSafe -Command { npm install -g firebase-tools } -FailureMessage "Firebase CLI installation failed."
}
if (-not (Get-Command flutterfire -ErrorAction SilentlyContinue)) {
    Invoke-NativeSafe -Command { dart pub global activate flutterfire_cli } -FailureMessage "FlutterFire CLI installation failed."
    if (Test-Path $PubCacheBin) { $env:Path = "$PubCacheBin;$env:Path" }
}
if (-not (Get-Command flutterfire -ErrorAction SilentlyContinue)) {
    throw "FlutterFire CLI was installed but is not in PATH. Add $PubCacheBin to PATH and rerun."
}

$projectsResult = Invoke-NativeSafe -Command { firebase projects:list --json } -AllowFailure -Capture
if ($projectsResult.ExitCode -ne 0) {
    Invoke-NativeSafe -Command { firebase login } -FailureMessage "Firebase login failed."
    $projectsResult = Invoke-NativeSafe -Command { firebase projects:list --json } -FailureMessage "Could not read Firebase projects after login." -Capture
}
$projectCheck = $projectsResult.Output
if ($projectCheck -notmatch [regex]::Escape($FirebaseProjectId)) {
    throw "Firebase project '$FirebaseProjectId' was not found in the signed-in account. Create the QR AJN project first or use the correct Project ID."
}

$firebaserc = @"
{
  "projects": {
    "default": "$FirebaseProjectId"
  }
}
"@
[System.IO.File]::WriteAllText((Join-Path $Root ".firebaserc"), $firebaserc, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Configuring FlutterFire for Android package com.qr.ajn..." -ForegroundColor Cyan
Set-Location $App
Invoke-NativeSafe -Command { flutterfire configure --project=$FirebaseProjectId --platforms=android --android-package-name=com.qr.ajn --out=lib/firebase_options.dart --yes } -FailureMessage "FlutterFire configuration failed."

$googleServices = Join-Path $App "android\app\google-services.json"
if (-not (Test-Path $googleServices)) { throw "google-services.json was not generated." }
$googleText = Get-Content $googleServices -Raw
if ($googleText -notmatch '"package_name"\s*:\s*"com\.qr\.ajn"') {
    throw "google-services.json does not contain package com.qr.ajn."
}

Write-Host "Preparing Firebase Web app..." -ForegroundColor Cyan
Set-Location $Root
$webAppId = $null
try {
    $listResult = Invoke-NativeSafe -Command { firebase apps:list --project $FirebaseProjectId --json } -AllowFailure -Capture
    if ($listResult.ExitCode -eq 0) {
        $list = $listResult.Output | ConvertFrom-Json
        $items = if ($list.result) { @($list.result) } elseif ($list.apps) { @($list.apps) } else { @() }
        $web = $items | Where-Object { $_.platform -eq "WEB" } | Select-Object -First 1
        if ($web) { $webAppId = $web.appId }
    }
} catch {}

if (-not $webAppId) {
    try {
        $createdResult = Invoke-NativeSafe -Command { firebase apps:create WEB "QR AJN Web" --project $FirebaseProjectId --json } -AllowFailure -Capture
        if ($createdResult.ExitCode -eq 0) {
            $created = $createdResult.Output | ConvertFrom-Json
            if ($created.result -and $created.result.appId) { $webAppId = $created.result.appId }
            elseif ($created.appId) { $webAppId = $created.appId }
        }
    } catch {
        Write-Host "Web app auto-creation was skipped. Create a Firebase Web app and rerun this script." -ForegroundColor Yellow
    }
}

if ($webAppId) {
    try {
        $sdkResult = Invoke-NativeSafe -Command { firebase apps:sdkconfig WEB $webAppId --project $FirebaseProjectId --json } -AllowFailure -Capture
        if ($sdkResult.ExitCode -eq 0) {
            $sdk = $sdkResult.Output | ConvertFrom-Json
            $cfg = if ($sdk.result) { $sdk.result } else { $sdk }
            if ($cfg.sdkConfig) { $cfg = $cfg.sdkConfig }
            $js = @"
export const firebaseConfig = {
  apiKey: "$($cfg.apiKey)",
  authDomain: "$($cfg.authDomain)",
  projectId: "$($cfg.projectId)",
  storageBucket: "$($cfg.storageBucket)",
  messagingSenderId: "$($cfg.messagingSenderId)",
  appId: "$($cfg.appId)"
};
export const publicDomain = "https://qrajn.online";
"@
            [System.IO.File]::WriteAllText((Join-Path $Root "web_dashboard\firebase-config.js"), $js, (New-Object System.Text.UTF8Encoding($false)))
        }
    } catch {
        Write-Host "Could not generate Firebase Web config automatically. Fill web_dashboard\firebase-config.js manually." -ForegroundColor Yellow
    }
}

$dbCreate = Invoke-NativeSafe -Command { firebase firestore:databases:create "(default)" --location $FirestoreLocation --project $FirebaseProjectId } -AllowFailure -Capture
if ($dbCreate.ExitCode -ne 0) {
    Write-Host "Firestore database may already exist or must be created from Firebase Console. Continuing." -ForegroundColor Yellow
} else {
    Write-Host $dbCreate.Output
}

if (-not $SkipDeploy) {
    Invoke-NativeSafe -Command { firebase deploy --only firestore,remoteconfig,hosting --project $FirebaseProjectId } -FailureMessage "Firebase deploy failed."
}

$manual = @"
QR AJN FIREBASE MANUAL ACTIONS

Project: $FirebaseProjectId
Android package: com.qr.ajn

1. Authentication > Sign-in method:
   - Enable Email/Password
   - Enable Google
2. App Check:
   - Register the Android app with Play Integrity
   - Add the release SHA-256 certificate
3. Firestore:
   - Confirm rules and indexes deployed
4. Remote Config:
   - Set blaze_api_base_url only after deploying the optional Blaze backend
5. Hosting:
   - Add qrajn.online as a custom domain

Console:
https://console.firebase.google.com/project/$FirebaseProjectId/overview
"@
[System.IO.File]::WriteAllText((Join-Path $Root "FIREBASE_MANUAL_ACTIONS.txt"), $manual, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "Firebase connection completed." -ForegroundColor Green
Start-Process "https://console.firebase.google.com/project/$FirebaseProjectId/overview" -ErrorAction SilentlyContinue
