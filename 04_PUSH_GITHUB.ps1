param(
    [Parameter(Mandatory = $true)][string]$RepositoryUrl,
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
Set-StrictMode -Version Latest

function Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Command,
        [string]$FailureMessage = "Command failed.",
        [switch]$AllowFailure,
        [switch]$Capture
    )

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        if ($Capture) {
            $output = (& $Command 2>&1 | Out-String)
        }
        else {
            & $Command 2>&1 | Out-Host
            $output = ""
        }

        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }

    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "$FailureMessage Exit code: $exitCode`n$output"
    }

    return [pscustomobject]@{
        Output   = $output
        ExitCode = $exitCode
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "flutter_app\pubspec.yaml"))) {
    throw "QR AJN project root was not found: $ProjectRoot"
}

if ($RepositoryUrl -notmatch '^https://github\.com/[^/]+/[^/]+(?:\.git)?$') {
    throw "Enter a valid HTTPS GitHub repository URL."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git for Windows is not installed or not available in PATH."
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI is not installed. Install it with: winget install --id GitHub.cli"
}

Step "Checking GitHub authentication"

$auth = Invoke-Native `
    -Command { gh auth status } `
    -AllowFailure `
    -Capture

if ($auth.ExitCode -ne 0) {
    [void](Invoke-Native `
        -Command {
            gh auth login `
                --hostname github.com `
                --git-protocol https `
                --web
        } `
        -FailureMessage "GitHub authentication failed.")
}

[void](Invoke-Native `
    -Command { gh auth setup-git } `
    -FailureMessage "GitHub Git credential setup failed.")

Set-Location $ProjectRoot

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot ".git"))) {
    Step "Creating local Git repository"

    [void](Invoke-Native `
        -Command { git init } `
        -FailureMessage "git init failed.")
}

[void](Invoke-Native `
    -Command { git branch -M main } `
    -FailureMessage "Could not select the main branch.")

$origin = Invoke-Native `
    -Command { git remote get-url origin } `
    -AllowFailure `
    -Capture

if ($origin.ExitCode -eq 0) {
    [void](Invoke-Native `
        -Command { git remote set-url origin $RepositoryUrl } `
        -FailureMessage "Could not update the origin URL.")
}
else {
    [void](Invoke-Native `
        -Command { git remote add origin $RepositoryUrl } `
        -FailureMessage "Could not add the origin remote.")
}

Step "Configuring Git author when required"

$name = Invoke-Native `
    -Command { git config user.name } `
    -AllowFailure `
    -Capture

if ($name.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($name.Output)) {
    $login = (
        Invoke-Native `
            -Command { gh api user --jq .login } `
            -Capture
    ).Output.Trim()

    [void](Invoke-Native `
        -Command { git config user.name $login } `
        -FailureMessage "Could not configure the Git author name.")
}

$email = Invoke-Native `
    -Command { git config user.email } `
    -AllowFailure `
    -Capture

if ($email.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($email.Output)) {
    $login = (
        Invoke-Native `
            -Command { gh api user --jq .login } `
            -Capture
    ).Output.Trim()

    $userId = (
        Invoke-Native `
            -Command { gh api user --jq .id } `
            -Capture
    ).Output.Trim()

    [void](Invoke-Native `
        -Command {
            git config user.email "$userId+$login@users.noreply.github.com"
        } `
        -FailureMessage "Could not configure the Git author email.")
}

Step "Protecting local Firebase and signing files"

$gitIgnorePath = Join-Path $ProjectRoot ".gitignore"

$requiredIgnores = @(
    ".firebaserc",
    "PRODUCTION_CONFIG.ps1",
    "BUILD_DEFINES.ps1",
    "flutter_app/android/local.properties",
    "flutter_app/android/key.properties",
    "flutter_app/android/app/google-services.json",
    "flutter_app/lib/firebase_options.dart",
    "flutter_app/secure_keys/",
    "web_dashboard/firebase-config.js",
    "PLAY_STORE_UPLOAD/",
    "BUILD_LOGS/",
    "*.jks",
    "*.keystore"
)

$ignoreText = if (Test-Path -LiteralPath $gitIgnorePath) {
    Get-Content -LiteralPath $gitIgnorePath -Raw
}
else {
    ""
}

foreach ($entry in $requiredIgnores) {
    $escaped = [regex]::Escape($entry)

    if ($ignoreText -notmatch "(?m)^$escaped\s*$") {
        $ignoreText = $ignoreText.TrimEnd() + "`r`n$entry`r`n"
    }
}

[System.IO.File]::WriteAllText(
    $gitIgnorePath,
    $ignoreText,
    [System.Text.UTF8Encoding]::new($false)
)

[void](Invoke-Native `
    -Command {
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
    } `
    -AllowFailure)

Step "Preparing the V5 production commit"

[void](Invoke-Native `
    -Command { git add . } `
    -FailureMessage "git add failed.")

$cachedDiff = Invoke-Native `
    -Command { git diff --cached --quiet } `
    -AllowFailure

if ($cachedDiff.ExitCode -ne 0) {
    [void](Invoke-Native `
        -Command {
            git commit -m "QR AJN V5 complete production platform"
        } `
        -FailureMessage "Git commit failed.")
}

$headCheck = Invoke-Native `
    -Command { git rev-parse HEAD } `
    -AllowFailure `
    -Capture

if ($headCheck.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($headCheck.Output)) {
    throw "The local QR AJN V5 repository has no commit to publish."
}

$localHead = $headCheck.Output.Trim()

Step "Reading the existing remote main branch"

$remoteLookup = Invoke-Native `
    -Command { git ls-remote --heads origin main } `
    -FailureMessage "Could not access origin/main." `
    -Capture

if ([string]::IsNullOrWhiteSpace($remoteLookup.Output)) {
    Write-Host "The remote repository is empty. Publishing V5 normally." -ForegroundColor Yellow

    [void](Invoke-Native `
        -Command { git push -u origin main } `
        -FailureMessage "Initial GitHub push failed.")
}
else {
    $remoteLine = (
        $remoteLookup.Output -split "`r?`n" |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 1
    )

    $remoteSha = ($remoteLine -split "\s+")[0].Trim()

    if ($remoteSha -notmatch '^[0-9a-fA-F]{40}$') {
        throw "Could not resolve the current remote main commit."
    }

    [void](Invoke-Native `
        -Command { git fetch origin main } `
        -FailureMessage "Could not fetch the existing remote main branch.")

    $mergeBase = Invoke-Native `
        -Command { git merge-base main origin/main } `
        -AllowFailure `
        -Capture

    if ($mergeBase.ExitCode -eq 0 -and
        -not [string]::IsNullOrWhiteSpace($mergeBase.Output)) {
        Step "Remote history is related; rebasing and pushing normally"

        [void](Invoke-Native `
            -Command { git pull --rebase origin main } `
            -FailureMessage "Git rebase failed.")

        [void](Invoke-Native `
            -Command { git push -u origin main } `
            -FailureMessage "GitHub push failed.")
    }
    else {
        Step "Preserving the previous remote production branch"

        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupBranch = "backup/pre-qrajn-v5-$stamp"
        $backupRefSpec = "${remoteSha}:refs/heads/$backupBranch"

        $backupRoot = Join-Path $env:USERPROFILE "Documents\QR_AJN_GIT_BACKUPS"
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

        $bundlePath = Join-Path $backupRoot "QR_AJN_REMOTE_MAIN_$stamp.bundle"

        [void](Invoke-Native `
            -Command {
                git bundle create $bundlePath refs/remotes/origin/main
            } `
            -FailureMessage "Could not create the local Git bundle backup.")

        [void](Invoke-Native `
            -Command { git bundle verify $bundlePath } `
            -FailureMessage "The local Git backup bundle could not be verified.")

        [void](Invoke-Native `
            -Command { git push origin $backupRefSpec } `
            -FailureMessage "Could not create the remote backup branch.")

        Write-Host "Remote backup branch: $backupBranch" -ForegroundColor Green
        Write-Host "Local Git bundle: $bundlePath" -ForegroundColor Green

        Step "Replacing remote main with QR AJN V5 using an exact lease"

        $leaseArgument = "--force-with-lease=main:$remoteSha"

        $forcePush = Invoke-Native `
            -Command {
                git push -u origin main $leaseArgument
            } `
            -AllowFailure `
            -Capture

        if ($forcePush.ExitCode -ne 0) {
            Write-Host $forcePush.Output -ForegroundColor Yellow

            $v5Branch = "v5-production-$stamp"

            [void](Invoke-Native `
                -Command { git push -u origin "main:refs/heads/$v5Branch" } `
                -FailureMessage "Could not publish the fallback V5 branch.")

            throw @"
GitHub protected the main branch from replacement.

Your previous main branch is safe:
$backupBranch

QR AJN V5 was published to:
$v5Branch

Open GitHub repository settings or create a pull request from $v5Branch to main.
"@
        }
    }
}

Step "Verifying the published remote commit"

$verifiedRemote = Invoke-Native `
    -Command { git ls-remote --heads origin main } `
    -FailureMessage "Could not verify the published main branch." `
    -Capture

$verifiedLine = (
    $verifiedRemote.Output -split "`r?`n" |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -First 1
)

$verifiedSha = ($verifiedLine -split "\s+")[0].Trim()

if ($verifiedSha -ne $localHead) {
    $currentLocal = (
        Invoke-Native `
            -Command { git rev-parse HEAD } `
            -Capture
    ).Output.Trim()

    if ($verifiedSha -ne $currentLocal) {
        throw "Remote verification failed. Local: $currentLocal Remote: $verifiedSha"
    }

    $localHead = $currentLocal
}

$status = @"
QR AJN V5 GITHUB STATUS

Repository:
$RepositoryUrl

Branch:
main

Commit:
$localHead

Result:
PUBLISHED AND VERIFIED

Safety:
The previous unrelated remote main branch was preserved before replacement.
"@

$statusPath = Join-Path $ProjectRoot "FINAL_GITHUB_STATUS.txt"
$status | Set-Content -LiteralPath $statusPath -Encoding UTF8

Write-Host "`nGitHub V5 push completed and verified." -ForegroundColor Green
Write-Host "Repository: $RepositoryUrl" -ForegroundColor Green
Write-Host "Commit: $localHead" -ForegroundColor Green
Write-Host "Status: $statusPath" -ForegroundColor Green
