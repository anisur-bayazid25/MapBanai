import 'package:mapbanai/services/workflow_requirements_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:uuid/uuid.dart';

/// Observations and status events are durable survey rows. They never overwrite
/// a site's baseline, and existing response sync/export carries their context.
class StudyCollectionService {
  final AppDatabase db;
  StudyCollectionService(this.db);
  static const workflowKey = 'study_collection_v1';
  static Map<String, dynamic>? data(SurveySession row) {
    try {
      final value = Map<String, dynamic>.from(jsonDecode(row.responses));
      return value['workflow'] == workflowKey ? value : null;
    } catch (_) {
      return null;
    }
  }

  static String roundKey(StudyWorkflow workflow, CollectionRound? round) =>
      workflow == StudyWorkflow.recurring ? round!.id : 'visits';

  Future<void> _validate(int projectId, StudyAreaSite site,
      StudyWorkflow workflow, CollectionRound? round) async {
    final workspace =
        await ProjectWorkspaceService(db).load(projectId, workflow: workflow);
    if (workflow == StudyWorkflow.verification ||
        !GuidedVisitService.belongsToProject(site, workspace.project) ||
        !workspace.layers.any((layer) => layer.id == site.layerId))
      throw StateError('Choose a site from this project and workflow.');
    if (workflow == StudyWorkflow.recurring &&
        (round == null ||
            !(await ProjectWorkspaceService(db).rounds(projectId, site.layerId))
                .any((item) => item.id == round.id)))
      throw StateError('Choose a collection round for this layer.');
  }

  Future<SurveySession> save(
      {required int projectId,
      required StudyAreaSite site,
      required StudyWorkflow workflow,
      CollectionRound? round,
      StoredForm? form,
      Map<String, dynamic> answers = const {},
      required StudyAreaStatus outcome,
      bool draft = false,
      SurveySession? previous,
      String note = '',
      bool statusOnly = false,
      PhotoRecord? evidencePhoto}) async {
    await _validate(projectId, site, workflow, round);
    if (![
      StudyAreaStatus.pending,
      StudyAreaStatus.completed,
      StudyAreaStatus.needsReview
    ].contains(outcome)) throw ArgumentError('Invalid collection status.');
    final requirements =
        await WorkflowRequirementsService(db).get(projectId, workflow);
    final photo = evidencePhoto ??
        (previous == null
            ? null
            : FieldQualityService.photo(data(previous)?['photo']));
    if (statusOnly &&
        outcome == StudyAreaStatus.completed &&
        (requirements.questionnaire || requirements.photo)) {
      throw StateError(
          'Complete the required questionnaire and photo before marking this site done.');
    }
    SurveyForm? schema;
    if (!statusOnly) {
      if (form == null && requirements.questionnaire) {
        throw StateError('Select a questionnaire from this project.');
      }
      if (form != null) {
        if (!(await db.getStoredFormsForProject(projectId))
            .any((row) => row.id == form.id)) {
          throw StateError('Select a questionnaire from this project.');
        }
        schema = SurveyForm.fromJson(jsonDecode(form.json));
        if (!draft) {
          final errors = await FieldQualityService.validateAnswersInWorker(
              schema, answers);
          errors
              .addAll(await FieldQualityService.validateMedia(schema, answers));
          if (errors.isNotEmpty) throw StateError(errors.first);
        }
      }
      if (!draft &&
          (photo != null ||
              (requirements.photo && outcome == StudyAreaStatus.completed))) {
        final error =
            await WorkflowRequirementsService.photoError(answers, photo);
        if (error != null) throw StateError(error);
      }
    }
    final project = (await db.getProjectById(projectId))!;
    final timestamp = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'workflow': workflowKey,
      'study_workflow': workflow.name,
      'record_kind': statusOnly ? 'status' : 'observation',
      'project_external_id': project.externalId,
      'site_id': site.id,
      'feature_uuid': site.featureUuid,
      'layer_id': site.layerId,
      'round_id': roundKey(workflow, round),
      'collection_round': round?.toJson(),
      'site_name': site.displayName,
      'geometry': site.currentGeometry,
      'form_id': schema?.id,
      'form_name': schema?.name,
      'stored_form_id': form?.id,
      'form_snapshot': schema?.toJson(),
      'workflow_requirements': requirements.toJson(),
      if (photo != null) 'photo': photo.toJson(),
      'answers': answers,
      'outcome': outcome.name,
      'note': note.trim(),
      'user_name': await db.getSetting('user_name') ?? '',
      'observed_at': timestamp.toIso8601String(),
      'draft_revision': (previous == null
              ? 0
              : data(previous)?['draft_revision'] as int? ?? 0) +
          1,
    };
    return db.transaction(() async {
      int id;
      if (previous != null) {
        final current = await db.getSurveySession(previous.id);
        final saved = current == null ? null : data(current);
        if (current == null ||
            saved == null ||
            current.status != 'draft' ||
            current.projectId != projectId ||
            saved['site_id'] != site.id ||
            saved['study_workflow'] != workflow.name ||
            saved['round_id'] != payload['round_id'] ||
            saved['form_id'] != payload['form_id'] ||
            saved['draft_revision'] != data(previous)?['draft_revision'])
          throw StateError('This draft changed. Reopen it before saving.');
        id = current.id;
        await db.updateSurveySession(id,
            responses: jsonEncode(payload), status: draft ? 'draft' : 'saved');
      } else {
        id = await db.insertSurveySession(SurveySessionsCompanion(
            projectId: Value(projectId),
            externalId: Value(const Uuid().v4()),
            title:
                Value('${round?.name ?? workflow.title} — ${site.displayName}'),
            status: Value(draft ? 'draft' : 'saved'),
            responses: Value(jsonEncode(payload)),
            createdAt: Value(timestamp)));
      }
      return (await db.getSurveySession(id))!;
    });
  }

  Future<Map<String, StudyAreaStatus>> statuses(int projectId, String layerId,
      StudyWorkflow workflow, CollectionRound? round) async {
    final rows = await db.getSurveySessionsByProject(projectId);
    rows.sort((a, b) {
      final order = a.createdAt.compareTo(b.createdAt);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    final latest = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final value = data(row);
      if (row.status != 'saved' ||
          value == null ||
          value['layer_id'] != layerId ||
          value['study_workflow'] != workflow.name ||
          value['round_id'] != roundKey(workflow, round)) continue;
      final old = latest[value['site_id']];
      if (old == null ||
          '${value['observed_at']}'.compareTo('${old['observed_at']}') >= 0)
        latest[value['site_id']] = value;
    }
    return {
      for (final entry in latest.entries)
        entry.key: StudyAreaStatus.values
                .where((status) => status.name == entry.value['outcome'])
                .firstOrNull ??
            StudyAreaStatus.pending
    };
  }

  Future<SurveySession?> draftFor(int projectId, StudyAreaSite site,
      StudyWorkflow workflow, CollectionRound? round, StoredForm? form) async {
    final schemaId = form == null ? null : (jsonDecode(form.json) as Map)['id'];
    return (await db.getSurveySessionsByProject(projectId)).where((row) {
      final value = data(row);
      return row.status == 'draft' &&
          value?['site_id'] == site.id &&
          value?['layer_id'] == site.layerId &&
          value?['study_workflow'] == workflow.name &&
          value?['round_id'] == roundKey(workflow, round) &&
          value?['form_id'] == schemaId;
    }).firstOrNull;
  }

  /// Extract only records from the selected questionnaire/measurement. The
  /// source responses remain intact; stable site IDs prevent duplicate sites
  /// when a previous layer is used as the source for another round.
  Future<List<Map<String, dynamic>>> measurementFeatures(
      int projectId, String formId, String field) async {
    final result = <String, Map<String, dynamic>>{};
    final forms = await db.getStoredFormsForProject(projectId);
    final sourceForm = forms
        .where((row) => (jsonDecode(row.json) as Map)['id'] == formId)
        .firstOrNull;
    if (sourceForm == null)
      throw StateError('Select a questionnaire from this project.');
    final schema = SurveyForm.fromJson(jsonDecode(sourceForm.json));
    if (!schema.questions.any((question) =>
        question.name == field &&
        [QuestionType.integer, QuestionType.decimal, QuestionType.calculated]
            .contains(question.type)))
      throw StateError('Select a numeric measurement from this questionnaire.');
    final geopoints = schema.questions
        .where((question) => question.type == QuestionType.geopoint)
        .map((question) => question.name)
        .toSet();
    for (final row in await db.getSurveySessionsByProject(projectId)) {
      if (row.status != 'saved') continue;
      Map<String, dynamic> response;
      try {
        response = Map<String, dynamic>.from(jsonDecode(row.responses));
      } catch (_) {
        continue;
      }
      final value = (response['answers'] as Map?)?[field];
      if (response['form_id'] != formId ||
          value == null ||
          '$value'.trim().isEmpty ||
          response['record_kind'] == 'status') continue;
      final number =
          value is num ? value.toDouble() : double.tryParse('$value');
      if (number == null || !number.isFinite) continue;
      final feature = await WebMapDataService(db)
          .featureForSession(row, geopointFields: geopoints);
      if (feature == null ||
          (feature['geometry'] as Map)['type'] != 'Point' ||
          !FieldQualityService.validGeometry(
              Map<String, dynamic>.from(feature['geometry']))) continue;
      final id = '${response['site_id'] ?? row.externalId ?? row.id}';
      result[id] = {
        'type': 'Feature',
        'geometry': feature['geometry'],
        'properties': {
          'id': id,
          'name': response['site_name'] ??
              (response['answers'] as Map?)?['site_name'] ??
              (response['answers'] as Map?)?['station_name'] ??
              row.title,
          field: value,
          'source_response_id': row.externalId ?? row.id,
          'source_form_id': formId,
          'measurement_field': field,
        }
      };
    }
    return result.values.toList();
  }

  Future<String> createMeasurementLayer(
      int projectId, String name, String formId, String field) async {
    if (name.trim().isEmpty) throw ArgumentError('Enter a layer name.');
    final features = await measurementFeatures(projectId, formId, field);
    if (features.isEmpty)
      throw StateError(
          'No saved measurements with point locations match this selection.');
    final service = ProjectVectorLayerService(db);
    final id = const Uuid().v4();
    await service.save(projectId, [
      ...await service.load(projectId),
      {
        'id': id,
        'name': name.trim(),
        'visible': true,
        'color': '#467ca1',
        'opacity': 0.8,
        'role': 'study_area',
        'workflows': [StudyWorkflow.recurring.name],
        'features': features,
        'source_form_id': formId,
        'measurement_field': field,
      }
    ]);
    await ProjectWorkspaceService(db).select(projectId,
        layerId: 'vector:$id', workflow: StudyWorkflow.recurring);
    return 'vector:$id';
  }
}
