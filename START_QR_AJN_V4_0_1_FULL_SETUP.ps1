param(
    [string]$FirebaseProjectId = "",
    [string]$GitHubRepository = "",
    [string]$Domain = "qrajn.online",
    [string]$DestinationRoot = "",
    [switch]$SkipGit,
    [switch]$SkipFirebaseDeploy,
    [switch]$SkipBuild,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Normalize-GitHubRepository([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
    $clean = $Value.Trim()
    $clean = $clean -replace '^https?://github\.com/', ''
    $clean = $clean -replace '^git@github\.com:', ''
    $clean = $clean -replace '\.git$', ''
    return $clean.Trim('/')
}

function Select-CompatibleJava {
    $candidates = @(
        "$env:ProgramFiles\Android\Android Studio\jbr",
        "$env:LOCALAPPDATA\Programs\Android Studio\jbr",
        "$env:ProgramFiles\Android\Android Studio\jre"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path (Join-Path $candidate "bin\java.exe"))) {
            $env:JAVA_HOME = $candidate
            $env:Path = "$(Join-Path $candidate 'bin');$env:Path"
            Write-Host "Using Android Studio Java: $candidate" -ForegroundColor Green
            return
        }
    }
}

function Find-SetupScript([string[]]$Roots) {
    foreach ($root in $Roots) {
        if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) { continue }
        $direct = Join-Path $root "ONE_CLICK_FULL_SETUP.ps1"
        if (Test-Path -LiteralPath $direct) { return (Get-Item -LiteralPath $direct).FullName }
        $found = Get-ChildItem -LiteralPath $root -Recurse -File -Filter "ONE_CLICK_FULL_SETUP.ps1" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

function Find-PackageZip([string[]]$Roots) {
    foreach ($root in $Roots) {
        if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) { continue }
        $found = Get-ChildItem -LiteralPath $root -File -Filter "QR_AJN_COMPLETE_PRODUCTION_V4_0_1*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $found) {
            $found = Get-ChildItem -LiteralPath $root -File -Filter "QR_AJN_COMPLETE_PRODUCTION_V4*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
        if ($found) { return $found.FullName }
    }
    return $null
}

Select-CompatibleJava

$current = (Get-Location).Path
$downloads = Join-Path $env:USERPROFILE "Downloads"
if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
    $DestinationRoot = Join-Path $env:USERPROFILE "Documents\QR_AJN_COMPLETE_PRODUCTION_V4_0_1"
}

Write-Step "Finding QR AJN setup files"
$setupScript = Find-SetupScript @($current, (Join-Path $current "QR_AJN_COMPLETE_PRODUCTION_V4_0_1"), $DestinationRoot)

if (-not $setupScript) {
    $zip = Find-PackageZip @($current, $downloads)
    if (-not $zip) { throw "QR AJN V4.0.1 ZIP was not found. Place it in $downloads" }
    Write-Host "ZIP found: $zip" -ForegroundColor Green
    Write-Step "Extracting production package"
    Set-Location $env:TEMP
    if (Test-Path -LiteralPath $DestinationRoot) { & $env:ComSpec /d /s /c "rd /s /q `"$DestinationRoot`"" | Out-Null }
    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $DestinationRoot -Force
    $setupScript = Find-SetupScript @($DestinationRoot)
    if (-not $setupScript) { throw "ONE_CLICK_FULL_SETUP.ps1 was not found after extraction." }
}

$packageRoot = Split-Path -Parent $setupScript
Write-Host "Setup folder: $packageRoot" -ForegroundColor Green

if ([string]::IsNullOrWhiteSpace($FirebaseProjectId) -or $FirebaseProjectId -eq "YOUR_FIREBASE_PROJECT_ID") {
    $FirebaseProjectId = Read-Host "Enter the real QR AJN Firebase Project ID"
}
if ([string]::IsNullOrWhiteSpace($FirebaseProjectId) -or $FirebaseProjectId -eq "YOUR_FIREBASE_PROJECT_ID") {
    throw "A real Firebase Project ID is required."
}

if (-not $SkipGit -and [string]::IsNullOrWhiteSpace($GitHubRepository)) {
    $GitHubRepository = Read-Host "Enter OWNER/REPOSITORY or a GitHub URL, or press Enter to skip Git"
    if ([string]::IsNullOrWhiteSpace($GitHubRepository)) { $SkipGit = $true }
}
$GitHubRepository = Normalize-GitHubRepository $GitHubRepository

Write-Step "Starting QR AJN production setup"
Write-Host "Firebase project: $FirebaseProjectId"
Write-Host "Domain: $Domain"
if (-not $SkipGit) { Write-Host "GitHub repository: $GitHubRepository" }
Write-Host "Ads: Google test IDs until real AdMob IDs are configured"

$params = @{
    FirebaseProjectId = $FirebaseProjectId
    Domain = $Domain
    SkipGit = $SkipGit
    SkipFirebaseDeploy = $SkipFirebaseDeploy
    SkipBuild = $SkipBuild
    SkipTests = $SkipTests
}
if (-not $SkipGit -and -not [string]::IsNullOrWhiteSpace($GitHubRepository)) { $params["GitHubRepository"] = $GitHubRepository }

Set-Location $packageRoot
Set-ExecutionPolicy -Scope Process Bypass -Force
& $setupScript @params
Write-Host "`nQR AJN setup completed." -ForegroundColor Green
Write-Host "Project folder: $packageRoot" -ForegroundColor Green
