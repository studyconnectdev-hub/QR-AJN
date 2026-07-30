param(
    [string]$ZipPath = "",
    [string]$Destination = "$env:USERPROFILE\Documents\QR_AJN_COMPLETE_PRODUCTION_V5_0_0"
)

$ErrorActionPreference = "Stop"

$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceRoot = $scriptFolder

if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot "flutter_app\pubspec.yaml"))) {
    if ([string]::IsNullOrWhiteSpace($ZipPath)) {
        $ZipPath = Get-ChildItem `
            -LiteralPath (Join-Path $env:USERPROFILE "Downloads") `
            -Filter "QR_AJN_COMPLETE_PRODUCTION_V5_0_0*.zip" `
            -File `
            -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if ([string]::IsNullOrWhiteSpace($ZipPath) -or -not (Test-Path -LiteralPath $ZipPath)) {
        throw "QR AJN V5 ZIP was not found in Downloads."
    }

    $extractRoot = Join-Path $env:TEMP "QR_AJN_V5_EXTRACT"
    if (Test-Path -LiteralPath $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractRoot -Force

    $sourceRoot = Get-ChildItem `
        -LiteralPath $extractRoot `
        -Recurse `
        -Filter "ONE_CLICK_FULL_SETUP.ps1" `
        -File |
        Select-Object -First 1 |
        ForEach-Object { Split-Path -Parent $_.FullName }
}

$resolvedSource = [System.IO.Path]::GetFullPath($sourceRoot).TrimEnd("\")
$resolvedDestination = [System.IO.Path]::GetFullPath($Destination).TrimEnd("\")

if ($resolvedSource -ieq $resolvedDestination) {
    Set-ExecutionPolicy -Scope Process Bypass -Force
    & (Join-Path $sourceRoot "ONE_CLICK_FULL_SETUP.ps1") -ProjectRoot $sourceRoot
    exit $LASTEXITCODE
}

if (Test-Path -LiteralPath $Destination) {
    $backup = "$Destination`_ROLLBACK_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Move-Item -LiteralPath $Destination -Destination $backup
    Write-Host "Previous project moved to: $backup" -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
& robocopy $sourceRoot $Destination /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XD ".git" "build" ".dart_tool" ".gradle" | Out-Host
if ($LASTEXITCODE -gt 7) {
    throw "Project copy failed. Robocopy exit code: $LASTEXITCODE"
}

Set-ExecutionPolicy -Scope Process Bypass -Force
& (Join-Path $Destination "ONE_CLICK_FULL_SETUP.ps1") -ProjectRoot $Destination
