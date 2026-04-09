param(
  [Parameter(Mandatory=$true)][string]$ReleaseId,
  [string]$Bucket = "piano.thegyromusic.com",
  [string]$Profile = "piano",
  [string]$DistributionId = "E3K16XT2P4N288",
  [switch]$SkipBuild,
  [switch]$SkipDeploy,
  [switch]$SkipSnapshot
)

$ErrorActionPreference = "Stop"

Write-Host "Starting stable release flow: $ReleaseId"

if (-not $SkipBuild -and -not $SkipDeploy) {
  Write-Host "Deploying web app via hardened deploy script..."
  powershell -ExecutionPolicy Bypass -File "tools\deploy_web.ps1" `
    -Bucket $Bucket `
    -Profile $Profile `
    -DistributionId $DistributionId
}

if (-not $SkipSnapshot) {
  Write-Host "Creating immutable release snapshot..."
  powershell -ExecutionPolicy Bypass -File "tools\create_release_snapshot.ps1" `
    -ReleaseId $ReleaseId `
    -Bucket $Bucket `
    -Profile $Profile `
    -DistributionId $DistributionId
}

Write-Host "Stable release flow complete: $ReleaseId"
