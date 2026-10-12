import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:uuid/uuid.dart';

class GuidedVisitResult {
  final SurveySession session;
  final bool mapApplied;
  final String? error;
  const GuidedVisitResult(this.session, {required this.mapApplied, this.error});
}

/// A durable survey row is the authoritative visit record. Map reconciliation
/// is separate and explicitly retryable because SQLite and JSON cannot share
/// an atomic transaction. The visit UUID makes site audit updates idempotent.
class GuidedVisitService {
  final AppDatabase database;
  final StudyAreaStore sites;
  GuidedVisitService({required this.database, required this.sites});

  static bool belongsToProject(StudyAreaSite site, Project project) {
    if (site.projectExternalId != null)
      return site.projectExternalId == project.externalId;
    return site.projectId == project.id;
  }

  static bool isVisit(SurveySession session) {
    try {
      return decode(session)['visit'] is Map &&
          decode(session)['workflow'] == 'guided_visit_v1';
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> decode(SurveySession session) =>
      Map<String, dynamic>.from(jsonDecode(session.responses) as Map);
  static Map<String, dynamic> visit(SurveySession session) =>
      Map<String, dynamic>.from(decode(session)['visit'] as Map);
  static int sequence(SurveySession session) =>
      (visit(session)['sequence'] as num?)?.toInt() ?? 0;

  Future<SurveySession> start(
      {required int projectId, required StudyAreaSite site}) async {
    var project = await database.getProjectById(projectId);
    if (project != null && project.externalId == null) {
      await database.transaction(() async {
        final current = (await database.getProjectById(projectId))!;
        if (current.externalId == null) {
          await (database.update(database.projects)
                ..where((row) => row.id.equals(projectId)))
              .write(ProjectsCompanion(
                  externalId: drift.Value(const Uuid().v4())));
        }
      });
      project = await database.getProjectById(projectId);
    }
    if (project == null) throw StateError('Project no longer exists.');
    if (!belongsToProject(site, project))
      throw StateError('This feature belongs to a different project.');
    final snapshot =
        jsonDecode(jsonEncode(site.toJson())) as Map<String, dynamic>;
    final row = await database.insertSurveySession(SurveySessionsCompanion(
        projectId: drift.Value(projectId),
        title: drift.Value('Visit draft — ${site.displayName}'),
        status: const drift.Value('draft'),
        responses: drift.Value(jsonEncode({
          'workflow': 'guided_visit_v1',
          'layer_id': site.layerId,
          'answers': <String, dynamic>{},
          'visit': {
            'id': const Uuid().v4(),
            'project_id': projectId,
            'project_external_id': project.externalId,
            'site_id': site.id,
            'feature_uuid': site.featureUuid,
            'layer_id': site.layerId,
            'started_at': DateTime.now().toUtc().toIso8601String(),
            'state': 'draft',
            'sequence': 0,
            'form_validated': false,
            'site_sync': 'not_started',
            'expected_revision': site.revision,
            'expected_revision_id': site.revisionToken,
            'site_before': snapshot,
            'site_after': snapshot,
          },
        }))));
    return (await database.getSurveySession(row))!;
  }

  Future<SurveySession> saveDraft(
      {required SurveySession session,
      StudyAreaSite? revisedSite,
      StoredForm? storedForm,
      Map<String, dynamic>? answers,
      bool? formValidated,
      PhotoRecord? photo}) async {
    await database.transaction(() async {
      final current = await database.getSurveySession(session.id);
      if (current == null || !isVisit(current))
        throw StateError('Visit draft no longer exists.');
      if (current.projectId != session.projectId || current.status != 'draft')
        throw StateError(
            'This visit is already finalized. Reload its saved record.');
      if (sequence(current) != sequence(session))
        throw StateError(
            'This draft changed in another screen. Reload before saving.');
      final response = decode(current);
      final metadata = visit(current);
      if (revisedSite != null) {
        if (revisedSite.id != metadata['site_id'])
          throw StateError('A draft cannot change its linked feature.');
        response['visit'] = metadata;
        metadata['site_after'] = revisedSite.toJson();
      }
      if (storedForm != null) {
        if (storedForm.projectId != current.projectId)
          throw StateError('Choose a form from this project.');
        final form = SurveyForm.fromJson(
            Map<String, dynamic>.from(jsonDecode(storedForm.json) as Map));
        response['form_id'] = form.id;
        response['form_name'] = form.name;
        response['form_snapshot'] = form.toJson();
        metadata['stored_form_id'] = storedForm.id;
        metadata['form_validated'] = false;
      }
      if (answers != null)
        response['answers'] = jsonDecode(jsonEncode(answers));
      if (formValidated != null) metadata['form_validated'] = formValidated;
      if (photo != null) response['photo'] = photo.toJson();
      metadata['sequence'] = sequence(current) + 1;
      metadata['last_saved_at'] = DateTime.now().toUtc().toIso8601String();
      response['visit'] = metadata;
      await database.updateSurveySession(current.id,
          responses: jsonEncode(response));
    });
    return (await database.getSurveySession(session.id))!;
  }

  Future<GuidedVisitResult> finalize(SurveySession session) async {
    final current = await database.getSurveySession(session.id);
    if (current == null || !isVisit(current))
      throw StateError('Visit does not exist.');
    if (current.status == 'saved') return reconcile(current);
    if (sequence(current) != sequence(session))
      throw StateError('Draft changed. Reload it before finishing.');
    final response = decode(current);
    final metadata = visit(current);
    if (metadata['form_validated'] != true || response['form_snapshot'] is! Map)
      throw StateError('Complete and save the selected survey first.');
    final form = SurveyForm.fromJson(
        Map<String, dynamic>.from(response['form_snapshot']));
    final errors = await FieldQualityService.validateAnswersInWorker(
        form, Map<String, dynamic>.from(response['answers'] as Map));
    if (errors.isNotEmpty) throw StateError(errors.first);
    final photoError = await FieldQualityService.validatePhoto(
        FieldQualityService.photo(response['photo']));
    if (photoError != null) throw StateError(photoError);
    final site = StudyAreaSite.fromJson(
        Map<String, dynamic>.from(metadata['site_after'] as Map));
    if (site.status == StudyAreaStatus.pending ||
        site.status == StudyAreaStatus.completed)
      throw StateError(
          'Choose a visit outcome: verified, updated, not found or needs review.');
    if (site.status != StudyAreaStatus.verified &&
        site.changeNote.trim().isEmpty)
      throw StateError('Add a change or review note for this visit outcome.');
    final geometry = site.currentGeometry;
    site.formAnswers = Map<String, dynamic>.from(response['answers'] as Map);
    site.formSnapshot = Map<String, dynamic>.from(response['form_snapshot']);
    metadata['site_after'] = site.toJson();
    if (!FieldQualityService.validGeometry(geometry))
      throw StateError('Feature geometry is missing or invalid.');
    await database.transaction(() async {
      final latest = await database.getSurveySession(current.id);
      if (latest == null) throw StateError('Visit was deleted.');
      if (latest.status == 'saved') return;
      if (sequence(latest) != sequence(current))
        throw StateError('Draft changed while finalizing. Reload it.');
      metadata['state'] = 'committed';
      metadata['site_sync'] = 'pending';
      metadata['completed_at'] = DateTime.now().toUtc().toIso8601String();
      metadata['sequence'] = sequence(current) + 1;
      response['visit'] = metadata;
      response['site_id'] = site.id;
      response['user_name'] = await database.getSetting('user_name');
      response['recorded_at'] = metadata['completed_at'];
      await database.updateSurveySession(current.id,
          title: 'Visit — ${site.displayName}',
          status: 'saved',
          responses: jsonEncode(response));
    });
    return reconcile((await database.getSurveySession(current.id))!);
  }

  /// Called only after the user reviews the current map and the proposed visit.
  /// A second optimistic token prevents changes during that review being lost.
  Future<GuidedVisitResult> rebasePending(SurveySession session,
      {required String expectedCurrentToken}) async {
    final currentSite = (await sites.loadSites())
        .where((site) => site.id == visit(session)['site_id'])
        .firstOrNull;
    if (currentSite == null)
      throw StateError(
          'Feature was removed. Restore or review the study map before applying this visit.');
    if (currentSite.revisionToken != expectedCurrentToken)
      throw StateError(
          'Map changed again during review. Reload and compare the versions.');
    final project = (await database.getProjectById(session.projectId))!;
    if (!belongsToProject(currentSite, project))
      throw StateError('Current feature belongs to another project.');
    await database.transaction(() async {
      final latest = (await database.getSurveySession(session.id))!;
      final response = decode(latest);
      final metadata = visit(latest);
      if (latest.status != 'saved' || metadata['site_sync'] == 'applied')
        throw StateError('Only a saved pending visit can be rebased.');
      if (sequence(latest) != sequence(session))
        throw StateError('Visit changed during review. Reload it.');
      final proposal = Map<String, dynamic>.from(metadata['site_after'] as Map);
      proposal['revision'] = currentSite.revision;
      proposal['revision_id'] = currentSite.revisionToken;
      proposal['history'] = currentSite.toJson()['history'];
      metadata['site_after'] = proposal;
      metadata['reconciliation_before'] = currentSite.toJson();
      metadata['expected_revision'] = currentSite.revision;
      metadata['expected_revision_id'] = currentSite.revisionToken;
      metadata['sequence'] = sequence(latest) + 1;
      metadata['reviewed_at'] = DateTime.now().toUtc().toIso8601String();
      response['visit'] = metadata;
      await database.updateSurveySession(latest.id,
          responses: jsonEncode(response));
    });
    return reconcile((await database.getSurveySession(session.id))!);
  }

  Future<GuidedVisitResult> reconcile(SurveySession session) async {
    final latest = (await database.getSurveySession(session.id))!;
    if (latest.status != 'saved' || !isVisit(latest))
      throw StateError('Only saved visits can reconcile the map.');
    final response = decode(latest);
    final metadata = visit(latest);
    if (metadata['site_sync'] == 'applied')
      return GuidedVisitResult(latest, mapApplied: true);
    final site = StudyAreaSite.fromJson(
        Map<String, dynamic>.from(metadata['site_after'] as Map));
    site.projectId = latest.projectId;
    site.projectExternalId = metadata['project_external_id'] as String?;
    try {
      await sites.updateSite(site,
          expectedRevision: (metadata['expected_revision'] as num?)?.toInt(),
          expectedRevisionId: metadata['expected_revision_id'] as String?,
          author: response['user_name']?.toString() ?? 'Local fieldworker',
          visitId: metadata['id'] as String,
          sessionId: latest.id,
          formId: (metadata['stored_form_id'] as num?)?.toInt(),
          photoPath: FieldQualityService.photo(response['photo'])?.path);
      metadata['site_sync'] = 'applied';
      metadata.remove('reconciliation_error');
      metadata['applied_revision_id'] = site.revisionToken;
      metadata['site_after'] = site.toJson();
      response['visit'] = metadata;
      await database.updateSurveySession(latest.id,
          responses: jsonEncode(response));
      return GuidedVisitResult((await database.getSurveySession(latest.id))!,
          mapApplied: true);
    } catch (error) {
      // Survey row remains saved even when an optimistic map revision conflicts.
      metadata['site_sync'] = 'pending';
      metadata['reconciliation_error'] = error.toString();
      response['visit'] = metadata;
      await database.updateSurveySession(latest.id,
          responses: jsonEncode(response));
      return GuidedVisitResult((await database.getSurveySession(latest.id))!,
          mapApplied: false, error: error.toString());
    }
  }
}
