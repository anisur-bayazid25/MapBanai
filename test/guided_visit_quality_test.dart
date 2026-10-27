import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/workflow_requirements_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';

class FailingVisitStore extends StudyAreaStore {
  FailingVisitStore(Directory dir) : super(baseDir: dir);
  bool fail = false;
  @override
  Future<void> updateSite(StudyAreaSite site,
      {int? expectedRevision,
      String? expectedRevisionId,
      String author = 'Local fieldworker',
      String? visitId,
      int? sessionId,
      int? formId,
      String? photoPath}) {
    if (fail) throw const FileSystemException('Simulated map write failure');
    return super.updateSite(site,
        expectedRevision: expectedRevision,
        expectedRevisionId: expectedRevisionId,
        author: author,
        visitId: visitId,
        sessionId: sessionId,
        formId: formId,
        photoPath: photoPath);
  }
}

void main() {
  test(
      'quality accepts timezone dates and legacy time but rejects impossible dates',
      () {
    final form =
        SurveyForm(id: 'date', name: 'Date', description: '', questions: [
      Question(name: 'date', label: 'Date', type: QuestionType.datetime),
      Question(name: 'time', label: 'Time', type: QuestionType.time)
    ]);
    expect(
        FieldQualityService.validateAnswers(
            form, {'date': '2026-10-12T00:05:00+06:00', 'time': '4:35 PM'}),
        isEmpty);
    expect(
        FieldQualityService.validateAnswers(
            form, {'date': '2026-02-31', 'time': '25:00'}),
        hasLength(2));
  });

  late AppDatabase db;
  late Directory dir;
  late FailingVisitStore store;
  late GuidedVisitService service;
  late int projectId;
  late StudyAreaSite baseline;
  late StoredForm stored;
  late PhotoRecord photo;
  setUp(() async {
    db = AppDatabase.forTesting();
    dir = Directory.systemTemp.createTempSync('mapbanai_visit_');
    store = FailingVisitStore(dir);
    service = GuidedVisitService(database: db, sites: store);
    projectId = await db.insertProject(
        const ProjectsCompanion(name: drift.Value('Field project')));
    baseline = StudyAreaSite(
        id: 'site-1',
        projectId: projectId,
        latitude: 23,
        longitude: 90,
        attributes: {'name': 'Baseline'});
    await store.addSites([baseline]);
    final form = SurveyForm(
        id: 'form-1',
        name: 'Field form',
        description: '',
        questions: [
          Question(
              name: 'condition',
              label: 'Condition',
              type: QuestionType.text,
              required: true)
        ]);
    final id = await db.insertStoredForm(StoredFormsCompanion(
        projectId: drift.Value(projectId),
        name: drift.Value(form.name),
        json: drift.Value(jsonEncode(form.toJson()))));
    stored = (await db.getStoredFormsForProject(projectId))
        .singleWhere((row) => row.id == id);
    photo = await PhotoStore.saveGeotagged(
        Uint8List.fromList(image.encodeJpg(image.Image(width: 8, height: 8))),
        latitude: 23,
        longitude: 90,
        dir: Directory('${dir.path}/photos'),
        accuracy: 250,
        gpsFixedAt: DateTime.now());
  });
  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<SurveySession> ready() async {
    final draft = await service.start(projectId: projectId, site: baseline);
    final revised = baseline.revised(
        latitude: baseline.latitude,
        longitude: baseline.longitude,
        attributes: baseline.attributes,
        status: StudyAreaStatus.verified);
    return service.saveDraft(
        session: draft,
        revisedSite: revised,
        storedForm: stored,
        answers: {'condition': 'Good'},
        formValidated: true,
        photo: photo);
  }

  test(
      'visit is one durable linked survey with geotag photo and audited map revision',
      () async {
    final draft = await ready();
    final result = await service.finalize(draft);
    expect(result.mapApplied, isTrue);
    expect(result.session.status, 'saved');
    final response = GuidedVisitService.decode(result.session);
    expect(response['workflow'], 'guided_visit_v1');
    expect(response['form_id'], 'form-1');
    expect(response['photo']['path'], photo.path);
    expect(response['visit']['project_external_id'],
        (await db.getProjectById(projectId))!.externalId);
    expect(
        (response['answers'] as Map).containsKey('_visit_geometry'), isFalse);
    final site = (await store.loadSites()).single;
    expect(site.status, StudyAreaStatus.verified);
    expect(site.history.single.visitId, response['visit']['id']);
    expect(site.history.single.sessionId, result.session.id);
    expect(site.history.single.formId, stored.id);
    expect(site.history.single.photoPath, photo.path);
    // Accuracy is recorded for review, never a photo/finalize gate.
    expect(photo.accuracy, 250);
    final retried = await service.finalize(draft);
    expect(retried.mapApplied, isTrue);
    expect((await db.getSurveySessions()).length, 1);
    expect((await store.loadSites()).single.history.length, 1);
  });

  test(
      'quality uses the collected form snapshot after the project form changes',
      () async {
    final result = await service.finalize(await ready());
    final newerForm = SurveyForm(
        id: 'form-1',
        name: 'Changed form',
        description: '',
        questions: [
          Question(
              name: 'new_required',
              label: 'New required field',
              type: QuestionType.text,
              required: true)
        ]);
    await db.updateStoredForm(stored.id, json: jsonEncode(newerForm.toJson()));
    final issues = await FieldQualityService().inspect(
        sessions: [result.session],
        forms: await db.getStoredFormsForProject(projectId),
        sites: await store.loadSites(),
        accuracyThresholdM: 25);
    expect(issues.any((issue) => issue.code == 'answer'), isFalse);
    expect(issues.any((issue) => issue.code == 'gps_accuracy'), isTrue);
  });

  test(
      'failed map write keeps saved survey and retries without duplicate records',
      () async {
    final draft = await ready();
    store.fail = true;
    final result = await service.finalize(draft);
    expect(result.mapApplied, isFalse);
    expect(result.session.status, 'saved');
    expect(GuidedVisitService.visit(result.session)['site_sync'], 'pending');
    expect((await store.loadSites()).single.history, isEmpty);
    store.fail = false;
    final retry = await service.reconcile(result.session);
    expect(retry.mapApplied, isTrue);
    expect((await db.getSurveySessions()).length, 1);
    expect((await store.loadSites()).single.history.length, 1);
  });

  test('stale draft cannot overwrite a newer saved draft', () async {
    final initial = await service.start(projectId: projectId, site: baseline);
    await service.saveDraft(session: initial, answers: {'condition': 'first'});
    await expectLater(
        service.saveDraft(session: initial, answers: {'condition': 'stale'}),
        throwsStateError);
    expect(
        GuidedVisitService.decode(
            (await db.getSurveySession(initial.id))!)['answers']['condition'],
        'first');
  });

  test(
      'missing survey answer or photo blocks commit and preserves resumable draft',
      () async {
    await WorkflowRequirementsService(db).save(projectId, {
      StudyWorkflow.verification:
          const WorkflowRequirements(questionnaire: true, photo: true),
    });
    var draft = await service.start(projectId: projectId, site: baseline);
    draft = await service.saveDraft(
        session: draft, storedForm: stored, formValidated: true, answers: {});
    await expectLater(service.finalize(draft), throwsStateError);
    draft =
        await service.saveDraft(session: draft, answers: {'condition': 'Good'});
    await expectLater(service.finalize(draft), throwsStateError);
    expect((await db.getSurveySession(draft.id))!.status, 'draft');
    expect((await store.loadSites()).single.history, isEmpty);
  });

  test(
      'map conflict preserves both versions and only rebases after reviewed token',
      () async {
    final draft = await ready();
    final changed = baseline.revised(
        latitude: 23,
        longitude: 90,
        attributes: {'name': 'Teammate revision'},
        status: StudyAreaStatus.updated,
        changeNote: 'Team edit');
    await store.updateSite(changed);
    final result = await service.finalize(draft);
    expect(result.mapApplied, isFalse);
    expect((await store.loadSites()).single.attributes['name'],
        'Teammate revision');
    await expectLater(
        service.rebasePending(result.session,
            expectedCurrentToken: 'stale-token'),
        throwsStateError);
    final rebased = await service.rebasePending(result.session,
        expectedCurrentToken: changed.revisionToken);
    expect(rebased.mapApplied, isTrue);
    final current = (await store.loadSites()).single;
    expect(current.attributes['name'], 'Baseline');
    expect(current.history.length, 2);
    expect(current.history.last.before!['attributes']['name'],
        'Teammate revision');
    expect(
        GuidedVisitService.visit(rebased.session)['reconciliation_before']
            ['attributes']['name'],
        'Teammate revision');
  });

  test(
      'quality checks relevance, required media, advisory GPS and nearby GIS/baseline points',
      () async {
    final qualityForm =
        SurveyForm(id: 'quality', name: 'Quality', description: '', groups: [
      const GroupInfo(name: 'conditional', relevance: r"${flag} = 'yes'")
    ], questions: [
      Question(
          name: 'required',
          label: 'Required field',
          type: QuestionType.text,
          required: true),
      Question(
          name: 'hidden_required',
          label: 'Hidden required',
          type: QuestionType.text,
          required: true,
          groupPath: ['conditional']),
      Question(
          name: 'photo',
          label: 'Photo',
          type: QuestionType.image,
          required: true)
    ]);
    final formId = await db.insertStoredForm(StoredFormsCompanion(
        projectId: drift.Value(projectId),
        name: const drift.Value('Quality'),
        json: drift.Value(jsonEncode(qualityForm.toJson()))));
    final surveyId = await db.insertSurveySession(SurveySessionsCompanion(
        projectId: drift.Value(projectId),
        title: const drift.Value('Survey'),
        status: const drift.Value('saved'),
        responses: drift.Value(jsonEncode({
          'form_id': 'quality',
          'answers': {'flag': 'no'}
        }))));
    final gisId = await db.insertSurveySession(SurveySessionsCompanion(
        projectId: drift.Value(projectId),
        title: const drift.Value('GIS point'),
        status: const drift.Value('saved'),
        responses: drift.Value(jsonEncode({
          'feature_type': 'point',
          'latitude': 23.00001,
          'longitude': 90,
          'accuracy_m': 90,
          'recorded_at': '2026-01-01T10:00:00Z',
          'gps_fix_timestamp': '2026-01-01T09:50:00Z',
          'photo': photo.toJson()
        }))));
    final issues = await FieldQualityService().inspect(
        sessions: await db.getSurveySessions(),
        forms: (await db.getStoredFormsForProject(projectId))
            .where((row) => row.id == formId)
            .toList(),
        sites: [baseline],
        accuracyThresholdM: 25,
        duplicateDistanceM: 10);
    expect(
        issues.any((issue) =>
            issue.sessionId == surveyId &&
            issue.message.contains('Required field')),
        isTrue);
    expect(issues.any((issue) => issue.message.contains('Hidden required')),
        isFalse);
    expect(issues.any((issue) => issue.code == 'photo'), isTrue);
    expect(
        issues.any((issue) =>
            issue.sessionId == gisId && issue.code == 'gps_accuracy'),
        isTrue);
    expect(
        issues.any(
            (issue) => issue.sessionId == gisId && issue.code == 'gps_stale'),
        isTrue);
    expect(
        issues.any((issue) =>
            issue.code == 'near_duplicate' &&
            issue.siteId == baseline.id &&
            issue.sessionId == gisId),
        isTrue);
  });

  test(
      'duplicate detection compares separate GIS points and excludes linked revisit',
      () async {
    for (var index = 0; index < 2; index++) {
      await db.insertSurveySession(SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value('Point $index'),
          status: const drift.Value('saved'),
          responses: drift.Value(jsonEncode({
            'feature_type': 'point',
            'latitude': 23 + index * 0.00001,
            'longitude': 90
          }))));
    }
    final issues = await FieldQualityService().inspect(
        sessions: await db.getSurveySessions(),
        forms: [],
        sites: [],
        accuracyThresholdM: 25);
    expect(issues.where((issue) => issue.code == 'near_duplicate').length, 1);
  });

  test('GeoJSON collection baseline validation accepts valid shapes', () {
    expect(
        FieldQualityService.validGeometry({
          'type': 'GeometryCollection',
          'geometries': [
            {
              'type': 'Point',
              'coordinates': [90, 23]
            },
            {
              'type': 'LineString',
              'coordinates': [
                [90, 23],
                [90.1, 23.1]
              ]
            }
          ]
        }),
        isTrue);
    expect(
        FieldQualityService.validGeometry({
          'type': 'GeometryCollection',
          'geometries': [
            {
              'type': 'Point',
              'coordinates': [double.nan, 23]
            }
          ]
        }),
        isFalse);
  });

  test('verification can finish without form or photo when project permits it',
      () async {
    await WorkflowRequirementsService(db).save(projectId, {
      StudyWorkflow.verification:
          const WorkflowRequirements(questionnaire: false, photo: false)
    });
    final draft = await service.start(projectId: projectId, site: baseline);
    final edited = baseline.revised(
        latitude: baseline.latitude,
        longitude: baseline.longitude,
        attributes: baseline.attributes,
        status: StudyAreaStatus.verified);
    final saved = await service
        .finalize(await service.saveDraft(session: draft, revisedSite: edited));
    expect(saved.session.status, 'saved');
    expect(saved.mapApplied, true);
    final issues = await FieldQualityService().inspect(
        sessions: [saved.session],
        forms: [],
        sites: [],
        accuracyThresholdM: 30);
    expect(issues.where((issue) => issue.code == 'photo'), isEmpty);
  });

  test(
      'guided verification photo is optional by default with a valid questionnaire',
      () async {
    final draft = await service.start(projectId: projectId, site: baseline);
    final edited = baseline.revised(
        latitude: baseline.latitude,
        longitude: baseline.longitude,
        attributes: baseline.attributes,
        status: StudyAreaStatus.verified);
    final ready = await service.saveDraft(
        session: draft,
        revisedSite: edited,
        storedForm: stored,
        answers: {'condition': 'Good'},
        formValidated: true);
    final result = await service.finalize(ready);
    expect(result.session.status, 'saved');
    expect(result.mapApplied, true);
    expect(GuidedVisitService.decode(result.session)['photo'], isNull);
    expect(
        GuidedVisitService.decode(result.session)['workflow_requirements']
            ['require_photo'],
        false);
  });
}
