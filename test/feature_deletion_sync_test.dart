import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:mapbanai/services/project_field_data_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late Directory dir;
  late StudyAreaStore store;
  late Project project;
  late StudyAreaSite site;
  setUp(() async {
    db = AppDatabase.forTesting();
    dir = await Directory.systemTemp.createTemp('deletion_sync_');
    store = StudyAreaStore(baseDir: dir);
    await db.createProject('Deletion test');
    project = (await db.getProjectByName('Deletion test'))!;
    // Assign the stable project identity before making linked field records.
    await (db.update(db.projects)..where((row) => row.id.equals(project.id)))
        .write(const ProjectsCompanion(
            externalId: drift.Value('deletion-project')));
    project = (await db.getProjectById(project.id))!;
    site = StudyAreaSite(
        id: 'water-point',
        latitude: 23.8,
        longitude: 90.4,
        projectId: project.id,
        projectExternalId: project.externalId,
        attributes: {'name': 'Water point'});
    await store.addSites([site]);
    await db.upsertSyncConfig(
        projectId: project.id,
        syncEndpointUrl: 'https://example.com/exec',
        syncApiKey: 'test');
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
      'deletion journal survives reopen, exports, and does not resend acknowledged events',
      () async {
    final deletion = await store.deleteSiteForSync(site, 'Fieldworker');
    store = StudyAreaStore(baseDir: dir);
    expect(await store.loadSites(), isEmpty);
    expect(
        (await store.loadDeletions()).single.operationId, deletion.operationId);
    var batches = 0;
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      if (body['action'] == 'sync_data') {
        batches++;
        final row = (body['features'] as List).single as Map;
        expect(row['deleted'], true);
        expect(row['status'], 'Deleted');
        expect(row['site_id'], site.id);
      }
      return http.Response(
          jsonEncode({
            'ok': true,
            'connectionVerified': true,
            'revisionSupport': true,
            'deletionSupport': true
          }),
          200);
    });
    final sync = CloudSyncService(db, client: client, studyAreaStore: store);
    expect((await sync.syncProject(project.id)).featuresSynced, 1);
    expect((await sync.syncProject(project.id)).featuresSynced, 0);
    expect(batches, 1);
    final exported =
        await ProjectFieldDataService(db, store: store).export(project);
    expect((exported['study_deletions'] as List), hasLength(1));
    expect(
        (await WebMapDataService(db, studyAreaStore: store)
            .buildFeatureCollectionForProject(project.id))['features'],
        isEmpty);
  });

  test('deleting an edited/synced site updates the same feature revision',
      () async {
    final outbox = StudyAreaOutboxService(db);
    await outbox.enqueue(site, 'Fieldworker');
    final original = (await db.getSurveySessionsByProject(project.id)).single;
    await outbox
        .enqueueDeletion(await store.deleteSiteForSync(site, 'Fieldworker'));
    final updated = (await db.getSurveySessionsByProject(project.id)).single;
    expect(updated.id, original.id);
    expect(updated.externalId, original.externalId);
    expect(jsonDecode(updated.responses)['response_revision'], 2);
    await outbox.enqueueDeletion((await store.loadDeletions()).single);
    expect(
        jsonDecode((await db.getSurveySession(updated.id))!.responses)[
            'response_revision'],
        2);
  });

  test('project copy preserves deletion journal and remaps site identity',
      () async {
    await store.deleteSiteForSync(site, 'Fieldworker');
    final data =
        await ProjectFieldDataService(db, store: store).export(project);
    await db.createProject('Copy');
    final target = (await db.getProjectByName('Copy'))!;
    final copy = target.copyWith(externalId: const drift.Value('copy-project'));
    final targetStore = StudyAreaStore(baseDir: Directory('${dir.path}/copy'));
    await ProjectFieldDataService(db, store: targetStore)
        .import(data, copy, newCopy: true);
    await ProjectVectorLayerService(db)
        .ensureStudySites(copy, 'default', targetStore);
    expect(await targetStore.loadSites(), isEmpty);
    final deleted = (await targetStore.loadDeletions()).single;
    expect(deleted.site.id, 'copy-project:${site.id}');
    expect(deleted.site.projectId, target.id);
    // Re-export before opening Study Area must also retain durable import seeds.
    final roundTrip =
        await ProjectFieldDataService(db, store: targetStore).export(copy);
    expect(roundTrip['study_deletions'], hasLength(1));
  });

  test('old backend cannot receive or acknowledge a deletion', () async {
    await store.deleteSiteForSync(site, 'Fieldworker');
    var sentData = false;
    final sync = CloudSyncService(db, studyAreaStore: store,
        client: MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      if (body['action'] == 'sync_data') sentData = true;
      return http.Response(
          '{"ok":true,"connectionVerified":true,"revisionSupport":true}', 200);
    }));
    await expectLater(
        sync.syncProject(project.id), throwsA(isA<CloudSyncException>()));
    expect(sentData, false);
    expect(await sync.queryUnsyncedFeatures(project.id), hasLength(1));
  });

  test(
      'native saved feature deletion retains ID and increments revision; drafts are discarded',
      () async {
    final id = await db.insertSurveySession(SurveySessionsCompanion(
        projectId: drift.Value(project.id),
        title: const drift.Value('GIS point'),
        status: const drift.Value('saved'),
        responses: drift.Value(jsonEncode(
            {'feature_type': 'point', 'latitude': 23.8, 'longitude': 90.4}))));
    final before = (await db.getSurveySession(id))!;
    await StudyAreaOutboxService(db).deleteFeatureSession(id);
    final after = (await db.getSurveySession(id))!;
    expect(after.externalId, before.externalId);
    expect(jsonDecode(after.responses)['response_revision'], 2);
    expect(jsonDecode(after.responses)['deleted'], true);
    expect(await WebMapDataService(db).featureForSession(after), isNull);
    final draft = await db.insertSurveySession(SurveySessionsCompanion(
        projectId: drift.Value(project.id),
        title: const drift.Value('Draft'),
        status: const drift.Value('draft'),
        responses: const drift.Value('{}')));
    await StudyAreaOutboxService(db).deleteFeatureSession(draft);
    expect(await db.getSurveySession(draft), isNull);
  });
}
