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

## Release workflow
1. Build artifacts.
2. Run `tools/create_release_snapshot.ps1`.
3. Verify the files under `releases/<release-id>/`.
4. Upload the release snapshot to S3 under `releases/<release-id>/`.
5. Deploy the live site from the tested build.

## Rollback workflow
Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\rollback_release.ps1 -ReleaseId stable-2026-04-08-0208
```

This restores the named release from S3 back to the live bucket root and refreshes bridge downloads, then invalidates CloudFront.

## Important limitation
The GitHub repository `dfunkgyro/piano` is currently not the source repository for this workspace. Release tooling and manifests can be stored there, but source rollback protection requires the app source itself to live in git.
