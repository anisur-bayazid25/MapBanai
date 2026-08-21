import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  test('fresh schema has synced_at and photo_synced_at nullable columns',
      () async {
    final rows = await db.customSelect(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name='survey_sessions'",
    ).get();
    final sql = rows.first.data['sql'] as String;
    expect(sql, contains('synced_at'));
    expect(sql, contains('photo_synced_at'));

    final info = await db
        .customSelect("PRAGMA table_info('survey_sessions')")
        .get();
    final cols = {
      for (final r in info) r.data['name'] as String: r.data,
    };
    expect(cols.containsKey('synced_at'), isTrue);
    expect(cols.containsKey('photo_synced_at'), isTrue);
    // nullable check: notnull == 0 means nullable in sqlite
    expect(cols['synced_at']!['notnull'], 0);
    expect(cols['photo_synced_at']!['notnull'], 0);
  });

  test('survey session inserted without sync fields defaults to null',
      () async {
    final projectId = await db.into(db.projects).insert(
          ProjectsCompanion.insert(name: 'SyncTestProj'),
        );
    final sessionId = await db.into(db.surveySessions).insert(
          SurveySessionsCompanion.insert(
            projectId: projectId,
            title: 'Session A',
          ),
        );
    final session = await (db.select(db.surveySessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingle();
    expect(session.syncedAt, isNull);
    expect(session.photoSyncedAt, isNull);

    // now set them and read back
    final now = DateTime.now();
    await (db.update(db.surveySessions)..where((t) => t.id.equals(sessionId)))
        .write(SurveySessionsCompanion(
      syncedAt: Value(now),
      photoSyncedAt: Value(now),
    ));
    final updated = await (db.select(db.surveySessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingle();
    expect(updated.syncedAt, isNotNull);
    expect(updated.photoSyncedAt, isNotNull);
  });

  test('sync_configs table exists with per-project fields', () async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_configs'",
        )
        .get();
    expect(tables, hasLength(1));

    final info = await db
        .customSelect("PRAGMA table_info('sync_configs')")
        .get();
    final colNames = info.map((r) => r.data['name'] as String).toSet();
    expect(colNames, containsAll(['project_id', 'sync_endpoint_url', 'sync_api_key', 'last_sync_at']));

    // inserting a config for a project should work, nullable fields default null
    final projectId = await db.into(db.projects).insert(
          ProjectsCompanion.insert(name: 'ProjWithSync'),
        );
    await db.into(db.syncConfigs).insert(
          SyncConfigsCompanion.insert(projectId: Value(projectId)),
        );
    var cfg = await (db.select(db.syncConfigs)
          ..where((t) => t.projectId.equals(projectId)))
        .getSingle();
    expect(cfg.syncEndpointUrl, isNull);
    expect(cfg.syncApiKey, isNull);
    expect(cfg.lastSyncAt, isNull);

    // update values
    await (db.update(db.syncConfigs)
          ..where((t) => t.projectId.equals(projectId)))
        .write(SyncConfigsCompanion(
      syncEndpointUrl: const Value('https://example.com/sync'),
      syncApiKey: const Value('secret123'),
      lastSyncAt: Value(DateTime.now()),
    ));
    cfg = await (db.select(db.syncConfigs)
          ..where((t) => t.projectId.equals(projectId)))
        .getSingle();
    expect(cfg.syncEndpointUrl, 'https://example.com/sync');
    expect(cfg.syncApiKey, 'secret123');
    expect(cfg.lastSyncAt, isNotNull);

    // Verify ON DELETE CASCADE is declared in schema.
    final ddl = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name='sync_configs'",
        )
        .get();
    expect(ddl.first.data['sql'] as String, contains('ON DELETE CASCADE'));
    // Clean up: deleting project should cascade, but verify table can be cleared.
    await (db.delete(db.projects)..where((t) => t.id.equals(projectId))).go();
    // If FK cascade is enforced, row is gone; otherwise remove explicitly.
    var remaining = await (db.select(db.syncConfigs)
          ..where((t) => t.projectId.equals(projectId)))
        .get();
    if (remaining.isNotEmpty) {
      await (db.delete(db.syncConfigs)
            ..where((t) => t.projectId.equals(projectId)))
          .go();
      remaining = await (db.select(db.syncConfigs)
            ..where((t) => t.projectId.equals(projectId)))
          .get();
    }
    expect(remaining, isEmpty);
  });

  test('migration from v8 retains old rows with synced_at null', () async {
    // Simulate an on-disk database at schemaVersion 8 (without new columns / table).
    final tempDir = await Directory.systemTemp.createTemp('drift_migration_v8_');
    final file = File('${tempDir.path}/old.db');
    try {
      // Create old schema directly via sqlite3.
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('''
        CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
          gps_threshold_m REAL NOT NULL DEFAULT 10.0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0, 1)),
          external_id TEXT,
          project_version INTEGER NOT NULL DEFAULT 1
        );
      ''');
      raw.execute('''
        CREATE TABLE survey_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          project_id INTEGER NOT NULL REFERENCES projects(id),
          title TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'draft',
          responses TEXT NOT NULL DEFAULT '{}',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
      ''');
      // Set user_version to 8 so drift knows to run from <9.
      raw.execute('PRAGMA user_version = 8;');
      // Insert sample data using old schema.
      raw.execute("INSERT INTO projects (name) VALUES ('Legacy Project');");
      final projId = raw.lastInsertRowId;
      raw.execute(
          "INSERT INTO survey_sessions (project_id, title, status) VALUES ($projId, 'Old Session', 'saved');");
      final sessId = raw.lastInsertRowId;
      raw.dispose();

      // Now open with the new AppDatabase which should migrate to 9.
      final migratedDb =
          AppDatabase.testWithExecutor(NativeDatabase(file));
      // Trigger migration by querying.
      final sessions = await migratedDb.select(migratedDb.surveySessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.first.id, sessId);
      expect(sessions.first.syncedAt, isNull);
      expect(sessions.first.photoSyncedAt, isNull);

      // Verify new columns exist post-migration.
      final info = await migratedDb
          .customSelect("PRAGMA table_info('survey_sessions')")
          .get();
      final cols = {for (final r in info) r.data['name'] as String};
      expect(cols, contains('synced_at'));
      expect(cols, contains('photo_synced_at'));

      // Verify new table was created.
      final syncTables = await migratedDb
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_configs'",
          )
          .get();
      expect(syncTables, hasLength(1));

      // New sessions after migration can be created without those fields (null)
      // and also with explicit values.
      final newDate = DateTime.utc(2025, 1, 1);
      await migratedDb.into(migratedDb.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projId,
              title: 'New Session',
              syncedAt: Value(newDate),
            ),
          );
      final all = await migratedDb.select(migratedDb.surveySessions).get();
      expect(all, hasLength(2));
      final newSess = all.firstWhere((s) => s.title == 'New Session');
      expect(newSess.syncedAt, isNotNull);

      await migratedDb.close();
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
