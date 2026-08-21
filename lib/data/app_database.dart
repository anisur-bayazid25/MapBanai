import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  RealColumn get gpsThresholdM => real().withDefault(const Constant(10))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  /// Stable cross-device project identity used by the .mbproj package
  /// format. Null on databases migrated to schema 8 before any project was
  /// created; created/imported projects always get a value.
  TextColumn get externalId => text().nullable()();
  /// Project definition version; preserved across export/import.
  IntColumn get projectVersion => integer().withDefault(const Constant(1))();
}

class SurveySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(Projects, #id)();
  TextColumn get title => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get responses => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get photoSyncedAt => dateTime().nullable()();
  /// Stable cross-device identity for sync deduplication. Generated once at
  /// creation time (UUID v4), not at sync time, and preserved via .mbproj
  /// if sessions were ever exported.
  TextColumn get externalId => text().nullable()();
}

class StoredForms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get json => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class GpsLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get surveyor => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// User-defined attribute fields attached to a project. These show up in the
/// GIS data-collection sheet so each captured feature can carry the project's
/// custom attributes (e.g. material, condition).
class ProjectFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(Projects, #id)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Per-project sync configuration (endpoint + shared-secret token).
/// One row per project — `projectId` is the primary key and cascades on
/// project delete. Stored as-is, no encryption (shared-secret token).
class SyncConfigs extends Table {
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get syncEndpointUrl => text().nullable()();
  TextColumn get syncApiKey => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {projectId};
}

@DriftDatabase(tables: [
  Projects,
  SurveySessions,
  StoredForms,
  AppSettings,
  GpsLogs,
  ProjectFields,
  SyncConfigs,
])
class AppDatabase extends _$AppDatabase {
  /// Test hook: use a same-isolate file connection instead of opening the
  /// database on a background isolate. Background-isolate responses are not
  /// delivered reliably inside widget tests' FakeAsync zone, so screens
  /// constructed in tests can share the on-disk database only with this on.
  static bool useInProcessFileForTesting = false;

  AppDatabase()
      : super(useInProcessFileForTesting
            ? _openInProcessConnection()
            : _openConnection());

  @visibleForTesting
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @visibleForTesting
  AppDatabase.testWithExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(surveySessions, surveySessions.responses);
      }
      if (from < 3) {
        await migrator.createTable(storedForms);
      }
      if (from < 4) {
        await customStatement('DROP TABLE IF EXISTS field_tasks');
        await migrator.createTable(appSettings);
        await migrator.createTable(gpsLogs);
      }
      if (from < 5) {
        await migrator.addColumn(projects, projects.description);
        await migrator.addColumn(projects, projects.archived);
        await migrator.addColumn(projects, projects.gpsThresholdM);
      }
      if (from < 6) {
        await migrator.createTable(projectFields);
      }
      if (from < 7) {
        await migrator.addColumn(storedForms, storedForms.projectId);
        // Attach legacy (globally shared) forms to the active project so
        // every project becomes independent going forward.
        await customStatement(
          'UPDATE stored_forms SET project_id = '
          '(SELECT id FROM projects WHERE is_active = 1 LIMIT 1) '
          'WHERE project_id IS NULL;'
          'UPDATE stored_forms SET project_id = '
          '(SELECT id FROM projects ORDER BY id LIMIT 1) '
          'WHERE project_id IS NULL;',
        );
      }
      if (from < 8) {
        await migrator.addColumn(projects, projects.externalId);
        await migrator.addColumn(projects, projects.projectVersion);
        // Backfill stable ids for existing projects.
        final existing = await select(projects).get();
        for (final project in existing) {
          if (project.externalId == null) {
            await (update(projects)..where((row) => row.id.equals(project.id)))
                .write(
              ProjectsCompanion(externalId: Value(const Uuid().v4())),
            );
          }
        }
      }
      if (from < 9) {
        await migrator.addColumn(surveySessions, surveySessions.syncedAt);
        await migrator.addColumn(surveySessions, surveySessions.photoSyncedAt);
        await migrator.createTable(syncConfigs);
      }
      if (from < 10) {
        await migrator.addColumn(surveySessions, surveySessions.externalId);
        final existing = await select(surveySessions).get();
        for (final row in existing) {
          if (row.externalId == null) {
            await (update(surveySessions)..where((t) => t.id.equals(row.id)))
                .write(
              SurveySessionsCompanion(externalId: Value(const Uuid().v4())),
            );
          }
        }
      }
    },
  );

  Future<List<Project>> getProjects({bool includeArchived = false}) {
    final query = select(projects)
      ..orderBy([(project) => OrderingTerm.asc(project.name)]);
    if (!includeArchived) {
      query.where((row) => row.archived.equals(false));
    }
    return query.get();
  }

  Future<Project?> getProjectByName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;
    final matches = await (select(projects)
          ..where((row) => row.name.equals(cleanName))
          ..orderBy([(row) => OrderingTerm(expression: row.id)]))
        .get();
    // Names are not unique: a "new copy" import intentionally duplicates a
    // project under a fresh identity. Return the earliest-created match.
    return matches.isEmpty ? null : matches.first;
  }

  Future<Project?> getProjectById(int id) async {
    return (select(projects)..where((row) => row.id.equals(id)))
        .getSingleOrNull();
  }

  Future<bool> projectExists(String name) async {
    return await getProjectByName(name.trim()) != null;
  }

  /// Finds a project by its stable cross-device identity.
  Future<Project?> getProjectByExternalId(String externalId) async {
    final clean = externalId.trim();
    if (clean.isEmpty) return null;
    return (select(projects)..where((row) => row.externalId.equals(clean)))
        .getSingleOrNull();
  }

  /// Whether a project with this stable identity (or exactly this name)
  /// already exists on the device.
  Future<Project?> findProjectConflict({
    required String? externalId,
    required String name,
  }) async {
    if (externalId != null && externalId.trim().isNotEmpty) {
      final byExternal = await getProjectByExternalId(externalId);
      if (byExternal != null) return byExternal;
    }
    return getProjectByName(name);
  }

  Future<int> insertProject(ProjectsCompanion entry) => into(projects).insert(entry);

  Future<int> insertSurveySession(SurveySessionsCompanion entry) {
    final withExternalId = entry.externalId.present
        ? entry
        : entry.copyWith(externalId: Value(const Uuid().v4()));
    return into(surveySessions).insert(withExternalId);
  }

  Future<List<SurveySession>> getSurveySessions() {
    return (select(surveySessions)
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<List<SurveySession>> getSurveySessionsByProject(int projectId) {
    return (select(surveySessions)
          ..where((row) => row.projectId.equals(projectId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  /// Draft sessions (in-progress surveys / features) across all projects,
  /// newest first.
  Future<List<SurveySession>> getDraftSurveySessions() {
    return (select(surveySessions)
          ..where((row) => row.status.equals('draft'))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<SurveySession?> getSurveySession(int id) async {
    return (select(surveySessions)..where((row) => row.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateSurveySession(
    int id, {
    String? title,
    String? status,
    String? responses,
  }) async {
    await (update(surveySessions)..where((row) => row.id.equals(id))).write(
      SurveySessionsCompanion(
        title: title == null ? const Value.absent() : Value(title),
        status: status == null ? const Value.absent() : Value(status),
        responses: responses == null
            ? const Value.absent()
            : Value(responses),
      ),
    );
  }

  Future<void> deleteSurveySession(int id) =>
      (delete(surveySessions)..where((row) => row.id.equals(id))).go();

  /// Deletes a project together with all its survey sessions/features,
  /// attribute fields, stored forms and sync config.
  Future<void> deleteProject(int id) async {
    await (delete(surveySessions)..where((row) => row.projectId.equals(id))).go();
    await (delete(projectFields)..where((row) => row.projectId.equals(id))).go();
    await (delete(storedForms)..where((row) => row.projectId.equals(id))).go();
    await (delete(syncConfigs)..where((row) => row.projectId.equals(id))).go();
    await (delete(projects)..where((row) => row.id.equals(id))).go();
  }

  Future<List<String>> getProjectNames({bool includeArchived = false}) async {
    final items = await getProjects(includeArchived: includeArchived);
    return items.map((project) => project.name).toList();
  }

  Future<int?> getProjectIdByName(String name) async {
    final project = await getProjectByName(name);
    return project?.id;
  }

  Future<void> createProject(
    String name, {
    String description = '',
    double gpsThresholdM = 10,
  }) async {
    if (name.trim().isEmpty) return;

    final project = ProjectsCompanion(
      name: Value(name.trim()),
      description: Value(description.trim()),
      gpsThresholdM: Value(gpsThresholdM),
      isActive: const Value(true),
      externalId: Value(const Uuid().v4()),
    );

    await insertProject(project);
  }

  /// Inserts a complete project definition (used by the .mbproj importer).
  /// `isActive` is always false so an imported project never hijacks the
  /// current selection; the user picks it explicitly.
  Future<int> insertImportedProject(
    String name, {
    required String externalId,
    String description = '',
    double gpsThresholdM = 10,
    DateTime? createdAt,
    bool archived = false,
    int projectVersion = 1,
  }) =>
      into(projects).insert(
        ProjectsCompanion(
          name: Value(name.trim()),
          description: Value(description.trim()),
          gpsThresholdM: Value(gpsThresholdM),
          archived: Value(archived),
          createdAt: Value(createdAt ?? DateTime.now()),
          isActive: const Value(false),
          externalId: Value(externalId),
          projectVersion: Value(projectVersion),
        ),
      );

  Future<void> updateProject(
    int id, {
    String? name,
    String? description,
    double? gpsThresholdM,
    bool? archived,
  }) async {
    await (update(projects)..where((row) => row.id.equals(id))).write(
      ProjectsCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        description: description == null
            ? const Value.absent()
            : Value(description.trim()),
        gpsThresholdM: gpsThresholdM == null
            ? const Value.absent()
            : Value(gpsThresholdM),
        archived: archived == null ? const Value.absent() : Value(archived),
      ),
    );
  }

  Future<void> archiveProject(int id, {required bool archived}) =>
      updateProject(id, archived: archived);

  Future<int> surveySessionCountForProject(int projectId) async {
    final count = surveySessions.id.count();
    final query = selectOnly(surveySessions)
      ..addColumns([count])
      ..where(
        surveySessions.projectId.equals(projectId) &
            surveySessions.status.equals('draft').not(),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Counts of collected data for a project: (survey responses, GIS features).
  /// A session counts as a GIS feature when its responses JSON contains a
  /// `feature_type` key. Drafts are not collected data.
  Future<({int survey, int gis})> responseCountsForProject(int projectId) async {
    final count = surveySessions.id.count();
    final totalQuery = selectOnly(surveySessions)
      ..addColumns([count])
      ..where(
        surveySessions.projectId.equals(projectId) &
            surveySessions.status.equals('draft').not(),
      );
    final total = (await totalQuery.getSingle()).read(count) ?? 0;

    final gisQuery = selectOnly(surveySessions)
      ..addColumns([count])
      ..where(
        surveySessions.projectId.equals(projectId) &
            surveySessions.status.equals('draft').not() &
            surveySessions.responses.like('%feature_type%'),
      );
    final gis = (await gisQuery.getSingle()).read(count) ?? 0;

    return (survey: total - gis, gis: gis);
  }

  // ── Stored survey forms ──────────────────────────────────────

  Future<int> insertStoredForm(StoredFormsCompanion entry) =>
      into(storedForms).insert(entry);

  Future<List<StoredForm>> getStoredForms() {
    return (select(storedForms)
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
  }

  /// Forms that belong to a single project. Each project has its own forms;
  /// created forms are never shared between projects.
  Future<List<StoredForm>> getStoredFormsForProject(int projectId) {
    return (select(storedForms)
          ..where((row) => row.projectId.equals(projectId))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
  }

  Future<StoredForm?> getStoredFormByName(String name, {int? projectId}) async {
    final projectFilter = projectId;
    if (projectFilter != null) {
      return (select(storedForms)
            ..where(
              (row) =>
                  row.name.equals(name) & row.projectId.equals(projectFilter),
            ))
          .getSingleOrNull();
    }
    return (select(storedForms)
          ..where((row) => row.name.equals(name)))
        .getSingleOrNull();
  }

  Future<void> deleteStoredForm(int id) =>
      (delete(storedForms)..where((row) => row.id.equals(id))).go();

  Future<void> updateStoredForm(
    int id, {
    String? name,
    String? description,
    String? json,
    int? version,
  }) async {
    await (update(storedForms)..where((row) => row.id.equals(id))).write(
      StoredFormsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        description: description == null
            ? const Value.absent()
            : Value(description),
        json: json == null ? const Value.absent() : Value(json),
        version: version == null ? const Value.absent() : Value(version),
      ),
    );
  }

  // ── App settings (key/value) ─────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await (into(appSettings).insert(
      AppSettingsCompanion.insert(key: key, value: value),
      onConflict: DoUpdate(
        (_) => AppSettingsCompanion(value: Value(value)),
        target: [appSettings.key],
      ),
    ));
  }

  // ── GPS logs ─────────────────────────────────────────────────

  Future<int> insertGpsLog(GpsLogsCompanion entry) => into(gpsLogs).insert(entry);

  Future<List<GpsLog>> getGpsLogs() {
    return (select(gpsLogs)
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<void> renameGpsLog(int id, String name) async {
    await (update(gpsLogs)..where((row) => row.id.equals(id))).write(
      GpsLogsCompanion(name: Value(name)),
    );
  }

  Future<void> deleteGpsLog(int id) =>
      (delete(gpsLogs)..where((row) => row.id.equals(id))).go();

  // ── Project attribute fields ─────────────────────────────────

  Future<List<ProjectField>> getProjectFields(int projectId) {
    return (select(projectFields)
          ..where((row) => row.projectId.equals(projectId))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
  }

  Future<int> insertProjectField(int projectId, String name) =>
      into(projectFields).insert(
        ProjectFieldsCompanion(
          projectId: Value(projectId),
          name: Value(name.trim()),
        ),
      );

  Future<void> renameProjectField(int id, String name) async {
    await (update(projectFields)..where((row) => row.id.equals(id))).write(
      ProjectFieldsCompanion(name: Value(name.trim())),
    );
  }

  Future<void> deleteProjectField(int id) =>
      (delete(projectFields)..where((row) => row.id.equals(id))).go();

  // ── Sync config (per-project) ────────────────────────────────

  Future<SyncConfig?> getSyncConfig(int projectId) async {
    return (select(syncConfigs)..where((t) => t.projectId.equals(projectId)))
        .getSingleOrNull();
  }

  Future<void> upsertSyncConfig({
    required int projectId,
    String? syncEndpointUrl,
    String? syncApiKey,
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) async {
    final trimmedUrl = syncEndpointUrl?.trim();
    final trimmedKey = syncApiKey?.trim();
    await into(syncConfigs).insert(
      SyncConfigsCompanion(
        projectId: Value(projectId),
        syncEndpointUrl: trimmedUrl == null || trimmedUrl.isEmpty
            ? const Value(null)
            : Value(trimmedUrl),
        syncApiKey: trimmedKey == null || trimmedKey.isEmpty
            ? const Value(null)
            : Value(trimmedKey),
        lastSyncAt: lastSyncAt,
      ),
      onConflict: DoUpdate(
        (old) => SyncConfigsCompanion(
          syncEndpointUrl: trimmedUrl == null || trimmedUrl.isEmpty
              ? const Value(null)
              : Value(trimmedUrl),
          syncApiKey: trimmedKey == null || trimmedKey.isEmpty
              ? const Value(null)
              : Value(trimmedKey),
          lastSyncAt: lastSyncAt,
        ),
        target: [syncConfigs.projectId],
      ),
    );
  }

  Future<void> deleteSyncConfig(int projectId) async {
    await (delete(syncConfigs)..where((t) => t.projectId.equals(projectId)))
        .go();
  }

  // ── Reset / maintenance ──────────────────────────────────────

  /// Deletes all user-generated data (projects, sessions, stored forms and
  /// GPS logs). The `user_name` setting is preserved so the current user
  /// survives a reset. Photo files on disk are left untouched.
  Future<void> resetAllData() async {
    await delete(surveySessions).go();
    await delete(syncConfigs).go();
    await delete(projects).go();
    await delete(storedForms).go();
    await delete(gpsLogs).go();
    await delete(projectFields).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mapbanai.db'));
    return NativeDatabase.createInBackground(file, logStatements: false);
  });
}

LazyDatabase _openInProcessConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mapbanai.db'));
    return NativeDatabase(file, logStatements: false);
  });
}
