param(
    [Parameter(Mandatory=$true)][string]$Repository,
    [switch]$Public
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Normalize-Repository([string]$Value) {
    $clean = $Value.Trim()
    $clean = $clean -replace '^https?://github\.com/', ''
    $clean = $clean -replace '^git@github\.com:', ''
    $clean = $clean -replace '\.git$', ''
    $clean = $clean.Trim('/')

    if ($clean -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "GitHub repository must be OWNER/REPOSITORY or a GitHub URL. Received: $Value"
    }
    return $clean
}

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
        if ($Capture) { $output = (& $Command 2>&1 | Out-String) }
        else { & $Command 2>&1 | Out-Host; $output = "" }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if (-not $AllowFailure -and $code -ne 0) { throw "$FailureMessage Exit code: $code" }
    return [pscustomobject]@{ Output = $output; ExitCode = $code }
}

$Repository = Normalize-Repository $Repository
Write-Host "GitHub repository: $Repository" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is not installed." }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Invoke-NativeSafe -Command { winget install --id GitHub.cli --exact --source winget --accept-package-agreements --accept-source-agreements } -FailureMessage "GitHub CLI installation failed."
        $GhFolder = Join-Path $env:ProgramFiles "GitHub CLI"
        if (Test-Path $GhFolder) { $env:Path = "$GhFolder;$env:Path" }
    }
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI is missing. Install it from https://cli.github.com/ and rerun."
}

$auth = Invoke-NativeSafe -Command { gh auth status } -AllowFailure -Capture
if ($auth.ExitCode -ne 0) {
    Invoke-NativeSafe -Command { gh auth login } -FailureMessage "GitHub authentication failed."
}

Set-Location $Root
if (-not (Test-Path ".git")) { Invoke-NativeSafe -Command { git init } -FailureMessage "git init failed." }
Invoke-NativeSafe -Command { git config core.autocrlf true } -FailureMessage "Git configuration failed."

$userNameResult = Invoke-NativeSafe -Command { git config user.name } -AllowFailure -Capture
$userEmailResult = Invoke-NativeSafe -Command { git config user.email } -AllowFailure -Capture
$userName = $userNameResult.Output.Trim()
$userEmail = $userEmailResult.Output.Trim()
if ([string]::IsNullOrWhiteSpace($userName)) { Invoke-NativeSafe -Command { git config user.name "QR AJN" } -FailureMessage "Could not set Git user name." }
if ([string]::IsNullOrWhiteSpace($userEmail)) { Invoke-NativeSafe -Command { git config user.email "developer@qrajn.online" } -FailureMessage "Could not set Git email." }

Invoke-NativeSafe -Command { git add . } -FailureMessage "git add failed."
Invoke-NativeSafe -Command { git reset -- "flutter_app/secure_keys" "flutter_app/android/key.properties" "UPLOAD_KEY_RECOVERY_PRIVATE.txt" "PRODUCTION_CONFIG.ps1" "PLAY_STORE_UPLOAD" } -AllowFailure

$status = Invoke-NativeSafe -Command { git status --porcelain } -FailureMessage "Could not read Git status." -Capture
$changes = $status.Output.Trim()
if (-not [string]::IsNullOrWhiteSpace($changes)) {
    Invoke-NativeSafe -Command { git commit -m "QR AJN V4 production platform" } -FailureMessage "Git commit failed."
}

$remoteResult = Invoke-NativeSafe -Command { git remote get-url origin } -AllowFailure -Capture
$remote = $remoteResult.Output.Trim()
if ([string]::IsNullOrWhiteSpace($remote)) {
    if ($Public) {
        Invoke-NativeSafe -Command { gh repo create $Repository --public --source . --remote origin --push } -FailureMessage "GitHub repository creation/push failed."
    } else {
        Invoke-NativeSafe -Command { gh repo create $Repository --private --source . --remote origin --push } -FailureMessage "GitHub repository creation/push failed."
    }
} else {
    Invoke-NativeSafe -Command { git branch -M main } -FailureMessage "Could not rename Git branch."
    Invoke-NativeSafe -Command { git push -u origin main } -FailureMessage "GitHub push failed."
}
Write-Host "GitHub push completed." -ForegroundColor Green
