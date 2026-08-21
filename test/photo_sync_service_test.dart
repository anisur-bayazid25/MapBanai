import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/photo_sync_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.forTesting();
    tempDir = Directory.systemTemp.createTempSync('photo-sync-test-');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<String> createTempPhoto(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<int> createProjectWithSync(String endpoint, {int maxBytes = 15 * 1024 * 1024}) async {
    final id = await db.into(db.projects).insert(
          ProjectsCompanion.insert(name: 'ProjPhoto'),
        );
    await db.upsertSyncConfig(
      projectId: id,
      syncEndpointUrl: endpoint,
      syncApiKey: 'key123',
    );
    return id;
  }

  test('retry succeeds after two failures', () async {
    final photoPath = await createTempPhoto('a.jpg', List<int>.filled(100, 1));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var attempts = 0;
    server.listen((req) async {
      attempts++;
      await utf8.decoder.bind(req).join();
      if (attempts < 3) {
        req.response.statusCode = 500;
        req.response.write('temp fail');
        await req.response.close();
      } else {
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'ok': true}));
        await req.response.close();
      }
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'Feat with photo',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'feature_type': 'point',
                'latitude': 23.0,
                'longitude': 90.0,
                'photo': {'path': photoPath},
              })),
            ),
          );

      final svc = PhotoSyncService(
        db,
        delay: (d) async {}, // no wait in tests
      );
      final result = await svc.syncPhotos(projectId);

      expect(attempts, 3);
      expect(result.total, 1);
      expect(result.synced, 1);
      expect(result.failed, 0);
      expect(result.skippedOversized, 0);

      final sessions = await db.getSurveySessionsByProject(projectId);
      expect(sessions.first.photoSyncedAt, isNotNull);
    } finally {
      await server.close(force: true);
    }
  });

  test('one failing photo does not block next', () async {
    final photoA = await createTempPhoto('a.jpg', List<int>.filled(50, 2));
    final photoB = await createTempPhoto('b.jpg', List<int>.filled(50, 3));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var totalRequests = 0;
    server.listen((req) async {
      totalRequests++;
      final body = await utf8.decoder.bind(req).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final filename = decoded['filename'] as String;
      if (filename.contains('a.jpg')) {
        // always fail
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'ok': false, 'error': 'bad photo A'}));
        await req.response.close();
      } else {
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'ok': true}));
        await req.response.close();
      }
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'F1',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'feature_type': 'point',
                'latitude': 1,
                'longitude': 1,
                'photo': {'path': photoA},
              })),
            ),
          );
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'F2',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'feature_type': 'point',
                'latitude': 2,
                'longitude': 2,
                'photo': {'path': photoB},
              })),
            ),
          );

      final svc = PhotoSyncService(db, delay: (d) async {});
      final result = await svc.syncPhotos(projectId);

      // a.jpg fails 3 attempts, b.jpg succeeds 1 => total 4
      expect(totalRequests, 4);
      expect(result.total, 2);
      expect(result.synced, 1);
      expect(result.failed, 1);

      final sessions = await db.getSurveySessionsByProject(projectId);
      final sA = sessions.firstWhere((s) => s.title == 'F1');
      final sB = sessions.firstWhere((s) => s.title == 'F2');
      expect(sA.photoSyncedAt, isNull);
      expect(sB.photoSyncedAt, isNotNull);
    } finally {
      await server.close(force: true);
    }
  });

  test('oversized photo is skipped without network call', () async {
    // Use tiny threshold for test
    final photoPath = await createTempPhoto('big.jpg', List<int>.filled(200, 9));
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests++;
      await utf8.decoder.bind(req).join();
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': true}));
      await req.response.close();
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'BigPhoto',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'feature_type': 'point',
                'latitude': 1,
                'longitude': 1,
                'photo': {'path': photoPath},
              })),
            ),
          );

      // threshold 100 bytes, file is 200 => oversize
      final svc = PhotoSyncService(
        db,
        delay: (d) async {},
        maxPhotoBytes: 100,
      );
      final result = await svc.syncPhotos(projectId);

      expect(requests, 0);
      expect(result.total, 1);
      expect(result.skippedOversized, 1);
      expect(result.synced, 0);
      expect(result.failed, 0);

      final sessions = await db.getSurveySessionsByProject(projectId);
      expect(sessions.first.photoSyncedAt, isNull);
    } finally {
      await server.close(force: true);
    }
  });

  test('queryUnsyncedPhotos finds only photo sessions with null photo_synced_at', () async {
    final p1 = await createTempPhoto('p1.jpg', [1]);
    await db.into(db.projects).insert(ProjectsCompanion.insert(name: 'ProjX'));
    final projId = (await db.getProjectByName('ProjX'))!.id;
    await db.upsertSyncConfig(
      projectId: projId,
      syncEndpointUrl: 'http://example.com',
      syncApiKey: 'k',
    );
    await db.into(db.surveySessions).insert(
          SurveySessionsCompanion.insert(
            projectId: projId,
            title: 'WithPhoto',
            status: const drift.Value('saved'),
            responses: drift.Value(jsonEncode({
              'feature_type': 'point',
              'photo': {'path': p1},
            })),
          ),
        );
    await db.into(db.surveySessions).insert(
          SurveySessionsCompanion.insert(
            projectId: projId,
            title: 'NoPhoto',
            status: const drift.Value('saved'),
            responses: drift.Value(jsonEncode({'form_name': 'F'})),
          ),
        );

    final svc = PhotoSyncService(db);
    final list = await svc.queryUnsyncedPhotos(projId);
    expect(list, hasLength(1));
    expect(list.first.title, 'WithPhoto');
  });

  test('photo POST follows Apps Script 302 with GET and marks synced',
      () async {
    final photoPath = await createTempPhoto('r.jpg', List<int>.filled(80, 7));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? postBody;
    var postMethod = '';
    var followMethod = '';
    var hits = 0;
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      hits++;
      if (req.uri.path == '/exec') {
        postMethod = req.method;
        postBody = body;
        req.response.statusCode = 302;
        req.response.headers
            .set('Location', 'http://127.0.0.1:${server.port}/redirected');
        await req.response.close();
      } else if (req.uri.path == '/redirected') {
        followMethod = req.method;
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
              title: 'RedirectPhoto',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'feature_type': 'point',
                'latitude': 1,
                'longitude': 1,
                'photo': {'path': photoPath},
              })),
            ),
          );
      final svc = PhotoSyncService(db, delay: (d) async {});
      final result = await svc.syncPhotos(projectId);

      expect(hits, 2);
      expect(postMethod, 'POST');
      expect(followMethod, 'GET',
          reason: 'Apps Script redirect target only accepts GET; '
              're-POSTing returns 405');
      expect(postBody, isNotNull);
      final decoded = jsonDecode(postBody!) as Map<String, dynamic>;
      expect(decoded['action'], 'upload_photo');
      expect(decoded['apiKey'], 'key123');

      expect(result.synced, 1);
      final sessions = await db.getSurveySessionsByProject(projectId);
      expect(sessions.first.photoSyncedAt, isNotNull);
    } finally {
      await server.close(force: true);
    }
  });

  test('survey response with embedded PhotoQuestion photo is queued for upload', () async {
    final photoPath = await createTempPhoto('embedded.jpg', List<int>.filled(60, 5));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var hits = 0;
    String? capturedFilename;
    server.listen((req) async {
      hits++;
      final body = await utf8.decoder.bind(req).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      capturedFilename = decoded['filename'] as String?;
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': true}));
      await req.response.close();
    });

    try {
      final endpoint = 'http://127.0.0.1:${server.port}/exec';
      final projectId = await createProjectWithSync(endpoint);
      // Simulate a survey response where a PhotoQuestion answer is stored as JSON string under arbitrary field name
      final answers = {
        'site_name': 'Test Site',
        'site_photo': jsonEncode({
          'path': photoPath,
          'thumb': '${photoPath}_thumb',
          'latitude': 23.5,
          'longitude': 90.5,
        }),
        'notes': 'some notes',
      };
      await db.into(db.surveySessions).insert(
            SurveySessionsCompanion.insert(
              projectId: projectId,
              title: 'SurveyWithPhoto',
              status: const drift.Value('saved'),
              responses: drift.Value(jsonEncode({
                'form_name': 'TestForm',
                'user_name': 'Tester',
                'answers': answers,
              })),
            ),
          );

      final svc = PhotoSyncService(db, delay: (d) async {});
      // Should find the embedded photo
      final unsynced = await svc.queryUnsyncedPhotos(projectId);
      expect(unsynced, hasLength(1));
      expect(unsynced.first.title, 'SurveyWithPhoto');

      final result = await svc.syncPhotos(projectId);
      expect(hits, 1);
      expect(capturedFilename, 'embedded.jpg');
      expect(result.total, 1);
      expect(result.synced, 1);
      final sessions = await db.getSurveySessionsByProject(projectId);
      expect(sessions.first.photoSyncedAt, isNotNull);
    } finally {
      await server.close(force: true);
    }
  });
}
