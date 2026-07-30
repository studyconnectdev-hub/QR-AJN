param(
    [Parameter(Mandatory=$true)][string]$GoogleCloudProjectId,
    [string]$Region = "asia-south1",
    [Parameter(Mandatory=$true)][string]$AdminApiKey,
    [string]$AllowedOrigin = "*"
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backend = Join-Path $Root "blaze_backend"
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) { throw "Google Cloud CLI is required." }
Set-Location $Backend
gcloud config set project $GoogleCloudProjectId
gcloud services enable run.googleapis.com cloudbuild.googleapis.com firestore.googleapis.com
gcloud run deploy qr-ajn-api `
  --source . `
  --region $Region `
  --allow-unauthenticated `
  --set-env-vars "ADMIN_API_KEY=$AdminApiKey,ALLOWED_ORIGIN=$AllowedOrigin,ANDROID_PACKAGE_NAME=com.qr.ajn,PREMIUM_MONTHLY_ID=qrajn_pro_monthly,PREMIUM_YEARLY_ID=qrajn_pro_yearly,BUSINESS_MONTHLY_ID=qrajn_business_monthly" `
  --min-instances 0 `
  --max-instances 10 `
  --memory 512Mi `
  --cpu 1 `
  --concurrency 80 `
  --timeout 15
Write-Host "Blaze backend deployed. Copy its URL into Remote Config: blaze_api_base_url" -ForegroundColor Green
