# Repository Size Audit

Generated: 2026-04-08

## Largest tracked items
1. `catalog/pd_catalog.json` - ~50.9 MB
2. `assets/fonts/SF-Compact.ttf` - ~6.7 MB
3. `assets/fonts/SF-Pro-Italic.ttf` - ~6.6 MB
4. `assets/fonts/SFPro.ttf` - ~6.1 MB
5. `assets/fonts/SF-Compact-Italic.ttf` - ~6.0 MB
6. Many additional `assets/fonts/*` files in the 3.4-3.7 MB range

## Assessment
### Keep in git
- `catalog/pd_catalog.json`
  - It is core runtime data for the app.
  - It is large, but still below GitHub's hard block threshold.
  - If it grows further, move to release artifacts or split/compress it.

### Candidates for cleanup or deduplication
- `assets/fonts/SFPro.ttf` and `assets/fonts/SF-Compact.ttf`
- duplicate family variants such as:
  - `SF-Pro-Display-Regular.ttf` and `SFProDisplay-Regular.ttf`
  - `SF-Pro-Display-Medium.ttf` and `SFProDisplay-Medium.ttf`
  - many similar `SF-Compact-*`, `SF-Pro-*`, and `SFPro*` variants

These should be audited for:
- true duplicate binaries
- unused families
- redundant aliases with different filenames

## Recommended next cleanup
1. Run a duplicate-hash audit on `assets/fonts/`.
2. Remove duplicate font files with identical hashes.
3. Remove unused font families from `pubspec.yaml`.
4. Consider moving very large non-source data to release artifacts or Git LFS if growth continues.

## Already fixed
- Removed `tools/pd_work/state.json` from git tracking.
- Added `tools/pd_work/` to `.gitignore`.
