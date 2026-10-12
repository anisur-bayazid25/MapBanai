import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/backup_service.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/services/photo_sync_service.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:mapbanai/services/data_export_service.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/ui/survey_form_detail_screen.dart';
import 'package:mapbanai/state/app_settings_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String> getApplicationDocumentsPath() async => root;
}

void main() {
  test('settings releases its database and reloads after a restore', () async {
    final root =
        Directory.systemTemp.createTempSync('mapbanai-settings-restore-');
    final oldPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.path);
    final settings = AppSettingsProvider();
    addTearDown(() async {
      await settings.prepareForRestore();
      settings.dispose();
      PathProviderPlatform.instance = oldPaths;
      root.deleteSync(recursive: true);
    });
    await settings.reload();
    await settings.setLanguage('bn');
    await settings.prepareForRestore();
    // Replacing the file is possible only after the provider releases it.
    final original = File(p.join(root.path, 'mapbanai.db'));
    final snapshot = await original.rename(p.join(root.path, 'old.db'));
    await snapshot.copy(original.path);
    final restored = AppDatabase();
    await restored.setSetting(AppSettingsProvider.languageKey, 'en');
    await restored.close();
    await settings.resumeAfterRestore();
    expect(settings.language, 'en');
    expect(settings.isLoaded, isTrue);
  });

  test('every survey polygon and trace appears in map and CSV exports',
      () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final project =
        await db.insertImportedProject('Field', externalId: 'field');
    final polygon = {
      'type': 'Polygon',
      'coordinates': [
        [
          [90.0, 23.0],
          [90.1, 23.0],
          [90.1, 23.1],
          [90.0, 23.0]
        ]
      ]
    };
    final line = {
      'type': 'LineString',
      'coordinates': [
        [90.0, 23.0],
        [90.1, 23.1]
      ]
    };
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: Value(project),
      title: const Value('Site'),
      status: const Value('saved'),
      responses: Value(jsonEncode({
        'answers': {'boundary': polygon, 'route': line}
      })),
    ));
    final collection =
        await WebMapDataService(db).buildFeatureCollectionForProject(project);
    final features = collection['features'] as List;
    expect(features, hasLength(2));
    expect((features.first as Map)['geometry'], polygon);
    expect((features.last as Map)['properties']['question_name'], 'route');
    final csv = DataExportService.exportSurveyResponsesAsCSV([
      {'boundary': polygon}
    ], [
      'boundary'
    ]);
    expect(csv, contains('23.0 90.0 0 0;23.0 90.1 0 0'));
    expect(csv, isNot(contains('{type:')));
  });

  testWidgets('survey saves to form project even when its name is duplicated',
      (tester) async {
    final root =
        Directory.systemTemp.createTempSync('mapbanai-project-regression-');
    final oldPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.path);
    AppDatabase.useInProcessFileForTesting = true;
    final db = AppDatabase();
    addTearDown(() async {
      await db.close();
      AppDatabase.useInProcessFileForTesting = false;
      PathProviderPlatform.instance = oldPaths;
      root.deleteSync(recursive: true);
    });
    final first = await db.insertImportedProject('Field', externalId: 'first');
    final second =
        await db.insertImportedProject('Field', externalId: 'second');
    final form =
        SurveyForm(id: 'verify', name: 'Verify', description: '', questions: [
      Question(name: 'name', label: 'Name', type: QuestionType.text),
    ]);
    await db.insertStoredForm(StoredFormsCompanion(
      projectId: Value(second),
      name: Value(form.name),
      json: Value(jsonEncode(form.toJson())),
    ));
    final row = (await db.getStoredFormsForProject(second)).single;
    await tester.pumpWidget(MaterialApp(
        home: SurveyFormDetailScreen(row: row, projectName: 'Field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run survey'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Bridge');
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(await db.getSurveySessionsByProject(first), isEmpty);
    expect(
        (await db.getSurveySessionsByProject(second)).single.status, 'saved');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  test('damaged asset backup fails before replacing live data', () async {
    final root = Directory.systemTemp.createTempSync('mapbanai-backup-damage-');
    final oldPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.path);
    final db = AppDatabase.forTesting();
    addTearDown(() async {
      await db.close();
      PathProviderPlatform.instance = oldPaths;
      root.deleteSync(recursive: true);
    });
    final photo = File(p.join(root.path, 'photos', 'field.jpg'));
    photo.parent.createSync();
    photo.writeAsStringSync('original');
    final service = BackupService(db);
    final path = await service.createBackup();
    expect(path, isNotNull);
    await File(p.join(path!, 'photos', 'field.jpg')).writeAsString('damaged');
    expect(await service.restoreLatest(), isFalse);
    expect(photo.readAsStringSync(), 'original');
  });

  test('editing synced answers and photos queues both for sync again',
      () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final project =
        await db.insertImportedProject('Field', externalId: 'field');
    final id = await db.insertSurveySession(SurveySessionsCompanion(
      projectId: Value(project),
      title: const Value('Site'),
      status: const Value('saved'),
      syncedAt: Value(DateTime.now()),
      photoSyncedAt: Value(DateTime.now()),
      responses: Value(jsonEncode({
        'answers': {'age': '20'}
      })),
    ));
    await db.updateSurveySession(id,
        responses: jsonEncode({
          'answers': {'age': '21', 'photo': '{"path":"photos/new.jpg"}'}
        }));
    expect(
        (await CloudSyncService(db).queryUnsyncedResponses(project)).single.id,
        id);
    expect((await PhotoSyncService(db).queryUnsyncedPhotos(project)).single.id,
        id);
  });

  test('sync acknowledgement does not hide an edit made during upload',
      () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final project =
        await db.insertImportedProject('Field', externalId: 'field');
    await db.upsertSyncConfig(
        projectId: project, syncEndpointUrl: 'https://example.com/sync');
    final id = await db.insertSurveySession(SurveySessionsCompanion(
      projectId: Value(project),
      title: const Value('Site'),
      status: const Value('saved'),
      responses: Value(jsonEncode({
        'answers': {'age': '20'}
      })),
    ));
    final client = MockClient((request) async {
      await db.updateSurveySession(id,
          responses: jsonEncode({
            'answers': {'age': '21'}
          }));
      return http.Response('{"ok":true}', 200);
    });
    addTearDown(client.close);
    await CloudSyncService(db, client: client).syncProject(project);
    expect((await db.getSurveySession(id))!.syncedAt, isNull);
  });

  test('question called feature_type is still classified as a survey answer',
      () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final project =
        await db.insertImportedProject('Field', externalId: 'field');
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: Value(project),
      title: const Value('Site'),
      status: const Value('saved'),
      responses: Value(jsonEncode({
        'answers': {'feature_type': 'bridge'}
      })),
    ));
    expect(await CloudSyncService(db).queryUnsyncedResponses(project),
        hasLength(1));
    expect(await CloudSyncService(db).queryUnsyncedFeatures(project), isEmpty);
  });

  test('complete backup restores assets and remaps photo paths to new install',
      () async {
    final root =
        Directory.systemTemp.createTempSync('mapbanai-backup-regression-');
    final oldPaths = PathProviderPlatform.instance;
    final docs = Directory(p.join(root.path, 'old-install'))..createSync();
    PathProviderPlatform.instance = _Paths(docs.path);
    final db = AppDatabase.forTesting();
    addTearDown(() async {
      await db.close();
      PathProviderPlatform.instance = oldPaths;
      root.deleteSync(recursive: true);
    });
    final photoPath = p.join(docs.path, 'photos', 'photo.jpg');
    final project =
        await db.insertImportedProject('Field', externalId: 'field');
    final id = await db.insertSurveySession(SurveySessionsCompanion(
      projectId: Value(project),
      title: const Value('Site'),
      status: const Value('saved'),
      responses: Value(jsonEncode({
        'answers': {
          'photo': jsonEncode({'path': photoPath})
        }
      })),
    ));
    for (final entry in {
      'photos/photo.jpg': 'image-fixture',
      'photos/photo.jpg.json': jsonEncode({'path': photoPath}),
      'gps_logs/log_1.csv': 'GPS fixture',
      'study_area/study_area_sites.json': jsonEncode([
        {
          'id': 'site',
          'history': [
            {'photo_path': photoPath}
          ]
        }
      ]),
    }.entries) {
      final file = File(p.join(docs.path, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    final backup = BackupService(db);
    final path = await backup.createBackup();
    expect(path, isNotNull);
    expect(File(p.join(path!, 'gps_logs/log_1.csv')).readAsStringSync(),
        'GPS fixture');
    final newDocs = Directory(p.join(root.path, 'new-install'))..createSync();
    Directory(p.join(newDocs.path, 'mapbanai_backups')).createSync();
    await Directory(path)
        .rename(p.join(newDocs.path, 'mapbanai_backups', p.basename(path)));
    PathProviderPlatform.instance = _Paths(newDocs.path);
    expect(await backup.restoreLatest(), isTrue);
    expect(File(p.join(newDocs.path, 'photos/photo.jpg')).readAsStringSync(),
        'image-fixture');
    expect(File(p.join(newDocs.path, 'gps_logs/log_1.csv')).readAsStringSync(),
        'GPS fixture');
    final study = jsonDecode(
        File(p.join(newDocs.path, 'study_area/study_area_sites.json'))
            .readAsStringSync()) as List;
    expect(p.normalize(study.single['history'].single['photo_path'] as String),
        p.join(newDocs.path, 'photos', 'photo.jpg'));
    final restored = AppDatabase();
    addTearDown(restored.close);
    final session = await restored.getSurveySession(id);
    final responses = jsonDecode(session!.responses) as Map;
    final photo =
        jsonDecode((responses['answers'] as Map)['photo'] as String) as Map;
    expect(p.normalize(photo['path'] as String),
        p.join(newDocs.path, 'photos', 'photo.jpg'));
  });
}
