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
- Web build:
  - Use `flutter build web --release --pwa-strategy=none`
  - Sync to `s3://piano.thegyromusic.com` excluding catalog:
    - `aws s3 sync build/web s3://piano.thegyromusic.com --delete --exclude "catalog/*"`
    - Then re-upload catalog if needed:
      - `aws s3 cp catalog/pd_catalog.json s3://piano.thegyromusic.com/catalog/pd_catalog.json`
  - Invalidate CloudFront distribution `E3K16XT2P4N288`
- Rollback:
  - Bucket versioning is enabled.
  - Current rollback snapshot is documented in `rollback-versions.json` and `ROLLBACK.md`.

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
