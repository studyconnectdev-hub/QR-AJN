param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [string]$Domain = "qrajn.online",
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

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
        }
        else {
            & $Command 2>&1 | Out-Host
            $output = ""
        }

        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }

    if (-not $AllowFailure -and $code -ne 0) {
        throw "$FailureMessage Exit code: $code`n$output"
    }

    return [pscustomobject]@{
        Output   = $output
        ExitCode = $code
    }
}

Push-Location $ProjectRoot

try {
    Write-Host "`n==> Deploying Firestore, Remote Config and Hosting" -ForegroundColor Cyan

    [void](Invoke-Native `
        -Command {
            firebase deploy `
                --project "$ProjectId" `
                --only firestore:rules,firestore:indexes,remoteconfig,hosting
        } `
        -FailureMessage "Core Firebase deployment failed.")

    Write-Host "`nCore Firebase deployment completed." -ForegroundColor Green

    Write-Host "`n==> Checking optional Cloud Storage deployment" -ForegroundColor Cyan

    $storage = Invoke-Native `
        -Command {
            firebase deploy `
                --project "$ProjectId" `
                --only storage
        } `
        -AllowFailure `
        -Capture

    if ($storage.ExitCode -eq 0) {
        Write-Host $storage.Output
        $storageStatus = "DEPLOYED"
        Write-Host "Cloud Storage rules deployed." -ForegroundColor Green
    }
    elseif ($storage.Output -match "has not been set up|click 'Get Started'|Storage has not been set up") {
        $storageStatus = "PENDING_BLAZE_AND_CONSOLE_SETUP"

        Write-Host @"

Cloud Storage was skipped safely.

Firestore, Remote Config and Hosting are already deployed.
New Firebase default Storage buckets require Blaze billing and first-time
provisioning from Firebase Console. The QR scanner, static generator,
authentication, Firestore profiles, dynamic QR records and website remain
available. Business photo, logo, gallery and brochure uploads remain disabled
until Storage is activated.

"@ -ForegroundColor Yellow
    }
    else {
        $storageStatus = "PENDING_OTHER_ERROR"
        Write-Host $storage.Output -ForegroundColor Yellow
        Write-Host "Storage rules could not be deployed, but the core Firebase deployment is complete." -ForegroundColor Yellow
    }
}
finally {
    Pop-Location
}

$steps = @"
QR AJN CUSTOM DOMAIN AND STORAGE STATUS

Firebase project:
$ProjectId

Domain:
$Domain

Hosting:
https://$ProjectId.web.app

Core Firebase:
DEPLOYED
- Firestore rules
- Firestore indexes
- Remote Config
- Firebase Hosting

Cloud Storage:
$storageStatus

CUSTOM DOMAIN

1. Open:
   https://console.firebase.google.com/project/$ProjectId/hosting/sites

2. Click Add custom domain.

3. Enter:
   $Domain

4. Add the exact DNS records displayed by Firebase to your registrar.

5. Also connect:
   www.$Domain

6. Add authorized domains in Firebase Authentication:
   - $Domain
   - www.$Domain
   - $ProjectId.web.app
   - $ProjectId.firebaseapp.com

CLOUD STORAGE LATER

To enable business images, logos, gallery files and brochures:

1. Upgrade the Firebase project to Blaze.
2. Open:
   https://console.firebase.google.com/project/$ProjectId/storage
3. Click Get started.
4. Choose the desired bucket location.
5. Rerun:
   firebase deploy --project "$ProjectId" --only storage

Important:
Use the exact DNS records shown by Firebase Hosting.
"@

$statusPath = Join-Path $ProjectRoot "DOMAIN_AND_STORAGE_STATUS.txt"
$steps | Set-Content -LiteralPath $statusPath -Encoding UTF8

Write-Host "`nFirebase deployment workflow completed." -ForegroundColor Green
Write-Host "Status: $statusPath" -ForegroundColor Green