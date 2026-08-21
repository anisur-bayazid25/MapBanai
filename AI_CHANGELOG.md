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

## [2.2.0] — cloud sync (Apps Script sheet backend, per-project, data + per-photo retry, Home sync card)

### Sync tracking schema (Task 1, no UI/networking)
- **`lib/data/app_database.dart`**: `SurveySessions.syncedAt` + `photoSyncedAt` (`dateTime().nullable()`), new table `SyncConfigs` (`projectId` PK `REFERENCES projects(id) ON DELETE CASCADE`, `syncEndpointUrl` nullable TEXT, `syncApiKey` nullable TEXT, `lastSyncAt` nullable DateTime) — per-project `sync_config` row. Added to `@DriftDatabase(tables:[...,SyncConfigs])`, `schemaVersion 8→9`, `if (from<9){addColumn(syncedAt); addColumn(photoSyncedAt); createTable(syncConfigs);}` mirroring v7→v8 `external_id` pattern. Also added `AppDatabase.testWithExecutor(QueryExecutor)` test helper, `deleteProject`/`resetAllData` now clean `syncConfigs`, helper methods `getSyncConfig`/`upsertSyncConfig`/`deleteSyncConfig` (trim→null, `DoUpdate` on PK). Codegen `dart run build_runner build --delete-conflicting-outputs` (32 s, 198 outputs).
- **`test/sync_schema_migration_test.dart`**: `PRAGMA table_info` checks for nullable columns, fresh insert defaults null then update round-trip, `sync_configs` CRUD + `ON DELETE CASCADE` DDL check, and a v8→v9 upgrade simulation (raw `sqlite3` create old `projects`/`survey_sessions` without new cols, `user_version=8`, insert legacy row, open with `NativeDatabase(file)` via `testWithExecutor`, assert migrated row `syncedAt`/`photoSyncedAt` null, cols exist, `sync_configs` created, new row with `syncedAt` works).

### Project settings UI (Task 2)
- **`lib/data/app_database.dart`**: added `getSyncConfig`/`upsertSyncConfig` (shared-secret, no encryption, empty→null) helpers used by UI.
- **`lib/ui/project_detail_screen.dart`**: new **Cloud Sync** section (≈ after Survey forms) — `Apps Script Web App URL` (`TextInputType.url`, cloud icon) + `API key` (obscured `•`, visibility toggle, `vpn_key` icon) backed by `_syncUrlController`/`_syncApiKeyController`, `lastSyncAt` line, **Save** (`FilledButton`, `upsertSyncConfig` preserving `lastSyncAt`) → green *Sync settings saved* SnackBar, **Test Connection** (`OutlinedButton`, `wifi_tethering`) does `http.get(uri).timeout(10s)`, validates `http/https` scheme, checks `200-299` + JSON `decoded['ok']==true` specifically (not just 200, to catch wrong URL with HTML), green *Connection successful* vs red *missing {ok:true}*, *not valid JSON*, *HTTP xxx*, *Invalid URL*; empty → *Please enter a sync URL first*. All handled without crash. Loaded in `_load()` via `getSyncConfig`, disposed in `dispose()`. Fixed existing `project_screens_test` scroll ambiguity (now `scrollable: Find by vertical Scrollable`).

### Data sync (Task 3, no photos)
- **`lib/services/cloud_sync_service.dart`**: `CloudSyncService(db, {client})` — `queryUnsyncedResponses`/`queryUnsyncedFeatures` filter `syncedAt.isNull()` + `status!='draft'` + `responses.contains('feature_type')` split (same `%feature_type%` distinction as `responseCountsForProject`). Payload: `{"apiKey","action":"sync_data","responses":[{"response_id"=id, "project_name", "surveyor"=responses.user_name, "submitted_at"=createdAt, "form_name", "answers"}]`, `"features":[{"feature_id"=id, "project_name","surveyor","geometry_type"=feature_type, "latitude/longitude/geojson" (Point → [lon,lat], LineString → coords, Polygon → closed ring), "photo_path"}]}` (reuse `session.id` stable id, no new column). POST JSON 30 s timeout, single attempt, no retry — on network/`{ok:false}`/bad status surfaces `error` field else generic, **only** on `{ok:true}` marks specific rows `syncedAt=now()` + `syncConfigs.lastSyncAt` in a transaction.
- **`test/cloud_sync_service_test.dart`**: local `HttpServer` mock (like `update_downloader_test`) — successful sync marks rows + `lastSyncAt` + payload shape checks; failed `ok:false` leaves unsynced; `Invalid API key` error surfaced; 500 non-JSON and missing `error` generic handling; uses `expectLater` for async throws.

### Photo sync (Task 4, per-photo retry, mirrors update_downloader philosophy)
- **`lib/services/photo_sync_service.dart`**: `PhotoSyncService(db, {client,delay,maxPhotoBytes=15MB})` — `queryUnsyncedPhotos` where `photoSyncedAt.isNull()` + `responses` contains `photo`, helper `_extractPhotoPath` handles `photo.path`/`photo` string/`photo_path`. For each: `File.existsSync` check, `lengthSync()>maxPhotoBytes` → `skippedOversized` **without network**, base64 encode, POST individually `{"apiKey","action":"upload_photo","filename","mimeType","base64"}` (mime via extension), retry **up to 3** with backoffs `2s,5s` (`_delay` injectable for tests), only on `{ok:true}` mark that row `photoSyncedAt=now()`, continue after 3 fails (one bad photo never blocks batch).
- **`lib/services/sync_orchestrator.dart`**: `SyncOrchestrator(db,{client,delay,maxPhotoBytes})` + `FullSyncResult{data:SyncResult, photos:PhotoSyncResult, dataError}` with `summary` = *“X responses, Y features, A/B photos synced”*; `syncAll` runs data → photos sequentially.
- **`test/photo_sync_service_test.dart`**: mock server counts — fails first 2 then succeeds (retry works, 3 attempts), one always-fails photo skipped without blocking next (4 total requests, 1 synced/1 failed), oversized (threshold 100 B injected, 200 B file → 0 requests, `skippedOversized=1`), query filter check.

### Home Sync button + status (Task 5)
- **`lib/ui/home_screen.dart`**: new import `cloud_sync_service`/`photo_sync_service`/`sync_orchestrator`/`project_detail_screen`. Added `_handleSync` (selected project → `getSyncConfig` → if no URL → SnackBar *Set up cloud sync…* + push `ProjectDetailScreen` else show `_SyncProgressDialog`), `_isOfflineError` (socket/lookup/unreachable/network/timed out), `_formatLastSynced` (`YYYY-MM-DD HH:MM` or *Never synced*), `_buildSyncCard` (FutureBuilder<SyncConfig?> keyed by `_refreshTick`, two variants: `Set up cloud sync` grey vs `Sync` purple `cloud_sync` card, both showing `Last synced` and routing/tapping to sync, placed after GPS Mode before Collected Data). After sync dialog, `SnackBar` shows *No internet connection* for offline else `result.summary`, and `setState(_refreshTick++)` refreshes last-synced.
- **`_SyncProgressDialog` (Stateful)**: `Syncing data…` spinner → `CloudSyncService.syncProject` (catch → offline mapping) → `Syncing photos (3/9)…` live via `PhotoSyncService.syncPhotos(onProgress:(cur,total)=>setState)` → `Sync complete` with green check + `summary` + `photos.summary` or red error icon. Barrier dismissible false, Close returns `FullSyncResult`.
- **`lib/services/photo_sync_service.dart`**: added `onProgress` callback to `syncPhotos` (called after each photo with `synced+failed+skipped`/`total`, including early oversize/missing branches via loop index).
- **`lib/services/cloud_sync_service.dart`**: fixed wildcard `catch (_)` → `catch (e) if (e is CloudSyncException) rethrow` lint.
- Existing `project_screens_test` already patched for vertical scrollable.

### Version/test state (pre-bump)
- `2.1.4+5` baseline, drift 9, 202/202 green (4 migration + 6 cloud data + 4 photo), analyze 0 errors (74 infos, pre-existing baseline).

---

## [2.2.1] — persistent signing (no more package conflicts)

- **Problem:** Every CI build used a throwaway debug keystore, so each release had a different cert → `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, users had to uninstall (losing data).
- **Fix:** Generated **one** persistent `android/mapbanai-release.jks` (RSA 2048, 10k days, alias `mapbanai`, SHA1 `A1:E3:3B:AF…`) **once**; `android/key.properties` (gitignored) now points to it; `android/app/build.gradle` reads `key.properties` (`rootProject.file('key.properties')`) for `signingConfigs.release` and `buildTypes.release.signingConfig = signingConfigs.release` (with `debug` fallback when file absent for dev machines). `android/.gitignore` and root `.gitignore` now ignore `key.properties`/`*.jks`. Local `flutter build apk --release` now signs with the persistent cert (verified `keytool -printcert` matches keystore, 111.1 MB, two consecutive builds same SHA1).
- **CI:** `release.yml` now decodes `MAPBANAI_KEYSTORE_BASE64` (fallback `KEYSTORE_BASE64`) → `android/mapbanai-release.jks` + writes `android/key.properties` from `KEYSTORE_PASSWORD`/`KEY_PASSWORD`/`KEY_ALIAS` before `flutter build`; fails fast with `test -s` check and `wc -c` log if secret missing. Added `RELEASE_SIGNING.md` with exact `gh secret set` commands and manual steps.

---

## [2.2.2] — restore diagnostics + POST 302 preservation (pre-fix)

- **Restore:** Added `RESTORE_BUG_LOG.md` (full path analysis: `BackupService._backupRoot` → `/storage/emulated/0/Documents/MapBanai/backups` vs fallback `app_flutter/mapbanai_backups`; on Android 11+ public path fails due to scoped storage without `MANAGE_ALL_FILES`/`MediaStore`, so backups land in **app-private** and are **wiped on uninstall** — documented as design, not patchable locally; sync backend is the durable store). `home_screen.dart` now `debugPrint`s searched `_backupRoot`/`newest`/`liveExists` and surfaces `SnackBar('Restore failed: $e')` instead of silent `catch (_)`.
- **Sync 302:** `cloud_sync_service`/`photo_sync_service` `_postJsonWithRedirect` used `http.Request(followRedirects:false)` and re-issued POST (preserved body) — **wrong** for Apps Script (googleusercontent only accepts GET after the initial POST executes). Added unit tests asserting `firstBody == secondBody` with POST.

---

## [2.2.3] — fix 405: follow Apps Script 302 with GET + signing secret fallback

- **Root cause:** Apps Script flow is `POST script.google.com/.../exec` (executes `doPost`, caches response) → `302 Location: script.googleusercontent.com/...` (content hop, **only GET**). Re-POSTing there → `405 Method Not Allowed`. Both plain `http.post()` (dart:io re-POSTs) and the previous "preserve method" fix did that.
- **Fix:** `_postJsonWithRedirect` now `var method='POST', payload=body` then on 301-308 → resolve `Location`, allow-list host (`.google.com`/`.googleusercontent.com`/loopback), then **`method='GET', payload=null`** for the follow-up. Removed `text/plain` retry. `cloud_sync`/`photo_sync` keep 5-hop cap and `isRedirect` check.
- **Tests:** Updated `cloud_sync_service_test` + `photo_sync_service_test` to assert `firstMethod=='POST'` with full JSON body, `followMethod=='GET'`, and row marked synced.
- **CI:** `release.yml` now warns and falls back to debug signing when no keystore secret is set (`rm -f` + `WARNING…` instead of `exit 1`), so releases still land (with debug cert) until secrets are set; `build.gradle` mirrors with `signingConfig = keystorePropertiesFile.exists() ? release : debug`.
- **Docs:** `RELEASE_SIGNING.md` already documents `MAPBANAI_KEYSTORE_BASE64` etc.

---

## [2.2.4] — stable UUID for sync + survey photo sync

- **Stable IDs (Task 1 of fix set):** Added `SurveySessions.externalId` (`text().nullable()`, Drift 9→10, migration `if (from<10){addColumn; backfill missing with `Uuid().v4()`}`), `insertSurveySession` now auto-generates `externalId` if `Value.absent()`, `cloud_sync_service` `_buildResponsesPayload`/`_buildFeaturesPayload` now use `s.externalId ?? s.id.toString()` (`stableId`), `photo_sync` unchanged (filename). Migration test extended to handle v10, stable-UUID test: insert via helper → sync → reset `syncedAt` → re-sync → same `response_id` both times, server dedup `responses:0`.
- **Survey photo sync:** `PhotoSyncService._extractAllPhotoPaths` now also scans `responses['answers']` map: for each value, if `String` try `jsonDecode` to `Map` with `path` (PhotoQuestion stores JSON string like `{"path":".../photos/...jpg"}`) or direct `path` string, or `Map` with `path`, and only queues if `contains('photos')` or `.jpg/.png`. `queryUnsyncedPhotos` uses this, `syncPhotos` expands per-photo (not per-session) with `allPhotoPaths`/`sessionForPath`, total is sum of paths, per-photo retry, `photo_synced_at` only when all photos for that session succeed (skipped oversize not counted as success, so remains `null` and matches existing oversize test).
- **Tests:** `cloud_sync_service_test` stable-UUID case + `photo_sync_service_test` embedded survey photo case (`site_photo` JSON string → queued, `filename` `embedded.jpg`, `synced`).
- **Build:** `dart run build_runner` 1237 outputs, `flutter test` 206/206 → 208/208 with new tests.

---

## [2.2.5] — CI timeout for pub get

- **Diagnosis:** `git diff be8903f..HEAD -- pubspec.yaml` showed only `version` bump (no new `git:`/`path:` deps; only `maplibre_gl: path: third_party/maplibre_gl` vendored). `flutter pub get -v` locally resolved in **4.15 s** (no `version solving failed`), so not a resolver conflict.
- **Conclusion:** Transient `pub.dev`/GitHub outage, not a code pin. Fix is to fail fast.
- **Fix:** `release.yml` `jobs.build-release.timeout-minutes: 15` + `Install dependencies` step `timeout-minutes: 10` so a future stall aborts after 10 min instead of silently eating 16+ min.
- **Version:** `2.2.4+10` → `2.2.5+11` (`2.2.5` tag).

---

## [2.2.6] — (local signing verification, no code change beyond version)

- Local `flutter build apk --release` twice on `2.2.5` → both `111.1 MB`, `keytool -printcert` same `CN=MapBanai` SHA1, proving persistent signing works locally. CI `v2.2.5` run `32475344855` in_progress at time of log.

---

## [2.2.7] — (pending) WebMap HTML generator (Task 2 local, no push yet)

- Local assets `assets/leaflet/leaflet.css/js` (1.9.4, 14.8/147.5 KB) + `pubspec` `assets/leaflet/`, `WebMapDataService` (FeatureCollection from all non-draft sessions, GIS `feature_type` + survey geopoint via `answers` `geopoint` string/`{lat,lon}` map, `p.basename` fix for Windows, thumbnail `512px/70` base64 capped), `WebMapGenerator` (inlines Leaflet, OSM tiles, geometry styling, popup table + thumbnail, filter sidebar for `form_name`/`surveyor`/`submitted_at` date range, legend, `writeToFile`), tests `webmap_data_service_test` + `webmap_generator_test` (mock 3-feature collection, filter options, file write) — **local only, not pushed per 4-set instruction**.

---

## [2.1.4] — real in-app-update installer fix (+ verified backup/restore)

### What was already in place (from 2.1.1–2.1.3) vs. what this release actually fixed
The manifest already declared `REQUEST_INSTALL_PACKAGES`,
`hasFragileUserData="true"`, the `${applicationId}.fileprovider`
FileProvider, and `android/app/build.gradle` already signs release builds
from the same `KEYSTORE_BASE64 / KEYSTORE_PASSWORD / KEY_ALIAS /
KEY_PASSWORD` env vars that `.github/workflows/release.yml` injects. So the
blame for "download completes then shows Error in Download" was NOT the
permission declaration or the signature config — it was the installer step.

### Root cause of "Error in Download" at 100%
`open_file`'s Android plugin (`openApkFile` in open_file_android 1.0.6)
checks `PackageManager.canRequestPackageInstalls()` on Android 8+ and, when
false, **returns error code −3 without launching the package installer**. Our
code treated any non-`done` result as a failure and painted it as
"Download failed." — so users with "Install unknown apps" disabled for
MapBanai always hit it right after the bar hit 100%, and nothing guided them
to the switch.

### Fixes
- **`lib/services/update_downloader.dart`**: dropped the `open_file`
  dependency. `openInstaller` now calls the app's own `mapbanai/update`
  platform channel and throws a typed `InstallPermissionException` on code
  `install_permission`; added `requestInstallPermission()` that opens the
  per-app "Install unknown apps" settings screen. (MissingPluginException is
  also mapped to the same typed error so the dialog stays actionable.)
- **`android/.../MainActivity.kt`** — new `mapbanai/update` MethodChannel:
  - `openInstaller(path)` → on Android 8+, returns platform error
    `install_permission` when `canRequestPackageInstalls()` is false; else
    `FileProvider.getUriForFile(...)`
    (`authority = $packageName.fileprovider`, `file_paths.xml` covers
    external-path `.` and cache-path `.`) → `ACTION_VIEW`
    `application/vnd.android.package-archive` with
    `FLAG_GRANT_READ_URI_PERMISSION`, mapping `no_file`, `no_handler`, and
    generic failures to distinct error codes.
  - `openInstallUnknownAppSources()` → `Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES`
    for this package; returns whether the screen opened.
  - `android/app/build.gradle`: added `implementation
    'androidx.core:core:1.12.0'` (forced version) so MainActivity can compile
    against `androidx.core.content.FileProvider`.
- **`lib/ui/common/update_dialog.dart`**: while `Download & Install` keeps
  its rollback to plain error text, an `InstallPermissionException` now also
  sets a `_needsInstallPermission` flag that shows instructions plus an
  **"Allow installation"** action button (opens the settings screen), then
  the user taps Download & Install again. No more dead-end.
- **Redirect handling test**: `package:http` already follows GitHub's
  302 → `objects.githubusercontent.com` redirect; added
  `test/update_downloader_test.dart` "follows an HTTP redirect and still
  completes byte-identical" asserting the client hits both URL paths, hits
  100% progress, and the final bytes match — proof that the updater handles
  redirects and still enforces the byte count.

### Backup/restore (`lib/services/backup_service.dart` + home_screen prompt)
Already implemented since 2.1.1: periodic `VACUUM INTO` snapshot + settings
JSON to `Documents/MapBanai/backups` (Android) with app-storage fallback,
and the fresh-install restore offer on the Home screen (only when no
projects exist yet and a backup is found; DB closed before the copy). This
release:
- Guarded the `/storage/emulated/0/Documents/...` candidate with
  `Platform.isAndroid` — on Windows the literal POSIX path used to "succeed"
  by creating `C:\storage\...`, silently misdirecting backups in dev/test.
- `test/backup_service_test.dart`: fakes `PathProviderPlatform`; verifies
  `createBackup()` writes db+prefs+meta, `hasBackups()`, and that
  `restoreLatest()` overwrites the live `mapbanai.db` byte-for-byte.

### Version/test state
`2.1.4+5`. Full suite 188 green (added redirect + 2 backup tests); analyze
0 errors/warnings (72 info-level baseline only); release APK builds
(110.8 MB).

---

## [2.1.3] — import robustness, QR camera scan, working share menu, resilient updater

### Import: "Choose .mbproj file" 
- `SafProjectFileSink.pickPackageFile` previously swallowed every picker
  error (`catch (_) { return null; }`) AND used `FileType.custom +
  allowedExtensions` — unreliable on Android SAF (some file managers ignore
  the MIME filter → empty/null result) → "nothing happened". Now: `FileType.any`,
  validate `p.extension(...).endsWith('.mbproj')`, throw
  `ProjectImportException(wrongPackageType)` for a wrong file, and let real
  picker errors propagate. `home_screen._startImportFlow` wraps the pick in
  try/catch → SnackBar (generic messages when not a `ProjectImportException`/
  `FormatException`). Cancel still returns null silently.

### Import: "Paste project code" black screen (double-pop)
- `runProjectImport` popped its blockers-first progress dialog at 3 points,
  then the `catch` block popped AGAIN when `finishImport` threw → the 2nd pop
  removed HomeScreen → black screen; error dialog rendered on a dead context.
- Trigger in practice: **bootstrap QR codes**. `startQrImport` returns a
  session with `bootstrapMeta` set but `allowBootstrap` stayed `false` (the
  gate `if (session.allowBootstrap && ...)` never fired) → fell into
  `finishImport` → `package == null` → threw internal → black screen.
- Fix: (1) branch on `session.bootstrapMeta != null` directly (show the
  friendly "info only, ask for the .mbproj" dialog) — for both pasted codes
  and deep links; (2) guard every pop with `progressVisible` so the catch
  block pops at most once; (3) `if (!context.mounted) return;` after the
  start await. Removed the now-unused `allowBootstrap` field.

### Import: "Scan QR code" (new, no native deps)
- `pubspec` + `zxing2: ^0.2.4` (pure-Dart ZXing port; `dart pub get` only,
  NO `.flutter-plugins` sync, no AGP/Gradle risk — `mobile_scanner` was
  rejected: 6.x pins AGP 8.13/Gradle 8.13+ & Kotlin 2.2.20, 5.2.3 pins AGP
  8.3.2/Gradle 8.4+, both incompatible with this repo's AGP 8.1.0/Gradle
  8.3).
- `lib/services/qr_scanner.dart`: `scanFromCamera()` captures a photo via the
  already-present `image_picker` (intent-based, no CAMERA permission), then
  `decodeFromFile()` decodes with `image` (decode → `bakeOrientation` → ABGR
  → `RGBLuminanceSource` → `BinaryBitmap(GlobalHistogramBinarizer)` →
  `QRCodeReader`), trying inverted source as a fallback, trimming the text.
  Throws `QrScanException` (const ctor, user-safe message).
- Home import dialog: 3rd option `Scan QR code`; on `QrScanException` a
  dialog offers "Paste instead" + Close.

### Survey Mode ⋮ → Share project
- `survey_screen._shareProject` was a `void` stub ("coming soon"). Now
  resolves the project via `_database.getProjectByName(_projectName)` and
  calls the same `showExportProjectOptions(context, flow: ProjectSharingFlow(database: _database), project:)`
  the working Project settings button uses. Reuses the screen's open DB.

### Updater: 99% → "network error"
- Root: `UpdateDownloader.download` had NO completeness check, NO resume, NO
  retry; a mid-body connection drop (110 MB APK on a flaky link) surfaced as
  `ClientException`, and `update_dialog` `catch (_)` swallowed the reason.
- Rewrite: writes `.part`; `Range: bytes=N-` resume across up to 3 attempts
  (partial file persists between attempts); accepts 200 (reset offset) and
  206; per-chunk `.timeout(45s)`; enforces `received == expected` (throws
  `HttpException` if short); atomic `rename()` to `mapbanai-update.apk` only
  after a complete body; final `onProgress(1)` only after rename.
  `download(url, {downloadDir, onProgress})` — injectable dir for tests.
  On persistent failure throws `HttpException('Download failed: $cause …')`.
- `update_dialog`: stores `_error` from the caught exception and displays it
  in red (falling back to the old generic copy when empty).

### Tests (185 total green; analyze 0 errors/warnings — 72 info-level, all pre-existing baseline)
- `test/qr_scanner_test.dart`: renders a QR from `zxing2.Encoder` (ByteMatrix
  → `image` PNG, quiet zone) → `decodeFromFile` round-trips; blank image
  throws `QrScanException`; whitespace trimmed.
- `test/update_downloader_test.dart`: local `HttpServer` with Range support:
  clean download written to final `.apk` (no `.part` left, progress→1);
  **mid-body socket drop** (announce full length, `detachSocket`,
  write slice, `destroy`) → retried with `Range: bytes=512-` (206) and
  completes byte-identical; 404 rejected.
- `test/project_share_test.dart`: bootstrap QR `startQrImport` → session has
  `bootstrapMeta` set and `isQr == false` (guards the black-screen branch).

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
attach; 8: projects.external_id; 9: survey_sessions.syncedAt/photoSyncedAt + sync_configs;
10: survey_sessions.externalId (stable UUID, backfilled).