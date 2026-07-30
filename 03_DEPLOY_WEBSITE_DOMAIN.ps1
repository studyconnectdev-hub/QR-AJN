param(
    [Parameter(Mandatory=$true)][string]$FirebaseProjectId,
    [string]$Domain = "qrajn.online"
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$previousPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    firebase deploy --only hosting --project $FirebaseProjectId | Out-Host
    $deployCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $previousPreference
}
if ($deployCode -ne 0) { throw "Firebase Hosting deployment failed. Exit code: $deployCode" }

$guide = @"
QR AJN DOMAIN CONNECTION

Firebase project: $FirebaseProjectId
Domain: $Domain

1. Open Firebase Console > Hosting.
2. Click Add custom domain.
3. Add $Domain.
4. Add the exact TXT ownership record shown by Firebase to your registrar DNS.
5. Add the exact A/AAAA records shown by Firebase.
6. Add www.$Domain and redirect it to $Domain.
7. Remove conflicting old A, AAAA or CNAME records.
8. Wait for DNS propagation and managed SSL.

Firebase Hosting:
https://console.firebase.google.com/project/$FirebaseProjectId/hosting/sites
"@
[System.IO.File]::WriteAllText((Join-Path $Root "DOMAIN_CONNECTION_STEPS.txt"), $guide, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "Website deployed. DNS ownership must now be completed at the domain registrar." -ForegroundColor Green
Start-Process "https://console.firebase.google.com/project/$FirebaseProjectId/hosting/sites" -ErrorAction SilentlyContinue
