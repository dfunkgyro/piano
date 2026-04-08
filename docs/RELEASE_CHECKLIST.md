# Release Checklist

## Pre-release
- Confirm working tree is clean.
- Choose a new release ID in the format `stable-YYYY-MM-DD-HHMM`.
- Verify build version is shown correctly in app settings.
- Confirm icon/branding assets are correct.
- Confirm bridge downloads are current.
- Confirm catalog changes are intentional.

## Build
- Run:
  `powershell -ExecutionPolicy Bypass -File tools\release_stable.ps1 -ReleaseId <release-id>`
- Verify web build completes.
- Verify APK build completes.
- Verify release snapshot uploads to `releases/<release-id>/`.

## Verification
- Check app loads from `https://piano.thegyromusic.com`.
- Check bridge manifest/download URLs resolve.
- Check website still serves correctly.
- Smoke-test audio, library, sheet music, and external MIDI.

## Post-release
- Record notable changes in `CHANGELOG.md`.
- Tag the release if needed.
- Keep the release ID for rollback reference.

## Rollback
- Run:
  `powershell -ExecutionPolicy Bypass -File tools\rollback_release.ps1 -ReleaseId <release-id>`
- Verify the restored build version in the app.
