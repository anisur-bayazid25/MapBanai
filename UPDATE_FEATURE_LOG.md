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

(waiting on Part A)