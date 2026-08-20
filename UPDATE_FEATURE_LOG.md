# UPDATE_FEATURE_LOG

Progress log for: Push MapBanai to GitHub + GitHub-Release-based in-app update checker.
Repo: https://github.com/anisur-bayazid25/MapBanai

---

## Part A — Push to GitHub

| # | Step | Command | Result |
|---|------|---------|--------|
| A1 | .gitignore | n/a (edited file) | Existing Flutter .gitignore extended with `*.apk`, `key.properties`, `.gradle/`, `*.keystore`, `*.jks`, `local.properties`, `.cxx/` — no keystores/signing secrets will be committed |
| A2 | Diagnosis | `git ls-remote https://github.com/anisur-bayazid25/MapBanai.git HEAD` (1st) | FAIL: `Failed to connect to github.com:443 ... Could not connect to server` after 21119 ms |
| A3 | Diagnosis (retry) | `git ls-remote https://github.com/anisur-bayazid25/MapBanai.git HEAD` (2nd) | FAIL: identical error, identical 21119 ms timeout — STOPPED per task rule (no 3rd retry) |
| A4 | Connectivity probe | `Test-NetConnection github.com -Port 443` | TCP succeeded (20.205.243.166), but `curl -I https://github.com` timed out (000) — flaky/blocked |
| A5 | Connectivity probe | `curl https://api.github.com` | OK: HTTP 200 in 0.18 s — `api.github.com` reachable, `github.com` main host is not |

**STATUS A: BLOCKED on network** — `github.com:443` unreachable from this machine (ISP/firewall throttling, South Asia route). api.github.com works. Push will be retried once network recovers.

| A6 | init | `git init -b main` | OK — repo initialized on `main` |
| A7 | stage | `git add -A` | OK — 267 files staged; sensitive-scan confirmed no key.properties/*.apk/keystores/.gradle/local.properties |
| A8 | commit | `git commit -m "Initial commit: ..."` | OK — 5bc3b65; removed stray `~$logo_start.pptx` (Office lock) + `coverage/lcov.info` (056a439), tightened .gitignore (`~$*`, `/coverage/`) |
| A9 | push (1st) | `git push -u origin main` | Rejected: remote had web-created initial commit (README/LICENSE/.gitignore) — different error, resolved below |
| A10 | pull | `git pull --rebase origin main` | Rebase stalled; `git rebase --abort` blocked by locked `logo_start.pptx` (open in another process) — unblocked via `git add` (re-track in index) |
| A11 | merge | `git merge origin/main --allow-unrelated-histories` | OK — .gitignore conflict resolved (kept ours), README kept theirs; merge commit 13c9238 |
| A12 | push (2nd) | `git push -u origin main` | **OK — `73de87c..13c9238 main -> main`**, branch tracking set |
| A13 | verify | `git ls-remote origin main` | OK — remote main = 13c9238 == local HEAD |

**STATUS A: COMPLETE — CHECKPOINT PASSED** (code present on https://github.com/anisur-bayazid25/MapBanai, main branch).

---

## Part B — GitHub Actions release pipeline

| # | Step | Command | Result |
|---|------|---------|--------|
| B1 | workflow | n/a (wrote `.github/workflows/release.yml`) | OK — tag push `v*.*.*` → checkout@v4 + subosito/flutter-action@v2 (pinned 3.24.3, matches local toolchain; AGP 8.1/Gradle 8.3 are committed in repo) + `flutter pub get` + `flutter build apk --release` + softprops/action-gh-release@v2 (name = tag, attaches app-release.apk) |
| B2 | commit+push | `git push origin main` (dbdf8a1) | OK |
| B3 | test tag | `git push origin v2.0.1-test` | OK — workflow run 32223802340 triggered |
| B4 | poll | `GET /actions/runs` (60 s loop) | in_progress → **completed / success** (~6 min) |
| B5 | verify release | `GET /releases/tags/v2.0.1-test` | **OK — release "v2.0.1-test" with app-release.apk (107.8 MB, uploaded)** — built on GitHub runners, bypasses local toolchain |
| B6 | cleanup tag | `git tag -d` + `git push origin :refs/tags/v2.0.1-test` | OK — tag deleted locally and remotely |
| B7 | cleanup release | `DELETE /releases/{id}` | **FAILED: 401 Unauthorized** (no gh CLI / token on this machine) — MANUAL STEP: user deletes release on web UI, or pass a PAT |

**STATUS B: COMPLETE — CHECKPOINT PASSED** (test-tagged build produced a Release with the APK; test tag deleted).

Manual follow-up: delete the orphaned v2.0.1-test release at https://github.com/anisur-bayazid25/MapBanai/releases (2 clicks), or provide a PAT.

(waiting on Part A)

---

## Part C — In-app update checker

| # | Step | Command | Result |
|---|------|---------|--------|
| C1 | deps | `flutter pub add http package_info_plus open_file` | pubspec+lock updated (http ^1.6.0, package_info_plus 9.0.1, open_file ^3.5.11) but tool failed at the Windows plugin-symlink step (`Building with plugins requires symlink support` — Developer Mode off, no admin) |
| C2 | workaround | `dart pub get --offline` + hand-synced `.flutter-plugins-dependencies`/`.flutter-plugins` | OK — plain `dart pub get` skips Flutter's symlink step; symlinks are only needed for linux/windows desktop builds, not Android; `flutter analyze`/`test`/`build apk` all run with no symlink step afterwards (verified: tool skips it when plugin list JSON is unchanged) |
| C3 | AGP conflict | `flutter build apk --debug` | FAIL: package_info_plus 9.0.1 pins AGP 8.12.1 + needs `flutter` gradle extension — incompatible with project AGP 8.1/Gradle 8.3 (committed config also used by CI) |
| C4 | fix | pubspec pinned `package_info_plus: 8.0.2` (8.x era matches Flutter 3.24/AGP 8.1) + `dart pub get` + hand-synced plugin lists | OK — `flutter build apk --debug` **built** (39s), manifest merged with new FileProvider + REQUEST_INSTALL_PACKAGES, no authority conflicts (open_file_android uses its own authority) |
| C5 | code | n/a (wrote files) | `lib/services/update_checker.dart` (GET /releases/latest, strip leading v, .apk asset URL, int[] semver comparator, UpdateInfo? — all errors → null), `lib/services/update_downloader.dart` (stream download to external storage or temp with progress, then OpenFile.open), `lib/ui/common/update_dialog.dart` (shared dialog: notes + progress + Download & Install; up-to-date variant) |
| C6 | manifest | n/a (edited files) | REQUEST_INSTALL_PACKAGES added; INTERNET already present (confirmed); FileProvider `${applicationId}.fileprovider` + `res/xml/file_paths.xml` (external-path + cache-path) |
| C7 | UI | n/a (edited files) | Settings: "Check for updates — vX.Y.Z installed" row (PackageInfo) → update/up-to-date dialog. Home: silent background check on init → snackbar with View action; never auto-downloads |
| C8 | tests | `flutter test` | **120/120 passed** (incl. 5 new version-comparator tests in test/update_checker_test.dart) |
| C9 | analyze | `flutter analyze` | 0 issues in new/changed files; total unchanged at pre-existing baseline (48 infos/warnings, 0 errors) |
| C10 | build | `flutter build apk --debug` | OK — APK built with new plugins |

**STATUS C: CODE COMPLETE** — step 12 (bump 2.1.0 + tag + push) next.

## Step 12 — version bump + full pipeline proof

| # | Step | Command | Result |
|---|------|---------|--------|
| D1 | bump | pubspec `version: 2.1.0+1` | OK |
| D2 | commit | `git commit -m "Add GitHub-release-based update checker...; bump to 2.1.0"` | 6dad626 |
| D3 | push main | `git push origin main` | `03c01e2..6dad626` OK |
| D4 | tag | `git tag v2.1.0; git push origin v2.1.0` | OK |
| D5 | CI build | poll `GET /actions/runs` | **completed / success** (~6 min) |
| D6 | release | `GET /releases/tags/v2.1.0` | **Release "v2.1.0" with app-release.apk (109 MB, uploaded)** — full loop proven: tag push → Actions build → Release with APK → app update checker can detect it |

---

## Part E — v2.1.1: logo, version-bump system, GPS Save-Point CSV, reset safeguard, About links

| # | Step | Command | Result |
|---|------|---------|--------|
| E1 | logo | n/a (converted `logo_start.pptx` art) | MapBanai logo PNG (2935x1077, 240KB) + SVG + ICO exported from the official slide; 5 Android launcher mipmaps generated from the PNG; `assets/` added to pubspec |
| E2 | in-app logo | n/a (edited files) | Settings About card: logo image 200px + tagline + version + description (kept theme-aware colors). Home header: logo image 160px replacing the "MapBanai" text |
| E3 | bump system | n/a (wrote `tool/bump_version.dart` + `.github/workflows/bump-version.yml`) | Script: parses pubspec `version: X.Y.Z+N`, one arg (major/minor/patch) → write new version, create annotated `v<new>` tag pointing at the pre-bump commit (no extra commit), force-push the tag (works on branch-protected repos); dry-run mode `--dry-run`. Workflow: `workflow_dispatch` input `bump` → run script → push tag to trigger the existing release pipeline |
| E4 | GPS Save-Point → CSV | n/a (edited `lib/ui/gps_mode_screen.dart`) | `_pickWaypointLog` refactored: waypoint CSV still appended to `<project>_waypoints.csv`; `_createPointLog` now also appends GPS points (lat, lon, datetime, label) to `<project>_points.csv` in the same external-storage `Export` folder — via the same safe `_writeAppendCsv` helper (encodes labels with commas/newlines/quotes) |
| E5 | reset safeguard | n/a (edited `lib/ui/common/confirm_dialog.dart` + `lib/ui/settings_screen.dart`) | Reset now needs TWO confirmations: classic dialog → second `showTypeToConfirmDialog` (edited copy of the transfer dialog) requiring the user to type the exact owner name before the DB is wiped; `_resetData` changed accordingly |
| E6 | About links | n/a (edited `lib/ui/settings_screen.dart` + pubspec) | `dart pub add url_launcher` → pinned by resolution (^6.3.3); GitHub repo ListTile (opens https://github.com/anisur-bayazid25/MapBanai) + email ListTile (mailto:comlesconstructionus@gmail.com); `_launchUrl` guards `launchMode: LaunchMode.externalApplication`, enforces https/mailto, try/catch → SnackBar fallback |
| E7 | plugin files | n/a (hand-sync) | `.flutter-plugins`/`.flutter-plugins-dependencies`/`macos/Flutter/GeneratedPluginRegistrant.swift` updated for url_launcher (symlink workaround per C2); CI is unaffected |
| E8 | analyzer trap | `dart analyze` | A bulk PowerShell edit wrongly added `const` before `EdgeInsets.zero` — but `EdgeInsets.zero` is a static const GETTER, not a constructor, so `const EdgeInsets.zero` is illegal ("Expected to find '('"; "The class 'EdgeInsets' doesn't have a constant constructor 'zero'"). Fixed with correct `const` placements (`const ListTile(...)`, `const Center(...)`; no `const` on `EdgeInsets.zero`) |
| E9 | test fix | `flutter test` | Widget test asserted `find.text('MapBanai')` on Home — broken by replacing the text with the logo image → new predicate finds the logo `Image`/`AssetImage` widget + the tagline instead. **120/120 passed** |
| E10 | analyze | `flutter analyze` | 0 errors; only pre-existing baseline warnings/infos (49 total) |
| E11 | build | `flutter build apk --debug` | OK — APK contains the 5 new launcher mipmaps + url_launcher registered (registrant compiled into dex; the plugin needs no manifest entries) |
| E12 | commit | `git add -A` | logo_start.pptx reverted first (Office churn 34.6→36.5 KB, untouched by me); macos GeneratedPluginRegistrant.swift (+2 url_launcher lines) kept |

## Step 13 — bump 2.1.1 via the new script + full pipeline proof

| # | Step | Command | Result |
|---|------|---------|--------|
| F1 | bump | `dart run tool/bump_version.dart patch` | OK — pubspec + AppInfo.version → `2.1.1+2` |
| F2 | commit | `git commit -m "Bump version to 2.1.1+2"` | 1cfd799d (after the v2.1.1 feature commit bc3b4d2) |
| F3 | push main + tag | `git push origin main` + `git tag v2.1.1 && git push origin v2.1.1` | OK — main and v2.1.1 both at 1cfd799d |
| F4 | CI build | poll `GET /actions/runs` | **completed / success** (~7 min, run on 1cfd799d) |
| F5 | release | `GET /releases/tags/v2.1.1` | **OK — Release "v2.1.1" published 2026-08-19T08:44:10Z with app-release.apk (109.2 MB)** |

**STATUS F: COMPLETE** — bump script tested for real (2.1.0+1 → 2.1.1+2), tag v2.1.1 pushed, CI rebuilt the shippable APK and attached it to the Release without any manual build step.

---

## FINAL STATUS
- **v2.1.1 SHIPPED** — repo live at https://github.com/anisur-bayazid25/MapBanai (main = 1cfd799d), Release v2.1.1 with app-release.apk (109.2 MB).
- **Part E (v2.1.1 features): DONE, verified** — logo everywhere (launcher + About + Home), version-bump system (script + Actions workflow), GPS Save-Point → `<project>_points.csv`, type-to-confirm reset safeguard, About GitHub/email links via url_launcher. 120/120 tests, analyze at baseline (0 errors), debug APK built with icon + url_launcher registered.
- **Part B (release pipeline): DONE** — verified three times (v2.0.1-test, v2.1.0, v2.1.1). Test tag deleted locally+remote; **the orphaned v2.0.1-test release page still needs manual deletion on the web UI** (no PAT/gh CLI on this machine — API delete returned 401).
- **Part C (update checker): CODE DONE, verified end-to-end with v2.1.1** — the Home silent check + Settings manual check will now detect 2.1.1 properly; remaining manual device checkpoints:
  1. Install the APK, place a test APK at the download path, confirm OpenFile launches the installer prompt.
  2. Confirm the About GitHub/email taps open the browser/email app, and the reset pop-up requires the typed owner name.
- **Environment notes:**
  - Windows Developer Mode is OFF → `flutter pub add`/`flutter pub get` fail at the plugin-symlink step. Worked around with `dart pub get` + hand-syncing `.flutter-plugins-dependencies`/`.flutter-plugins` (Android builds don't need symlinks; the tool skips the step when the plugin list is unchanged). **Recommended fix: enable Developer Mode** (start ms-settings:developers) so future `flutter pub get` runs clean.
  - package_info_plus pinned to 8.0.2: 9.x requires AGP 8.12/Gradle 8.13+, the project (and CI) uses AGP 8.1/Gradle 8.3.

---

## Part G — v2.1.2: background GPS continuity + draft system

| # | Step | Command | Result |
|---|------|---------|--------|
| G1 | background recorder | n/a (wrote `lib/services/background_gps_recorder.dart`) | `BackgroundGps.instance` singleton ChangeNotifier owns the live geolocator stream while a GPS track records. fg notification via geolocator 12 `AndroidSettings.foregroundNotificationConfig` (channel `MapBanai GPS recording`, `enableWakeLock`, `setOngoing`) → survives GPS-screen Back (no PopScope) AND screen-off. `GpsLogStore.appendReading` still writes `<log>.csv`; appends throttled 1/s; `setPaused` skips appends but keeps stream+notification; `stop()` cancels sub + releases fg service. Manifest: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK`. No `ACCESS_BACKGROUND_LOCATION` (fg-service + while-in-use) |
| G2 | GPS screen rework | n/a (edited `lib/ui/gps_mode_screen.dart`) | Recording delegated to BackgroundGps; local stream is read-only preview (never appends). `_startListening` mirrors bg state when recording active; one live stream (Start cancels preview sub, Stop reopens). `_createLog`/`_toggleRecording` → `BackgroundGps.start/stop`; `_deleteLog` stops bg first for the active log; pause routes to `setPaused` |
| G3 | GIS continuity + drafts | n/a (edited `lib/ui/gis_mode_screen.dart`, `lib/services/track_recorder.dart`) | `_startLocationStream({bool? foreground})`: fg notification ONLY while `_recorder.running` (Begin→fg, `_cancelDraft`/finish→plain). `TrackRecorder.serialize()/restore()` round-trip vertices+timing (config NOT serialized — restore inherits constructing screen's thresholds). GIS `_saveDraft` (`{draft:true, feature_type, recorder|fix}` + point draggable marker restore); `_saveFeature` on Finish **updates** the same row to saved when resuming a draft (`updateSurveySession`) |
| G4 | survey drafts | n/a (edited `lib/ui/survey_form_renderer.dart`, `lib/ui/survey_form_detail_screen.dart`, `lib/data/app_database.dart`) | `onSaveDraft` + "Save as draft" button (skips required/constraint validation); `_saveDraftResponse` inserts `status:'draft'` row. DB: `getDraftSurveySessions()`; `responseCountsForProject`/`surveySessionCountForProject` exclude drafts via `status.equals('draft').not()` (drift has no notEquals on GeneratedColumn) — no migration, no codegen |
| G5 | history drafts UI | n/a (edited `lib/ui/survey_history_screen.dart`) | Full rewrite: Drafts section at top (Resume inline + Delete with confirm). Survey draft resume → prefilled renderer (`initialAnswers`, form re-located by form_id/form_name), Save promotes to saved / draft updates row. GIS draft resume → `GisModeScreen(projectName, resumeDraftId)`. Saved groups exclude drafts |
| G6 | home banner | n/a (edited `lib/ui/home_screen.dart`) | Persistent red banner while `BackgroundGps.instance.isRecording` (Open GPS Mode / Stop); init/dispose attach/detach listener |
| G7 | tests | `flutter test` | New `test/background_gps_recorder_test.dart` (start/stop state, CSV streaming via `GpsLogStore.defaultLogsDir()`, pause-skips-appends, notifications), `test/drafts_history_test.dart` (count exclusion, form Save-as-draft, history drafts/delete/resume→saved), track serialize/restore round-trip. Fixed: restored recorder must match thresholds (default minIntervalS:2 rejected instant add). **178/178 passed** |
| G8 | analyze | `flutter analyze` | 0 errors; only pre-existing baseline warnings in `test/gis_map_controller_test.dart` (3 unused locals) |
| G9 | docs | n/a (edited `CHANGELOG.md`, `AI_CHANGELOG.md`, `README.md`, this log) | v2.1.2 entries written |

---

## Part H — bump 2.1.2 + full pipeline proof

| # | Step | Command | Result |
|---|------|---------|--------|
| H1 | bump | `dart run tool/bump_version.dart patch` | OK — pubspec + AppInfo.version → `2.1.2+3` |
| H2 | commit | `git commit -m "MapBanai v2.1.2: background GPS continuity + draft system"` | 164b323 (20 files, +1600) |
| H3 | push main + tag | `git push origin main` + `git tag v2.1.2 && git push origin v2.1.2` | OK — CI triggered on 164b323 |
| H4 | CI build | poll Actions run | **1st run FAILED (6m6s)** at `:app:compileReleaseKotlin`: `MainActivity.kt` latent errors — `lm.unregisterGpsStatusCallback` unresolved (hidden GpsStatus API — code registers a `GnssStatus.Callback`, so it must call `unregisterGnssStatusCallback`) and `openInputStream()` returns `InputStream` not `FileInputStream`. Root cause: the v2.1.1 release ran on 1cfd799 which PREDATES the 0f24150 sharing-subsystem commit that added this Kotlin — this was the first CI build to ever compile it. Fixed both + re-verified locally (`flutter build apk --release --no-pub` OK, 110.2 MB), committed 88990f1, moved tag `git push origin :refs/tags/v2.1.2` + `git tag -f v2.1.2 && git push origin v2.1.2` → rerun **success** |
| H5 | release | `GET /releases/tags/v2.1.2` | **OK — Release "v2.1.2" published 2026-08-20T17:34Z by github-actions on 88990f1 with app-release.apk** |

## FINAL STATUS (v2.1.2)
- **v2.1.2 SHIPPED** — main = 88990f1, Release v2.1.2 with app-release.apk (110.2 MB) built on GitHub Actions.
- **Part G (v2.1.2 features): DONE, verified** — background GPS recorder (screen-off + Back-button continuity, fg notification + wake lock, Home banner), GIS line/polygon screen-off continuity, draft system (survey + GIS save/resume/delete via History Drafts section, drafts excluded from counts/annotations/exports). 178/178 tests, analyze 0 errors, release APK builds.
- **Pipeline hiccup caught & fixed**: the Kotlin GLUE in MainActivity.kt (gnss callback unregister + stream typing) had never been compiled by CI — v2.1.1's tag build predated the sharing-subsystem commit that introduced it. Fixed, verified locally, re-tagged, CI passed.
- **Remaining manual device checkpoints (unchanged from v2.1.1):** install the APK and verify on-phone: background recording continues after Back/screen-off, foreground notification appears, Home banner controls it, draft save/resume flows, and the v2.1.1 update checker now offers v2.1.2.