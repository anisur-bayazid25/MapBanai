import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

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

  Future<String?>? _activeBackup;
  static const _assetFolders = ['photos', 'gps_logs', 'study_area'];

  /// Concurrent requests share one snapshot. A failed snapshot is never published.
  Future<String?> createBackup() {
    final current = _activeBackup;
    if (current != null) return current;
    final future = _createBackup();
    _activeBackup = future;
    return future.whenComplete(() => _activeBackup = null);
  }

  Future<String?> _createBackup() async {
    Directory? staging;
    try {
      final root = await _backupRoot();
      final name = '${_stamp()}_${DateTime.now().microsecondsSinceEpoch}';
      staging = Directory(p.join(root.path, '$name.partial'));
      await staging.create();
      final snapshot = File(p.join(staging.path, 'mapbanai.db'));
      // Never copy a live SQLite main file: committed rows may be in its WAL.
      if (!await _vacuumInto(snapshot.path)) {
        throw StateError('Could not produce a consistent database snapshot');
      }
      _checkDatabase(snapshot.path);
      final docs = await getApplicationDocumentsDirectory();
      for (final name in _assetFolders) {
        final source = Directory(p.join(docs.path, name));
        if (await source.exists()) {
          await _copyDirectory(source, Directory(p.join(staging.path, name)));
        }
      }
      final rows = await _database.select(_database.appSettings).get();
      await File(p.join(staging.path, 'prefs.json')).writeAsString(
        jsonEncode({for (final row in rows) row.key: row.value}),
        flush: true,
      );
      final files = <String, String>{};
      await for (final file
          in staging.list(recursive: true, followLinks: false)) {
        if (file is File) {
          files[p
                  .relative(file.path, from: staging.path)
                  .replaceAll('\\', '/')] =
              (await sha256.bind(file.openRead()).first).toString();
        }
      }
      await File(p.join(staging.path, 'meta.json')).writeAsString(
        jsonEncode({
          'app': 'mapbanai',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'backup_version': 2,
          'documents_path': docs.path,
          'asset_folders': _assetFolders,
          'files': files,
        }),
        flush: true,
      );
      final published = await staging.rename(p.join(root.path, name));
      staging = null;
      await _pruneOld(root);
      return published.path;
    } catch (e) {
      debugPrint('[BackupService] backup failed: $e');
      return null;
    } finally {
      if (staging != null && await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  static void _checkDatabase(String path) {
    final connection = sqlite.sqlite3.open(path);
    try {
      final result = connection.select('PRAGMA integrity_check');
      if (result.length != 1 || result.first.values.first != 'ok') {
        throw StateError('Backup database is damaged');
      }
    } finally {
      connection.dispose();
    }
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final destination = p.join(target.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
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
          .where((d) =>
              !d.path.endsWith('.partial') &&
              File(p.join(d.path, 'mapbanai.db')).existsSync())
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
          .where((d) =>
              !d.path.endsWith('.partial') &&
              File(p.join(d.path, 'meta.json')).existsSync())
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
    if (latest == null) return false;
    Directory? staging;
    bool cleanupStaging = true;
    final movedAside = <String, String>{};
    final installed = <String>[];
    try {
      final docs = await getApplicationDocumentsDirectory();
      await docs.create(recursive: true);
      staging = Directory(p.join(
          docs.path, '.restore-${DateTime.now().microsecondsSinceEpoch}'));
      await staging.create();
      final stagedDb = File(p.join(staging.path, 'mapbanai.db'));
      await File(p.join(latest.path, 'mapbanai.db')).copy(stagedDb.path);
      _checkDatabase(stagedDb.path);
      Map<String, dynamic> meta = {};
      final metadata = File(p.join(latest.path, 'meta.json'));
      if (metadata.existsSync()) {
        meta = (jsonDecode(await metadata.readAsString()) as Map)
            .cast<String, dynamic>();
      }
      final version = (meta['backup_version'] as num?)?.toInt() ?? 1;
      if (version > 2) throw StateError('Unsupported backup version');
      final names = <String>['mapbanai.db'];
      if (version == 2) {
        final checksums = meta['files'];
        if (checksums is! Map || !checksums.containsKey('mapbanai.db')) {
          throw StateError('Backup file manifest is missing');
        }
        for (final entry in checksums.entries) {
          final path = p.normalize(p.join(latest.path, entry.key.toString()));
          if (!p.isWithin(latest.path, path))
            throw StateError('Invalid backup file path');
          final file = File(path);
          if (!file.existsSync() ||
              (await sha256.bind(file.openRead()).first).toString() !=
                  entry.value) {
            throw StateError('Backup file is missing or damaged: ${entry.key}');
          }
        }

        for (final name in _assetFolders) {
          final source = Directory(p.join(latest.path, name));
          final target = Directory(p.join(staging.path, name));
          if (source.existsSync()) {
            await _copyDirectory(source, target);
          } else {
            await target.create();
          }
          names.add(name);
        }
        _remapPhotoPaths(
            stagedDb.path, meta['documents_path'] as String?, docs.path);
        // Photo sidecars and visit revision histories contain attachment paths.
        for (final folder in _assetFolders) {
          final assets = Directory(p.join(staging.path, folder));
          await for (final file
              in assets.list(recursive: true, followLinks: false)) {
            if (file is File && file.path.endsWith('.json')) {
              final decoded = jsonDecode(await file.readAsString());
              await file.writeAsString(
                  jsonEncode(_remapValue(
                      decoded, meta['documents_path'] as String?, docs.path)),
                  flush: true);
            }
          }
        }
      }
      // All connections must be closed by the caller before replacement.
      for (final name in [...names, 'mapbanai.db-wal', 'mapbanai.db-shm']) {
        final destination = p.join(docs.path, name);
        if (FileSystemEntity.typeSync(destination) !=
            FileSystemEntityType.notFound) {
          final rollback = p.join(staging.path, 'old-$name');
          if (Directory(destination).existsSync()) {
            await Directory(destination).rename(rollback);
          } else {
            await File(destination).rename(rollback);
          }
          movedAside[destination] = rollback;
        }
      }
      for (final name in names) {
        final destination = p.join(docs.path, name);
        final source = p.join(staging.path, name);
        if (_assetFolders.contains(name)) {
          await Directory(source).rename(destination);
        } else {
          await File(source).rename(destination);
        }
        installed.add(destination);
      }
      return true;
    } catch (e) {
      debugPrint('[BackupService] restore failed: $e');
      // If any rollback step fails, retain every recovery file in staging.
      cleanupStaging = false;
      var rollbackOk = true;
      for (final destination in installed.reversed) {
        try {
          if (Directory(destination).existsSync()) {
            await Directory(destination).delete(recursive: true);
          } else if (File(destination).existsSync()) {
            await File(destination).delete();
          }
        } catch (rollbackError) {
          rollbackOk = false;
          debugPrint(
              '[BackupService] Could not remove partial restore: $rollbackError');
        }
      }
      for (final entry in movedAside.entries) {
        try {
          if (Directory(entry.value).existsSync()) {
            await Directory(entry.value).rename(entry.key);
          } else if (File(entry.value).existsSync()) {
            await File(entry.value).rename(entry.key);
          }
        } catch (rollbackError) {
          rollbackOk = false;
          debugPrint(
              '[BackupService] Original data kept for recovery in ${staging?.path}: $rollbackError');
        }
      }
      cleanupStaging = rollbackOk;
      return false;
    } finally {
      if (cleanupStaging && staging != null && await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  static dynamic _remapValue(dynamic value, String? oldRoot, String newRoot) {
    if (value is Map) {
      return value.map(
          (key, item) => MapEntry(key, _remapValue(item, oldRoot, newRoot)));
    }
    if (value is List) {
      return value.map((v) => _remapValue(v, oldRoot, newRoot)).toList();
    }
    if (value is String) {
      if (oldRoot != null &&
          (value.startsWith('$oldRoot/') || value.startsWith('$oldRoot\\'))) {
        return p.join(newRoot, value.substring(oldRoot.length + 1));
      }
      // Survey photo answers may themselves be JSON encoded strings.
      if (value.trimLeft().startsWith('{')) {
        try {
          return jsonEncode(_remapValue(jsonDecode(value), oldRoot, newRoot));
        } catch (_) {}
      }
    }
    return value;
  }

  static void _remapPhotoPaths(String dbPath, String? oldRoot, String newRoot) {
    if (oldRoot == null || oldRoot == newRoot) return;
    final connection = sqlite.sqlite3.open(dbPath);
    try {
      final rows =
          connection.select('SELECT id, responses FROM survey_sessions');
      for (final row in rows) {
        final decoded = jsonDecode(row['responses'] as String);
        connection.execute(
            'UPDATE survey_sessions SET responses = ? WHERE id = ?',
            [jsonEncode(_remapValue(decoded, oldRoot, newRoot)), row['id']]);
      }
    } finally {
      connection.dispose();
    }
  }

  static String _stamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
