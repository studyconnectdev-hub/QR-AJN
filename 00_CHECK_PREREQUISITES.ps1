param(
    [switch]$InstallMissingCliTools
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$PubCacheBin = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"
if (Test-Path $PubCacheBin) { $env:Path = "$PubCacheBin;$env:Path" }

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

    Write-Host "Android Studio JBR was not found. Using Java from PATH." -ForegroundColor Yellow
}

function Require-Command([string]$Name, [string]$Message) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw $Message
    }
    Write-Host "PASS: $Name" -ForegroundColor Green
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
        if ($Capture) {
            $output = (& $Command 2>&1 | Out-String)
        } else {
            & $Command 2>&1 | Out-Host
            $output = ""
        }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if (-not $AllowFailure -and $code -ne 0) {
        throw "$FailureMessage Exit code: $code"
    }

    return [pscustomobject]@{ Output = $output; ExitCode = $code }
}

Select-CompatibleJava

Require-Command "flutter" "Flutter is not in PATH. Install Flutter and reopen PowerShell."
Require-Command "dart" "Dart is not available. It should be included with Flutter."
Require-Command "java" "Java is missing. Install Android Studio with its bundled JBR."
Require-Command "keytool" "keytool is missing. Install Android Studio with its bundled JBR."
Require-Command "git" "Git for Windows is missing."
Require-Command "node" "Node.js 20+ is missing."
Require-Command "npm" "npm is missing."

$nodeResult = Invoke-NativeSafe -Command { node --version } -FailureMessage "Could not read Node.js version." -Capture
$nodeText = $nodeResult.Output.Trim()
Write-Host "Node.js: $nodeText"
if ($nodeText -match '^v(\d+)') {
    if ([int]$Matches[1] -lt 20) { throw "Node.js 20 or newer is required. Current: $nodeText" }
}

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    if ($InstallMissingCliTools) {
        Invoke-NativeSafe -Command { npm install -g firebase-tools } -FailureMessage "Firebase CLI installation failed."
    } else {
        throw "Firebase CLI missing. Run: npm install -g firebase-tools"
    }
}

if (-not (Get-Command flutterfire -ErrorAction SilentlyContinue)) {
    if ($InstallMissingCliTools) {
        Invoke-NativeSafe -Command { dart pub global activate flutterfire_cli } -FailureMessage "FlutterFire CLI installation failed."
        if (Test-Path $PubCacheBin) { $env:Path = "$PubCacheBin;$env:Path" }
    } else {
        throw "FlutterFire CLI missing. Run: dart pub global activate flutterfire_cli"
    }
}

$javaResult = Invoke-NativeSafe -Command { java -version } -FailureMessage "Could not read Java version." -Capture
$javaText = $javaResult.Output
Write-Host $javaText.Trim()

if ($javaText -match 'version\s+"(?:1\.)?(\d+)') {
    $javaMajor = [int]$Matches[1]
    if ($javaMajor -lt 17) { throw "Java 17 or newer is required. Current major version: $javaMajor" }
    if ($javaMajor -gt 23) {
        throw "Java $javaMajor is too new for this project's Gradle 8.11.1. Install Android Studio and use its bundled JBR (Java 17-23)."
    }
}

Set-Location (Join-Path $Root "flutter_app")
Invoke-NativeSafe -Command { flutter doctor -v } -FailureMessage "flutter doctor reported a setup failure."
Write-Host "Prerequisite check completed." -ForegroundColor Green
