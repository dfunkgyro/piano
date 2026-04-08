param(
  [string]$Bucket = "piano.thegyromusic.com",
  [string]$Profile = "piano",
  [string]$DistributionId = "E3K16XT2P4N288",
  [switch]$SkipBuild,
  [switch]$SkipCatalog,
  [switch]$SkipInvalidate
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying web build to s3://$Bucket ..."

if (-not $SkipBuild) {
  Write-Host "Building Flutter web..."
  $buildVersion = Get-Date -Format "yyyyMMdd-HHmmss"
  $buildDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  Write-Host "Build version: $buildVersion ($buildDate)"
  flutter build web --release --pwa-strategy=none `
    --dart-define=BUILD_VERSION=$buildVersion `
    --dart-define=BUILD_DATE=$buildDate
}

Write-Host "Syncing build/web (excluding catalog/*)..."
aws s3 sync build/web "s3://$Bucket" --delete --exclude "catalog/*" --profile $Profile

if (-not $SkipCatalog) {
  $catalogPath = "catalog/pd_catalog.json"
  if (Test-Path $catalogPath) {
    Write-Host "Uploading catalog/pd_catalog.json..."
    aws s3 cp $catalogPath "s3://$Bucket/catalog/pd_catalog.json" --profile $Profile
  } else {
    Write-Warning "catalog/pd_catalog.json not found. Skipping catalog upload."
  }
}

if (-not $SkipInvalidate) {
  Write-Host "Invalidating CloudFront distribution $DistributionId ..."
  aws cloudfront create-invalidation --distribution-id $DistributionId --paths "/*" --profile $Profile
}

Write-Host "Done."
