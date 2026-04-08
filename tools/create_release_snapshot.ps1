param(
  [Parameter(Mandatory=$true)][string]$ReleaseId,
  [string]$Bucket = "piano.thegyromusic.com",
  [string]$Profile = "piano",
  [string]$DistributionId = "E3K16XT2P4N288"
)

$ErrorActionPreference = "Stop"
$releaseDir = Join-Path "releases" $ReleaseId
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$artifactPaths = @(
  "build/web",
  "build/app/outputs/flutter-apk/app-release.apk",
  "downloads/bridge/android/gyro-midi-bridge-android.apk",
  "downloads/bridge/windows/gyro-midi-bridge-windows.zip",
  "downloads/bridge/manifest.json",
  "catalog/pd_catalog.json"
)

$artifacts = @()
foreach ($path in $artifactPaths) {
  if (Test-Path $path) {
    if ((Get-Item $path).PSIsContainer) {
      Get-ChildItem $path -Recurse -File | ForEach-Object {
        $hash = Get-FileHash $_.FullName -Algorithm SHA256
        $artifacts += [ordered]@{
          path = $_.FullName.Replace((Get-Location).Path + '\\', '')
          sha256 = $hash.Hash
          size = $_.Length
          lastWriteTimeUtc = $_.LastWriteTimeUtc.ToString('o')
        }
      }
    } else {
      $item = Get-Item $path
      $hash = Get-FileHash $item.FullName -Algorithm SHA256
      $artifacts += [ordered]@{
        path = $path
        sha256 = $hash.Hash
        size = $item.Length
        lastWriteTimeUtc = $item.LastWriteTimeUtc.ToString('o')
      }
    }
  }
}

$manifest = [ordered]@{
  releaseId = $ReleaseId
  createdAtUtc = (Get-Date).ToUniversalTime().ToString('o')
  bucket = $Bucket
  distributionId = $DistributionId
  s3ReleasePrefix = "releases/$ReleaseId"
  artifacts = $artifacts
}

($manifest | ConvertTo-Json -Depth 8) | Set-Content (Join-Path $releaseDir 'release-manifest.json')
($artifacts | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $releaseDir 'artifact-hashes.json')

aws s3 sync build/web "s3://$Bucket/releases/$ReleaseId/web" --delete --profile $Profile
aws s3 cp "build/app/outputs/flutter-apk/app-release.apk" "s3://$Bucket/releases/$ReleaseId/app-release.apk" --profile $Profile
aws s3 cp "downloads/bridge/android/gyro-midi-bridge-android.apk" "s3://$Bucket/releases/$ReleaseId/bridge/android/gyro-midi-bridge-android.apk" --profile $Profile
aws s3 cp "downloads/bridge/windows/gyro-midi-bridge-windows.zip" "s3://$Bucket/releases/$ReleaseId/bridge/windows/gyro-midi-bridge-windows.zip" --profile $Profile
aws s3 cp "downloads/bridge/manifest.json" "s3://$Bucket/releases/$ReleaseId/bridge/manifest.json" --profile $Profile
if (Test-Path "catalog/pd_catalog.json") {
  aws s3 cp "catalog/pd_catalog.json" "s3://$Bucket/releases/$ReleaseId/catalog/pd_catalog.json" --profile $Profile
}
aws s3 cp (Join-Path $releaseDir 'release-manifest.json') "s3://$Bucket/releases/$ReleaseId/release-manifest.json" --profile $Profile
aws s3 cp (Join-Path $releaseDir 'artifact-hashes.json') "s3://$Bucket/releases/$ReleaseId/artifact-hashes.json" --profile $Profile
Write-Host "Release snapshot created: $ReleaseId"
