import 'dart:convert';
import 'package:drift/drift.dart' as d;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';

void main() {
  late AppDatabase db;
  late int project;
  setUp(() async {
    db = AppDatabase.forTesting();
    project =
        await db.insertProject(ProjectsCompanion.insert(name: 'Salinity'));
    await db.setSetting('user_name', 'Alice');
    await db.upsertSyncConfig(
        projectId: project,
        syncEndpointUrl: 'https://example.com/exec',
        syncApiKey: 'key');
  });
  tearDown(() => db.close());
  Future<int> create({String status = 'saved'}) =>
      db.insertSurveySession(SurveySessionsCompanion.insert(
        projectId: project,
        title: 'Visit',
        status: d.Value(status),
        responses: d.Value(jsonEncode({
          'answers': {'salinity': 2},
          'form_version': 7
        })),
      ));
  test(
      'saved edits retain identity and collector, increment revisions and requeue both outboxes',
      () async {
    final id = await create();
    final original = (await db.getSurveySession(id))!;
    expect(jsonDecode(original.responses)['user_name'], 'Alice');
    await (db.update(db.surveySessions)..where((r) => r.id.equals(id))).write(
        SurveySessionsCompanion(
            syncedAt: d.Value(DateTime.now()),
            photoSyncedAt: d.Value(DateTime.now())));
    await db.setSetting('user_name', 'Bob');
    await db.updateSurveySession(id,
        responses: jsonEncode({
          'answers': {'salinity': 3},
          'user_name': 'Bob'
        }));
    var saved = (await db.getSurveySession(id))!;
    var body = jsonDecode(saved.responses);
    expect(saved.externalId, original.externalId);
    expect(saved.syncedAt, isNull);
    expect(saved.photoSyncedAt, isNull);
    expect(body['user_name'], 'Alice');
    expect(body['edited_by'], 'Bob');
    expect(body['response_revision'], 2);
    expect(body['edited_at'], isNotEmpty);
    await db.updateSurveySession(id, title: 'Corrected visit');
    saved = (await db.getSurveySession(id))!;
    body = jsonDecode(saved.responses);
    expect(body['response_revision'], 3);
    await db.updateSurveySession(id, responses: saved.responses);
    expect(
        jsonDecode(
            (await db.getSurveySession(id))!.responses)['response_revision'],
        3);
  });
  test('unchanged study sites stay acknowledged after a revised upload',
      () async {
    final site = StudyAreaSite(
        id: 'site',
        latitude: 23.8,
        longitude: 90.4,
        projectId: project,
        projectExternalId: 'project');
    final outbox = StudyAreaOutboxService(db);
    await outbox.enqueue(site, 'Alice');
    site.changeNote = 'Verified';
    await outbox.enqueue(site, 'Bob');
    final row = (await db.getSurveySessionsByProject(project)).single;
    expect(jsonDecode(row.responses)['response_revision'], 2);
    await (db.update(db.surveySessions)..where((r) => r.id.equals(row.id)))
        .write(SurveySessionsCompanion(syncedAt: d.Value(DateTime.now())));
    await outbox.enqueue(site, 'Bob');
    final unchanged = (await db.getSurveySession(row.id))!;
    expect(unchanged.syncedAt, isNotNull);
    expect(jsonDecode(unchanged.responses)['response_revision'], 2);
  });
  test('draft autosaves and initial completion remain revision one', () async {
    final id = await create(status: 'draft');
    await db.updateSurveySession(id,
        responses: jsonEncode({
          'answers': {'salinity': 4}
        }));
    await db.updateSurveySession(id, status: 'saved');
    expect(
        jsonDecode(
            (await db.getSurveySession(id))!.responses)['response_revision'],
        1);
  });
  test(
      'old backend cannot acknowledge an edited response; revision-aware retry can',
      () async {
    final id = await create();
    await db.updateSurveySession(id, title: 'Edited');
    var modern = false;
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body);
      expect(payload['responses'][0]['response_revision'], 2);
      expect(payload['responses'][0]['surveyor'], 'Alice');
      return http.Response(
          jsonEncode({'ok': true, if (modern) 'revisionSupport': true}), 200);
    });
    final service = CloudSyncService(db, client: client);
    await expectLater(
        service.syncProject(project), throwsA(isA<CloudSyncException>()));
    expect((await db.getSurveySession(id))!.syncedAt, isNull);
    modern = true;
    expect((await service.syncProject(project)).responsesSynced, 1);
    expect((await db.getSurveySession(id))!.syncedAt, isNotNull);
    client.close();
  });
}
