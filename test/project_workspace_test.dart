import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/record_geometry.dart';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:mapbanai/services/webmap_generator.dart';
import 'package:mapbanai/services/form_attribute_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'projects own layers and forms; legacy sites require explicit assignment',
      () async {
    final db = AppDatabase.forTesting();
    final dir = await Directory.systemTemp.createTemp('workspace_');
    final store = StudyAreaStore(baseDir: dir);
    try {
      final a = await db
          .insertProject(const ProjectsCompanion(name: drift.Value('A')));
      final b = await db
          .insertProject(const ProjectsCompanion(name: drift.Value('B')));
      final service = ProjectWorkspaceService(db);
      final salt = await service.addLayer(a, 'Salinity — October');
      final next = await service.addLayer(a, 'Salinity — December');
      expect(salt.layerId, isNot(next.layerId));
      expect((await service.load(b)).layers.length, 1);
      final form = SurveyForm(
          id: 'salt',
          name: 'Salinity',
          description: '',
          questions: [
            Question(
                name: 'salinity',
                label: 'Salinity (ppt)',
                type: QuestionType.decimal)
          ]);
      final id = await db.insertStoredForm(StoredFormsCompanion(
          projectId: drift.Value(a),
          name: drift.Value(form.name),
          json: drift.Value(jsonEncode(form.toJson()))));
      await service.select(a, formId: id, layerId: salt.layerId);
      await expectLater(service.select(b, formId: id), throwsStateError);
      await expectLater(
          service.select(b, layerId: salt.layerId), throwsStateError);
      final legacy = StudyAreaSite(id: 'old', latitude: 23, longitude: 90);
      expect(
          GuidedVisitService.belongsToProject(legacy, salt.project), isFalse);
      await store.addSites([legacy]);
      expect(
          await store.assignUnclaimedSites(
              projectId: a,
              projectExternalId: salt.project.externalId!,
              layerId: salt.layerId),
          1);
      final site = (await store.loadSites()).single;
      expect(
          GuidedVisitService.belongsToProject(
              site, (await service.load(b)).project),
          isFalse);
      expect(GuidedVisitService.belongsToProject(site, salt.project), isTrue);
      site.formAnswers = {'salinity': 4.5};
      site.formSnapshot = form.toJson();
      await store.updateSite(site);
      final roundTrip = StudyAreaService.parseGeoJson(jsonEncode({
        'type': 'FeatureCollection',
        'features': [site.toGeoJsonFeature()]
      })).single;
      expect(roundTrip.layerId, salt.layerId);
      expect(roundTrip.formAnswers['salinity'], 4.5);
      final outbox = StudyAreaOutboxService(db);
      await outbox.enqueue(site, 'Alice');
      await outbox.enqueue(site, 'Alice');
      expect((await db.getSurveySessionsByProject(a)).length, 1);
      expect((await db.getSurveySessionsByProject(b)), isEmpty);
      final fc = await WebMapDataService(db, studyAreaStore: store)
          .buildFeatureCollectionForProject(a);
      expect(fc['features'], hasLength(1));
      expect(
          fc['features'][0]['properties']['layer_name'], 'Salinity — October');
      expect(
          (await WebMapDataService(db, studyAreaStore: store)
              .buildFeatureCollectionForProject(b))['features'],
          isEmpty);
      final html = await WebMapGenerator().generateHtml(featureCollection: fc);
      await File('.dart_tool/project-atlas-preview.html').writeAsString(html);
      expect(html, contains('value-field'));
      expect(html, contains('renderVersion'));
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test('project replacement retains credentials and named layer catalogue',
      () async {
    final db = AppDatabase.forTesting();
    try {
      final id = await db
          .insertProject(const ProjectsCompanion(name: drift.Value('Round')));
      final workspace =
          await ProjectWorkspaceService(db).addLayer(id, 'Salinity round 2');
      await db.upsertSyncConfig(
          projectId: id,
          syncEndpointUrl: 'https://example.org/script',
          syncApiKey: 'private-key');
      final package =
          await ProjectExporter(db).buildData((await db.getProjectById(id))!);
      expect(package.meta.projectId, workspace.project.externalId);
      final replaced = await ProjectImporter(db)
          .commitQrData(package, newCopy: false, replaceExistingId: id);
      expect((await db.getSyncConfig(replaced.projectId))!.syncApiKey,
          'private-key');
      expect(
          (await ProjectWorkspaceService(db).load(replaced.projectId))
              .layers
              .last
              .name,
          'Salinity round 2');
      final copy =
          await ProjectImporter(db).commitQrData(package, newCopy: true);
      expect(await db.getSyncConfig(copy.projectId), isNull);
    } finally {
      await db.close();
    }
  });

  test(
      'survey geometry renders alongside GIS without treating text as location',
      () {
    final geometries = RecordGeometry.fromResponses({
      'form_snapshot': {
        'questions': [
          {'name': 'location', 'type': 'geopoint'}
        ]
      },
      'answers': {
        'location': '23.8,90.4,5',
        'text': '11 12',
        'boundary': {
          'type': 'Polygon',
          'coordinates': [
            [
              [90, 23],
              [91, 23],
              [90, 24],
              [90, 23]
            ]
          ]
        }
      }
    });
    expect(geometries.map((g) => g['type']), ['Point', 'Polygon']);
  });

  test('sync URL and key survive partial writes and database reopen', () async {
    final dir = await Directory.systemTemp.createTemp('sync_retention_');
    final file = File('${dir.path}/app.db');
    var db = AppDatabase.testWithExecutor(NativeDatabase(file));
    try {
      final project = await db
          .insertProject(const ProjectsCompanion(name: drift.Value('Field')));
      await db.upsertSyncConfig(
          projectId: project,
          syncEndpointUrl: 'https://example.org/script',
          syncApiKey: 'test-key');
      await db.upsertSyncConfig(
          projectId: project, lastSyncAt: drift.Value(DateTime.now()));
      await db.close();
      db = AppDatabase.testWithExecutor(NativeDatabase(file));
      final config = (await db.getSyncConfig(project))!;
      expect(config.syncEndpointUrl, 'https://example.org/script');
      expect(config.syncApiKey, 'test-key');
      await db.upsertSyncConfig(projectId: project, syncEndpointUrl: '');
      expect((await db.getSyncConfig(project))!.syncEndpointUrl, isNull);
      expect((await db.getSyncConfig(project))!.syncApiKey, 'test-key');
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test(
      'shared form prefills typed choices and geometry without overwriting answers',
      () {
    final form = SurveyForm(id: 'f', name: 'Form', description: '', questions: [
      Question(
          name: 'types', label: 'Types', type: QuestionType.select_multiple),
      Question(name: 'location', label: 'Location', type: QuestionType.geopoint)
    ]);
    final answers = FormAttributeService.prefill(form, {
      'types': '["a","b"]'
    }, geometry: {
      'type': 'Point',
      'coordinates': [90.4, 23.8]
    });
    expect(answers['types'], ['a', 'b']);
    expect(answers['location'], '23.8,90.4,0.0');
  });

  test('large form validates in worker and unsafe calculations finish promptly',
      () async {
    final form = SurveyForm(
        id: 'big',
        name: 'Large form',
        description: '',
        questions: List.generate(
            1500,
            (i) => Question(
                name: 'q$i',
                label: 'Q$i',
                type: QuestionType.integer,
                required: true,
                constraint: '. >= 0')));
    final watch = Stopwatch()..start();
    final errors = await FieldQualityService.validateAnswersInWorker(
        form, {for (var i = 0; i < 1500; i++) 'q$i': '3'});
    expect(errors, isEmpty);
    expect(watch.elapsed.inSeconds, lessThan(3));
    final impossible = SurveyForm(
        id: 'bad',
        name: 'Bad calculation',
        description: '',
        questions: [
          Question(
              name: 'x',
              label: 'X',
              type: QuestionType.integer,
              constraint: 'round(., 1000000000) = .')
        ]);
    expect(
        await FieldQualityService.validateAnswersInWorker(
            impossible, {'x': '3'}),
        isNotEmpty);
  });

  test('WebMap escapes script injection in data and filter labels', () async {
    const name = '</script><script>alert(1)</script>';
    final html = await WebMapGenerator().generateHtml(featureCollection: {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [90, 23]
          },
          'properties': {'form_name': name, 'surveyor': name}
        }
      ]
    }, leafletCss: '', leafletJs: '');
    expect(html, isNot(contains(name)));
    expect(html, contains(r'\u003c/script>'));
  });
}
