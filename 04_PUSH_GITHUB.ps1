param(
    [Parameter(Mandatory = $true)][string]$RepositoryUrl,
    [string]$ProjectRoot = $PSScriptRoot
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

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "Project root not found: $ProjectRoot"
}
if ($RepositoryUrl -notmatch '^https://github\.com/[^/]+/[^/]+(?:\.git)?$') {
    throw "Enter a valid HTTPS GitHub repository URL."
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI is missing. Install GitHub CLI or winget."
    }
    Write-Step "Installing GitHub CLI"
    [void](Invoke-Native -Command {
        winget install --id GitHub.cli --exact --source winget `
            --accept-package-agreements --accept-source-agreements
    } -FailureMessage "GitHub CLI installation failed.")
    $env:Path = "$env:ProgramFiles\GitHub CLI;$env:Path"
}

Write-Step "Authenticating GitHub"
$auth = Invoke-Native -Command { gh auth status } -AllowFailure -Capture
if ($auth.ExitCode -ne 0) {
    [void](Invoke-Native -Command {
        gh auth login --hostname github.com --git-protocol https --web
    } -FailureMessage "GitHub authentication failed.")
}
[void](Invoke-Native -Command { gh auth setup-git } -FailureMessage "Git credential setup failed.")

Set-Location $ProjectRoot
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot ".git"))) {
    Write-Step "Creating local Git repository"
    [void](Invoke-Native -Command { git init } -FailureMessage "git init failed.")
}
[void](Invoke-Native -Command { git branch -M main } -FailureMessage "Could not select main branch.")

Write-Step "Configuring Git author when missing"
$currentName = Invoke-Native -Command { git config user.name } -AllowFailure -Capture
if ($currentName.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($currentName.Output)) {
    $login = (Invoke-Native -Command { gh api user --jq .login } -Capture).Output.Trim()
    [void](Invoke-Native -Command { git config user.name "$login" } -FailureMessage "Could not configure Git user name.")
}
$currentEmail = Invoke-Native -Command { git config user.email } -AllowFailure -Capture
if ($currentEmail.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($currentEmail.Output)) {
    $login = (Invoke-Native -Command { gh api user --jq .login } -Capture).Output.Trim()
    $userId = (Invoke-Native -Command { gh api user --jq .id } -Capture).Output.Trim()
    [void](Invoke-Native -Command {
        git config user.email "$userId+$login@users.noreply.github.com"
    } -FailureMessage "Could not configure Git user email.")
}

Write-Step "Protecting signing and generated Firebase configuration"
[void](Invoke-Native -Command {
    git rm -r --cached `
        flutter_app/secure_keys `
        flutter_app/android/key.properties `
        flutter_app/android/app/google-services.json `
        flutter_app/lib/firebase_options.dart `
        web_dashboard/firebase-config.js `
        BUILD_DEFINES.ps1 `
        PRODUCTION_CONFIG.ps1 `
        PLAY_STORE_UPLOAD `
        BUILD_LOGS `
        2>$null
} -AllowFailure)

$origin = Invoke-Native -Command { git remote get-url origin } -AllowFailure -Capture
if ($origin.ExitCode -eq 0) {
    [void](Invoke-Native -Command { git remote set-url origin "$RepositoryUrl" } -FailureMessage "Could not update origin.")
} else {
    [void](Invoke-Native -Command { git remote add origin "$RepositoryUrl" } -FailureMessage "Could not add origin.")
}

Write-Step "Preparing production commit"
[void](Invoke-Native -Command { git add . } -FailureMessage "git add failed.")
$diff = Invoke-Native -Command { git diff --cached --quiet } -AllowFailure
if ($diff.ExitCode -ne 0) {
    [void](Invoke-Native -Command { git commit -m "QR AJN V5 production platform" } -FailureMessage "Git commit failed.")
}

Write-Step "Inspecting the remote repository"
$remoteMain = Invoke-Native -Command { git ls-remote --heads origin main } -AllowFailure -Capture
if ($remoteMain.ExitCode -ne 0) {
    throw "Could not access the GitHub repository. Confirm the URL and permissions.`n$($remoteMain.Output)"
}

if ([string]::IsNullOrWhiteSpace($remoteMain.Output)) {
    Write-Host "The GitHub repository is empty. Publishing QR AJN V5 as its first main branch." -ForegroundColor Yellow
    [void](Invoke-Native -Command { git push -u origin main } -FailureMessage "Initial GitHub push failed.")
} else {
    [void](Invoke-Native -Command { git fetch origin main } -FailureMessage "Could not fetch origin/main.")
    $remoteTree = Invoke-Native -Command { git ls-tree -r --name-only origin/main } -FailureMessage "Could not inspect remote branch." -Capture
    $remoteFiles = @(
        $remoteTree.Output -split "`r?`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    )
    $starterOnly = (
        $remoteFiles.Count -eq 0 -or
        ($remoteFiles.Count -le 2 -and
            ($remoteFiles | Where-Object { $_ -notin @("README.md", ".gitignore") }).Count -eq 0)
    )

    if ($starterOnly) {
        Write-Host "Remote contains only starter files. Replacing them with the complete QR AJN source." -ForegroundColor Yellow
        [void](Invoke-Native -Command { git push -u origin main --force-with-lease } -FailureMessage "GitHub push failed.")
    } else {
        $base = Invoke-Native -Command { git merge-base main origin/main } -AllowFailure -Capture
        if ($base.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($base.Output)) {
            throw "The remote contains unrelated production files. Review it before replacing the branch."
        }
        [void](Invoke-Native -Command { git pull --rebase origin main } -FailureMessage "Git rebase failed.")
        [void](Invoke-Native -Command { git push -u origin main } -FailureMessage "GitHub push failed.")
    }
}

$head = (Invoke-Native -Command { git rev-parse HEAD } -Capture).Output.Trim()
Write-Host "`nGitHub push completed." -ForegroundColor Green
Write-Host "Repository: $RepositoryUrl" -ForegroundColor Green
Write-Host "Commit: $head" -ForegroundColor Green
