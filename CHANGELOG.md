# Changelog

All notable changes to MapBanai are documented here.
Format: Keep-a-Changelog style. SemVer, but the Android build number is
managed by `tool/bump_version.dart` (see AI_CHANGELOG.md).

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