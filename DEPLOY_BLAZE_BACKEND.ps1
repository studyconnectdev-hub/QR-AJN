param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [Parameter(Mandatory = $true)][string]$AdminApiKey,
    [string]$AllowedOrigin = "https://qrajn.online",
    [string]$ProjectRoot = $PSScriptRoot,
    [string]$Region = "asia-south1"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Command,
        [string]$FailureMessage = "Command failed."
    )
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command 2>&1 | Out-Host
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $old
    }
    if ($code -ne 0) {
        throw "$FailureMessage Exit code: $code"
    }
}

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    throw "Google Cloud CLI is required for the optional Blaze backend."
}
if ($AdminApiKey.Length -lt 32) {
    throw "Admin API key must contain at least 32 characters."
}

$backend = Join-Path $ProjectRoot "blaze_backend"
Set-Location $backend

Invoke-Native -Command {
    npm install
} -FailureMessage "Backend npm install failed."

Invoke-Native -Command {
    npm run check
} -FailureMessage "Backend source validation failed."

Invoke-Native -Command {
    npm test
} -FailureMessage "Backend tests failed."

Invoke-Native -Command {
    gcloud config set project "$ProjectId"
} -FailureMessage "Could not select Google Cloud project."

Invoke-Native -Command {
    gcloud services enable `
        run.googleapis.com `
        cloudbuild.googleapis.com `
        artifactregistry.googleapis.com `
        androidpublisher.googleapis.com `
        secretmanager.googleapis.com `
        --project "$ProjectId"
} -FailureMessage "Required Blaze APIs could not be enabled."

Invoke-Native -Command {
    gcloud run deploy qr-ajn-api `
        --source . `
        --project "$ProjectId" `
        --region "$Region" `
        --allow-unauthenticated `
        --set-env-vars "ALLOWED_ORIGIN=$AllowedOrigin,ADMIN_API_KEY=$AdminApiKey,ANDROID_PACKAGE_NAME=com.qr.ajn,PREMIUM_MONTHLY_ID=qrajn_pro_monthly,PREMIUM_YEARLY_ID=qrajn_pro_yearly,BUSINESS_MONTHLY_ID=qrajn_business_monthly,BUSINESS_YEARLY_ID=qrajn_business_yearly"
} -FailureMessage "Cloud Run deployment failed."

Write-Host "Blaze backend deployment completed." -ForegroundColor Green
Write-Host "Add the Cloud Run URL to Remote Config key: blaze_api_base_url" -ForegroundColor Yellow
