param(
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

function Require-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$InstallHint
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue

    if (-not $command) {
        throw "$Name is missing. $InstallHint"
    }

    Write-Host "PASS: $Name -> $($command.Source)" -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "flutter_app\pubspec.yaml"))) {
    throw "Invalid QR AJN project root: $ProjectRoot"
}

$jbr = Join-Path $env:ProgramFiles "Android\Android Studio\jbr"

if (Test-Path -LiteralPath (Join-Path $jbr "bin\java.exe")) {
    $env:JAVA_HOME = $jbr
    $env:Path = "$(Join-Path $jbr 'bin');$env:Path"
}

Write-Step "Checking QR AJN production prerequisites"

Require-Command -Name "flutter" -InstallHint "Install Flutter stable and add flutter\bin to PATH."
Require-Command -Name "dart" -InstallHint "Flutter should provide Dart."
Require-Command -Name "git" -InstallHint "Install Git for Windows."
Require-Command -Name "node" -InstallHint "Install Node.js 20 or newer."
Require-Command -Name "npm" -InstallHint "Install Node.js 20 or newer."
Require-Command -Name "java" -InstallHint "Install Android Studio with its bundled JBR."
Require-Command -Name "keytool" -InstallHint "Install Android Studio or a JDK."

$flutterResult = Invoke-Native `
    -Command { flutter --version } `
    -FailureMessage "Could not read the Flutter version." `
    -Capture

$nodeResult = Invoke-Native `
    -Command { node --version } `
    -FailureMessage "Could not read the Node.js version." `
    -Capture

# java -version writes normal version text to stderr. Capture it while
# ErrorActionPreference is temporarily Continue so Windows PowerShell 5.1
# does not convert valid Java output into a terminating NativeCommandError.
$javaResult = Invoke-Native `
    -Command { java -version } `
    -FailureMessage "Could not read the Java version." `
    -Capture

Write-Host $flutterResult.Output
Write-Host "Node.js: $($nodeResult.Output.Trim())"
Write-Host $javaResult.Output

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Step "Installing Firebase CLI"

    [void](Invoke-Native `
        -Command { npm install -g firebase-tools } `
        -FailureMessage "Firebase CLI installation failed.")
}

Write-Host "PASS: firebase" -ForegroundColor Green

if (-not (Get-Command flutterfire -ErrorAction SilentlyContinue)) {
    Write-Step "Installing FlutterFire CLI"

    [void](Invoke-Native `
        -Command { dart pub global activate flutterfire_cli } `
        -FailureMessage "FlutterFire CLI installation failed.")

    $pubCacheBin = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"

    if (Test-Path -LiteralPath $pubCacheBin) {
        $env:Path = "$pubCacheBin;$env:Path"
    }
}

if (-not (Get-Command flutterfire -ErrorAction SilentlyContinue)) {
    throw "FlutterFire CLI is installed but not visible. Add $env:LOCALAPPDATA\Pub\Cache\bin to PATH and reopen PowerShell."
}

Write-Host "PASS: flutterfire" -ForegroundColor Green

$androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$adb = Join-Path $androidSdk "platform-tools\adb.exe"

if (-not (Test-Path -LiteralPath $adb)) {
    throw "Android SDK Platform-Tools not found: $adb"
}

Write-Host "PASS: Android SDK -> $androidSdk" -ForegroundColor Green

if (Test-Path -LiteralPath (Join-Path $jbr "bin\java.exe")) {
    [void](Invoke-Native `
        -Command { flutter config --jdk-dir="$jbr" } `
        -FailureMessage "Flutter JDK configuration failed.")

    Write-Host "PASS: Android Studio Java -> $jbr" -ForegroundColor Green
}

Write-Step "Running Flutter doctor"

[void](Invoke-Native `
    -Command { flutter doctor -v } `
    -FailureMessage "Flutter doctor reported a command failure." `
    -AllowFailure)

Write-Host "`nQR AJN prerequisite check completed." -ForegroundColor Green
