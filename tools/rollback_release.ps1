param(
  [Parameter(Mandatory=$true)][string]$ReleaseId,
  [string]$Bucket = "piano.thegyromusic.com",
  [string]$Profile = "piano",
  [string]$DistributionId = "E3K16XT2P4N288"
)

$ErrorActionPreference = "Stop"

aws s3 sync "s3://$Bucket/releases/$ReleaseId/web" "s3://$Bucket" --delete --exclude "downloads/*" --exclude "releases/*" --profile $Profile
aws s3 cp "s3://$Bucket/releases/$ReleaseId/bridge/android/gyro-midi-bridge-android.apk" "s3://$Bucket/downloads/bridge/android/gyro-midi-bridge-android.apk" --profile $Profile
aws s3 cp "s3://$Bucket/releases/$ReleaseId/bridge/windows/gyro-midi-bridge-windows.zip" "s3://$Bucket/downloads/bridge/windows/gyro-midi-bridge-windows.zip" --profile $Profile
aws s3 cp "s3://$Bucket/releases/$ReleaseId/bridge/manifest.json" "s3://$Bucket/downloads/bridge/manifest.json" --profile $Profile
aws s3 cp "s3://$Bucket/releases/$ReleaseId/catalog/pd_catalog.json" "s3://$Bucket/catalog/pd_catalog.json" --profile $Profile
aws cloudfront create-invalidation --distribution-id $DistributionId --paths "/*" --profile $Profile
Write-Host "Rollback completed: $ReleaseId"
