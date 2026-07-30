param(
    [Parameter(Mandatory = $true)][Alias("FirebaseProjectId")][string]$ProjectId,
    [string]$Domain = "qrajn.online",
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
& (Join-Path $ProjectRoot "03_DEPLOY_FIREBASE_DOMAIN.ps1") `
    -ProjectId $ProjectId `
    -Domain $Domain `
    -ProjectRoot $ProjectRoot
