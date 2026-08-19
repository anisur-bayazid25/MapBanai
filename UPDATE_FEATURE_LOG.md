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