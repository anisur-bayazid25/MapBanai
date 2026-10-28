import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/response_layer_service.dart';

void main() {
  late AppDatabase db;
  late int project;
  late ResponseLayerService service;
  setUp(() async {
    db = AppDatabase.forTesting();
    project = await db
        .insertProject(const ProjectsCompanion(name: Value('Field study')));
    service = ResponseLayerService(db);
    final schema = SurveyForm(
        id: 'facilities',
        name: 'Facilities',
        description: '',
        questions: [
          Question(
              name: 'type',
              label: 'Type',
              type: QuestionType.select_multiple,
              choices: [
                Choice(name: 'tap', label: 'Tap'),
                Choice(name: 'toilet', label: 'Toilet')
              ]),
          Question(
              name: 'gps_a', label: 'Source GPS', type: QuestionType.geopoint),
          Question(
              name: 'gps_b',
              label: 'Destination GPS',
              type: QuestionType.geopoint),
        ]);
    await db.insertStoredForm(StoredFormsCompanion(
        projectId: Value(project),
        name: Value(schema.name),
        json: Value(jsonEncode(schema.toJson()))));
  });
  tearDown(() => db.close());

  Future<void> record(
      {int? projectId,
      String status = 'saved',
      String form = 'facilities',
      String layer = 'facilities',
      bool polygon = false,
      bool deleted = false}) async {
    await db.insertSurveySession(SurveySessionsCompanion(
        projectId: Value(projectId ?? project),
        title: const Value('Site'),
        status: Value(status),
        responses: Value(jsonEncode({
          'form_id': form,
          'layer_id': layer,
          'deleted': deleted,
          'geometry': polygon
              ? {
                  'type': 'Polygon',
                  'coordinates': [
                    [
                      [89.0, 22.0],
                      [89.1, 22.0],
                      [89.1, 22.1],
                      [89.0, 22.0]
                    ]
                  ]
                }
              : {
                  'type': 'Point',
                  'coordinates': [89.0, 22.0]
                },
          'answers': {
            'facility_name': 'Water point',
            'type': 'tap',
            'salinity': 2.4
          }
        }))));
  }

  test(
      'separates forms, layers and projects; retains typed answers and sources',
      () async {
    await record();
    await record(status: 'draft');
    await record(form: 'salinity');
    await record(layer: 'other');
    await record(deleted: true);
    final other =
        await db.insertProject(const ProjectsCompanion(name: Value('Other')));
    await record(projectId: other);
    final features = await service.features(project,
        formId: 'facilities', layerId: 'facilities');
    expect(features, hasLength(1));
    final properties = features.single['properties'] as Map;
    expect(properties['name'], 'Water point');
    expect(properties['salinity'], 2.4);
    expect(properties['source_response_id'], isNotNull);
    final before = await db.getSurveySessionsByProject(project);
    final id = await service.create(project, 'Facilities',
        formId: 'facilities', layerId: 'facilities');
    expect(
        (await ProjectWorkspaceService(db).load(project))
            .layers
            .any((l) => l.id == id),
        isTrue);
    expect(
        (await ProjectVectorLayerService(db).load(project)).single['features'],
        hasLength(1));
    expect(
        (await db.getSurveySessionsByProject(project)).map((s) => s.responses),
        before.map((s) => s.responses));
  });

  test(
      'boundary snapshots require polygons and remain visible reference layers',
      () async {
    await record(polygon: true, form: 'boundary', layer: 'boundary');
    await record();
    await expectLater(service.create(project, 'Mixed boundary', boundary: true),
        throwsStateError);
    await service.create(project, 'Study boundary',
        layerId: 'boundary', boundary: true);
    final layer = (await ProjectVectorLayerService(db).load(project)).single;
    expect(layer['role'], 'reference');
    expect(layer['visible'], isTrue);
    await expectLater(
        service.create(project, 'Empty', formId: 'missing'), throwsStateError);
  });

  test(
      'answer filters use exact values and map every explicitly selected GPS answer',
      () async {
    for (final type in ['tap toilet', 'tapstand', 'school']) {
      await db.insertSurveySession(SurveySessionsCompanion(
          projectId: Value(project),
          title: const Value('Station'),
          status: const Value('saved'),
          responses: Value(jsonEncode({
            'form_id': 'facilities',
            'layer_id': 'default',
            'answers': {
              'type': type,
              'gps_a': '22.0 89.0 0 5',
              'gps_b': {'latitude': 22.1, 'longitude': 89.1}
            }
          }))));
    }
    final features = await service.features(project,
        formId: 'facilities',
        question: 'type',
        values: {'tap', 'toilet'},
        gpsFields: {'gps_a', 'gps_b'});
    expect(features, hasLength(2));
    expect(features.map((f) => (f['properties'] as Map)['gps_question']),
        {'gps_a', 'gps_b'});
    expect((features.last['geometry'] as Map)['coordinates'], [89.1, 22.1]);
    expect(features.map((f) => (f['properties'] as Map)['id']).toSet(),
        hasLength(2));
    final layerId = await service.create(project, 'Water and sanitation',
        formId: 'facilities',
        question: 'type',
        values: {'tap', 'toilet'},
        gpsFields: {'gps_a', 'gps_b'});
    final layer = (await ProjectVectorLayerService(db).load(project)).single;
    expect(layer['answer_filter'], {
      'question': 'type',
      'values': ['tap', 'toilet']
    });
    expect(layer['gps_questions'], ['gps_a', 'gps_b']);
    expect(
        (await ProjectWorkspaceService(db).load(project))
            .layers
            .any((l) => l.id == layerId),
        isTrue);
    await expectLater(
        service.features(project, formId: 'facilities', question: 'type'),
        throwsStateError);
    await expectLater(
        service.features(project, formId: 'facilities', gpsFields: {'type'}),
        throwsStateError);
    expect(ResponseLayerService.matches(['tap', 'toilet'], {'tap'}), isTrue);
    expect(ResponseLayerService.matches('tapstand', {'tap'}, multiple: true),
        isFalse);
  });

  test('a bad first GPS cannot hide a valid selected second GPS', () async {
    await db.insertSurveySession(SurveySessionsCompanion(
        projectId: Value(project),
        title: const Value('Station'),
        status: const Value('saved'),
        responses: Value(jsonEncode({
          'form_id': 'facilities',
          'answers': {'gps_a': '999 999', 'gps_b': '22 89'}
        }))));
    final features = await service
        .features(project, formId: 'facilities', gpsFields: {'gps_b'});
    expect(features, hasLength(1));
    expect((features.single['geometry'] as Map)['coordinates'], [89, 22]);
  });

  test(
      'an invalid selected GPS never falls back to an unselected top-level location',
      () async {
    await db.insertSurveySession(SurveySessionsCompanion(
        projectId: Value(project),
        title: const Value('Station'),
        status: const Value('saved'),
        responses: Value(jsonEncode({
          'form_id': 'facilities',
          'gps': '22 89',
          'answers': {'gps_a': 'not a location'}
        }))));
    expect(
        await service
            .features(project, formId: 'facilities', gpsFields: {'gps_a'}),
        isEmpty);
  });
}
