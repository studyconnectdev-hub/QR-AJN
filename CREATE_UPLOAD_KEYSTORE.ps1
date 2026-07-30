param([string]$KeystorePassword = "")
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$App = Join-Path $Root "flutter_app"
$Keys = Join-Path $App "secure_keys"
$Keystore = Join-Path $Keys "qr-ajn-upload.jks"
$Properties = Join-Path $App "android\key.properties"
$Recovery = Join-Path $Root "UPLOAD_KEY_RECOVERY_PRIVATE.txt"
$Alias = "qrajn-upload"

if ((Test-Path $Keystore) -and (Test-Path $Properties)) {
    Write-Host "Existing QR AJN upload key preserved." -ForegroundColor Green
    return
}
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) { throw "keytool was not found." }
if ([string]::IsNullOrWhiteSpace($KeystorePassword)) {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $KeystorePassword = [Convert]::ToBase64String($bytes).Replace("/", "A").Replace("+", "B").TrimEnd("=")
}
New-Item -ItemType Directory -Force -Path $Keys | Out-Null
& keytool -genkeypair -v -keystore $Keystore -storepass $KeystorePassword -keypass $KeystorePassword -alias $Alias -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=QR AJN, OU=Mobile, O=QR AJN, L=Hyderabad, ST=Telangana, C=IN"
if ($LASTEXITCODE -ne 0) { throw "Upload keystore generation failed." }
$propertiesText = "storePassword=$KeystorePassword`r`nkeyPassword=$KeystorePassword`r`nkeyAlias=$Alias`r`nstoreFile=../../secure_keys/qr-ajn-upload.jks`r`n"
[System.IO.File]::WriteAllText($Properties, $propertiesText, (New-Object System.Text.UTF8Encoding($false)))
$recoveryText = "QR AJN UPLOAD KEY RECOVERY`r`n`r`nKeystore: $Keystore`r`nAlias: $Alias`r`nStore password: $KeystorePassword`r`nKey password: $KeystorePassword`r`n`r`nBack up the JKS and this recovery file permanently. Never commit them to GitHub.`r`n"
[System.IO.File]::WriteAllText($Recovery, $recoveryText, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "Upload key created: $Keystore" -ForegroundColor Green
Write-Host "PRIVATE recovery file: $Recovery" -ForegroundColor Yellow
