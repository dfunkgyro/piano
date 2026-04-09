# Rollback Strategy

This project keeps a named, immutable rollback snapshot for each stable release.

## Current stable release
- Release ID: `stable-2026-04-08-0208`
- S3 release prefix: `releases/stable-2026-04-08-0208`
- App bucket: `piano.thegyromusic.com`
- CloudFront distribution: `E3K16XT2P4N288`

## What is protected
- Web app deployable files
- Main Android APK
- Bridge Android APK
- Bridge Windows ZIP
- Release manifest and SHA-256 hashes

## Safe live deploy workflow
Use the hardened deploy script instead of raw `aws s3 sync build/web ... --delete`:

```powershell
powershell -ExecutionPolicy Bypass -File tools\deploy_web.ps1
```

By default this preserves runtime-managed paths such as:
- `catalog/`
- `downloads/`
- `releases/`

## Stable release workflow
Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\release_stable.ps1 -ReleaseId <release-id>
```

This will:
1. Deploy the live web app via the hardened deploy script.
2. Snapshot the current build and artifacts under `releases/<release-id>/`.

## Rollback workflow
Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\rollback_release.ps1 -ReleaseId stable-2026-04-08-0208
```

This restores the named release from S3 back to the live bucket root and refreshes bridge downloads, then invalidates CloudFront.
