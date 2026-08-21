# Changelog

All notable changes to MapBanai are documented here.
Format: Keep-a-Changelog style. SemVer, but the Android build number is
managed by `tool/bump_version.dart` (see AI_CHANGELOG.md).

## [2.2.0] - 2026-08-21

### Added
- **Cloud sync (Google Sheets via Apps Script)** — per-project `sync_config` with Web App URL + shared-secret API key, stored in Drift table `sync_configs` (Task 1), editable in Project Detail → Cloud Sync with Save + Test Connection (plain GET expecting `{ok:true}`) and obscured API key field
- **Data sync** — `CloudSyncService` batches unsynced survey responses vs GIS features (`synced_at IS NULL` split on `feature_type`), POSTs `{apiKey, action:"sync_data", responses[], features[]}` with `response_id`/`feature_id` = `session.id`, marks `synced_at`/`last_sync_at` only on `{ok:true}`
- **Photo sync** — `PhotoSyncService` uploads each unsynced photo individually as base64 `{apiKey, action:"upload_photo", filename, mimeType, base64}` with 3-attempt retry (2 s, 5 s backoff), per-photo `photo_synced_at`, over-15 MB skipped without network call, never blocks whole batch
- **Home Sync card** — near mode buttons, shows `Last synced`/`Never synced`, routes to project settings when no config, otherwise runs data→photos sequentially with progress dialog (`Syncing data…` → `Syncing photos (3/9)…` → summary like *12 responses, 3 features, 8/9 photos synced*) and distinct *No internet connection* handling

### Changed
- Drift schema v8 → v9 (`synced_at`, `photo_synced_at` on `survey_sessions` + `sync_configs` table) with migration and cascade deletes, project delete/reset now cleans sync state
- `SyncOrchestrator` composes data then photos for reporting; `last_sync_at` displayed under Home Sync and Project Cloud Sync

## [2.1.4] - 2026-08-21

### Fixed
- **In-app update no longer shows "Error in Download" after 100%**: the
  download was fine — the installer step failed silently. The old helper
  refused to open the APK when "Install unknown apps" is not enabled for
  MapBanai (Android 8+), with no way to change it. MapBanai now opens the
  package installer itself, waits for that permission, and the update dialog
  detects the blocked state and offers an **"Allow installation"** button
  that jumps straight to the device setting. (The manifest already declared
  `REQUEST_INSTALL_PACKAGES`; the setting itself must be granted per-app.)
- **Update downloads verified against HTTP redirects**: GitHub release URLs
  302-redirect to the CDN; a new test proves the downloader follows the
  redirect and still verifies the final byte count. The completed APK is
  handed to the installer via our own FileProvider instead of the removed
  `open_file` plugin.
- **Release signing already matches CI** (`KEYSTORE_BASE64` +
  `KEYSTORE_PASSWORD` + `KEY_ALIAS` + `KEY_PASSWORD` are used by
  `android/app/build.gradle` exactly as `.github/workflows/release.yml`
  passes them) — verified. Both the CI release and local
  `keystore.properties` releases sign with the same expected key, so the
  in-app update installs cleanly over the previous release.
- **Backup service** (still backs up `mapbanai.db` + settings to
  `Documents/MapBanai/backups` when the OS allows it, else app storage) no
  longer tries the Android-only public path on other platforms; restore and
  auto-backup behavior are now covered by tests. `hasFragileUserData` allows
  Android's own backup to keep data too.

### Tests
- Downloader: clears the 302 → final-URL redirect scenario.
- Backup: snapshot creation (db + settings) and restore-overwrite.

## [2.1.3] - 2026-08-21

### Fixed
- **Import → "Choose .mbproj file" now works and never fails silently**: the
  Android SAF filter could report nothing (or an error was swallowed) — the
  picker now accepts any file and validates the `.mbproj` extension, and any
  real failure shows a message instead of doing nothing.
- **Import → "Paste project code" no longer black-screens the app**: the
  import flow popped its progress dialog twice when the commit step threw
  (removing the Home screen). Bootstrap codes (projects too large for a QR)
  now show their friendly "ask the sender for the file" message instead of
  an "Import failed" crash.
- **Survey Mode ⋮ → Share project** now runs the real share sheet (Save /
  Share .mbproj) instead of "coming soon".
- **In-app update download no longer fails at ~99%**: downloads resume from
  the last byte across dropped connections (up to 3 attempts), verify the
  byte count against the server, and rename to the final APK atomically. The
  dialog now shows the actual reason instead of a generic message.

### Added
- **Import → "Scan QR code"**: open the camera, photograph a project QR code
  and import it (pure-Dart ZXing decode; paste is offered as a fallback if
  the code can't be read).

## [2.1.2] - 2026-08-20

### Added
- **GPS recording continues after leaving GPS Mode and with the screen off**:
  - Track recording runs as a **background recorder** with a foreground
    notification + wake lock — start a track, press Back, switch modes, even
    lock the screen, and fixes keep flowing into the log CSV
  - A live red banner on the Home screen appears while a recording is active
    (Open GPS Mode / Stop)
- **Drafts** — save unfinished work and resume it later:
  - Survey mode: **Save as draft** keeps a partially filled form (no
    required/validation blocking); resume it from History
  - GIS mode: **Save draft** while drawing a point/line/polygon, then resume
    the exact shape later from History
  - New **Drafts** section at the top of Survey History with **Resume** /
    **Delete** actions
  - Drafts never count as collected data (map annotations, exports, project
    statistics skip them)

### Changed
- GIS line/polygon recording also uses a foreground notification + wake lock,
  so drawing continues with the screen off
- History groups saved responses as before; drafts live in their own section

## [2.1.1] - 2026-08-19

### Added
- **Project export/import/sharing** — `.mbproj` package format:
  - Export Project / Share Project from the project menu (SAF save + Android share sheet)
  - Import Project from the Home screen, and "Open with MapBanai" file association
  - Never overwrites an existing project (import as new copy / replace / cancel)
  - `mapbanai://project/import?...` link support
  - QR bootstrap codes for project transfer
- MapBanai **logo** (launcher icon, About card, Home screen header)
- Version **bump system**: `dart run tool/bump_version.dart patch|minor|major`
  + GitHub Actions workflow
- GPS **Save Point → CSV** export (`<project>_points.csv`)
- **Reset safeguard**: type your exact user name to confirm a data reset
- **About section**: GitHub repository + email contact links

### Changed
- Home screen header shows the logo image instead of the app-name text
- Project identity: stable external project IDs (uuid) added to the data model

### Fixed
- Widget test updated for the new logo header

## [2.1.0] - 2026-08-19

### Added
- **In-app update checker**:
  - Home-screen silent update check (snackbar + View action)
  - Settings → Check for updates (shows release notes)
  - Download & Install with progress (streamed download, Android installer)
  - Version comparator with automated tests
- GitHub Actions **release pipeline**: tag push `v*.*.*` → build APK →
  publish GitHub Release with `app-release.apk`

### Changed
- Settings screen shows the installed version
- Manifest additions: `REQUEST_INSTALL_PACKAGES`, FileProvider config
- `package_info_plus` pinned to 8.0.2 (AGP 8.1 compatibility)

## [1.0.0] - 2026-08-19 (initial release imported to GitHub)

### Added
- Offline-first field data collection GIS:
  - **Project manager** (create/rename/archive/delete)
  - **Survey mode** with XLSForm (.xlsx) import, form builder, conditional
    logic (relevance/constraints), choice lists, calculations, GPS capture
  - **GPS mode**: live tracks, waypoints, save points, log management
  - **GIS mode**: MapLibre map, points/lines/polygons, attribute fields,
    5 basemaps, accuracy thresholds and filters
  - **Data export**: survey responses CSV/JSON, GIS CSV/GeoJSON/KML
  - Geotagged photos with EXIF writing
  - Settings: user name, language (system/English/Bengali)

[2.1.1]: https://github.com/anisur-bayazid25/MapBanai/releases/tag/v2.1.1
[2.1.0]: https://github.com/anisur-bayazid25/MapBanai/releases/tag/v2.1.0