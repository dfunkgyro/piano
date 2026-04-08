# Rollback Strategy

This repository stores the app source plus named immutable release snapshots.

## Current stable release
- Release ID: `stable-2026-04-08-0208`
- S3 release prefix: `releases/stable-2026-04-08-0208`
- App bucket: `piano.thegyromusic.com`
- CloudFront distribution: `E3K16XT2P4N288`

## Protected assets
- Web app deployable files
- Main Android APK
- Bridge Android APK
- Bridge Windows ZIP
- Song catalog
- Release manifest and SHA-256 hashes

## Standard process
1. Run `tools\release_stable.ps1` with a new release ID.
2. Verify the release snapshot under `releases/<release-id>/` and in S3.
3. If needed, restore with `tools\rollback_release.ps1`.

## Rollback command
```powershell
powershell -ExecutionPolicy Bypass -File tools\rollback_release.ps1 -ReleaseId stable-2026-04-08-0208
```
