import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/services/history_cleanup_service.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late Directory directory;
  late StudyAreaStore store;
  late Project project;
  setUp(() async {
    db = AppDatabase.forTesting();
    directory = await Directory.systemTemp.createTemp('history_cleanup_');
    store = StudyAreaStore(baseDir: directory);
    final id = await db.insertProject(const ProjectsCompanion(
        name: Value('CARE'), externalId: Value('care-project')));
    project = (await db.getProjectById(id))!;
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<int> addRecord(
          {int? projectId,
          String? layer = 'shyampur',
          DateTime? day,
          String status = 'saved',
          Map<String, dynamic>? data}) =>
      db.insertSurveySession(SurveySessionsCompanion(
        projectId: Value(projectId ?? project.id),
        title: const Value('Record'),
        status: Value(status),
        createdAt: Value(day ?? DateTime(2026, 10, 25, 12)),
        responses: Value(jsonEncode(data ??
            {
              'answers': {'name': 'Test survey'},
              if (layer != null) 'layer_id': layer
            })),
      ));

  test(
      '920 imports can be removed by project, layer and day without losing one survey',
      () async {
    await db.batch((batch) => batch.insertAll(
        db.surveySessions,
        List.generate(
            920,
            (index) => SurveySessionsCompanion(
                  projectId: Value(project.id),
                  title: Value('Imported $index'),
                  status: const Value('saved'),
                  createdAt: Value(DateTime(2026, 10, 25, 12)),
                  responses: Value(jsonEncode({
                    'workflow': 'study_area_feature_v1',
                    'feature_type': 'point',
                    'site_id': 'point-$index',
                    'layer_id': 'shyampur'
                  })),
                ))));
    final survey = await addRecord();
    final otherLayer = await addRecord(layer: 'shyamnagar');
    final otherDay = await addRecord(day: DateTime(2026, 10, 26));
    final draft = await addRecord(status: 'draft');
    final otherProject =
        await db.insertProject(const ProjectsCompanion(name: Value('Other')));
    final other = await addRecord(projectId: otherProject);
    final service = HistoryCleanupService(db, store: store);
    final preview = await service.preview(HistoryScope(
        projectId: project.id,
        layerId: 'shyampur',
        day: '2026-10-25',
        kind: 'study'));
    expect(preview.records, hasLength(920));
    expect(preview.pendingCount, 920);
    expect(await service.delete(preview), 920);
    expect(
        await CloudSyncService(db).queryUnsyncedFeatures(project.id), isEmpty);
    for (final id in [survey, otherLayer, otherDay, draft, other]) {
      expect(await db.getSurveySession(id), isNotNull);
    }
  });

  test(
      'large study-area snapshots round trip through worker decoding and scoped deletion',
      () async {
    final text = List.filled(1200, 'x').join();
    final sites = List.generate(
        460,
        (index) => StudyAreaSite(
            id: 'large-$index',
            latitude: 23.68,
            longitude: 90.44,
            projectId: project.id,
            projectExternalId: project.externalId,
            attributes: {'name': 'Point $index', 'description': text}));
    await store.saveSites(sites);
    expect(
        await File(await store.filePath()).length(), greaterThan(256 * 1024));
    expect(await store.loadSites(), hasLength(460));
    await store.deleteSites(sites.take(230).map((site) => site.id).toSet());
    expect(await store.loadSites(), hasLength(230));
  });

  test(
      'history-only cleanup keeps map data and cannot be requeued until edited',
      () async {
    final site = StudyAreaSite(
        id: 'old',
        latitude: 23.68,
        longitude: 90.44,
        projectId: project.id,
        projectExternalId: project.externalId,
        layerId: 'shyampur');
    await store.addSites([site]);
    final outbox = StudyAreaOutboxService(db);
    await outbox.enqueue(site, 'Collector');
    final service = HistoryCleanupService(db, store: store);
    await service.delete(await service
        .preview(HistoryScope(projectId: project.id, layerId: 'shyampur')));
    expect(await store.loadSites(), hasLength(1));
    await StudyAreaOutboxService(db)
        .enqueue((await store.loadSites()).single, 'Collector');
    expect(await db.getSurveySessionsByProject(project.id), isEmpty);
    final edited = (await store.loadSites()).single;
    edited.status = StudyAreaStatus.completed;
    await store.updateSite(edited, author: 'Collector');
    await outbox.enqueue(edited, 'Collector');
    expect(await CloudSyncService(db).queryUnsyncedFeatures(project.id),
        hasLength(1));
  });

  test(
      'removing a point includes linked visits from other days and preserves unrelated sites',
      () async {
    final site = StudyAreaSite(
        id: 'old',
        latitude: 23.68,
        longitude: 90.44,
        projectId: project.id,
        projectExternalId: project.externalId,
        layerId: 'shyampur');
    final other = StudyAreaSite(
        id: 'keep',
        latitude: 23.7,
        longitude: 90.4,
        projectId: project.id,
        projectExternalId: project.externalId,
        layerId: 'other');
    await store.addSites([site, other]);
    await StudyAreaOutboxService(db).enqueue(site, 'Collector');
    await addRecord(day: DateTime(2026, 10, 20), data: {
      'workflow': 'guided_visit_v1',
      'visit': {'site_id': site.id, 'layer_id': site.layerId}
    });
    final service = HistoryCleanupService(db, store: store);
    final preview = await service.preview(
        HistoryScope(projectId: project.id, kind: 'study'),
        removePoints: true);
    expect(preview.matchedCount, 1);
    expect(preview.relatedCount, 1);
    expect(preview.points.single.id, 'old');
    expect(await service.delete(preview), 2);
    expect((await store.loadSites()).single.id, 'keep');
  });

  test('a changed record cancels the whole deletion', () async {
    final first = await addRecord();
    final second = await addRecord();
    final service = HistoryCleanupService(db, store: store);
    final preview = await service.preview(HistoryScope(projectId: project.id));
    await db.updateSurveySession(second,
        title: 'New edit', responses: '{"answers":{"name":"Changed"}}');
    await expectLater(service.delete(preview), throwsStateError);
    expect(await db.getSurveySession(first), isNotNull);
    expect(await db.getSurveySession(second), isNotNull);
  });

  test('sync skips records deleted while a previous batch is uploading',
      () async {
    for (var index = 0; index < 50; index++) {
      await addRecord(day: DateTime(2026, 10, index < 20 ? 26 : 25));
    }
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      if (requests == 1) {
        final service = HistoryCleanupService(db, store: store);
        await service.delete(await service
            .preview(HistoryScope(projectId: project.id, day: '2026-10-25')));
      }
      return http.Response('{"ok":true,"revisionSupport":true}', 200);
    });
    try {
      await db.upsertSyncConfig(
          projectId: project.id,
          syncEndpointUrl: 'https://example.test/exec',
          syncApiKey: 'test');
      final result =
          await CloudSyncService(db, client: client).syncProject(project.id);
      expect(result.responsesSynced, 20);
      expect(requests, 1);
      expect(await CloudSyncService(db).queryUnsyncedResponses(project.id),
          isEmpty);
    } finally {
      client.close();
    }
  });
}
