# piano

This repository now holds the GrandPiano app source, release tooling, and rollback metadata.

## Stable release workflow
Create and protect a stable release with:

```powershell
powershell -ExecutionPolicy Bypass -File tools\release_stable.ps1 -ReleaseId stable-YYYY-MM-DD-HHMM
```

This will:
1. build the web app
2. build the Android APK
3. create an immutable release snapshot in S3
4. deploy the web app
5. invalidate CloudFront

## Rollback
```powershell
powershell -ExecutionPolicy Bypass -File tools\rollback_release.ps1 -ReleaseId stable-2026-04-08-0208
```

## Current protected release
- `stable-2026-04-08-0208`
