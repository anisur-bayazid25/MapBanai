import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Independent screen handles share one SQL executor and migration sequence.
/// Closing a screen releases its client, never another screen's database.
class SharedDatabaseLease {
  static _DatabaseHost? _current;
  static Future<void> _draining = Future.value();
  final _DatabaseHost _host;
  late final Future<DatabaseConnection> connection = _host.connect();
  bool _released = false;

  SharedDatabaseLease._(this._host) {
    _host.clients++;
  }

  static SharedDatabaseLease acquire() =>
      SharedDatabaseLease._(_current ??= _DatabaseHost(_draining));

  Future<void> release() async {
    if (_released) return;
    _released = true;
    try {
      // This also closes a connected client that never executed a query.
      // Drift's remote executor close is idempotent.
      await (await connection).close();
    } finally {
      if (--_host.clients == 0) {
        if (identical(_current, _host)) _current = null;
        // New handles wait until the old SQLite file is fully closed. Restore
        // can therefore replace files after all owning handles close.
        await (_draining = _host.shutdown().onError((error, stack) {
          // A failed open must not poison later connection attempts.
        }));
      }
    }
  }
}

class _DatabaseHost {
  final Future<void> previousShutdown;
  int clients = 0;
  Future<DriftIsolate>? _opening;
  _DatabaseHost(this.previousShutdown);

  Future<DatabaseConnection> connect() async =>
      (await (_opening ??= _open())).connect();

  Future<DriftIsolate> _open() async {
    await previousShutdown;
    final folder = await getApplicationDocumentsDirectory();
    return _spawnDatabase(p.join(folder.path, 'mapbanai.db'));
  }

  Future<void> shutdown() async {
    final opening = _opening;
    if (opening != null) await (await opening).shutdownAll();
  }
}

// Capture only the path in the isolate opener, not the pool or UI state.
Future<DriftIsolate> _spawnDatabase(String path) =>
    DriftIsolate.spawn(() => NativeDatabase(File(path), setup: (db) {
          db.execute('PRAGMA busy_timeout = 5000');
        }));
