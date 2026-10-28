import 'dart:convert';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:uuid/uuid.dart';

/// Makes a project-owned snapshot without moving or editing source responses.
class ResponseLayerService {
  final AppDatabase db;
  ResponseLayerService(this.db);

  Future<List<Map<String, dynamic>>> features(int projectId,
      {String? formId,
      String? layerId,
      String? question,
      Set<String> values = const {},
      Set<String> gpsFields = const {}}) async {
    SurveyForm? schema;
    if (formId != null) {
      final forms = await db.getStoredFormsForProject(projectId);
      final selected = forms
          .where((row) => (jsonDecode(row.json) as Map)['id'] == formId)
          .lastOrNull;
      if (selected == null)
        throw StateError('Select a questionnaire from this project.');
      schema = SurveyForm.fromJson(jsonDecode(selected.json));
    }
    final selectedQuestion =
        schema?.questions.where((q) => q.name == question).firstOrNull;
    if (question != null && (selectedQuestion == null || values.isEmpty)) {
      throw StateError('Select a question and at least one answer value.');
    }
    if (gpsFields.isNotEmpty &&
        (schema == null ||
            gpsFields.any((name) => !schema!.questions.any(
                (q) => q.name == name && q.type == QuestionType.geopoint)))) {
      throw StateError('Select GPS questions from this questionnaire.');
    }
    final collection =
        await WebMapDataService(db).buildFeatureCollectionForProject(projectId);
    var candidates = (collection['features'] as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .where((feature) {
      final properties = feature['properties'] as Map;
      return properties['source'] == 'collection' &&
          properties['status'] == 'saved' &&
          (formId == null || properties['form_id'] == formId) &&
          (layerId == null || properties['layer_id'] == layerId) &&
          (question == null ||
              matches((properties['answers'] as Map?)?[question], values,
                  multiple: selectedQuestion?.type ==
                      QuestionType.select_multiple)) &&
          (gpsFields.isNotEmpty ||
              FieldQualityService.validGeometry(
                  Map<String, dynamic>.from(feature['geometry'] as Map)));
    }).toList();
    if (gpsFields.isNotEmpty) {
      // Extract each chosen GPS answer explicitly, never another coordinate-like
      // answer or the GIS geometry that happens to precede it in the record.
      final permitted = candidates
          .map((f) => (f['properties'] as Map)['id'].toString())
          .toSet();
      final selected = <Map<String, dynamic>>[];
      for (final row in await db.getSurveySessionsByProject(projectId)) {
        final id = row.externalId ?? row.id.toString();
        if (!permitted.contains(id)) continue;
        final response = Map<String, dynamic>.from(jsonDecode(row.responses));
        final answers = response['answers'] as Map? ?? {};
        for (final field in gpsFields) {
          if (answers[field] == null) continue;
          final pointResponse = {...response}
            ..remove('geometry')
            ..remove('feature_type')
            ..remove('visit')
            ..remove('geopoint')
            ..remove('location_point')
            ..remove('location')
            ..remove('gps');
          pointResponse['answers'] = {field: answers[field]};
          final feature = await WebMapDataService(db).featureForSession(
              row.copyWith(responses: jsonEncode(pointResponse)));
          if (feature == null ||
              !FieldQualityService.validGeometry(feature['geometry'],
                  expectedType: 'Point')) continue;
          final properties =
              Map<String, dynamic>.from(feature['properties'] as Map);
          feature['properties'] = {
            ...properties,
            'id': '$id:gps:$field',
            'source_response_id': id,
            'gps_question': field,
            'answers': answers
          };
          selected.add(feature);
        }
      }
      candidates = selected;
    }
    final seen = <String>{};
    return candidates
        .where((feature) => seen.add(
            '${(feature['properties'] as Map)['id']}:${jsonEncode(feature['geometry'])}'))
        .map((feature) {
      final properties =
          Map<String, dynamic>.from(feature['properties'] as Map);
      return {
        ...feature,
        'properties': {
          ...?properties['answers'] as Map?,
          ...properties,
          'name': properties['name']?.toString().isNotEmpty == true
              ? properties['name']
              : (properties['answers'] as Map?)?['site_name'] ??
                  (properties['answers'] as Map?)?['facility_name'] ??
                  properties['id'],
          'source_response_id':
              properties['source_response_id'] ?? properties['id'],
        }
      };
    }).toList();
  }

  static bool matches(dynamic answer, Set<String> selected,
      {bool multiple = false}) {
    if (answer == null) return false;
    final answers = answer is List
        ? answer.map((v) => '$v').toSet()
        : multiple
            ? '$answer'.split(RegExp(r'\s+')).toSet()
            : {'$answer'};
    return answers.any(selected.contains);
  }

  Future<Set<String>> answerValues(int projectId, String formId, String field,
      {bool multiple = false, String? layerId}) async {
    final result = <String>{};
    for (final row in await db.getSurveySessionsByProject(projectId)) {
      if (row.status != 'saved') continue;
      try {
        final data = jsonDecode(row.responses) as Map;
        if (data['form_id'] != formId ||
            data['deleted'] == true ||
            (layerId != null && (data['layer_id'] ?? 'default') != layerId))
          continue;
        final value = (data['answers'] as Map?)?[field];
        if (value is List) {
          result.addAll(value.map((v) => '$v'));
        } else if (value != null) {
          result.addAll(multiple ? '$value'.split(RegExp(r'\s+')) : ['$value']);
        }
      } catch (_) {/* Skip malformed legacy records. */}
    }
    return result..remove('');
  }

  Future<String> create(int projectId, String name,
      {String? formId,
      String? layerId,
      bool boundary = false,
      String? question,
      Set<String> values = const {},
      Set<String> gpsFields = const {}}) async {
    if (name.trim().isEmpty) throw ArgumentError('Enter a layer name.');
    if (await db.getProjectById(projectId) == null) {
      throw StateError('Project no longer exists');
    }
    final selected = await features(projectId,
        formId: formId,
        layerId: layerId,
        question: question,
        values: values,
        gpsFields: gpsFields);
    if (selected.isEmpty) {
      throw StateError(
          'No saved responses with locations match this selection.');
    }
    if (boundary &&
        selected.any((f) => !['Polygon', 'MultiPolygon']
            .contains((f['geometry'] as Map)['type']))) {
      throw StateError('A boundary layer must contain only polygons.');
    }
    final id = const Uuid().v4();
    await db.transaction(() async {
      final vectors = ProjectVectorLayerService(db);
      await vectors.save(projectId, [
        ...await vectors.load(projectId),
        {
          'id': id,
          'name': name.trim(),
          'role': boundary ? 'reference' : 'study_area',
          'visible': true,
          'color': boundary ? '#d97706' : '#467ca1',
          'opacity': boundary ? 0.25 : 0.8,
          'features': selected,
          'source_form_id': formId,
          'source_layer_id': layerId,
          if (question != null)
            'answer_filter': {'question': question, 'values': values.toList()},
          if (gpsFields.isNotEmpty) 'gps_questions': gpsFields.toList(),
          'source_kind': 'response_snapshot',
          'snapshot_at': DateTime.now().toUtc().toIso8601String(),
        }
      ]);
    });
    return 'vector:$id';
  }
}
