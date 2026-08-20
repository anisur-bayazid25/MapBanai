# AI_CHANGELOG

In-depth, developer-oriented changelog written so future AI models (and
maintainers) can reconstruct the project's evolution, architecture and
operating quirks from file history alone. Read `UPDATE_FEATURE_LOG.md` for
the operational log (commands + results) and `PROJECT_SHARING_ANALYSIS.md`
for the pre-sharing-subsystem analysis.

---

## Repository & release architecture (stable facts)

- Repo: https://github.com/anisur-bayazid25/MapBanai — `main` + version tags
  `v*.*.*`. Releases are built **on GitHub Actions** (`.github/workflows/
  release.yml`): tag push → checkout + subosito/flutter-action (3.24.3) →
  `flutter build apk --release` → softprops/action-gh-release attaches
  `app-release.apk`.
- Version bump system (v2.1.1+): `dart run tool/bump_version.dart
  [patch|minor|major] [--dry-run]` edits `pubspec.yaml` `version:` AND
  `lib/models/app_info.dart` `static const String version`. A manual
  `workflow_dispatch` (`bump-version.yml`) exists for GitHub-side bumps.
  Human flow: bump → commit → `git tag vX.Y.Z` → push main + tag → CI
  builds → Release verified via `GET /repos/.../releases/tags/vX.Y.Z`.
- **Windows-specific environment trap**: Developer Mode is OFF → both
  `flutter pub get` and `flutter pub add` fail at the plugin symlink step
  ("Building with plugins requires symlink support"). Workaround: use
  `dart pub add` (or edit pubspec) + `dart pub get`, then hand-sync
  `.flutter-plugins` and `.flutter-plugins-dependencies` (and macOS
  `macos/Flutter/GeneratedPluginRegistrant.swift`) to match pubspec.lock.
  Android builds/analyze/test do NOT need symlinks (tool skips the step
  when the plugin JSON is unchanged).
- `package_info_plus` is pinned to **8.0.2**: 9.x requires AGP 8.12/Gradle
  8.13+, project uses AGP 8.1 / Gradle 8.3 (committed gradle files are
  used by CI too). `geolocator` pinned 12.0.0 with `geolocator_android`
  override 4.5.5; `maplibre_gl` is a **local path override** to
  `third_party/maplibre_gl`.
- Android: minSdk **23**, targetSdk = Flutter default (e.g. 34/35),
  compileSdk 36, Kotlin with jvmTarget 1.8; `androidx.core` forced to
  1.12.0 in Gradle. namespace `com.mapbanai.mapbanai`.
- DB: Drift (`pubspec: drift ^2.20.3`, `sqlite3_flutter_libs`,
  `NativeDatabase` in background isolate) — file `mapbanai.db` in
  `getApplicationDocumentsDirectory()`. Codegen: `app_database.g.dart`
  regenerated via `dart run build_runner build --delete-conflicting-outputs`.
- Update checker: GET `https://api.github.com/repos/anisur-bayazid25/
  MapBanai/releases/latest`, strips leading `v`, int[] semver compare
  (UpdateChecker.compareVersions), downloads `.apk` asset via stream into
  external/temp storage (`update_downloader.dart`), opens via
  `OpenFile.open`; needs `REQUEST_INSTALL_PACKAGES`. Home screen silently
  checks on init; Settings has manual "Check for updates".
- **Logging convention**: every delivered phase is appended to
  `UPDATE_FEATURE_LOG.md` in table form with exact commands + results;
  version bumps and pipeline proofs are recorded there.

---

## [2.1.2] — background GPS continuity + drafts

### Background GPS recorder (screen-off + Back-button continuity)

- **`lib/services/background_gps_recorder.dart`** — app-wide singleton
  `BackgroundGps.instance` (extends `ChangeNotifier`). While a GPS track is
  recording it owns the live geolocator stream; the GPS screen merely
  previews fixes. Uses geolocator 12 `AndroidSettings.foregroundNotificationConfig`
  (channel `MapBanai GPS recording`, `enableWakeLock`, `setOngoing`) →
  recording survives leaving GPS Mode (Back = default pop; **no PopScope**)
  and screen-off (process stays foreground, stream keeps delivering).
  `GpsLogStore.appendReading` still writes `<log>.csv`; appends throttled to
  1/s. `setPaused` skips appends but keeps stream + notification alive.
  `stop()` cancels sub + releases the fg service.
- **Manifest** (`android/app/src/main/AndroidManifest.xml`): added
  `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK`. No
  `ACCESS_BACKGROUND_LOCATION` required (fg-service + while-in-use suffices).
  Foreground service type `location` comes from the planted plugin
  `geolocator_android` `.GeolocatorLocationService` declaration.
- **Home**: `_buildGpsRecordingBanner` — persistent red banner while
  `bg.isRecording`, with Open GPS Mode + Stop; `initState`/`dispose` attach/
  detach the listener.
- **GpsModeScreen** rework: recording delegated to BackgroundGps; local
  stream is read-only (never appends). `_startListening` mirrors bg state
  when a recording is already active; one live stream at a time (Start
  cancels the preview sub, Stop reopens it). `_createLog`/`_toggleRecording`
  call `BackgroundGps.start/stop`; `_deleteLog` stops bg first if deleting
  the active log; pause button routes to `setPaused` while recording.

### GIS screen-off continuity

- `_startLocationStream({bool? foreground})` re-opens the stream with the fg
  notification ONLY while `_recorder.running` (Begin Recording → fg;
  `_cancelDraft`/Finish → downgraded back to plain). Back in GIS still stops
  logging (documented product decision). Discovery: `ForegroundNotificationConfig`
  is exported by `package:geolocator/geolocator.dart` (re-exported from
  geolocator_android); `AndroidSettings` is NOT const → drop `const` around
  it (analyzer const_with_non_const).

### Drafts (no migration, no codegen — reuse `status='draft'` column)

- Survey: `SurveyFormRenderer` gains `onSaveDraft` + "Save as draft" button
  (skips required/constraint validation); `SurveyFormDetailScreen._saveDraftResponse`
  inserts a `status:'draft'` row `{form_id, form_name, user_name, answers}`.
- GIS: `_saveDraft` stashes `{draft:true, feature_type, recorder:
  TrackRecorder.serialize()}` (line/polygon) or the point fix `{latitude,
  longitude, accuracy_m}` into a draft row; button in the draft banner
  (`_canSaveDraft` gates it). `TrackRecorder.serialize()/restore()` round-trip
  vertices + timing (`running`, `paused`, `started_at`, `last_resume_at`,
  `paused_total_ms`, `last_vertex_time`). NOTE: filter config is NOT
  serialized — a restored recorder inherits the constructing screen's
  `minDistanceM/minIntervalS/maxAccuracyM`.
- Resume (GIS): `GisModeScreen(projectName, resumeDraftId:)` restores the
  recorder/fix, re-adds draft annotations on `_onStyleLoaded` (+ a point
  marker), and `_saveFeature` **updates the same row** on Finish
  (`updateSurveySession(..., status:'saved')`) instead of inserting.
  `_addSurveyAnnotations` skips `status == 'draft'`.
- Resume (survey): History pushes a renderer prefilled with the draft
  `answers` (form re-located by `form_id`/`form_name` within the project's
  stored forms); "Save responses" promotes the row to saved, "Save as draft"
  updates it.
- History: `getDraftSurveySessions()` (new DB query); Drafts section at top
  with Resume/Delete (+ confirm dialog); saved grouping excludes drafts.
  Counters exclude drafts: `responseCountsForProject`,
  `surveySessionCountForProject` (project detail "responses" count), and GIS
  annotations.

### Tests (178 total, all green; analyze 0 errors)

- `test/track_recorder_test.dart` + round-trip serialize/restore (running +
  paused variants). Gotcha that bit the first attempt: restored recorder had
  DEFAULT `minIntervalS:2` so an immediate `add()` was rejected — construct
  restored recorder with matching thresholds.
- `test/background_gps_recorder_test.dart`: start/stop state, CSV streaming,
  pause-skips-appends-but-stream-alive, listener notifications. Reads counts
  via `GpsLogStore.defaultLogsDir()` (the recorder writes under
  documents/gps_logs).
- `test/drafts_history_test.dart`: count exclusion (draft survey/gis never
  counted, promoted on `status:'saved'`), form-detail "Save as draft" →
  resumable row, history lists drafts + group separation + delete + survey
  draft resume → promoted to saved. GIS-draft delete located via the card's
  title text (draft order not guaranteed — same-ms `currentDateAndTime`).
- `test/database_integration_test.dart`: `surveySessionCountForProject(b.id)`
  expectation changed 1 → 0 because a seeded `status:'draft'` row now
  correctly does not count as collected.

---

## [2.1.1] — project sharing subsystem

Intended to deliver (in progress per this session): the **project
export/import/sharing subsystem** + the docs already written
(`PROJECT_SHARING_ANALYSIS.md`, `README.md`, `CHANGELOG.md`, this file).

### Architecture introduced

- **`.mbproj` package**: ZIP container (`package:archive` — already a dep),
  package format version 1. Structure:
  ```
  manifest.json     # package_type=mapbanai_project, package_version,
                    # app_version, project_id(external), project_version,
                    # project_name, exported_at, contents[], checksums{path:sha256}
  project.json      # metadata: external_id, name, description, gps_threshold_m,
                    # created_at, updated_at, project_version, gps settings
  form/<uuid>.json  # one file per stored form (full SurveyForm.toJson)
  layers.json       # basemap/style configuration snapshot
  settings.json     # project-level settings (gps threshold etc.)
  assets/           # reserved; empty in v1
  metadata/version.json  # package schema + mapbanai schema versions
  ```
  RESPONSES / tracks / photos / app_settings are NEVER included.
- **Identity**: `projects.external_id` TEXT (uuid) column added
  (schema v7 → v8, `migrator.addColumn`); local `id` int stays. uuid from
  `package:uuid` (already a dep).
- **Export path**: Home → Open project → project ⋮ menu → Export Project:
  - SAVE PROJECT FILE → `file_picker` `saveFile` (SAF, no storage permission)
  - SHARE PROJECT → `ProjectTransferProvider` abstraction;
    `NativeShareProvider` impl uses `share_plus` `Share.shareXFiles`
    (ACTION_SEND with content URI).
- **Import path**: Home menu → Import Project (`file_picker` custom ext
  `mbproj`); Android "Open with MapBanai" via manifest `<intent-filter>`
  MIME `application/vnd.mapbanai.project` + pathPattern `*.mbproj`, and
  `mapbanai://project/import?...` scheme handled in `MainActivity.kt`
  (MethodChannel `mapbanai/intents` → Dart).
- **Import pipeline** (do NOT extract blindly): open ZIP → validate
  manifest JSON → package version ≤ supported → required files present →
  verify SHA-256 → reject `../`, absolute paths, symlinked entries →
  extract into temp dir under documents → duplicate check (external_id or
  trimmed name) → on conflict show dialog (Import as new copy / Replace /
  Cancel; Replace deletes existing project row + children first, New copy
  = fresh local external_id but keeps original metadata) → DB writes in a
  transaction → cleanup temp on success and failure. Imported project
  `is_active = false`.
- **QR** (v1 payloads): `MAPBANAI-PROJECT-V1:` + base64url(zlib(json)).
  json variants: `{#v1 small-project payload}` inline full project
  (metadata+forms+layers) when ≤ size budget else bootstrap-only
  (id/name/version/checksum/transfer_mode). UI shows "Project is too large
  for direct QR transfer" when payload would exceed QR capacity.
  Parsing/validation is string-level; camera scan intentionally deferred.
- **Future-proofing**: `ProjectTransferProvider` interface allows
  `LocalNetworkProvider`/`BluetoothProvider`/`NearbyProvider` without
  touching package/import/export code. HTTPS `.mbproj` URLs accepted by
  the link parser for a future server (none built now).

### Key files

```
lib/services/project_package.dart      # manifest + format constants + checksums
lib/services/project_exporter.dart     # build .mbproj bytes/stream from DB
lib/services/project_importer.dart     # validate + extract + DB import (atomic)
lib/services/project_transfer_provider.dart  # abstraction + NativeShareProvider
lib/services/project_qr.dart           # MAPBANAI-PROJECT-V1 payloads + validation
lib/ui/import_project_flow.dart        # dialogs: exists → new copy/replace/cancel
lib/ui/project_qr_screen.dart          # QR display screen
lib/ui/home_screen.dart                # Import Project entry (modified)
lib/ui/project_detail_screen.dart      # ⋮ menu: Export/Share/QR (modified)
lib/data/app_database.dart             # external_id + v8 migration (modified)
android/app/src/main/AndroidManifest.xml    # intent filters (modified)
android/.../MainActivity.kt                 # intent/channel bridge (modified)
test/project_share_test.dart           # round-trip + rejection matrix
README.md  CHANGELOG.md  AI_CHANGELOG.md  PROJECT_SHARING_ANALYSIS.md
```

### Test matrix (test/project_share_test.dart)

round trip w/ richest project (forms incl. select_one w/ choices,
relevance, constraint, calculation, photo + geopoint types, project fields,
gps threshold) → export → import into clean DB → equivalence asserted;
responses excluded; corrupted zip; bad manifest; unsupported package
version; zip path traversal (`../evil`); duplicate name/external id;
filename sanitization; version preservation; QR encode/decode round trip +
oversize rejection + prefix/checksum validation failures.

---

## [2.1.1] — logo, bump system, GPS save-point CSV, reset safeguard, About links

Commit `bc3b4d2` (`pubspec` bump commit `1cfd799`, tag `v2.1.1`).

- **Logo**: converted from `logo_start.pptx` art (POWERPOINT SOURCE FILE —
  `logo_start.pptx` is tracked; `assets/logo/MapBanai_logo.png` 2935×1077 +
  `MapBanai_logo.svg`) → Android launcher icons regenerated at
  `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/
  ic_launcher.png`. Shown in Home header (160 px) and Settings About card
  (200 px). pubspec `assets: - assets/logo/`.
- **bump system**: `tool/bump_version.dart` + `.github/workflows/
  bump-version.yml` (workflow_dispatch input `bump: patch|minor|major`,
  runs script + pushes tag — forces tag push so it works under branch
  protection). Dry-run flag supported.
- **GPS Save Point CSV**: `gps_mode_screen.dart` `_createPointLog` appends
  GPS points to `<project>_points.csv` in the same external `Export`
  folder as waypoints; shared CSV-escaping helper `_writeAppendCsv`
  (quotes/commas/newlines escaped).
- **Reset safeguard**: `settings_screen.dart` `_resetData` now requires
  second dialog `showTypeToConfirmDialog` (in `lib/ui/common/
  confirm_dialog.dart`) — user must type the exact owner name.
- **About links**: `url_launcher ^6.3.1` added (hand-synced plugin files);
  GitHub repo ListTile → https://github.com/anisur-bayazid25/MapBanai,
  email ListTile → mailto:comlesconstructionus@gmail.com;
  `_launchUrl` try/catch → SnackBar fallback.
- **Gotcha recorded**: `const EdgeInsets.zero` is ILLEGAL (static getter,
  not a constructor) — the first bulk-edit attempt tripped this.
- Home screen widget test previously asserted `find.text('MapBanai')`;
  replaced by logo-Image predicate + tagline assertion.

## [2.1.0] — update checker + release pipeline

Commit `6dad626`, tag `v2.1.0`. Details in UPDATE_FEATURE_LOG.md Part C/D:

- `.github/workflows/release.yml` (B-series); package_info_plus 8.0.2 pin
  (C4 — AGP conflict); `lib/services/update_checker.dart`,
  `update_downloader.dart`, `lib/ui/common/update_dialog.dart`;
  `REQUEST_INSTALL_PACKAGES` + FileProvider `${applicationId}.fileprovider`
  (`res/xml/file_paths.xml` exists with external-path + cache-path).
- Settings gains "Check for updates — vX installed"; Home does silent
  background check with snackbar "View".
- UpdateChecker.compareVersions is the canonical semver int[] comparator
  (exported + unit-tested).

## [1.0.0] — initial (commit `5bc3b65`)

Single-commit import of the working app (AGP 8.1/Gradle 8.3, Flutter 3.24.3,
minSdk 23). Architecture pre-sharing subsystem is fully documented in
PROJECT_SHARING_ANALYSIS.md (Drift schema v1..v7, models, GIS runtime
styles, Sync/Save flows, XLSForm parser in `lib/services/xlsform_parser.dart`
+ `xlsx_reader.dart`, photo pipeline with EXIF, GPS track recorder in
`lib/services/track_recorder.dart`, GNSS satellite stats via MethodChannel
`mapbanai/gnss` in MainActivity.kt, drift tables: projects, survey_sessions
(responses JSON column — GIS features are sessions whose responses JSON
contains `feature_type`), stored_forms (form JSON column), app_settings,
gps_logs, project_fields).

### Migration history (Drift schemaVersion)

1 → 2: survey_sessions.responses; 3: stored_forms table; 4: app_settings +
gps_logs (dropped field_tasks); 5: projects description/archived/
gpsThresholdM; 6: project_fields; 7: stored_forms.projectId + legacy form
attach; 8 (this session): projects.external_id.