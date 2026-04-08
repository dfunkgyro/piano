param(
  [Parameter(Mandatory=$true)][string]$ReleaseId,
  [string]$Bucket = "piano.thegyromusic.com",
  [string]$Profile = "piano",
  [string]$DistributionId = "E3K16XT2P4N288",
  [switch]$SkipWebDeploy,
  [switch]$SkipApkBuild,
  [switch]$SkipSnapshot
)

$ErrorActionPreference = "Stop"

$buildDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Host "ReleaseId: $ReleaseId"
Write-Host "Build date: $buildDate"

flutter pub get

flutter build web --release --pwa-strategy=none --dart-define=BUILD_VERSION=$ReleaseId --dart-define=BUILD_DATE=$buildDate

if (-not $SkipApkBuild) {
  flutter build apk --release
}

if (-not $SkipSnapshot) {
  powershell -ExecutionPolicy Bypass -File tools\create_release_snapshot.ps1 -ReleaseId $ReleaseId -Bucket $Bucket -Profile $Profile -DistributionId $DistributionId
}

if (-not $SkipWebDeploy) {
  aws s3 sync build\web "s3://$Bucket" --delete --exclude "downloads/*" --exclude "releases/*" --profile $Profile
  if (Test-Path "catalog/pd_catalog.json") {
    aws s3 cp "catalog/pd_catalog.json" "s3://$Bucket/catalog/pd_catalog.json" --profile $Profile
  }
  aws cloudfront create-invalidation --distribution-id $DistributionId --paths "/*" --profile $Profile
}

Write-Host "Stable release flow completed: $ReleaseId"
