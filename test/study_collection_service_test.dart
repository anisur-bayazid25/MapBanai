import 'dart:typed_data';
import 'package:image/image.dart' as image;
import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/workflow_requirements_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/services/study_collection_service.dart';
import 'package:mapbanai/services/site_observation_service.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';

void main() {
  late AppDatabase db;
  late ProjectWorkspaceService workspace;
  late StudyCollectionService service;
  late Directory directory;
  late StudyAreaStore store;
  late int projectId;
  late StoredForm form;
  late StudyAreaSite site;
  late CollectionRound first;
  late CollectionRound second;
  setUp(() async {
    db = AppDatabase.forTesting();
    workspace = ProjectWorkspaceService(db);
    service = StudyCollectionService(db);
    directory = Directory.systemTemp.createTempSync('mapbanai-collection-');
    store = StudyAreaStore(baseDir: directory);
    projectId = await db.insertProject(
        const ProjectsCompanion(name: Value('Salinity project')));
    final schema = SurveyForm(
        id: 'salinity',
        name: 'Salinity',
        description: '',
        questions: [
          Question(
              name: 'salt',
              label: 'Salinity (ppt)',
              type: QuestionType.decimal,
              required: true),
          Question(
              name: 'location', label: 'Location', type: QuestionType.geopoint),
        ]);
    await db.insertStoredForm(StoredFormsCompanion(
        projectId: Value(projectId),
        name: Value(schema.name),
        json: Value(jsonEncode(schema.toJson()))));
    form = (await db.getStoredFormsForProject(projectId)).single;
    final context = await workspace.addLayer(projectId, 'Salinity stations',
        workflow: StudyWorkflow.recurring);
    site = StudyAreaSite(
        id: 'station-1',
        projectId: projectId,
        projectExternalId: context.project.externalId,
        layerId: context.layerId,
        latitude: 23.75,
        longitude: 90.4,
        attributes: {'name': 'Station 1'});
    await store.addSites([site]);
    first = await workspace.addRound(projectId, site.layerId, 'Round 1',
        period: 'Dry season', date: '2026-10-27');
    second = await workspace.addRound(projectId, site.layerId, 'Round 2');
  });
  tearDown(() async {
    await db.close();
    directory.deleteSync(recursive: true);
  });

  test('round status is independent and earlier measurements remain intact',
      () async {
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        form: form,
        answers: {'salt': 3.5},
        outcome: StudyAreaStatus.completed);
    expect(
        (await service.statuses(
            projectId, site.layerId, StudyWorkflow.recurring, first))[site.id],
        StudyAreaStatus.completed);
    expect(
        await service.statuses(
            projectId, site.layerId, StudyWorkflow.recurring, second),
        isEmpty);
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: second,
        form: form,
        answers: {'salt': 4.2},
        outcome: StudyAreaStatus.completed);
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: second,
        outcome: StudyAreaStatus.needsReview,
        statusOnly: true);
    expect(
        (await service.statuses(
            projectId, site.layerId, StudyWorkflow.recurring, second))[site.id],
        StudyAreaStatus.needsReview);
    expect(
        (await service.statuses(
            projectId, site.layerId, StudyWorkflow.recurring, first))[site.id],
        StudyAreaStatus.completed);
    final observations = await SiteObservationService(db).load(projectId, site);
    expect(observations.map((row) => row.number('salt')), [3.5, 4.2]);
    expect(observations.map((row) => row.roundName), ['Round 1', 'Round 2']);
    expect(SiteObservationService.csv(site, observations),
        contains('collection_round'));
    expect((await store.loadSites()).single.status, StudyAreaStatus.pending);
    expect((await db.responseCountsForProject(projectId)).survey, 2);
    expect(await db.surveySessionCountForProject(projectId), 2);
  });

  test(
      'drafts stay uncollected, resume, reject stale writes and validate completion',
      () async {
    final draft = await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        form: form,
        answers: {},
        draft: true,
        outcome: StudyAreaStatus.completed);
    expect(
        await service.statuses(
            projectId, site.layerId, StudyWorkflow.recurring, first),
        isEmpty);
    expect(
        (await service.draftFor(
                projectId, site, StudyWorkflow.recurring, first, form))!
            .id,
        draft.id);
    await expectLater(
        service.save(
            projectId: projectId,
            site: site,
            workflow: StudyWorkflow.recurring,
            round: first,
            form: form,
            answers: {},
            previous: draft,
            outcome: StudyAreaStatus.completed),
        throwsStateError);
    final newer = await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        form: form,
        answers: {'salt': 2},
        previous: draft,
        draft: true,
        outcome: StudyAreaStatus.completed);
    await expectLater(
        service.save(
            projectId: projectId,
            site: site,
            workflow: StudyWorkflow.recurring,
            round: first,
            form: form,
            answers: {'salt': 7},
            previous: draft,
            outcome: StudyAreaStatus.completed),
        throwsStateError);
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        form: form,
        answers: {'salt': 2},
        previous: newer,
        outcome: StudyAreaStatus.completed);
    expect(
        await service.draftFor(
            projectId, site, StudyWorkflow.recurring, first, form),
        isNull);
  });

  test(
      'recurring cannot mark collected without a survey or use another layer round',
      () async {
    await expectLater(
        service.save(
            projectId: projectId,
            site: site,
            workflow: StudyWorkflow.recurring,
            round: first,
            outcome: StudyAreaStatus.completed,
            statusOnly: true),
        throwsStateError);
    final other = await workspace.addLayer(projectId, 'Other sites',
        workflow: StudyWorkflow.recurring);
    final round =
        await workspace.addRound(projectId, other.layerId, 'Other round');
    await expectLater(
        service.save(
            projectId: projectId,
            site: site,
            workflow: StudyWorkflow.recurring,
            round: round,
            form: form,
            answers: {'salt': 1},
            outcome: StudyAreaStatus.completed),
        throwsStateError);
  });

  test(
      'workflow assignments and selections are independent and preserve manual layers',
      () async {
    final visits = await workspace.addLayer(projectId, 'Dhaka STS',
        workflow: StudyWorkflow.visits);
    final recurring =
        await workspace.load(projectId, workflow: StudyWorkflow.recurring);
    expect(recurring.layers.any((layer) => layer.name == 'Dhaka STS'), isFalse);
    expect(recurring.layerId, site.layerId);
    await workspace.select(projectId,
        layerId: site.layerId,
        formId: form.id,
        workflow: StudyWorkflow.recurring);
    await workspace.selectRound(projectId, StudyWorkflow.recurring, first.id);
    expect(
        (await workspace.load(projectId, workflow: StudyWorkflow.visits))
            .layerId,
        visits.layerId);
    expect((await workspace.load(projectId)).layers.map((layer) => layer.name),
        containsAll(['Dhaka STS', 'Salinity stations']));
    final facility = StudyAreaSite(
        id: 'sts-1',
        projectId: projectId,
        projectExternalId: visits.project.externalId,
        layerId: visits.layerId,
        latitude: 23.7,
        longitude: 90.4);
    await service.save(
        projectId: projectId,
        site: facility,
        workflow: StudyWorkflow.visits,
        outcome: StudyAreaStatus.completed,
        statusOnly: true);
    await service.save(
        projectId: projectId,
        site: facility,
        workflow: StudyWorkflow.visits,
        outcome: StudyAreaStatus.pending,
        statusOnly: true);
    expect(
        (await service.statuses(projectId, facility.layerId,
            StudyWorkflow.visits, null))[facility.id],
        StudyAreaStatus.pending);
  });

  test('measurement extraction filters form, field, draft and missing geometry',
      () async {
    Future<void> response(String formId, Map<String, dynamic> answers,
            {bool draft = false}) async =>
        db.insertSurveySession(SurveySessionsCompanion(
            projectId: Value(projectId),
            title: const Value('Field measurement'),
            status: Value(draft ? 'draft' : 'saved'),
            responses:
                Value(jsonEncode({'form_id': formId, 'answers': answers}))));
    await response('salinity', {'salt': 3, 'location': '23.75,90.4,5'});
    await response('heat', {'salt': 9, 'location': '23.75,90.4,5'});
    await response('salinity', {'temperature': 30, 'location': '23.75,90.4,5'});
    await response('salinity', {'salt': 8});
    await response('salinity', {'salt': 8, 'location': '23.75,90.4,5'},
        draft: true);
    final before = await db.getSurveySessionsByProject(projectId);
    final features =
        await service.measurementFeatures(projectId, 'salinity', 'salt');
    expect(features, hasLength(1));
    expect(features.single['properties']['salt'], 3);
    final id = await service.createMeasurementLayer(
        projectId, 'Salinity only', 'salinity', 'salt');
    expect(
        (await workspace.load(projectId, workflow: StudyWorkflow.recurring))
            .layerId,
        id);
    expect(await db.getSurveySessionsByProject(projectId),
        hasLength(before.length));
    final vectors = await ProjectVectorLayerService(db).load(projectId);
    expect(vectors.single['workflows'], ['recurring']);
    await ProjectVectorLayerService(db)
        .ensureStudySites((await workspace.load(projectId)).project, id, store);
    expect((await store.loadSites()).where((site) => site.layerId == id),
        hasLength(1));
  });

  test(
      'project package round trip keeps round definitions, form selection and statuses',
      () async {
    await workspace.select(projectId,
        layerId: site.layerId,
        formId: form.id,
        workflow: StudyWorkflow.recurring);
    await workspace.selectRound(projectId, StudyWorkflow.recurring, first.id);
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        form: form,
        answers: {'salt': 5},
        outcome: StudyAreaStatus.completed);
    final payload = await ProjectExporter(db, studyAreaStore: store).buildData(
        (await workspace.load(projectId)).project,
        includeResponses: true);
    final result =
        await ProjectImporter(db).commitQrData(payload, newCopy: true);
    final copy = await workspace.load(result.projectId,
        workflow: StudyWorkflow.recurring);
    expect(copy.form!.id, isNot(form.id));
    expect(
        (await workspace.rounds(copy.project.id, copy.layerId))
            .map((r) => r.id),
        [first.id, second.id]);
    await ProjectVectorLayerService(db)
        .ensureStudySites(copy.project, copy.layerId, store);
    final copiedSite = (await store.loadSites())
        .firstWhere((s) => s.projectId == copy.project.id);
    expect(
        (await service.statuses(copy.project.id, copy.layerId,
            StudyWorkflow.recurring, first))[copiedSite.id],
        StudyAreaStatus.completed);
    final rows =
        await SiteObservationService(db).load(copy.project.id, copiedSite);
    expect(rows.single.number('salt'), 5);
  });

  test('cloud sync carries site, round, workflow and questionnaire snapshot',
      () async {
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        form: form,
        answers: {'salt': 4},
        outcome: StudyAreaStatus.completed);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    Map? payload;
    server.listen((req) async {
      payload = jsonDecode(await utf8.decoder.bind(req).join());
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': true, 'revisionSupport': true}));
      await req.response.close();
    });
    try {
      await db.upsertSyncConfig(
          projectId: projectId,
          syncEndpointUrl: 'http://127.0.0.1:${server.port}/exec',
          syncApiKey: 'test');
      await CloudSyncService(db).syncProject(projectId);
      final row = (payload!['responses'] as List).single as Map;
      expect(row['study_workflow'], 'recurring');
      expect(row['round_id'], first.id);
      expect(row['collection_round']['period'], 'Dry season');
      expect(row['site_id'], site.id);
      expect(row['form_snapshot']['id'], 'salinity');
    } finally {
      await server.close(force: true);
    }
  });

  test('requirements are isolated by project and preserve workspace settings',
      () async {
    final settings = WorkflowRequirementsService(db);
    final defaults = await settings.load(projectId);
    expect(defaults[StudyWorkflow.verification]!.photo, true);
    expect(defaults[StudyWorkflow.recurring]!.questionnaire, true);
    expect(defaults[StudyWorkflow.visits]!.questionnaire, false);
    final other =
        await db.insertProject(const ProjectsCompanion(name: Value('Other')));
    await settings.save(projectId, {
      StudyWorkflow.visits:
          const WorkflowRequirements(questionnaire: true, photo: true)
    });
    expect((await settings.get(other, StudyWorkflow.visits)).photo, false);
    expect((await workspace.rounds(projectId, site.layerId)).length, 2);
    expect(
        () => WorkflowRequirementsService.decode({
              'visits': {'require_photo': 'yes'}
            }),
        throwsFormatException);
  });

  test(
      'completion cannot bypass configured questionnaire or photo requirements',
      () async {
    final settings = WorkflowRequirementsService(db);
    await settings.save(projectId, {
      StudyWorkflow.recurring:
          const WorkflowRequirements(questionnaire: true, photo: true)
    });
    Future<SurveySession> save(
            {bool statusOnly = false, StoredForm? selected}) =>
        service.save(
            projectId: projectId,
            site: site,
            workflow: StudyWorkflow.recurring,
            round: first,
            form: selected,
            answers: {'salt': 4},
            outcome: StudyAreaStatus.completed,
            statusOnly: statusOnly);
    await expectLater(save(statusOnly: true), throwsStateError);
    await expectLater(save(), throwsStateError);
    await expectLater(save(selected: form), throwsStateError);
    expect(await db.getSurveySessionsByProject(projectId), isEmpty);
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        outcome: StudyAreaStatus.needsReview,
        statusOnly: true);
    final photo = await PhotoStore.saveGeotagged(
        Uint8List.fromList(image.encodeJpg(image.Image(width: 8, height: 8))),
        latitude: 23.75,
        longitude: 90.4,
        dir: Directory('${directory.path}/evidence'),
        accuracy: 5,
        gpsFixedAt: DateTime.now());
    final row = await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        form: form,
        answers: {'salt': 4},
        evidencePhoto: photo,
        outcome: StudyAreaStatus.completed);
    expect(StudyCollectionService.data(row)!['photo']['path'], photo.path);
    expect(
        StudyCollectionService.data(row)!['workflow_requirements']
            ['require_photo'],
        true);
  });

  test(
      'photo-only observations resume drafts and keep independent round progress',
      () async {
    await WorkflowRequirementsService(db).save(projectId, {
      StudyWorkflow.recurring:
          const WorkflowRequirements(questionnaire: false, photo: true)
    });
    var draft = await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        outcome: StudyAreaStatus.completed,
        draft: true);
    expect(
        (await service.draftFor(
                projectId, site, StudyWorkflow.recurring, first, null))!
            .id,
        draft.id);
    await expectLater(
        service.save(
            projectId: projectId,
            site: site,
            workflow: StudyWorkflow.recurring,
            round: first,
            outcome: StudyAreaStatus.completed,
            previous: draft),
        throwsStateError);
    final photo = await PhotoStore.saveGeotagged(
        Uint8List.fromList(image.encodeJpg(image.Image(width: 8, height: 8))),
        latitude: 23.75,
        longitude: 90.4,
        dir: Directory('${directory.path}/evidence'),
        accuracy: 5,
        gpsFixedAt: DateTime.now());
    draft = await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        outcome: StudyAreaStatus.completed,
        previous: draft,
        evidencePhoto: photo,
        draft: true);
    final completed = await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        outcome: StudyAreaStatus.completed,
        previous: draft);
    expect(
        StudyCollectionService.data(completed)!['photo']['path'], photo.path);
    expect(
        await service.statuses(
            projectId, site.layerId, StudyWorkflow.recurring, second),
        isEmpty);
  });

  test(
      'optional questionnaire allows status completion and package retains policy',
      () async {
    final settings = WorkflowRequirementsService(db);
    await settings.save(projectId, {
      StudyWorkflow.recurring:
          const WorkflowRequirements(questionnaire: false, photo: false),
      StudyWorkflow.visits:
          const WorkflowRequirements(questionnaire: true, photo: true)
    });
    await service.save(
        projectId: projectId,
        site: site,
        workflow: StudyWorkflow.recurring,
        round: first,
        outcome: StudyAreaStatus.completed,
        statusOnly: true);
    final payload = await ProjectExporter(db, studyAreaStore: store)
        .buildData((await workspace.load(projectId)).project);
    final copy = await ProjectImporter(db).commitQrData(payload, newCopy: true);
    expect(
        (await settings.get(copy.projectId, StudyWorkflow.recurring))
            .questionnaire,
        false);
    expect(
        (await settings.get(copy.projectId, StudyWorkflow.visits)).photo, true);
  });
}
