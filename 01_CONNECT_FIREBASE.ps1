param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [string]$ProjectRoot = $PSScriptRoot,
    [string]$FirestoreLocation = "asia-south1",
    [string]$Domain = "qrajn.online"
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
        [switch]$Capture
    )
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ($Capture) {
            $output = (& $Command 2>&1 | Out-String)
        } else {
            & $Command 2>&1 | Out-Host
            $output = ""
        }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $old
    }
    if (-not $AllowFailure -and $code -ne 0) {
        throw "$FailureMessage Exit code: $code`n$output"
    }
    return [pscustomobject]@{ Output = $output; ExitCode = $code }
}

function Read-JsonOutput([string]$Raw) {
    $start = $Raw.IndexOf("{")
    $end = $Raw.LastIndexOf("}")
    if ($start -lt 0 -or $end -le $start) {
        return $null
    }
    try {
        return ($Raw.Substring($start, $end - $start + 1) | ConvertFrom-Json)
    } catch {
        return $null
    }
}

$app = Join-Path $ProjectRoot "flutter_app"
$web = Join-Path $ProjectRoot "web_dashboard"

if (-not (Test-Path -LiteralPath (Join-Path $app "pubspec.yaml"))) {
    throw "Invalid project root: $ProjectRoot"
}

Write-Step "Authenticating Firebase CLI"
$login = Invoke-Native -Command {
    firebase login:list --json
} -AllowFailure -Capture

if ($login.ExitCode -ne 0 -or $login.Output -notmatch '"user"|"email"') {
    [void](Invoke-Native -Command {
        firebase login
    } -FailureMessage "Firebase login failed.")
}

Write-Step "Confirming Firebase project access"
$projects = Invoke-Native -Command {
    firebase projects:list --json
} -FailureMessage "Could not list Firebase projects." -Capture
if ($projects.Output -notmatch [regex]::Escape($ProjectId)) {
    throw "Firebase project '$ProjectId' is not visible to the logged-in account. Create it in Firebase Console or choose the correct Google account."
}

@"
{
  "projects": {
    "default": "$ProjectId"
  }
}
"@ | Set-Content -LiteralPath (Join-Path $ProjectRoot ".firebaserc") -Encoding UTF8

Write-Step "Configuring FlutterFire for com.qr.ajn"
Push-Location $app
try {
    [void](Invoke-Native -Command {
        flutterfire configure `
            --project="$ProjectId" `
            --platforms=android `
            --android-package-name=com.qr.ajn `
            --android-out=android/app/google-services.json `
            --out=lib/firebase_options.dart `
            --yes
    } -FailureMessage "FlutterFire configuration failed.")
} finally {
    Pop-Location
}

$googleServices = Join-Path $app "android\app\google-services.json"
if (-not (Test-Path -LiteralPath $googleServices)) {
    throw "google-services.json was not generated."
}
if ((Get-Content -LiteralPath $googleServices -Raw) -notmatch '"package_name"\s*:\s*"com\.qr\.ajn"') {
    throw "google-services.json does not contain package com.qr.ajn."
}

Write-Step "Creating or locating the QR AJN Firebase Web app"
$appsResult = Invoke-Native -Command {
    firebase apps:list WEB --project "$ProjectId" --json
} -FailureMessage "Could not list Firebase Web apps." -Capture
$appsJson = Read-JsonOutput $appsResult.Output
$webApp = $null

if ($appsJson -and $appsJson.result) {
    $candidateApps = @($appsJson.result)
    if ($appsJson.result.apps) {
        $candidateApps = @($appsJson.result.apps)
    }
    $webApp = $candidateApps |
        Where-Object { $_.displayName -eq "QR AJN Web" -or $_.displayName -eq "QR AJN" } |
        Select-Object -First 1
    if (-not $webApp) {
        $webApp = $candidateApps | Select-Object -First 1
    }
}

$webAppId = $webApp.appId

if ([string]::IsNullOrWhiteSpace($webAppId)) {
    $createResult = Invoke-Native -Command {
        firebase apps:create WEB "QR AJN Web" --project "$ProjectId" --json
    } -FailureMessage "Firebase Web app creation failed." -Capture
    $createJson = Read-JsonOutput $createResult.Output
    $webAppId = $createJson.result.appId
}

if ([string]::IsNullOrWhiteSpace($webAppId)) {
    throw "Could not determine the Firebase Web App ID."
}

Write-Step "Downloading Firebase Web SDK configuration"
$sdkResult = Invoke-Native -Command {
    firebase apps:sdkconfig WEB "$webAppId" --project "$ProjectId" --json
} -FailureMessage "Could not download Firebase Web configuration." -Capture
$sdkJson = Read-JsonOutput $sdkResult.Output
$config = $sdkJson.result.sdkConfig
if (-not $config) {
    $config = $sdkJson.result
}
if (-not $config.apiKey) {
    throw "Firebase Web SDK configuration did not contain an API key."
}

$configJs = @"
export const firebaseConfig = {
  apiKey: "$($config.apiKey)",
  authDomain: "$($config.authDomain)",
  projectId: "$($config.projectId)",
  storageBucket: "$($config.storageBucket)",
  messagingSenderId: "$($config.messagingSenderId)",
  appId: "$($config.appId)"
};

export const publicDomain = "https://$Domain";
"@
[System.IO.File]::WriteAllText(
    (Join-Path $web "firebase-config.js"),
    $configJs,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Step "Enabling Firebase and Google Cloud APIs when gcloud is available"
$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
if ($gcloud) {
    [void](Invoke-Native -Command {
        gcloud config set project "$ProjectId"
    } -FailureMessage "Could not select Google Cloud project." -AllowFailure)

    [void](Invoke-Native -Command {
        gcloud services enable `
            firestore.googleapis.com `
            firebasestorage.googleapis.com `
            firebasehosting.googleapis.com `
            identitytoolkit.googleapis.com `
            firebaseappcheck.googleapis.com `
            fcm.googleapis.com `
            cloudresourcemanager.googleapis.com `
            --project "$ProjectId"
    } -FailureMessage "One or more APIs could not be enabled automatically." -AllowFailure)

    [void](Invoke-Native -Command {
        gcloud firestore databases create `
            --database="(default)" `
            --location="$FirestoreLocation" `
            --type=firestore-native `
            --project="$ProjectId"
    } -FailureMessage "Firestore database may already exist." -AllowFailure)
} else {
    Write-Host "Google Cloud CLI is not installed. Firebase deploy will validate required APIs." -ForegroundColor Yellow
}

Write-Step "Deploying Firestore, Remote Config and Hosting"
Push-Location $ProjectRoot
try {
    $deploy = Invoke-Native -Command {
        firebase deploy `
            --project "$ProjectId" `
            --only firestore:rules,firestore:indexes,remoteconfig,hosting
    } -FailureMessage "Firebase deploy needs attention." -AllowFailure

    if ($deploy.ExitCode -ne 0) {
        Write-Host "A Firebase product may need first-time activation in Console. See FIREBASE_MANUAL_ACTIONS.txt, activate the product, then run 03_DEPLOY_FIREBASE_DOMAIN.ps1." -ForegroundColor Yellow
    }
} finally {
    Pop-Location
}

$manual = @"
QR AJN FIREBASE MANUAL ACTIONS

Project:
$ProjectId

1. Authentication
   Firebase Console > Authentication > Sign-in method
   Enable:
   - Email/Password
   - Google

2. App Check
   Firebase Console > App Check > Android app com.qr.ajn
   Register Play Integrity.
   Add the debug token only for local testing.

3. Storage
   If the first deploy says Storage is not initialized:
   Firebase Console > Storage > Get started
   Choose the same region as Firestore, then rerun deployment.

4. Android certificates
   Add the release SHA-1 and SHA-256 from the final upload certificate to:
   Project settings > Your apps > com.qr.ajn
   Download the refreshed google-services.json if requested.

5. Billing
   Spark supports the base app. Upgrade to Blaze only before deploying the optional Cloud Run backend.

Firebase Console:
https://console.firebase.google.com/project/$ProjectId/overview

Hosting:
https://$ProjectId.web.app

Planned custom domain:
https://$Domain
"@
$manual | Set-Content -LiteralPath (Join-Path $ProjectRoot "FIREBASE_MANUAL_ACTIONS.txt") -Encoding UTF8

Write-Host "`nFirebase connection completed for $ProjectId." -ForegroundColor Green
Write-Host "Hosting: https://$ProjectId.web.app" -ForegroundColor Green
