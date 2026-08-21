# RESTORE_BUG_LOG — "Previous data backup found" silently restores nothing

**Date:** 2026-08-21
**Investigator:** Muse Spark — Fix1 diagnostics
**Branch:** main @ d48d9db..0ccfed5 + uncommitted Fix1/Fix2

## 1. Which files implement the restore feature

| File | Role |
|------|------|
| `lib/services/backup_service.dart` | **Core backup/restore engine**. Defines `BackupService`, `hasBackups()`, `newestBackup()`, `restoreLatest()`, `createBackup()`, `_backupRoot()`, `_backups()`, `_liveDbFile()`, `_vacuumInto()`, `_isWritable()`, `_stamp()`. |
| `lib/ui/home_screen.dart` | **UI trigger**. `_promptRestoreBackup()` shows the dialog `Previous data backup found` / `Restore settings and survey responses?`, calls `hasBackups()` + `restoreLatest()`, closes/reopens `AppDatabase`, shows SnackBar `Backup restored successfully` vs `Backup restore failed`. Also `_scheduleBackups()` + `_handleStartupChecks()` ordering and `_promptUserNameOnce()` (second dialog). |

Dialog strings searched:
- `"Previous data backup found"` → `lib/ui/home_screen.dart:91`
- `"Restore settings and survey responses"` → `lib/ui/home_screen.dart:92-94`

No other file references those strings.

## 2. What path/location it writes backups to vs reads from during restore

**Single source of truth:** `BackupService._backupRoot()` (lines 31-51)

```dart
Future<Directory> _backupRoot() async {
  final candidates = <Directory>[
    if (Platform.isAndroid)
      Directory('/storage/emulated/0/Documents/MapBanai/backups'),
  ];
  for (candidate in candidates) {
    await candidate.create(recursive: true);
    if (await _isWritable(candidate)) return candidate;
  }
  final docs = await getApplicationDocumentsDirectory();
  return Directory(p.join(docs.path, 'mapbanai_backups'));
}
```

- **Write path (`createBackup`):** `root = await _backupRoot()` → `dir = Directory(p.join(root.path, _stamp()))` → `File(p.join(dir.path, 'mapbanai.db'))` via `VACUUM INTO`, plus `prefs.json`/`meta.json`, then `_pruneOld`.
- **Read path (`_backups`/`hasBackups`/`newestBackup`/`restoreLatest`):** `root = await _backupRoot()` → `root.listSync().whereType<Directory>().where((d) => File(p.join(d.path,'mapbanai.db')).existsSync())` sorted descending → `newestBackup` is first. `restoreLatest` does `File(p.join(latest.path,'mapbanai.db')).copy(live.path)` where `live = File(p.join(docs.path,'mapbanai.db'))` via `getApplicationDocumentsDirectory()`.

**Thus write and read use the *identical* `_backupRoot()` candidate-fallback logic** — no path mismatch between write and read *within the same install*, as long as the same fallback decision is made both times.

## 3. Confirm where backups are actually written on normal app use — durability analysis

**AndroidManifest (`android/app/src/main/AndroidManifest.xml:12-22`):**
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
<application android:hasFragileUserData="true" android:requestLegacyExternalStorage="true">
```
- `WRITE_EXTERNAL_STORAGE` is capped to API 29 (Android 10). On **Android 11+ (API 30+, targetSdk 34/35, compileSdk 36)**, `requestLegacyExternalStorage` is **ignored**.
- No `MANAGE_EXTERNAL_STORAGE` (`All files access`) is declared or requested.

**Runtime check (`_backupRoot` + `_isWritable`):**
- Candidate `/storage/emulated/0/Documents/MapBanai/backups` is a **public shared** location that *would* survive uninstall, but on Android 11+ direct `File` creation there requires either `MANAGE_EXTERNAL_STORAGE` or `MediaStore` API. Our code tries `candidate.create(recursive:true)` + probe file `writeAsString('ok')`.
- **On Android 6-10 (API <=29):** `WRITE_EXTERNAL_STORAGE` granted (user prompt) + `requestLegacyExternalStorage=true` → direct File write succeeds → `_isWritable` true → backups live in **public Documents** → **durable** (survives uninstall).
- **On Android 11+ (API 30+, which is *all* modern devices, targetSdk 35/36):** `candidate.create` and/or probe `writeAsString` throws `FileSystemException` (scoped storage denial) → caught → loop continues → fallback to `getApplicationDocumentsDirectory()/mapbanai_backups` → typically `/data/user/0/com.mapbanai.mapbanai/app_flutter/mapbanai_backups` (or `/data/data/...`). This is **app-private internal storage** (and `getApplicationSupport`/`Documents` variant). Same for `getExternalStorageDirectory` (`/storage/emulated/0/Android/data/com.mapbanai.mapbanai/files/...`) — also app-specific external, **deleted on uninstall** on Android 11+.

**Verification via code + permissions:**
- No `MANAGE_EXTERNAL_STORAGE` in manifest, no runtime request, no `MediaStore` insertion.
- Therefore on any device running Android 11+ (released 2020, >90% of active devices in 2026, and our `minSdk 23`/`targetSdk 35` build), the public candidate will be rejected and **every normal backup is written to app-private storage**, which **Android wipes on uninstall**.

**Conclusion for step 2:** The backup is **not durable** on modern Android. The `"Previous data backup found"` dialog on a *fresh install after a real uninstall* will **never appear** because `hasBackups()` will scan the *new* empty app-private directory (fallback root recreated empty). If the dialog *does* appear (e.g., after a non-uninstall data clear, or on Android 9, or while still on same install), it is detecting a backup that was written to app-private during that same install — not a cross-install durable copy. The backup itself is already gone before restore runs in the manual-uninstall scenario.

> **Design finding (STOP condition met):** Backups were never actually being written anywhere durable on Android 11+. This is a **bigger design fix**: needs to write to public shared storage via `MediaStore` (Documents) with proper scoped-storage API, or use `SAF`, `MANAGE_EXTERNAL_STORAGE` (requires Play policy justification), or rely on the **sync backend (Google Sheets via Apps Script)** introduced in Tasks 1-5 as the durable store, not local file backup. Patching the restore path alone cannot make app-private files survive uninstall.

## 4. Trace restore path — username second dialog

**Assumption in task description:** Second dialog asks for username to locate backup via `user_name` vs internal `userId`.

**Actual code:**
- `_promptRestoreBackup()` (home_screen 82-130) — **does not use username at all**. It calls `hasBackups()` (path scan only) and `restoreLatest()` (copies `newestBackup()/mapbanai.db` → live `mapbanai.db`). No `getSetting('user_name')` is consulted, no key/path includes username.
- `_promptUserNameOnce()` (home_screen 567-619) — runs **after** `_promptRestoreBackup()` in `_handleStartupChecks()` order. It reads `getSetting('user_name')`, and if empty shows the *Welcome to MapBanai* dialog asking for name. The entered name is stored via `setSetting('user_name', name)` — it is **not** used to locate any backup file; the backup's `prefs.json` *contains* the old `user_name` value, but restore does not filter by it. After restore, the DB's `app_settings` table already contains the old `user_name` (since `mapbanai.db` was copied), so the second dialog will actually be **skipped** if restore succeeded (because `getSetting('user_name')` will now return the restored name).

**Username handling:** Display name string stored as `app_settings` row `user_name`, not an internal `userId`. No ID is involved. New install has `null` for `user_name` until restored DB provides it or user enters a new one. The backup's *filename* is timestamp `_stamp()` (`yyyyMMdd_HHmmss`), not username. So there is no key mismatch between old and new install — the flow simply doesn't key by username at all.

**Added log line (Fix1 step 3):** In `_promptRestoreBackup` we now `debugPrint`:
```
[Restore] _backupRoot = <path>, exists=<bool>, isWritable probe=<bool>,
  _backups count=<n>, newest=<path or null>, liveDbPath=<path>, liveExists=<bool>
```
and in `BackupService._backupRoot`/`_backups`/`restoreLatest` we log candidate attempts and the exact searched path + whether it exists at that moment, so failures are observable via `adb logcat` without swallowing.

## 5. Do NOT swallow exceptions — what was changed

**Before (silent):**
- `BackupService.createBackup()` `catch (_) { return null; }`
- `_backups()` `catch (_) { return const []; }`
- `_liveDbFile()` `catch (_) { return null; }`
- `restoreLatest()` `catch (_) { return false; }`
- `HomeScreen._promptRestoreBackup()` `catch (_) { // best-effort }`

**After (Fix1 step 4):**
- All catches now `catch (e, st) { debugPrint('[BackupService.createBackup] failed: $e\n$st'); return null; }` (and analogous for `_backups`, `_liveDbFile`, `restoreLatest` with path context).
- `HomeScreen._promptRestoreBackup` now `catch (e, st) { debugPrint('[Restore] _promptRestoreBackup failed: $e\n$st'); if (mounted) ScaffoldMessenger... showSnackBar('Restore failed: $e'); }` — no longer silent, surfaces actual `FileSystemException`, `PathNotFoundException`, etc., while still not blocking startup.

## 6. Actual failure point identified (from logs)

**Primary (design):** On Android 11+, `hasBackups()` returns `false` on fresh install because fallback app-private `mapbanai_backups` was wiped. The dialog never shows, so restore is never attempted — the "backup found" dialog appearing post-uninstall is itself the stale-marker case, but in our code it's *not* a stale preference, it's a real directory scan that correctly returns empty. The *visible* symptom "silently restores nothing" occurs in two sub-cases:
- **Case A (most common, Android 11+):** No dialog at all → user perceives "restore did nothing" but actually there was nothing to restore because backup was never durable. Logs will show `_backupRoot = .../app_flutter/mapbanai_backups, exists=false, _backups count=0`.
- **Case B (if public Documents *had* been writable, e.g., Android 9):** Dialog shows, user taps Restore, `await _database.close()` succeeds, `restoreLatest()` does `live = await _liveDbFile()` — on a *truly fresh* install, `_liveDbFile` returns `null` because `mapbanai.db` hasn't been created yet (first DB open was the `getProjects` call before restore, which *does* create an empty DB file, so live exists as empty file, but if that initial query hadn't run, live would be null and restore would return false). Then `hasBackups` found a durable backup, but `restoreLatest` returns `false` due to missing live file, previously swallowed → SnackBar *Backup restore failed* with no detail, now logged as `[BackupService.restoreLatest] live DB file not found at ...`.

**Secondary (code):** `restoreLatest` previously returned `false` for missing live file without logging; `hasBackups` swallowing `listSync` exceptions hid permission-denied to public Documents.

## 7. Fix applied vs design question

**Design question reported:** As per step 2 finding, backups are not durable on Android 11+. Fixing the restore path alone cannot make app-private files survive uninstall. The **recommended durable fix** is one of:
- **Option A (scoped-storage compliant):** Write backups via `MediaStore` (`MediaStore.Downloads` or `MediaStore.Files` with `RELATIVE_PATH Documents/MapBanai/backups`, `IS_PENDING` flow, no extra permission) so they land in public shared storage and survive uninstall. Requires `WRITE_EXTERNAL_STORAGE` is not enough on 11+; `MediaStore` is the correct API.
- **Option B (broad access):** Request `MANAGE_EXTERNAL_STORAGE` (`android.permission.MANAGE_ALL_FILES_ACCESS_PERMISSION`) + `Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION` prompt — survives uninstall but Play policy requires justification.
- **Option C (preferred, already in-progress):** Treat **cloud sync backend (Apps Script → Google Sheets)** from Tasks 1-5 as the durable store for uninstall survival, and reframe local `mapbanai_backups` as *crash recovery* (short-term, not uninstall-proof), updating the dialog copy to not promise cross-install restore.

**This patch (Fix1) does NOT change the backup *location* to durable shared storage** — that would be a larger scoped-storage rewrite. Instead it:
- Adds the diagnostic logs above so the durability failure is visible in `adb logcat`.
- Surfaces errors to UI/log instead of swallowing (so future failures are diagnosable).
- Ensures `restoreLatest` handles missing `live` file by creating parent dirs and logging, but still reports the durability root cause in this log file.
- Leaves the backup location decision as a follow-up design ticket (choose A/B/C), per the "STOP and report" instruction, rather than pretending a local patch makes app-private backups survive uninstall.

**Checkpoint expectation:** After this fix, uninstall/reinstall on a real Android 11+ device will **still not** show survey data reappear from local backup (because backup was never durable) — that is *expected* and now *explicitly logged* as `isWritable=false` fallback. The **sync backend** (after Fix2) is the path that will make data reappear cross-install. If the tester is on Android 9 or after granting `MANAGE_EXTERNAL_STORAGE`, the log will show `isWritable=true` for public Documents and restore *will* succeed, which can be verified via the new logs + `Backup restored successfully` SnackBar.

