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
        [switch]$AllowFailure
    )
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command 2>&1 | Out-Host
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $old
    }
    if (-not $AllowFailure -and $code -ne 0) {
        throw "$FailureMessage Exit code: $code"
    }
    return $code
}

Push-Location $ProjectRoot
try {
    Write-Host "`n==> Deploying QR AJN Firebase resources" -ForegroundColor Cyan
    [void](Invoke-Native -Command {
        firebase deploy `
            --project "$ProjectId" `
            --only firestore:rules,firestore:indexes,storage,remoteconfig,hosting
    } -FailureMessage "Firebase deployment failed.")
} finally {
    Pop-Location
}

$steps = @"
QR AJN CUSTOM DOMAIN CONNECTION

Firebase project:
$ProjectId

Domain:
$Domain

Hosting URL:
https://$ProjectId.web.app

Complete these steps:

1. Open:
   https://console.firebase.google.com/project/$ProjectId/hosting/sites

2. Click Add custom domain.

3. Enter:
   $Domain

4. Firebase will display ownership and DNS records.
   Sign in to the registrar where $Domain is managed and add the records exactly.

5. Also connect:
   www.$Domain
   Choose redirect to the root domain when Firebase offers it.

6. Wait for Firebase to verify DNS and provision the SSL certificate.
   Do not remove the verification TXT record until Firebase shows Connected.

7. Add these authorized domains:
   Firebase Console > Authentication > Settings > Authorized domains
   - $Domain
   - www.$Domain
   - $ProjectId.web.app
   - $ProjectId.firebaseapp.com

8. Test:
   https://$Domain
   https://$Domain/@your-profile
   https://$Domain/q/YOURCODE

Important:
Custom-domain DNS records are account-specific. The setup cannot safely invent them.
Use only the values displayed by Firebase Hosting.
"@
$path = Join-Path $ProjectRoot "DOMAIN_CONNECTION_STEPS.txt"
$steps | Set-Content -LiteralPath $path -Encoding UTF8

Write-Host "`nFirebase Hosting deployment completed." -ForegroundColor Green
Write-Host "Domain instructions: $path" -ForegroundColor Green
Start-Process "https://console.firebase.google.com/project/$ProjectId/hosting/sites" -ErrorAction SilentlyContinue
