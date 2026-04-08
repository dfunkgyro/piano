# piano

Release management and rollback metadata for the current GrandPiano stable build live here.

## Current protected release
- `stable-2026-04-08-0208`

## Files
- `ROLLBACK.md`
- `tools/create_release_snapshot.ps1`
- `tools/rollback_release.ps1`
- `releases/stable-2026-04-08-0208/release-manifest.json`
- `releases/stable-2026-04-08-0208/artifact-hashes.json`

## Important limitation
This repository is currently not the full app source repository. It stores rollback tooling and release metadata, but source-code rollback protection requires the actual app source to be versioned in git.
