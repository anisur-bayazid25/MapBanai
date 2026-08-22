# Changelog

All notable changes to MapBanai are documented here.
Format: Keep-a-Changelog style. SemVer, but the Android build number is
managed by `tool/bump_version.dart` (see AI_CHANGELOG.md).

## [2.4.0] - 2026-08-23

### Added
- **KMZ import (Study Area Mode)** — zipped KML (.kmz) files are now accepted:
  the archive is unpacked in-memory, `doc.kml` (or any `.kml` member) is parsed,
  and placemark points become sites. KMZ is also detected by content when the
  extension is unknown.
- **Real compass in GPS Mode** — the compass card is now a full compass rose:
  N/E/S/W labels (north highlighted red), NE/SE/SW/NW intercardinals, degree
  tick marks every 15°, and a red needle that rotates with the GPS heading.
  The heading is displayed as degrees-from-north plus cardinal direction both
  in a pill at the top and inside the dial.

### Changed
- **Home screen layout** — the four collection modes (Survey, GIS, GPS, Study
  Area) are square tiles in a **2×2 grid** so every mode is visible without
  scrolling; below them a **3×1 row** of square utility tiles: GPS CSV Viewer,
  Cloud Sync and WebMap. The Cloud Sync tile shows the last-synced time (or
  "Set up sync") as its subtitle and keeps the existing tap behavior.
- **Settings moved to the top-right** — Home now has an AppBar with the logo
  on the left and a standard ☰ menu icon opening Settings; the bottom Settings
  button was removed.
- **History is collapsible** — Drafts, project (folder) groups and per-date
  groups can each be expanded/collapsed by tapping their header; headers show
  item counts and an animated chevron.
- **WebMap basemap switcher icon fixed** — Leaflet's default white layers
  toggle (invisible on light tiles) is replaced with a dark standard
  stacked-layers SVG icon via CSS override.
- **Dark mode contrast fixes** — the project selector, "Collected data" panel,
  stat tiles and history draft cards now use theme-aware surface colors
  instead of hard-coded light tints that washed out text in dark theme.
- Study Area import/export buttons are visually distinct: Import = blue
  download-tray icon, Export = green upload icon (app bar, empty state card
  and header card).

### Tests
- `test/study_area_service_test.dart` — new KMZ test: builds a zip containing
  `doc.kml`, parses it back into sites.
- `test/drafts_history_test.dart` — updated for collapsible headers
  (`River Basin` header now includes its count).
- Suite: 223 tests green.

## [2.3.0] - 2026-08-22

### Added
- **Study Area Mode** (new mode card on Home) — import a list of sites from CSV,
  GeoJSON, KML, GeoPackage (.gpkg) or Excel (.xlsx), see them as colored map
  circles (red = pending, green = completed), tap a site for live GPS distance +
  cardinal bearing navigation, mark sites completed/pending, and export the
  site list back to CSV or Excel. Sites are stored per-device in
  `documents/study_area/study_area_sites.json` (`StudyAreaStore`).
- **GPS CSV viewer + WebMap projection** — GPS logs in GPS Mode now open in a
  detail screen that renders every reading of the log CSV on an interactive
  map, and any log can be projected onto the generated HTML WebMap
  (`GpsCsvService` parses the `GpsLogStore` CSV format and feeds the webmap
  generator).
- **Bangla (বাংলা) app localization** — full English + Bangla ARB catalogs
  (`lib/l10n/`) wired through `flutter_localizations`; Home, Settings, sync and
  mode cards translate live when the language is changed.
- **Theme setting** — Settings now offers System / Light / Dark; applied
  immediately via the new `AppSettingsProvider` (persisted in `app_settings`
  alongside the language preference).
- **ODK multi-language XLSForm support** — headers like `label::English (en)` /
  `label::Bangla (bn)` / `hint::bn` / `constraint_message::…` are parsed into
  per-question/choice translation maps; multi-language forms expose their
  language list + default and the survey renderer can switch label language at
  runtime.
- **QR import from gallery** — Import → Scan QR now also offers "Scan QR from
  gallery", picking a saved QR image and decoding it via zxing
  (`QrScanner.scanFromGallery`).

### Changed
- **WebMap** — the filter panel is now collapsible (collapsed by default) with
  search / form-type / surveyor / date filters and a result count; GIS feature
  exports now include the feature **Name** and **Notes** fields in the webmap
  data.
- **Area units** — new Square kilometers (km²) unit; areas ≥ 1 km² auto-format
  to km² in the compact formatter.

### Removed
- **OSM Humanitarian basemap** — dropped from the basemap list (unreliable
  tile host); OSM, Carto light/dark and Esri satellite/topo remain.

### Tests
- `test/study_area_service_test.dart` — status parsing, CSV/GeoJSON/KML/GPKG/
  XLSX imports, geodesic distance/bearing math, CSV/Excel export round-trips.
- `test/gps_csv_service_test.dart` — CSV header detection, row parsing and
  webmap projection payload.
- Suite: 222 tests green.

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