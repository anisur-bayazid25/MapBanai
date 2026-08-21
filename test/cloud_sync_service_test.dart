import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createProjectWithSync(String endpoint) async {
    final id = await db.into(db.projects).insert(
          ProjectsCompanion.insert(
            name: 'TestProject',
            description: const drift.Value(''),
          ),
        );
    // Directly use companion to set externalId if needed
    await db.upsertSyncConfig(
      projectId: id,
      syncEndpointUrl: endpoint,
      syncApiKey: 'test-key-123',
    );
    return id;
  }

  test('queryUnsynced splits responses and features', () async {
    final projectId = await db.into(db.projects).insert(
          ProjectsCompanion.insert(name: 'ProjA'),
        );
    // response (no feature_type)
    await db.into(db.surveySessions).insert(
          SurveySessionsCompanion.insert(
            projectId: projectId,
            title: 'Resp 1',
            status: const drift.Value('saved'),
            responses: drift.Value(jsonEncode({
              'form_name': 'FormA',
              'user_name': 'Anis',
              'answers': {'q1': 'yes'},
            })),
          ),
        );
    // feature (has feature_type)
    await db.into(db.surveySessions).insert(
          SurveySessionsCompanion.insert(
            projectId: projectId,
            title: 'Point 1',
            status: const drift.Value('saved'),
            responses: drift.Value(jsonEncode({
              'feature_type': 'point',
              'user_name': 'Anis',
              'latitude': 23.7,
              'longitude': 90.3,
            })),
          ),
        );
    // draft should be ignored
    await db.into(db.surveySessions).insert(
          SurveySessionsCompanion.insert(
            projectId: projectId,
            title: 'Draft',
            status: const drift.Value('draft'),
            responses: drift.Value(jsonEncode({
              'form_name': 'FormA',
              'answers': {},
            })),
          ),
        );

    final svc = CloudSyncService(db);
    final responses = await svc.queryUnsyncedResponses(projectId);
    final features = await svc.queryUnsyncedFeatures(projectId);
    expect(responses, hasLength(1));
    expect(responses.first.title, 'Resp 1');
    expect(features, hasLength(1));
    expect(features.first.title, 'Point 1');
  });

  test('successful sync marks rows synced and updates lastSyncAt', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final captured = <Map<String, dynamic>>[];
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      captured.add(decoded);
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': true}));
      await req.response.close();
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);

      // Insert unsynced response
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'Resp1',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'form_name': 'Health Form',
                'user_name': 'Tester',
                'answers': {'age': 30},
              })),
            ),
          );
      // Insert unsynced feature
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'Feature1',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'feature_type': 'point',
                'user_name': 'Tester',
                'latitude': 23.780,
                'longitude': 90.407,
                'id': 'feat-1',
              })),
            ),
          );

      final svc = CloudSyncService(db);
      final result = await svc.syncProject(projectId);

      expect(result.responsesSynced, 1);
      expect(result.featuresSynced, 1);
      expect(captured, hasLength(1));
      final payload = captured.first;
      expect(payload['apiKey'], 'test-key-123');
      expect(payload['action'], 'sync_data');
      expect(payload['responses'], isA<List>());
      expect((payload['responses'] as List), hasLength(1));
      final respPayload = (payload['responses'] as List).first as Map;
      expect(respPayload['response_id'], isA<String>());
      expect(respPayload['project_name'], 'TestProject');
      expect(respPayload['form_name'], 'Health Form');
      expect(payload['features'], isA<List>());
      expect((payload['features'] as List), hasLength(1));
      final featPayload = (payload['features'] as List).first as Map;
      expect(featPayload['feature_id'], isA<String>());
      expect(featPayload['geometry_type'], 'point');
      expect(featPayload['latitude'], 23.78);
      expect(featPayload['photo_path'], '');

      // rows should now be marked synced
      final remainingResponses = await svc.queryUnsyncedResponses(projectId);
      final remainingFeatures = await svc.queryUnsyncedFeatures(projectId);
      expect(remainingResponses, isEmpty);
      expect(remainingFeatures, isEmpty);

      final sessions = await db.getSurveySessionsByProject(projectId);
      for (final s in sessions) {
        if (s.status != 'draft') {
          expect(s.syncedAt, isNotNull);
        }
      }

      final cfg = await db.getSyncConfig(projectId);
      expect(cfg?.lastSyncAt, isNotNull);
    } finally {
      await server.close(force: true);
    }
  });

  test('failed sync leaves rows unsynced', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      await utf8.decoder.bind(req).join(); // consume
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': false, 'error': 'Server boom'}));
      await req.response.close();
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'RespFail',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'form_name': 'FormFail',
                'answers': {},
              })),
            ),
          );
      final svc = CloudSyncService(db);
      await expectLater(
        svc.syncProject(projectId),
        throwsA(isA<CloudSyncException>().having(
          (e) => e.message,
          'message',
          contains('Server boom'),
        )),
      );
      // still unsynced
      final remaining = await svc.queryUnsyncedResponses(projectId);
      expect(remaining, hasLength(1));
      expect(remaining.first.syncedAt, isNull);
      final cfg = await db.getSyncConfig(projectId);
      expect(cfg?.lastSyncAt, isNull);
    } finally {
      await server.close(force: true);
    }
  });

  test('malformed API key response surfaces error message', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      await utf8.decoder.bind(req).join();
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': false, 'error': 'Invalid API key'}));
      await req.response.close();
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'RespAuth',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'form_name': 'F',
                'answers': {},
              })),
            ),
          );
      final svc = CloudSyncService(db);
      try {
        await svc.syncProject(projectId);
        fail('expected exception');
      } on CloudSyncException catch (e) {
        expect(e.message, contains('Invalid API key'));
      }
      final remaining = await svc.queryUnsyncedResponses(projectId);
      expect(remaining, hasLength(1));
    } finally {
      await server.close(force: true);
    }
  });

  test('non-JSON 500 surfaces generic message', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      await utf8.decoder.bind(req).join();
      req.response.statusCode = 500;
      req.response.write('Internal Server Error');
      await req.response.close();
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'Resp500',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({'form_name': 'F'})),
            ),
          );
      final svc = CloudSyncService(db);
      await expectLater(
        svc.syncProject(projectId),
        throwsA(isA<CloudSyncException>()),
      );
      final remaining = await svc.queryUnsyncedResponses(projectId);
      expect(remaining, hasLength(1));
    } finally {
      await server.close(force: true);
    }
  });

  test('missing ok:false without error gives generic message', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      await utf8.decoder.bind(req).join();
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': false}));
      await req.response.close();
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'RespGeneric',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({'form_name': 'F'})),
            ),
          );
      final svc = CloudSyncService(db);
      await expectLater(
        svc.syncProject(projectId),
        throwsA(isA<CloudSyncException>()
            .having((e) => e.message, 'message', contains('Sync failed'))),
      );
    } finally {
      await server.close(force: true);
    }
  });

  test('POST body survives 302 redirect preserving method and body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? firstBody;
    String? secondBody;
    var hits = 0;
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      hits++;
      if (req.uri.path == '/exec') {
        firstBody = body;
        req.response.statusCode = 302;
        req.response.headers
            .set('Location', 'http://127.0.0.1:${server.port}/redirected');
        await req.response.close();
      } else if (req.uri.path == '/redirected') {
        secondBody = body;
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'ok': true}));
        await req.response.close();
      } else {
        req.response.statusCode = 404;
        await req.response.close();
      }
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'RedirectResp',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'form_name': 'RedirectForm',
                'user_name': 'Tester',
                'answers': {'q': 'v'},
              })),
            ),
          );
      final svc = CloudSyncService(db);
      final result = await svc.syncProject(projectId);
      expect(result.responsesSynced, 1);
      expect(hits, 2);
      expect(firstBody, isNotNull);
      expect(secondBody, isNotNull);
      expect(secondBody, equals(firstBody));
      final decoded = jsonDecode(secondBody!) as Map<String, dynamic>;
      expect(decoded['action'], 'sync_data');
      expect(decoded['apiKey'], 'test-key-123');
      // Verify row was marked synced despite redirect
      final remaining = await svc.queryUnsyncedResponses(projectId);
      expect(remaining, isEmpty);
    } finally {
      await server.close(force: true);
    }
  });
}
