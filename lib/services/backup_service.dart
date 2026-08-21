import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Data-retention safety net.
///
/// Periodically snapshots the local MapBanai database (projects, stored
/// forms, survey responses, GPS logs, attribute fields and app settings all
/// live in `mapbanai.db`) into a backup folder. The backup is written to the
/// public Documents folder when the OS allows it (so it survives an
/// uninstall), otherwise to the app documents folder.
///
/// A fresh install can detect a previous backup and offer to restore it.
/// The snapshot is produced with SQLite `VACUUM INTO`, which is safe with
/// WAL mode and yields a consistent copy of the live database.
class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  static const String _relativePath = 'MapBanai/backups';
  static const int _keepNewest = 6;

  /// Candidates for the backup root, most preferable first. The first
  /// writable directory wins. On Android the public Documents folder
  /// survives app uninstalls; everything else falls back to app-private
  /// storage.
  Future<Directory> _backupRoot() async {
    // Public Documents survives app uninstalls on Android, so the backup
    // lives there when the OS allows direct access; the candidate is only
    // meaningful on Android (a literal POSIX path is garbage elsewhere).
    final candidates = <Directory>[
      if (Platform.isAndroid)
        Directory('/storage/emulated/0/Documents/$_relativePath'),
    ];
    for (final candidate in candidates) {
      try {
        await candidate.create(recursive: true);
        final writable = await _isWritable(candidate);
        debugPrint(
            '[BackupService._backupRoot] candidate=${candidate.path} writable=$writable');
        if (writable) return candidate;
      } catch (e, st) {
        debugPrint(
            '[BackupService._backupRoot] candidate=${candidate.path} failed: $e\n$st');
      }
    }
    final docs = await getApplicationDocumentsDirectory();
    final fallback = Directory(p.join(docs.path, 'mapbanai_backups'));
    await fallback.create(recursive: true);
    debugPrint('[BackupService._backupRoot] fallback=${fallback.path}');
    return fallback;
  }

  static Future<bool> _isWritable(Directory dir) async {
    final probe = File(p.join(dir.path, '.probe'));
    try {
      await probe.writeAsString('ok');
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<File?> _liveDbFile() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(p.join(docs.path, 'mapbanai.db'));
      final exists = file.existsSync();
      debugPrint('[BackupService._liveDbFile] path=${file.path} exists=$exists');
      return exists ? file : null;
    } catch (e, st) {
      debugPrint('[BackupService._liveDbFile] failed: $e\n$st');
      return null;
    }
  }

  /// Writes a new timestamped backup. Returns the backup folder path, or
  /// null when the backup could not be created.
  Future<String?> createBackup() async {
    try {
      final root = await _backupRoot();
      final dir = Directory(p.join(root.path, _stamp()));
      await dir.create(recursive: true);

      final snapshot = File(p.join(dir.path, 'mapbanai.db'));
      var snapshotOk = await _vacuumInto(snapshot.path);
      if (!snapshotOk) {
        final live = await _liveDbFile();
        if (live == null) {
          debugPrint('[BackupService.createBackup] live DB not found, aborting');
          await dir.delete(recursive: true);
          return null;
        }
        await live.copy(snapshot.path);
        snapshotOk = snapshot.existsSync();
      }
      if (!snapshotOk) {
        debugPrint('[BackupService.createBackup] snapshot failed for ${snapshot.path}');
        await dir.delete(recursive: true);
        return null;
      }

      final rows = await _database.select(_database.appSettings).get();
      await File(p.join(dir.path, 'prefs.json')).writeAsString(
        jsonEncode({for (final row in rows) row.key: row.value}),
      );
      await File(p.join(dir.path, 'meta.json')).writeAsString(
        jsonEncode({
          'app': 'mapbanai',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'backup_version': 1,
        }),
      );

      await _pruneOld(root);
      debugPrint('[BackupService.createBackup] success dir=${dir.path}');
      return dir.path;
    } catch (e, st) {
      debugPrint('[BackupService.createBackup] failed: $e\n$st');
      return null;
    }
  }

  Future<bool> _vacuumInto(String destinationPath) async {
    final escaped = destinationPath.replaceAll("'", "''");
    try {
      await _database.customStatement("VACUUM INTO '$escaped'");
      return File(destinationPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<List<Directory>> _backups() async {
    try {
      final root = await _backupRoot();
      debugPrint('[BackupService._backups] scanning root=${root.path}');
      final dirs = root
          .listSync(followLinks: false)
          .whereType<Directory>()
          .where((d) => File(p.join(d.path, 'mapbanai.db')).existsSync())
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      debugPrint('[BackupService._backups] found ${dirs.length} backups');
      return dirs;
    } catch (e, st) {
      debugPrint('[BackupService._backups] failed: $e\n$st');
      return const [];
    }
  }

  Future<void> _pruneOld(Directory root) async {
    try {
      final dirs = root
          .listSync(followLinks: false)
          .whereType<Directory>()
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final dir in dirs.skip(_keepNewest)) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Pruning is best-effort.
    }
  }

  /// Whether at least one previous backup exists that could be restored.
  Future<bool> hasBackups() async => (await _backups()).isNotEmpty;

  /// The newest backup folder, if any.
  Future<Directory?> newestBackup() async {
    final backups = await _backups();
    return backups.isEmpty ? null : backups.first;
  }

  /// Restores the newest backup by replacing the live database file.
  ///
  /// The caller must not use any open database connection during the copy —
  /// close [AppDatabase] instances first and open a fresh one afterwards.
  /// Returns true when the snapshot file was copied.
  Future<bool> restoreLatest() async {
    final latest = await newestBackup();
    debugPrint(
        '[BackupService.restoreLatest] latest=${latest?.path} exists=${latest != null ? Directory(latest.path).existsSync() : false}');
    if (latest == null) {
      debugPrint('[BackupService.restoreLatest] no backup found');
      return false;
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final livePath = p.join(docs.path, 'mapbanai.db');
      final liveFile = File(livePath);
      debugPrint(
          '[BackupService.restoreLatest] livePath=$livePath exists=${liveFile.existsSync()} latestDb=${p.join(latest.path, 'mapbanai.db')}');
      // Ensure parent dir exists for fresh installs where DB file hasn't been created yet
      await Directory(p.dirname(livePath)).create(recursive: true);
      await File(p.join(latest.path, 'mapbanai.db')).copy(livePath);
      debugPrint('[BackupService.restoreLatest] copy succeeded');
      return true;
    } catch (e, st) {
      debugPrint('[BackupService.restoreLatest] failed: $e\n$st');
      return false;
    }
  }

  static String _stamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}