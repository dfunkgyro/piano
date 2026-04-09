# GrandPiano Web Audio Setup Reminders

- Web audio uses legacy `WebAudioEngine` with preload + background warmup for low latency.
- Asset paths are resolved in this order for web:
  - `assets/assets/sounds/...` (Flutter web default)
  - `assets/sounds/...` (fallback)
- High Performance Mode:
  - Default is ON.
  - Stored in `performance_mode` prefs via `AppSettingsStore`.
  - Applied on Home, Lesson, Complete Song, and Safe modes.
- Ultra Performance Mode:
  - Default is OFF.
  - Modes: `audioOnly`, `polyphony`, `visuals`.
  - Stored in `ultra_performance_mode` via `AppSettingsStore`.
  - When enabled, it forces High Performance ON and adjusts audio engine limits.
- Web deploy:
  - Use `powershell -ExecutionPolicy Bypass -File tools\deploy_web.ps1`
  - This preserves `catalog/`, `downloads/`, and `releases/` by default.
  - Only use `-DeleteManagedWebFiles` if you explicitly want delete behavior for managed web files.
  - Do not use raw `aws s3 sync build/web s3://piano.thegyromusic.com --delete` for live deploys.
- Stable release flow:
  - Use `powershell -ExecutionPolicy Bypass -File tools\release_stable.ps1 -ReleaseId <release-id>`
  - This deploys via the hardened web deploy script, then snapshots the release under `releases/<release-id>/`.
- Rollback:
  - Bucket versioning is enabled.
  - Current rollback snapshot is documented in `ROLLBACK.md`.

## Song MIDI Sources

- Public-domain MIDI files were used to extend lesson songs:
  - Bach Minuet in G Major (BWV Anh. 114)
  - Chopin Prelude Op. 28 No. 4
  - Schumann Traumerei Op. 15 No. 7
  - Mozart Fantasia in D minor K.397
  - Debussy Clair de Lune
  - Bach Prelude in C Major BWV 846
  - Beethoven Fur Elise
- Moonlight Sonata 1st movement MIDI was sourced from Wikimedia Commons via `Special:FilePath/Moonlight_Sonata.mid`.
  - License attribution is required per Wikimedia Commons for that file.
