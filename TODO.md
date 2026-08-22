# MapBanai - Project TODO

**Status:** Phase 4e — v2.3.0 release batch (Complete — tests green, APK built 2026-08-22)  
**Last Updated:** 2026-08-22  
**Version:** 2.3.0

---

## ⚡ NEXT FOCUS — PRESSING ISSUES

1. **Device-test GIS Mode** (`GisModeScreen`) — pan/zoom, draw + record flow (point/line/polygon), feature tap → info panel, follow-me. Statically clean, but the map/draw interaction is only verifiable at runtime.
2. **Persist basemap choice** and **respect the project's GPS accuracy threshold** while drawing (threshold is currently unused in GIS draw / accuracy filter).
3. **GIS data export** — GeoJSON + CSV export of survey features from GIS Mode (`DataExportService` currently exports form/survey JSON + CSV, no GeoJSON yet).
4. **Edit & delete features on the map** — `_InfoFeature` panel shows title/type only; no open-detail, delete, or attribute editing from the map.
5. **Cleanup** — remove unused `go_router` & `intl` deps; fix the 39 pre-existing analyzer lints (0 in new GIS code).
6. **Satellites / GNSS diagnostics** — still deferred (needs a GNSS plugin; same blocker as Phase 2).

---

## PHASE 1: FOUNDATION (Complete ✅ — deviations noted inline)

### Core Setup
- [x] Create Flutter project structure
- [x] Add dependencies to pubspec.yaml
  - [x] Provider (ChangeNotifier, not Riverpod)
  - [x] Drift (SQLite ORM)
  - [x] MapLibre Flutter (vendored fork: `third_party/maplibre_gl` + platform interface 0.25.0)
  - [ ] GoRouter — NOT used (MaterialPageRoute navigation adopted)
  - [x] Geolocator / location service
  - [x] image_picker (pinned 1.1.2 for AGP 8.1)
  - [ ] http client — not needed yet (no network features)
  - [x] path_provider
  - [ ] intl (localization) — declared but unused; remove
  - [ ] freezed (code generation) — NOT used; drift/build_runner used instead
- [x] Configure build system
  - [x] Android build configuration
  - [x] Gradle wrapper
  - [x] Android manifest permissions (location, camera)
  - [x] iOS configuration (Podfile + Info.plist permissions) — added from Flutter template; not build-verified (no macOS here)
- [x] Set up code generation (Drift via build_runner; no Freezed)
- [x] Configure lint/analysis
  - [x] analysis_options.yaml
  - [ ] pre-commit hooks (optional) — not configured

### Database Schema
- [x] Define Drift database tables — physical schema (differs from DATA_MODEL vision): `projects`, `survey_sessions`, `stored_forms`, `app_settings`, `gps_logs` (schemaVersion 5)
  - [ ] users — not modeled (current user = app_settings `user_name`)
  - [x] projects
  - [ ] layers — not modeled (annotations rendered ad hoc)
  - [ ] features — not modeled (features stored as `survey_sessions.responses` JSON)
  - [ ] attributes — not modeled (embedded in session JSON)
  - [x] survey_responses — `survey_sessions` table
  - [ ] photos — files + sidecars via PhotoStore, no DB table
  - [ ] basemaps — not modeled (Basemap.defaults in code)
  - [ ] sync_queue / conflicts / project_versions — future (Phase 5)
  - [x] app_settings
- [x] Create DAOs for each entity (methods on AppDatabase)
- [x] Add database migrations (v1→v5; v4 drops `field_tasks`)
- [x] Write database initialization tests (database_integration_test.dart)
- [x] Test Drift code generation (analyze green, tests green)

### Project & User Models
- [x] Implement Project entity and repository
  - [x] CRUD operations (name, description, archive/restore, gps threshold)
  - [ ] Export/import ZIP — not implemented (JSON/CSV export only)
  - [ ] Project versioning — not implemented
- [x] Implement User entity and repository — no entity; user = app_settings `user_name`
  - [x] Current user management
  - [x] User listing — single current user (no multi-user yet)
  - [x] User switch UI — edit/clear in Settings
- [ ] Implement Layer entity and repository — not modeled
- [ ] Implement Feature entity and repository (basic) — features live in session JSON
- [x] Implement Basemap repository — `Basemap.defaults` in map_service.dart (OSM, OSM-HOT, Carto light/dark, Esri satellite)

### Navigation & Routing
- [ ] Set up GoRouter configuration — NOT used; MaterialPageRoute adopted
- [x] Define routes (via MaterialPageRoute pushes)
  - [x] Splash screen (implicit MaterialApp boot)
  - [x] User setup screen (dialog after first launch)
  - [x] Home screen
  - [x] Settings screen
- [x] Create basic navigation widget tree (rooted in app.dart)
- [x] Test navigation flows (widget/integration tests)

### UI Framework
- [x] Set up Material theme (MaterialApp in app.dart)
  - [x] Colors
  - [x] Typography
  - [x] Component styles
- [x] Create common widgets — kit in `lib/ui/common/`: SectionHeader, AppLoadingIndicator, ErrorMessage, EmptyState, showConfirmDialog; adopted across Settings, Home, GPS/GIS, point/line/polygon record, photo gallery, survey & project screens
- [x] Create responsive layout utilities — `ScreenLayout` in `lib/ui/common/responsive.dart` (maxWidthAlign, contentPadding, isWide); adopted in Home

### Settings & User
- [x] AppSettings key/value table + DAOs (getSetting/setSetting)
- [x] User name prompt on first launch (non-blocking dialog, re-prompts until
      entered or skipped; stored under `user_name`)
- [x] Settings screen (Home → Settings): edit/clear user name
- [x] User name wired to every output: survey session JSON (`user_name` for
      survey/point/line/polygon), GPS log CSV (`surveyor` column, captured at
      log creation), data export (JSON root `surveyor` + CSV `user_name`
      column)

### Basic Screens
- [x] Splash screen (app initialization) - implicit (MaterialApp boot)
- [x] User setup (first launch) - user name dialog on Home
- [x] Home screen (mode selector)
  - [x] Survey Mode button
  - [x] GIS Mode button
  - [x] GPS Mode button
  - [x] Settings button
- [x] Settings screen (user name edit)
  - [x] Current user display
  - [x] Language selection (stub) — preference stored (`language`); translations ship in Phase 6
  - [x] Version info
  - [x] About

### State Management Setup
- [x] Create Provider setup
  - [x] Service providers (ChangeNotifierProvider pattern in app.dart)
  - [x] Repository providers
  - [x] User state provider (app_settings user_name)
  - [x] Project state provider (ProjectState — state/project_state.dart)
- [ ] Create basic BLoCs/Cubits — NOT used (ChangeNotifier instead)
  - [ ] UserCubit — replaced by app_settings user_name
  - [x] ProjectBloc — ProjectState (list/select projects)
  - [ ] AppBloc (app-wide state) — not implemented

### Location Service (Basic)
- [x] Create location service wrapper (LocationService)
- [x] Implement permission handling
  - [x] Request location permissions (ensurePermission / permission_handler)
  - [x] Check permission status
  - [x] Handle denial (status readouts in GPS/Point/Line/Polygon/GIS screens)
- [x] Implement location stream
  - [x] Get current location
  - [x] Listen to location updates
- [ ] Implement GNSS status monitoring — deferred (needs GNSS plugin)
  - [ ] Get visible satellites
  - [ ] Get used satellites
  - [ ] Get provider info
- [x] Create location unit tests (accuracy_filter_test.dart, coordinate_utils_test.dart)

### Settings & Preferences
- [x] Implement AppSettings repository (getSetting/setSetting on AppDatabase)
  - [x] Get setting
  - [x] Set setting
- [x] Store current user preference (`user_name`)
- [x] Store app language preference (`language`: system/en/bn; applied in Phase 6 i18n)
- [x] Create SettingsScreen with form
  - [x] User name field (saved to `user_name`)
  - [x] Language selection — preference stored in Settings; translations ship in Phase 6
  - [x] Reset data option — confirm dialog + `AppDatabase.resetAllData()` (keeps user_name)

### Build & Test Setup
- [x] Configure test environment
  - [x] Test fixtures (test/helpers/test_utils.dart)
  - [x] In-memory DB (AppDatabase.forTesting)
- [x] Write unit tests for:
  - [x] Project repository (database_integration_test.dart)
  - [x] Location service (accuracy_filter_test.dart, coordinate_utils_test.dart)
  - [x] Validators (survey_logic_test.dart, xlsform_parser_test.dart)
- [x] Write widget tests for:
  - [x] Splash screen (widget_test.dart)
  - [x] Home screen (widget_test.dart)
  - [x] Settings screen (project_screens_test.dart flows)
- [ ] Set up CI/CD (optional) — not configured
- [x] Document build process (README, FOUNDATION_COMPLETE.md)

### Build Verification
- [x] `flutter pub get` ✅ (2026-08-18)
- [x] `flutter analyze` passes ✅ (0 issues in GIS code; 39 pre-existing lints in older files)
- [x] `flutter test` passes ✅ (106 tests, all green — incl. reset-data test; fixed 2 pre-existing xlsform parser bugs: English-label preference, `relevant`/`relevance` column)
- [x] `flutter build apk` produces APK ✅ (27.1 MB release APK)
- [x] APK installs on device ✅
- [x] App launches without crashes ✅
- [x] Basic navigation works ✅

---

## PHASE 2: SURVEY MODE BASIC

### Survey Schema & Validation
- [x] Implement SurveySchema model & repository (SurveyForm model + stored forms)
- [x] Create survey schema validator
  - [x] Validate question structure (XlsFormParser validation)
  - [x] Validate options (choices list lookup, missing list error)
  - [x] Validate calculations
  - [x] Validate conditionals
- [x] Create survey schema JSON import/export
- [x] Add XLSForm (.xlsx) import (survey/choices/settings sheets, all core types,
      appearance column: multiline/dropdown, localized labels, FilePicker import button
      in Form Builder, forms persisted to DB and listed in Survey Mode)
- [x] Robust .xlsx reader (xlsx_reader.dart): dependency-free ZIP/OOXML parser,
      shared strings + inline strings, case-insensitive sheet lookup, null-safe
      (no crashes on real-world files — fixed "Null check operator used on a
      null value" import failure; verified against openpyxl-generated fixture),
      legacy select_one_dropdown types, friendly .xls/format errors
- [x] Write validation tests (xlsform_parser_test.dart, 7 tests +
      xlsx_reader_test.dart, 7 tests)

### Question Types
- [x] Implement question type handlers
  - [x] TextQuestion
  - [x] LongTextQuestion
  - [x] IntegerQuestion
  - [x] DecimalQuestion
  - [x] YesNoQuestion
  - [x] SelectOneQuestion
  - [x] SelectMultipleQuestion
  - [x] DropdownQuestion
  - [x] DateQuestion
  - [x] TimeQuestion
  - [x] DateTimeQuestion
  - [x] PhotoQuestion (real camera capture via PhotoCaptureScreen, geotagged)
  - [x] LocationQuestion (geopoint via geolocator)
  - [x] CalculatedQuestion
  - [x] NoteQuestion
  - [x] GpsAccuracyQuestion
  - [x] HiddenMetadataQuestion
- [x] Create question validators (constraints via SurveyLogic)
- [x] Write unit tests for each type (survey_logic_test.dart)

### Survey Form Rendering
- [x] Create FormBuilder widget
- [x] Implement question rendering (all 17 types)
- [x] Implement conditional display logic (relevance engine: = != < > <= >= and/or/not selected() parentheses)
- [x] Implement calculation engine (arithmetic + string concat, chained/stable iteration)
- [x] Create form validation (required + constraints)
- [x] Create form submission (answers persisted as JSON in survey_sessions.responses)
- [x] Create FormScreen UI

### Point Recording
- [x] Create PointRecordScreen
- [x] Implement location recording flow (live GPS position stream)
- [x] Show accuracy & satellites (accuracy shown; satellites deferred — needs GNSS plugin)
- [x] Show GPS status indicator (ready / searching / permission denied)
- [x] Implement accuracy filter (AccuracyFilter service + tests)
  - [x] Check if accuracy acceptable
  - [x] Show wait/save/cancel options (Save Anyway dialog)
  - [x] Store actual accuracy with feature (in survey_sessions.responses JSON)
- [x] Connect to survey form (started from GIS mode toolbar)
- [x] Implement photo capture (via PhotoCaptureScreen; attached to features in session JSON)
- [x] Create feature with all data (survey answers + GPS + photo + accuracy in session JSON)
- [x] Write integration tests (database_integration_test.dart + project_screens_test.dart)

### Field Tasks → REMOVED (2026-08-17)
Field Tasks feature (clipboard coordinate to-do list, point recording at task
targets) was removed at user request. `field_tasks` DB table is dropped by
migration v4. Coordinate parsing utilities (coordinate_utils.dart) kept for
the GPS Mode copy flow.

### GPS Mode (basic GPS data collection)
- [x] GPS Mode card on home screen (below Survey Mode and GIS Mode)
- [x] GpsModeScreen: live GPS stream (1 s interval), real-time readouts
- [x] Show latitude/longitude (7 dp), accuracy with quality color, elevation,
      speed, and DMS format
- [x] Copy coordinates to clipboard (decimal degrees + DMS, usable anywhere)
- [x] GPS log files (GpsLogStore, app documents/gps_logs/log_<id>.csv)
  - [x] Auto-incremental row ids (derived from file, survive restarts)
  - [x] Columns: id, surveyor, timestamp, latitude, longitude, altitude_m,
        accuracy_m
  - [x] Create log (optional name → default "GPS Log N"), recording toggle
        per log, append on each GPS fix
  - [x] Rename, delete (with confirm, removes CSV file)
  - [x] Export/share CSV (share_plus)
- [x] GpsLogs DB table + DAOs (migration v4)
- [x] Write GpsLogStore tests (gps_log_store_test.dart, 5 tests)

### Line Recording
- [x] Create LineRecordScreen
- [x] Implement recording start/pause/resume/finish
- [x] Auto-collect vertices with filtering (TrackRecorder service)
  - [x] Minimum distance: 3m
  - [x] Minimum interval: 2s
  - [x] Maximum accuracy: 20m
- [x] Display live statistics
  - [x] Distance (m/km)
  - [x] Elapsed time
  - [x] Vertex count
  - [x] Current accuracy
- [x] Implement cancel/undo
- [x] Create line feature in database (survey_sessions.responses JSON)
- [x] Write integration tests (TrackRecorder + GeometryService unit tests)

### Polygon Recording
- [x] Create PolygonRecordScreen
- [x] Implement recording start/pause/resume/finish
- [x] Auto-collect vertices (shared TrackRecorder)
- [x] Display live statistics
  - [x] Area (m², hectares, acres)
  - [x] Perimeter (m/km)
  - [x] Vertex count
  - [x] Elapsed time
- [x] Implement undo last vertex
- [x] Close polygon automatically (perimeter closes loop)
- [x] Validate minimum 3 vertices (Save disabled until 3+)
- [x] Create polygon feature in database
- [x] Write integration tests

### Photo Management
- [x] Implement camera/photo capture (image_picker camera + gallery, pinned to
      image_picker 1.1.2 for AGP 8.1 compatibility)
- [x] Create PhotoCaptureScreen (capture → GPS fix → save → preview with
      geotag status, retake, use)
- [x] Geotagging (GeotagWriter service):
  - [x] Device GPS EXIF preserved untouched when the camera wrote it
  - [x] GPS embedded into JPEG EXIF when missing (insertion or in-place
        patch preserving orientation, verified via exif read-back)
  - [x] Non-JPEG (HEIC) stored with coordinates in sidecar JSON
  - [x] Captures without GPS fix allowed (photo saved, not geotagged)
- [x] Implement photo save to disk (PhotoStore, app documents/photos/) +
      sidecar metadata
- [x] Create photo thumbnail generation (512px, quality 70)
- [x] Implement photo gallery view (PhotoGalleryScreen grid, full-screen
      preview, geotag badge, delete; entry from History app bar)
- [x] Attach photos to features (survey form image question + point recording
      photo button; path + coords + GPS status in session JSON)
- [x] Implement photo deletion (gallery + confirm; file, thumbnail, sidecar)
- [x] Write photo/geotag service tests (photo_geotag_test.dart, 11 tests)

### Survey Mode Navigation
- [x] Create survey list screen (SurveyScreen)
- [x] Create survey detail screen (SurveyFormDetailScreen)
- [x] Create navigation flow (list → detail → run/edit/delete)
- [x] Implement screen transitions (MaterialPageRoute push/pop)

### Project Management (Basic)
- [x] Create project list screen (ProjectSetupScreen)
- [x] Create project detail screen (ProjectDetailScreen)
- [x] Implement "New Project" flow (name + description editable)
- [x] Implement "Open Project" flow (tap → SurveyScreen)
- [x] Implement project settings (edit name, description, GPS accuracy threshold)
- [x] Implement archive project (soft delete with restore)

### Validation & Error Handling
- [x] Add input validation to forms (required, constraints, duplicate project names)
- [x] Add error messages for invalid data (snackbars throughout)
- [x] Handle location service errors (permission denied states in GPS/Point/Line/Polygon)
- [x] Handle camera/photo errors (try/catch in PhotoCaptureScreen, gallery)
- [x] Write comprehensive error handling tests (database_integration_test + project_screens_test cover DB edge cases)

### Test Infrastructure
- [x] Set up integration test fixtures (test/helpers/test_utils.dart)
- [x] Create mock location data (testPosition factory)
- [x] Create mock survey schemas (sampleSurveyForm factory)
- [x] Write integration tests for survey flow (database_integration_test.dart: 11 tests)
- [x] Write integration tests for recording flow (track_recorder_test.dart: 14 tests; DB integration + widget tests for project flow)
- [ ] Achieve >80% code coverage (current: 33.1% — deferred; UI screens require plugin/hardware mocking for meaningful coverage)

### Build & Verification
- [x] `flutter test` passes all Phase 2 tests ✅ (103 tests)
- [x] `flutter build apk` successful ✅ (27.1 MB release APK)
- [ ] Manual testing on device
  - [ ] Create project works
  - [ ] Record point with photo works
  - [ ] Record line works
  - [ ] Record polygon works
  - [ ] Fill survey form works
  - [ ] Data saved to database

---

## PHASE 3: GIS MODE BASIC (In Progress)

### MapLibre Integration
- [x] Set up MapLibre Native
  - [x] iOS configuration — Podfile + Info.plist permissions added; not build-verified (no macOS here)
  - [x] Android native setup (vendored fork `third_party/maplibre_gl` + android/ impl)
  - [x] Platform channel bridge (existing maplibre_gl plugin + platform interface 0.25.0)
- [x] Create MapView widget (`MapLibreMap` in gis_map_screen.dart + gis_mode_screen.dart)
- [x] Implement map interactions
  - [x] Pan/zoom
  - [x] Double-tap to zoom (native default)
  - [ ] Long-press for info — not implemented
- [x] Implement location tracking
  - [x] Current location marker (`myLocationEnabled` + normal render mode)
  - [x] Follow-me mode toggle

### Basemap Management
- [x] Create basemap repository (`Basemap.defaults` in map_service.dart)
- [x] Implement OpenStreetMap provider (OSM + OSM-HOT)
- [ ] Implement offline MBTiles support — not started
- [x] Implement raster imagery support (Carto light/dark, Esri satellite)
- [x] Create BasemapSelector widget (dialogs in GIS Mode / GPS screen app bars)
- [x] Add basemap attribution display (raster style `attribution`)
- [ ] Implement basemap persistence — in-session selection only, not persisted
- [ ] Write basemap tests

### Layer Management
- [ ] Create LayerControl widget — not implemented (survey layers auto-rendered)
  - [ ] List layers
  - [ ] Toggle visibility
  - [ ] Change opacity
- [x] Implement feature rendering
  - [x] Point features (Circle annotations, saved survey points, draft points)
  - [x] Line features (Line annotations, draft lines)
  - [x] Polygon features (Fill annotations, draft fills)
- [x] Implement feature styling (per-feature color/stroke/opacity in annotation options)
  - [x] Color
  - [x] Stroke width
  - [x] Opacity
  - [ ] Labels (optional) — not implemented
- [ ] Write layer management tests

### Feature Display & Selection
- [x] Implement feature rendering on map (survey_sessions → circle/line/fill annotations, per-project)
- [x] Implement feature selection (tap via `controller.onFeatureTapped`)
- [x] Create feature info popup (info panel: title + feature type + session id)
  - [ ] Show attributes — partial (title/type only)
  - [ ] Show photos — not yet
  - [ ] Show survey answers — not yet
- [ ] Create feature detail screen — not started (FeatureDetailSheet covers drafting only)
- [x] Implement tap-to-select
- [ ] Write feature selection tests

### GPS Display & Diagnostics
- [x] Create GPS indicator widget (GPS status card in GIS Mode + AppBar status icon)
- [x] Show current location accuracy (±m in GPS card, draft metrics)
- [ ] Show satellite count (visible/used) — deferred (GNSS plugin)
- [ ] Show GNSS provider — deferred
- [ ] Create GPS diagnostics panel — deferred
- [ ] Show signal strength (if available) — deferred
- [ ] Write GPS display tests

### GIS Map Screen
- [x] Create GisModeScreen layout (lib/ui/gis_mode_screen.dart)
  - [x] Map view (main, MapLibreMap)
  - [x] Bottom panels (draft banner + live metrics while drawing)
  - [x] Top toolbar (project bar, GPS status, basemap picker)
  - [x] GPS indicator card
  - [x] Location button (center on GPS) + follow-me toggle
  - [ ] Layer control button — not implemented
  - [ ] Settings button — not implemented (Home → Settings used instead)
- [x] Implement bottom info panel for feature info (+ toggle FAB)
- [ ] Implement layer panel
- [x] Implement drawing toolbar (point/line/polygon buttons + undo/pause/finish, per-record)
- [ ] Create responsive layout — basic Stack positioning, not device-optimized

### Data Export (Basic)
- [ ] Implement GeoJSON export — not yet (DataExportService exports survey/form JSON + CSV; GIS features not exported)
  - [ ] Export all features
  - [ ] Export selected features
  - [ ] Export with attributes
- [x] Implement CSV export (survey answers + GPS logs via share_plus)
- [x] Create export screen/dialog (data_export_screen.dart)
- [ ] Test export files — not covered by dedicated tests
- [ ] Write export tests

### Test Infrastructure
- [ ] Set up MapLibre mock/test harness — not started
- [ ] Create map widget tests
- [ ] Write integration tests for map interactions
- [ ] Create performance benchmarks

### Build & Verification
- [ ] `flutter test` passes all Phase 3 tests ✅ — no Phase 3 tests yet
- [x] `flutter build apk` successful ✅ (Phase 2 release APK 27.1 MB)
- [ ] Manual testing on device
  - [ ] Map loads and pans/zooms
  - [ ] Features display correctly (saved points/lines/polygons render)
  - [ ] Tap feature → info panel (session id/type/title)
  - [ ] Draw + record point/line/polygon → save → re-render
  - [ ] Layer control works
  - [ ] GPS indicator shows data
  - [ ] Export to GeoJSON works

---

## PHASE 4: ADVANCED GIS EDITING

### Feature Editing UI
- [ ] Create FeatureEditScreen
- [ ] Implement feature selection on map
- [ ] Show editing toolbar
  - [ ] Edit attributes
  - [ ] Edit geometry
  - [ ] Delete feature
  - [ ] Undo/Redo

### Point Editing
- [ ] Implement point drag to move
- [ ] Implement point reposition dialog
- [ ] Update feature geometry
- [ ] Show before/after accuracy

### Line Editing
- [ ] Implement vertex visualization
- [ ] Implement drag-to-move vertex
- [ ] Implement long-press-to-delete vertex
- [ ] Implement add-vertex-on-edge
- [ ] Real-time distance calculation
- [ ] Update feature geometry

### Polygon Editing
- [ ] Implement vertex visualization
- [ ] Implement drag-to-move vertex
- [ ] Implement long-press-to-delete vertex
- [ ] Implement add-vertex-on-edge
- [ ] Real-time area/perimeter calculation
- [ ] Update feature geometry
- [ ] Write polygon editing tests

### Attribute Editing
- [ ] Create AttributeEditScreen
- [ ] Implement form for feature attributes
- [ ] Implement photo re-attachment
- [ ] Implement answer editing
- [ ] Update feature attributes in database
- [ ] Track updated_by and updated_at
- [ ] Write attribute editing tests

### Undo/Redo
- [ ] Implement undo stack
- [ ] Implement redo stack
- [ ] Implement undo operation
- [ ] Implement redo operation
- [ ] Show undo/redo buttons
- [ ] Write undo/redo tests

### Feature Deletion
- [ ] Implement soft delete (is_deleted flag)
- [ ] Confirm before delete
- [ ] Remove from map display
- [ ] Write deletion tests

### Test Infrastructure
- [ ] Create geometry editing test fixtures
- [ ] Write unit tests for geometry operations
- [ ] Write widget tests for editing UI
- [ ] Write integration tests for full editing flow

### Build & Verification
- [ ] `flutter test` passes all Phase 4 tests ✅
- [ ] `flutter build apk` successful ✅
- [ ] Manual testing on device
  - [ ] Edit point works
  - [ ] Edit line vertices works
  - [ ] Edit polygon vertices works
  - [ ] Edit attributes works
  - [ ] Undo/redo works

---

## PHASE 5: SYNC & CLOUD

### Sync Provider Interface
- [ ] Define abstract SyncProvider class
  - [ ] authenticate()
  - [ ] upload(project, features, photos)
  - [ ] download(project)
  - [ ] getStatus()
  - [ ] handleConflict()

### Google Drive Sync
- [ ] Implement OAuth2 for Google
- [ ] Create Google Drive file structure
  - [ ] projects/ directory
  - [ ] project.zip structure
  - [ ] versioning
- [ ] Implement upload logic
  - [ ] Batch uploads
  - [ ] Progress tracking
  - [ ] Retry logic
- [ ] Implement download logic
  - [ ] Find remote changes
  - [ ] Download files
  - [ ] Merge with local
- [ ] Implement conflict detection
- [ ] Write Google Drive tests (with mock)

### WebDAV Sync
- [ ] Implement WebDAV client
- [ ] Create WebDAV connection management
- [ ] Implement upload logic
- [ ] Implement download logic
- [ ] Implement conflict detection
- [ ] Write WebDAV tests (with mock)

### Sync Orchestration
- [ ] Create SyncBloc for orchestration
- [ ] Implement sync queue management
  - [ ] Add feature to queue
  - [ ] Remove from queue on success
  - [ ] Keep on queue if failed
- [ ] Implement sync state tracking
- [ ] Implement retry logic (exponential backoff)
- [ ] Implement sync scheduling
  - [ ] Manual sync
  - [ ] Auto-sync on interval
  - [ ] WiFi-only sync option
- [ ] Write sync orchestration tests

### Sync UI
- [ ] Create SyncSettingsScreen
  - [ ] Enable/disable sync
  - [ ] Select provider
  - [ ] Enter credentials
  - [ ] Set sync interval
  - [ ] WiFi-only toggle
- [ ] Create SyncStatusScreen
  - [ ] Show sync state
  - [ ] Show queue size
  - [ ] Show last sync time
  - [ ] Manual sync button
  - [ ] Cancel sync button
- [ ] Add sync indicator to main UI
- [ ] Create sync progress notification

### Conflict Resolution
- [ ] Create ConflictResolutionScreen
  - [ ] Show local version
  - [ ] Show remote version
  - [ ] Diff display
  - [ ] Resolution options (Keep Local, Keep Remote, Merge)
- [ ] Implement conflict resolution logic
- [ ] Update feature with resolution
- [ ] Archive resolved conflicts
- [ ] Write conflict resolution tests

### Credentials & Security
- [ ] Implement Android Keystore for credentials
- [ ] Implement credential storage
  - [ ] OAuth tokens
  - [ ] WebDAV username/password
- [ ] Implement credential retrieval (secure)
- [ ] Implement credential deletion
- [ ] Never log credentials
- [ ] Write security tests

### Offline Handling
- [ ] Detect network connectivity
- [ ] Queue features if offline
- [ ] Show offline indicator
- [ ] Retry when online
- [ ] Notify user on sync completion/failure

### Test Infrastructure
- [ ] Create mock SyncProvider
- [ ] Create test fixtures for sync scenarios
- [ ] Write unit tests for sync logic
- [ ] Write integration tests for full sync flow
- [ ] Create offline scenario tests
- [ ] Create conflict resolution scenario tests

### Build & Verification
- [ ] `flutter test` passes all Phase 5 tests ✅
- [ ] `flutter build apk` successful ✅
- [ ] Manual testing with cloud provider
  - [ ] Authenticate works
  - [ ] Upload works
  - [ ] Download works
  - [ ] Conflict resolution works

---

## PHASE 6: POLISH & DISTRIBUTION

### Internationalization (i18n)
- [ ] Extract all strings to resources
- [ ] Create English translation
- [ ] Create Bangla translation
- [ ] Implement language selection
- [ ] Test RTL support (if needed)
- [ ] Write i18n tests

### Advanced Features
- [ ] GPS diagnostics panel
  - [ ] Raw GNSS measurements (if available)
  - [ ] Signal strength display
  - [ ] Constellation visualization
- [ ] Advanced styling
  - [ ] Color ramp for attribute visualization
  - [ ] Custom marker icons
  - [ ] Feature clustering (if many features)

### Performance Optimization
- [ ] Profile app startup
- [ ] Optimize database queries
- [ ] Implement query pagination
- [ ] Cache frequently accessed data
- [ ] Optimize image handling
- [ ] Write performance benchmarks

### Documentation
- [ ] Write user guide (Survey Mode)
- [ ] Write user guide (GIS Mode)
- [ ] Write administrator guide
- [ ] Write developer guide
- [ ] Create video tutorials (optional)

### Release Build
- [ ] Set up app signing
  - [ ] Create keystore
  - [ ] Configure gradle signing
- [ ] Create release build
  - [ ] Strip debugging symbols
  - [ ] Optimize code
- [ ] Test release build on device
- [ ] Create APK distribution
  - [ ] Host APK for download
  - [ ] Document installation steps
  - [ ] Create ADB installation guide

### QA & Testing
- [ ] Comprehensive manual testing
- [ ] Test on multiple devices
- [ ] Test on different Android versions
- [ ] Test various network conditions
- [ ] Test with large datasets
- [ ] Performance testing
- [ ] Write final test report

### Deployment & Support
- [ ] Create installation guide
- [ ] Create troubleshooting guide
- [ ] Set up support email/contact
- [ ] Create feedback mechanism
- [ ] Plan bug tracking system

### Final Build Verification
- [ ] `flutter test` achieves >90% coverage ✅
- [ ] `flutter build apk --release` successful ✅
- [ ] APK size acceptable (<100MB target) ✅
- [ ] No console warnings/errors ✅
- [ ] Manual full-flow testing passed ✅
- [ ] Performance benchmarks met ✅
- [ ] Documentation complete ✅

---

## Future Enhancements (Post-MVP)

- [ ] iOS support (build, test, distribution)
- [ ] Web version (via Flutter Web)
- [ ] Advanced GIS features (raster processing, remote sensing)
- [ ] More SyncProviders (S3, Nextcloud, MEGA)
- [ ] Raw GNSS measurements & diagnostics
- [ ] Multi-project synchronization
- [ ] Data visualization & analytics
- [ ] Mobile-to-mobile data sync (Bluetooth, NFC)
- [ ] Offline maps with auto-update
- [ ] Custom vector tile support
- [ ] Advanced styling (heatmaps, choropleth)
- [ ] Time-series data visualization
- [ ] Social features (data sharing, collaboration)
- [ ] Offline copy of cloud data
- [ ] Barcode/QR code support

---

## PHASE 4b: FEATURE BATCH (2026-08-18) — Complete, tests green, APK built

- [x] Delete test projects / survey forms
- [x] GIS Mode — interactive feature editing: drag a point to move it on the map, delete features from the info panel
- [x] GIS Mode — single "Center on my location" button (removed duplicate Follow-me button)
- [x] Project editing — add / rename / delete custom data-collection fields (shown in GIS capture sheet)
- [x] Survey Mode — GPS accuracy (±m) shown beside coordinates in GIS capture and geopoint answers
- [x] Settings → About — creator credit (Anisur Rahman Bayazid) + GitHub updates note
- [x] Home screen — big, bold "MapBanai" title in muted navy
- [x] History — saved answers viewable with edit option, grouped by project then date
- [x] Export — survey responses as CSV, per-project selection for survey responses and GIS data (GeoJSON)
- [x] Survey Mode — no delete button on entry; 3-dot menu inside survey (rename project / share project / delete project)
- [x] Database — ProjectFields table (schema v5→v6), session update/delete, project delete cascade
- [x] `flutter test` — 106/106 pass (1 existing test updated to scroll to Archive tile)
- [x] `flutter analyze` — 0 errors/warnings (38 info lints, below pre-batch baseline of 39)
- [x] `flutter build apk --release` — succeeded

---

## PHASE 4c: PROJECT ISOLATION + EXPORT FILES (2026-08-18) — Complete, tests green

- [x] Home screen — removed duplicate small "MapBanai" AppBar title
- [x] Home screen — "Current project" is now a selectable dropdown of existing projects (ProjectState updates on pick)
- [x] Home screen — "Collected data" block moved below the mode cards, above Open/History/Export; shows the selected project's counts with separate Survey Responses and GIS Features tiles
- [x] Survey Mode — removed hardcoded "Riverbank Inspection" / "Infrastructure Assessment" forms
- [x] Survey Mode — empty state shows a "+" card "Start building survey form" that opens the form builder
- [x] Survey Mode — forms listed per project (created/imported forms belong to the selected project)
- [x] Project independence — StoredForms now has projectId (schema v6→v7); new projects start empty; deleting a form only affects its own project; project delete cascades its forms; legacy forms migrated onto the active project
- [x] GIS Mode — placeholder marker (blue circle at current GPS fix) shown immediately when starting a line/polygon draft; follows the GPS fix until recording starts; point draft marker made more visible
- [x] Survey history — GIS features are now editable (ID/name/notes/custom fields via the detail sheet, persisted to the session)
- [x] Export — survey responses export a real CSV file (UTF-8 BOM, Kobo/ODK-style columns) via the share sheet
- [x] Export — GIS data button prompts for format: CSV (WKT geometry), KML, GeoJSON, GeoPackage (minimal valid SQLite/GPKG with WKB blobs via sqlite3)
- [x] `flutter analyze` — 0 errors/warnings (38 info, below prior baseline)
- [x] `flutter test` — 106/106 pass
- [x] `flutter build apk --release` — succeeded

---

## PHASE 4d: GPKG FIX + FIELD-USE BATCH (2026-08-19) — Complete, tests green, APK built

- [x] GeoPackage export — hardened SQL (no escaped literals, no function DEFAULTs; values bound as parameters, explicit `last_change` and computed min/max bounds), geometry flags fixed to 0x08 (little endian, non-empty), WKB layout fixed (Point/LineString/Polygon headers now match the spec; previously wrote an oversized buffer that threw RangeError)
- [x] New regression test `test/gis_export_service_test.dart` — writes a GPKG, reopens it with sqlite3, verifies integrity check, gpkg_spatial_ref_sys / gpkg_contents / gpkg_geometry_columns rows, feature blobs and empty-export case
- [x] GIS Mode — draft point, draft start marker and saved survey points are now draggable (fork platform interface requires `draggable: true` on the feature; missing property = not draggable). Dragging the draft point updates the fix used by Finish; dragging the line/polygon start marker pins the drop position (auto-follow GPS stops) and seeds the first recorded vertex there
- [x] GIS Mode — default map center changed to Dhaka city (23.8103, 90.4125); draft banners now instruct how to place the marker
- [x] GPS Mode — roadout shows UTC time (from GPS timestamp) and Dhaka time (GMT+6)
- [x] GPS Mode — "Save waypoint" renamed "Save Point"; "+ New log" renamed "Record Track" (dialogs, snackbars and help text updated)
- [x] Project settings — new "Survey forms" section: list per-project forms, open form details, edit, delete, add form, and import XLSForm (.xlsx) (re-import updates an existing form and bumps its version)
- [x] `flutter analyze` — 0 errors/warnings (38 info, prior baseline)
- [x] `flutter test` — 108/108 pass
- [x] `flutter build apk --release` — succeeded (107.8 MB)

---

## PHASE 4e: V2.3.0 RELEASE BATCH (2026-08-22) — Complete, tests green

- [x] Study Area Mode (new Home card) — import sites from CSV / GeoJSON / KML / GeoPackage (.gpkg) / Excel (.xlsx), colored map circles (red pending / green completed), tap-to-navigate with live GPS distance + cardinal bearing, status toggle, CSV/Excel export; sites persisted to `documents/study_area/study_area_sites.json` (`StudyAreaService`, `StudyAreaStore`, `StudyAreaModeScreen`)
- [x] GPS CSV viewer — GPS Mode logs open in `GpsCsvDetailScreen`; readings rendered on an interactive map; any log can be projected onto the generated HTML WebMap (`GpsCsvService`)
- [x] Bangla localization — `l10n.yaml` + en/bn ARBs (`lib/l10n/`), generated `AppLocalizations`, wired through MaterialApp; Home/Settings/sync/mode cards translate live
- [x] Theme setting — System/Light/Dark in Settings, applied instantly via new `AppSettingsProvider` (`theme_mode` key in app_settings)
- [x] ODK multi-language XLSForm — `label::English (en)` / `label::Bangla (bn)` / hint/constraint translations parsed into per-question maps; renderer switches label language at runtime
- [x] QR import from gallery — "Scan QR from gallery" decodes a saved image (`QrScanner.scanFromGallery`)
- [x] WebMap — collapsible filter panel (search/form/surveyor/date + result count); GIS Name & Notes fields now included in webmap data
- [x] Area units — km² unit added; ≥1 km² auto-formats in compact display
- [x] Basemaps — removed OSM Humanitarian (unreliable tile host)
- [x] Version 2.3.0+16 (pubspec.yaml + AppInfo)
- [x] `flutter analyze` — no errors/warnings (pre-existing info lints only)
- [x] `flutter test` — 222/222 pass (incl. new study_area_service_test.dart + gps_csv_service_test.dart)
- [x] `flutter build apk --release` — succeeded
- [x] Documentation updated: CHANGELOG.md, README.md, TODO.md

---

## Notes

- Use this TODO as a rolling list; update frequently
- Mark completed items with ✅ as work progresses
- Move blocked items to backlog with reason
- Review TODO weekly during standup
- Document decisions that affect todo items
