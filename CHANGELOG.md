# Changelog

## v2.7.1 — 2026-10-27

- Correct the Settings Save action and pending-setting state; reuse the original MapBanai logo M for the launcher icon.

- Share the background SQLite executor between screen-owned clients to prevent concurrent schema initialization and locked project/settings access. Release the file when its last client closes, preserving backup restore behavior.
- Keep the name prompt controller alive through the dialog's closing animation. Add a retry state for Settings loading failures.
- Stack empty-site notices below map controls, retain only the bottom in-app atlas download action, and use theme surface/text colors for editable project cards and notices.
- Use USB phone previews and optional low-resolution, 30 fps scrcpy mirroring on E:.
- The v2.7.0 workflow was cancelled before publication after phone testing exposed these issues. v2.7.1 includes its Study Area, localization, responsive layout, update download and icon improvements.

## v2.7.0 — 2026-10-27

- Study Area opens Field Verification, Recurring Collection and Study Area Visits. Project layers and questionnaires are assigned per workflow; Collection rounds preserve separate salinity/heat measurements and progress.
- Visit sites use readable names, searchable selection, resumable drafts and green/red/yellow status markers. Create recurring point layers from selected numeric survey measurements without altering original responses.
- Nearest unvisited sites sort by straight-line GPS distance. Without a recent location they sort by name; refresh GPS from the list. Completion and review status is specific to the selected collection round.
- Project Settings > Workflow requirements configures required questionnaires and geotagged photos separately for each workflow. Requirements are checked before completion and carried in project packages; share an updated package after changing them. Questionnaire photos can satisfy the photo requirement.
- Compact Google Maps shortcuts open the selected site or current map area externally. Draggable site sheets, shared map controls, a refreshed theme and incremental status updates make the map interface easier to use.
- Responsive home/internal layouts, broader Bangla UI translations, and a new adaptive map-pin launcher icon, monochrome icon and matching Android splash screen.
- In-app update downloads stream with backpressure, check resumed ranges/source URLs and provide a browser fallback. Mobile-carrier throughput still needs a real-network comparison; APK size and carrier/CDN routing can also affect download time.

## v2.6.10 — 2026-10-26

- Added bulk survey-history cleanup by project, study layer, local recorded day, record type and sync status, with optional drafts and linked map-point removal. Deletion also clears the matching sync queue; unchanged map snapshots cannot recreate deleted history records.
- Clear all sites can now clear the selected layer's history and sync queue together. Unassigned legacy sites have a selectable preview showing their IDs, source and recorded date when available.
- Connected project vector imports to the Study Area layer selector. Existing source layers become selectable, can be verified on the map, and retain project ownership. Baseline imports do not create collected survey records.
- Both import screens use the same spatial parser, discover matching shapefile companions in accessible folders without case sensitivity, support selecting companion files together, and offer a folder picker or explicit geometry-only import when DBF attributes are missing.
- Reuse the native map across point selection and GPS changes, stop redrawing markers when point cards close, coalesce redraws, avoid duplicate source/point drawing, fit the actual layer bounds, and move large map JSON reads/writes into a worker.
- Home export now offers .mbproj projects with or without collected responses, plus responses-only JSON. Full packages preserve response photos, verification state, GIS sources, forms, settings and optional sync URL/API credentials; importing restores collected data.
- Fixed Windows local builds by using a writable canonical Java socket/temp directory in the build helper. The local Gradle release task graph now completes without the loopback connection error.

## v2.6.9 — 2026-10-26

- Project vector layers are available directly from Study Area Mode and retain independent visibility, type, colour and opacity settings.
- Importing spatial files in Study Area Mode now also registers the source layer and original file in Project Settings, keeping both import paths in sync.
- Imported point files are tracked as batches. Removing a batch deletes its map layer, imported points, local revision history and pending sync records.
- Large point and reference layers render in batched map updates, and selecting a point no longer redraws every map feature.
## v2.6.8 — 2026-10-25

- Fixed the Study Area header so its category-color control stays compact and the visible-feature count no longer wraps vertically on phones.
- Fixed verification saves for older imported features that match a project by external ID but do not yet have a local project ID; their edits can now be queued for project sync.
- Refresh the selected feature from storage after a revision conflict so the user can review the latest saved state.

## v2.6.7 — 2026-10-25

- Reworked Study Area point details to show only ID, layer, name and location. Added quick Unchanged, Location changed, Location removed and Edit/status actions; moving a point now uses a map placement screen with Cancel and Save.
- Simplified status to Pending verification, Verification Complete and Needs review. Verification states use circle, square and triangle markers with status outlines while retaining user-selected layer colours.
- Added road-network overlays and shortest-path directions from the current GPS position, with metre/kilometre distance display.
- Project settings can add and classify study-area, facility and road layers from shapefile/ZIP, CSV, Excel, GeoJSON and GeoPackage files. Original imported source files are preserved with normalized layers in project packages.
- Project packages retain original XLSForms, project settings, map layers and the matching cloud sync Code.gs/Map.html/Charts.html bundle. Sync URL/API key is included by default for team handoff and can be unchecked before export.
- Fixed clipped Latitude/Longitude labels in the Study Area edit dialog and refreshed Study Area guidance.

## v2.6.6 — 2026-10-13

- Poster map fills over 80% of the image, with compact titles/legends and a fit-data extent option. Shared by Android WebMap and Google Sheets atlas.
- WebMap categorical colours, per-value visibility and editable symbols support text fields such as imported layer categories. Added browser GeoJSON/shapefile ZIP overlays and map/chart fullscreen controls.
- Manager atlas startup repaired; clear loading and initialization errors replace blank dropdowns. Study status data is available in the manager map.
- Sync sends at most 20 records per batch, retries busy-server responses and preserves acknowledged progress. Server timeouts no longer appear as internet loss.
- Photos sheet shows readable metadata, private embedded thumbnails and clickable Drive links. Spreadsheet menu can refresh existing photo previews.
- Field quality now reviews only recorded GPS/photo accuracy above the selected limit. Accept accuracy persists per project on the device, with Undo and View record.
- Existing in-app Help explains the updated workflows and includes the complete matching manager scripts.

Install app-release.apk over the existing MapBanai installation to preserve local data. For Google Sheets, replace Code.gs, Map.html and Charts.html with the matching files, keeping the project ID/configuration. Save and deploy a new version for the sync API; reload the spreadsheet and reopen its workspace. Run MapBanai → Refresh photo previews for older uploaded photos.

Browser overlay uploads are temporary and do not change sheet records. Browser GeoPackage import is not included; use the Android importer or convert to GeoJSON. Accuracy acceptance is local and is not uploaded to the manager workbook. Basemap and manager library loading require internet.


All notable changes to MapBanai are documented here.
Format: Keep-a-Changelog style. SemVer, but the Android build number is
managed by `tool/bump_version.dart` (see AI_CHANGELOG.md).

## [2.6.5] - 2026-10-13

- Fixed Android spatial-file selection by choosing any file and validating formats after selection. Added zipped shapefile imports with companion attributes, safe extraction and size limits.
- Spatial files opened from Android file managers now offer an existing project, new project or view-only Study Area preview. Project packages retain their own import flow.
- Fixed study import project binding: features are refreshed immediately after saving, local project IDs are retained explicitly during imports, and sync-queue failures no longer report the saved map as a failed import.
- Removed duplicate Study Area import buttons; the top toolbar provides import/export. Project names align left; Add new Layer is inside the layer selector. The plus button opens the selected questionnaire at a fresh GPS location; long-press placement remains available.
- Added Categories & colors: all features have one default color. Choose any attribute column for category colors, select visible categories and adjust point size. Style choices are saved per project/study layer.
- Centered Home Field quality checks and Offline maps buttons as a group.

## [2.6.4] - 2026-10-13

- Replaced the public health-only sync test with authenticated, read-only project/key/data-sheet verification, with deployment/sign-in diagnostics and updated manager setup guidance.

- Unified GIS/Study Area basemaps through the existing shared picker; removed CARTO and added Topographic, Humanitarian, Cycling and No background with native tile zoom limits.
- Kept the name editor only in Home → three-bar menu → My name. Removed the duplicate Data collection fields editor; survey forms define questions across collection modes, while legacy fields/data are retained.
- Aligned Home card icons/titles with fixed title/subtitle space and shorter sync timestamps.
- Added semantic, view-aware legends with editable names, point symbols, line patterns, polygon outlines and PNG/self-contained SVG icons. Exported legends include matching symbols and only mapped categories.
- Scaled map export text, symbols and north arrow with image resolution, plus readability options and independent title/subtitle/legend fonts. Bundled Nunito, Lora, Oswald and Lobster for offline use.
- Removed feature/reference counts and no-basemap notices from images; only an included basemap receives source attribution.
- Replaced GPS travel bearing as the primary compass with foreground orientation sensors, circular smoothing and isolated compass updates. GPS bearing remains explicitly labelled fallback; altitude reference/uncertainty is clearer.
- Rewrote offline Help and manager documentation around a fresh project: edit only the project ID, generate the key/photo folder automatically, and deploy a new Web app. Formatted the complete Code.gs for readability.

## [2.6.3] - 2026-10-13

- Simplified enumerator access: My name/My responses/Help in the existing three-bar menu, questionnaire sync in Survey Mode and data sync on Home.
- Added response revisions, preserved collector/editor audit and requeued saved edits for data/photo sync; old backends cannot acknowledge corrections.
- Updated Code.gs to preserve compatible old tables/keys, reject version conflicts, maintain uploaded revision history and serve questionnaires from the same workbook.
- Rebuilt manager Map.html/Charts.html with filters, designs and exact-resolution downloads; bundled all three copyable files and updated setup guidance.

- Made Download Map a separate button and customization dialog, outside Explore, with 12 designs, custom colours, typography, caption alignment, portrait/landscape, aspect ratios and exact HD/Full HD/QHD/4K/custom pixel sizes.
- Added direct PNG/JPEG file saving and sharing, rendering tiles at the requested viewport resolution and restoring the map afterward.
- Added project-owned reference shapefile/ZIP/GeoJSON layers, individual visibility/colour/opacity, package portability, vector-only maps and reference geometry in image exports.
- Added topographic, humanitarian and cycling basemaps, plus No background.
- Kept Help in the existing three-bar menu, without an extra homepage shortcut.

## [2.6.2] - 2026-10-12

- Added stable-site timelines for repeated observations and reusable project/layer templates.
- Added five map-studio themes, captions, labels and PNG/JPEG poster/current-view exports with Android sharing.
- Added optional sync URL/API key inclusion in project file and inline QR sharing.
- Added Google Sheets XLSForm questionnaire sync through a project-authenticated Apps Script handler.
- Changed questionnaires create new local revisions; prior records/drafts remain unchanged and latest versions appear in selectors.
- Added Google Sheets setup and geospatial-app design reference guides.

## [2.6.1] - 2026-10-12

- Bound Survey, GIS, Study Area, WebMap and sync to project identity; GPS remains standalone.
- Added named project study layers, shared form selection and typed map attribute editing.
- Added explicit legacy site assignment and study-site sync outbox records.
- Preserved sync credentials through partial updates and same-project replacement.
- Corrected GNSS altitude presentation and made relative references explicit.
- Rebuilt the mobile project atlas with filters, measurement styling, answer tables and filtered exports.
- Bounded form validation and duplicate scanning, with quality progress reporting.
- Updated tagline and CARE/BRAC acknowledgements.

## [2.6.0] - 2026-10-12

- Added linked guided visits, durable drafts and retryable map updates.
- Added provider-approved offline map packages and shared basemap selection.
- Added site revision history, changed-only GeoJSON export and explicit team conflict resolution.
- Added field quality checks and inspection links.
- Photo GPS accuracy is recorded/displayed without an accuracy gate; EXIF coordinates remain mandatory.
- Saved visits retain their original form definition; restored histories retain working photo links.
- Scoped site clearing preserves other projects; release CI requires signing and runs tests/analysis.

The unpublished 2.5 fixes below are included in this release.

## [2.5.0] - 2026-10-12

### Changed
- Study Area now supports verification/update/new-feature/review/not-found statuses, retained original data, change notes, point/line/polygon editing and revised GeoJSON/HTML/CSV/XLSX export.
- Photo capture requires verified JPEG EXIF GPS tags and a fresh quality location for camera captures.
- XLSForm import validates unsupported features explicitly, handles prefixed Excel XML and defaults, and supports editable dates and line/polygon questions.

### Fixed
- Cross-question constraints and asynchronous form saving; failed saves retain answers.
- Duplicate-name project routing and cancelled resumed GIS drafts.
- Edits requeue data/photos for sync; older upload requests cannot acknowledge newer edits.
- Full backup attachments, integrity checks, cross-install photo paths and safe restore connection handling.
- Track pause/draft timing and survey geometry exports.

Re-import existing XLSForms to use parser fixes. See FIELD_WORKFLOW.md for the field procedure and supported-feature boundaries.

## [2.4.4] - 2026-08-23

### Fixed
- **Skip-logic hardening + proof** — the v2.4.3 group-gating path is now
  proven end-to-end by a UGGP-faithful pipeline test (real xlsx bytes with
  English/Bengali labels, styled spans, once/coalesce calculations, nested
  group + repeat, 4-choice outcome question → parse → render → only choice
  1 opens the gated module; choices 2/3/4 keep it closed with the red end
  note). Curly quotes (`‘ ’ “ ”`, common in Word-authored forms) and
  non-breaking spaces in expressions are normalized before parsing.

### IMPORTANT — re-import forms imported before v2.4.3
- Stored forms keep only their parsed JSON, and parses made before v2.4.3
  contain no group information — updating the app does **not** repair them.
  To get module skip logic: open **Project settings → Survey forms**,
  delete the old imported form, and **import the .xlsx again**. Fresh
  imports carry group relevance and gate correctly.

### Tests
- `survey_uggp_pipeline_test.dart`: parser keeps groups/paths/i18n/calcs;
  renderer gating across all four outcome choices; no raw markup.
- Engine: curly-quote normalization.
- Suite: 264 tests green.

## [2.4.3] - 2026-08-23

### Fixed
- **Label colors now render** — `<span style="color:red; font-weight:bold">`,
  `<b>`, `<i>`, `<u>`, `<font color>` and `<br/>` in question labels, hints,
  notes, group headers and form titles are rendered as styled text (named +
  hex colors) instead of showing raw markup. Malformed tags degrade
  gracefully (tag dropped, text kept).
- **Group skip logic works** — `begin_group` rows were silently dropped, so
  group-level `relevant` (e.g. `${a12} = '1'` on whole modules) never
  applied: answering "no" still showed every following question. Groups are
  now tracked with their relevance; a question shows only when its own AND
  all enclosing groups' relevance hold. Visible groups render their (styled)
  module header once.
- **New ODK functions**: `once()` (first computed value frozen — start-time
  stamps no longer recompute), `sum()` (totals numerics, skips blanks),
  `regex()` (full-match semantics, so mobile-number patterns validate
  correctly), `position()` (1 outside repeats).
- **Arithmetic coerces numeric strings** — `coalesce(${count}, 0) + ...`
  totals over string answers now add (`3`) instead of concatenating (`30`).
- Note questions no longer show their label twice (header + blue box).

### Known limitations
- Repeats (`begin_repeat`) render a single instance; `repeat_count` is
  recorded but not expanded yet. All other logic in repeat blocks evaluates
  normally.

### Tests
- Parser: a12-gating group test + nested group paths + JSON round-trip.
- Engine: once/sum/regex/position, string-coercion arithmetic, styled-text
  parsing (incl. malformed tags).
- New renderer widget tests: gated module hidden/shown/toggled live, no raw
  HTML, red span actually red, module header emitted.
- Suite: 260 tests green.

## [2.4.2] - 2026-08-23

### Fixed
- **ODK forms with calculations now load correctly** — the expression engine
  previously had no function support, so any `calculate` using `now()`,
  `today()`, `format-date-time()`, `concat()`, … evaluated to null and the
  question stuck at "Not computed yet". The engine now implements the ODK
  function library: `now`, `today`, `date`, `time`, `format-date`,
  `format-date-time`, `concat`, `join`, `if`, `coalesce`, `string-length`,
  `substr`, `upper`, `lower`, `contains`, `starts-with`, `ends-with`,
  `count-selected`, `selected-at`, `round`, `floor`, `ceil`, `abs`, `min`,
  `max`, `pow`, `sqrt`, `number`, `int`, `string`, `boolean` (plus
  hyphenated names like `format-date-time(...)` and legacy `selected(...)`).
  Dates compare correctly in relevance/constraints, and date results are
  stored as ISO strings.
- **HTML in form labels is no longer shown raw** — tags like
  `<span style="color:red">` are stripped (`<br>`/`</p>` become line breaks,
  entities decoded) in question labels, hints, notes and the form
  title/description.
- **Dynamic note labels work** — `${question}` placeholders in labels (e.g.
  `Interview date: ${date} | Start time: ${start_time}`) are substituted
  live with current answers, for notes, hints, titles and descriptions.
- Chained calculations keep evaluating in dependency order (fixpoint loop
  already in the renderer now feeds on real function results), and unknown
  functions fail safe (calculation → null, relevance → visible).

### Tests
- 17 new `survey_logic_test.dart` cases: date functions + chained
  `date`→`format-date`, concat/join note building, if/coalesce, string and
  math helpers, count/selected-at, date relevance, unknown-function safety,
  HTML stripping, `${}` interpolation.
- Suite: 244 tests green.

## [2.4.1] - 2026-08-23

### Fixed
- **Home logo restored** — the large top-centred MapBanai logo (260 px) is
  back on the home body; the AppBar now holds only the ☰ Settings menu.
- **Redundant bottom Settings button removed** — Settings lives solely in the
  top-right ☰ menu.

### Changed
- **"Open" renamed to "Project settings"** (button label uses the existing
  l10n key; English/Bangla strings unchanged in Bangla). Empty-project hints
  in Home and GIS Mode now say to open *Project settings* to create a project
  or use *Import Project* for a `.mbproj` file.
- **Compass reworked (GPS Mode)** — back to a collapsible card that opens
  instantly. The dial is now a static painting (ring, degree ticks every 15°,
  numbered degrees every 30°, N/E/S/W red-north labels, intercardinals) that
  rotates with `AnimatedRotation` through the shortest path (heading is
  unwrapped so crossing north never spins backwards); the red needle is
  fixed pointing up — the direction the phone faces — like standard phone
  compasses. Repaint cost per GPS fix dropped to zero (painters are constant,
  `shouldRepaint: false`), fixing the lag.
- **Study Area imports accept WKT and coordinate synonyms**:
  - CSV/XLSX columns `x/y`, `lon/lng/long`, `lat_dd`, `dd_lat`, `point_x/
    point_y`, etc. all recognized; a dedicated geometry column (`wkt`,
    `geometry`, `geom`, `the_geom`, `shape`, …) works even without lat/lon
    columns, and cells holding `POINT (lon lat)` / `POINT Z (…)` are parsed
    as fallback.
  - GeoJSON features without Point geometry fall back to a WKT string stored
    in their properties.
  - KML/KMZ placemarks without `<Point>` fall back to a WKT string embedded
    in ExtendedData/SimpleData attributes.
- **Shapefile (.shp) import (Study Area Mode)** — minimal binary reader
  extracts one site per record from Point/PointZ/PointM and the first vertex
  of PolyLine/Polygon/MultiPoint shapes (.dbf attributes not read yet).

### Tests
- New: CSV X/Y synonyms, CSV WKT-column-only, GeoJSON WKT property fallback,
  binary .shp Point parsing, plus existing suites.
- Suite: 227 tests green.

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

- Added offline Help & manager setup with feature guides, project-ID copying and a complete Sheets/Drive backend. One or two workbooks use one URL/key per project; data/photo uploads include project identity and stable photo IDs.

## v2.6.2 - Repeated observations and templates

Guided visits remain separate observations, linked through stable feature UUIDs. Study Area and the visit selector expose timelines, numeric comparisons and complete CSV export. Imported visit revisions and local saved interviews are deduplicated by visit UUID. Keep measurement units and question names consistent across form versions.

Reusable project/layer templates preserve definitions, omit data and credentials, and create fresh project/layer identities. Templates are stored in database settings for backup preservation.

This release also includes online XLSForm updates, optional connection sharing, styled PNG/JPEG export and offline Help with the complete Google backend. The parent/child pattern follows Mergin Maps one-to-many relations: https://merginmaps.com/docs/layer/one-to-n-relations/ (no service dependency added).

Study Area → Edit feature: questionnaires are mandatory for newly created features and Updated/New feature statuses. For Pending verification, Completed (legacy), Verified unchanged, Not found and Needs review, saving skips the questionnaire unless Fill questionnaire (optional) is checked. Existing answers are preserved when skipped. Categories & colors offers explicit Verification status coloring as well as attribute columns; the default remains a single color.
