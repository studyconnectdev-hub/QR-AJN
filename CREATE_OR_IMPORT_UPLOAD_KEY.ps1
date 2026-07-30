param(
    [string]$ProjectRoot = $PSScriptRoot,
    [string]$ExistingKeystore = "",
    [string]$ExistingKeyProperties = ""
)

$ErrorActionPreference = "Stop"

$app = Join-Path $ProjectRoot "flutter_app"
$keyFolder = Join-Path $app "secure_keys"
$keyFile = Join-Path $keyFolder "qr-ajn-upload.jks"
$keyProperties = Join-Path $app "android\key.properties"
$backupFolder = Join-Path $env:USERPROFILE "Documents\QR_AJN_UPLOAD_KEY_PERMANENT_BACKUP"

New-Item -ItemType Directory -Force -Path $keyFolder | Out-Null
New-Item -ItemType Directory -Force -Path $backupFolder | Out-Null

if ([string]::IsNullOrWhiteSpace($ExistingKeystore)) {
    $ExistingKeystore = @(
        (Join-Path $backupFolder "qr-ajn-upload.jks"),
        (Join-Path $env:USERPROFILE "Documents\PRIVATE_SAFE_QR\flutter_app\secure_keys\qr-ajn-upload.jks"),
        (Join-Path $env:USERPROFILE "Documents\QR_AJN_COMPLETE_PRODUCTION_V5_0_0\flutter_app\secure_keys\qr-ajn-upload.jks")
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($ExistingKeyProperties)) {
    $ExistingKeyProperties = @(
        (Join-Path $backupFolder "key.properties"),
        (Join-Path $env:USERPROFILE "Documents\PRIVATE_SAFE_QR\flutter_app\android\key.properties"),
        (Join-Path $env:USERPROFILE "Documents\QR_AJN_COMPLETE_PRODUCTION_V5_0_0\flutter_app\android\key.properties")
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not [string]::IsNullOrWhiteSpace($ExistingKeystore)) {
    Copy-Item -LiteralPath $ExistingKeystore -Destination $keyFile -Force
    Write-Host "Existing QR AJN upload keystore imported." -ForegroundColor Green
}
if (-not [string]::IsNullOrWhiteSpace($ExistingKeyProperties)) {
    Copy-Item -LiteralPath $ExistingKeyProperties -Destination $keyProperties -Force
    Write-Host "Matching key.properties imported." -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $keyFile)) {
    Write-Host "No existing upload key was found." -ForegroundColor Yellow
    Write-Host "For an existing Play app, use its original upload key or complete a Play upload-key reset." -ForegroundColor Yellow
    $generate = Read-Host "Generate a NEW upload key for a new Play listing? Type YES"
    if ($generate -ne "YES") { throw "Upload key setup cancelled." }

    $storePassword = Read-Host "Create a strong keystore password"
    $keyPassword = Read-Host "Create a strong key password"
    if ($storePassword.Length -lt 8 -or $keyPassword.Length -lt 8) {
        throw "Passwords must contain at least 8 characters."
    }

    & keytool -genkeypair `
        -v `
        -keystore $keyFile `
        -storepass $storePassword `
        -keypass $keyPassword `
        -alias qr_ajn_upload `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -dname "CN=QR AJN, OU=Mobile, O=QR AJN, L=Hyderabad, ST=Telangana, C=IN"
    if ($LASTEXITCODE -ne 0) { throw "Keystore generation failed." }

    @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=qr_ajn_upload
storeFile=../secure_keys/qr-ajn-upload.jks
"@ | Set-Content -LiteralPath $keyProperties -Encoding ASCII
}

if (-not (Test-Path -LiteralPath $keyProperties)) {
    Write-Host "The keystore exists, but its matching key.properties was not found." -ForegroundColor Yellow
    $storePassword = Read-Host "Enter the EXISTING keystore password"
    $keyPassword = Read-Host "Enter the EXISTING key password"
    $keyAlias = Read-Host "Enter the EXISTING key alias"
    if ([string]::IsNullOrWhiteSpace($keyAlias)) { throw "Key alias is required." }

    & keytool -list -keystore $keyFile -storepass $storePassword -alias $keyAlias | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "The existing keystore password or alias is incorrect." }

    @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=../secure_keys/qr-ajn-upload.jks
"@ | Set-Content -LiteralPath $keyProperties -Encoding ASCII
}

# Normalize the path expected by rootProject.file() in the Android module.
$propertiesText = Get-Content -LiteralPath $keyProperties -Raw
if ($propertiesText -match '(?m)^storeFile=') {
    $propertiesText = [regex]::Replace(
        $propertiesText,
        '(?m)^storeFile=.*$',
        'storeFile=../secure_keys/qr-ajn-upload.jks'
    )
} else {
    $propertiesText = $propertiesText.TrimEnd() + "`r`nstoreFile=../secure_keys/qr-ajn-upload.jks`r`n"
}
$propertiesText | Set-Content -LiteralPath $keyProperties -Encoding ASCII

Copy-Item -LiteralPath $keyFile -Destination (Join-Path $backupFolder "qr-ajn-upload.jks") -Force
Copy-Item -LiteralPath $keyProperties -Destination (Join-Path $backupFolder "key.properties") -Force

Write-Host "Upload key protected at: $backupFolder" -ForegroundColor Green
Write-Host "Never share the keystore or its passwords." -ForegroundColor Yellow
