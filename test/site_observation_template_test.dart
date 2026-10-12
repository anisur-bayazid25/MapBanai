import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/project_template_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/site_observation_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late Directory dir;
  late StudyAreaStore store;
  late int projectId;
  late StoredForm stored;
  setUp(() async {
    db = AppDatabase.forTesting();
    dir = await Directory.systemTemp.createTemp('observations_');
    store = StudyAreaStore(baseDir: dir);
    projectId = await db.insertProject(
        const ProjectsCompanion(name: drift.Value('Salinity campaign')));
    final form =
        SurveyForm(id: 'salt', name: 'Salinity', description: '', questions: [
      Question(
          name: 'salinity',
          label: 'Salinity (ppt)',
          type: QuestionType.decimal,
          required: true)
    ]);
    final id = await db.insertStoredForm(StoredFormsCompanion(
        projectId: drift.Value(projectId),
        name: drift.Value(form.name),
        json: drift.Value(jsonEncode(form.toJson()))));
    stored = (await db.getStoredFormsForProject(projectId))
        .singleWhere((row) => row.id == id);
    await ProjectWorkspaceService(db).addLayer(projectId, 'Salinity sites');
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  test(
      'two completed visits preserve salinity values and imported timeline deduplicates',
      () async {
    final workspace = await ProjectWorkspaceService(db).load(projectId);
    final baseline = StudyAreaSite(
        id: 'station-legacy-id',
        projectId: projectId,
        projectExternalId: workspace.project.externalId,
        layerId: workspace.layerId,
        latitude: 23,
        longitude: 90);
    await store.addSites([baseline]);
    final service = GuidedVisitService(database: db, sites: store);
    final photo = await PhotoStore.saveGeotagged(
        Uint8List.fromList(image.encodeJpg(image.Image(width: 8, height: 8))),
        latitude: 23,
        longitude: 90,
        dir: Directory('${dir.path}/photos'),
        accuracy: 250,
        gpsFixedAt: DateTime.now());
    final visitIds = <String>[];
    for (final measurement in [4.5, 7.25]) {
      final site = (await store.loadSites()).single;
      final draft = await service.start(projectId: projectId, site: site);
      final ready = await service.saveDraft(
          session: draft,
          storedForm: stored,
          answers: {'salinity': measurement},
          formValidated: true,
          photo: photo,
          revisedSite: site.revised(
              latitude: 23,
              longitude: 90,
              attributes: site.attributes,
              status: StudyAreaStatus.verified));
      final result = await service.finalize(ready);
      expect(result.mapApplied, true);
      final visit = GuidedVisitService.visit(result.session);
      visitIds.add(visit['id'] as String);
      expect(visit['feature_uuid'], baseline.featureUuid);
    }
    final current = (await store.loadSites()).single;
    final rows = await SiteObservationService(db).load(projectId, current);
    expect(rows, hasLength(2));
    expect(rows.map((r) => r.answers['salinity']), [4.5, 7.25]);
    expect(visitIds.toSet(), hasLength(2));
    expect(current.formAnswers['salinity'], 7.25);
    expect(SiteObservationService.numericFields(rows)['salinity'],
        'Salinity (ppt)');
    final imported =
        StudyAreaService.parseGeoJson(StudyAreaService.toGeoJson([current]))
            .single;
    expect(imported.featureUuid, current.featureUuid);
    expect((await SiteObservationService(db).load(projectId, imported)),
        hasLength(2));
    final csv = SiteObservationService.csv(imported, rows);
    expect(csv, contains('observation_uuid'));
    expect(csv, contains('4.5'));
    expect(csv, contains('7.25'));
    await db.delete(db.surveySessions).go();
    expect((await SiteObservationService(db).load(projectId, imported)),
        hasLength(2));
    final other = await db
        .insertProject(const ProjectsCompanion(name: drift.Value('Other')));
    await expectLater(
        SiteObservationService(db).load(other, imported), throwsStateError);
  });
  test(
      'project and layer templates reuse setup with fresh identities and no data or secrets',
      () async {
    await db.upsertSyncConfig(
        projectId: projectId,
        syncEndpointUrl: 'https://example.org/exec',
        syncApiKey: 'secret-for-original');
    await db.insertSurveySession(SurveySessionsCompanion(
        projectId: drift.Value(projectId),
        title: const drift.Value('Private observation')));
    final service = ProjectTemplateService(db);
    await service.save(projectId, 'Salinity campaign template');
    await service.save(projectId, 'Salinity layer', layerOnly: true);
    final templates = await service.list();
    expect(templates, hasLength(2));
    expect(jsonEncode(templates), isNot(contains('secret-for-original')));
    expect(jsonEncode(templates), isNot(contains('Private observation')));
    final original = await ProjectWorkspaceService(db).load(projectId);
    final freshId = await service.createProject(templates.first, 'Next season');
    final fresh = await ProjectWorkspaceService(db).load(freshId);
    expect(fresh.project.externalId, isNot(original.project.externalId));
    expect(fresh.layers.map((l) => l.name), original.layers.map((l) => l.name));
    expect(fresh.layerId, isNot(original.layerId));
    expect(fresh.schema!.id, 'salt');
    expect(await db.getSyncConfig(freshId), isNull);
    expect(await db.getSurveySessionsByProject(freshId), isEmpty);
    await service.applyLayers(templates.last, freshId);
    expect((await ProjectWorkspaceService(db).load(freshId)).layers.length,
        fresh.layers.length + 1);
    expect((await db.getStoredFormsForProject(freshId)), hasLength(1));
    await expectLater(service.createProject(templates.first, 'Next season'),
        throwsStateError);
    await service.remove(templates.first['id'] as String);
    expect(await service.list(), hasLength(1));
  });
}
