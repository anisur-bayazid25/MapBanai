import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _Paths extends PathProviderPlatform {
  final String path;
  _Paths(this.path);
  @override
  Future<String> getApplicationDocumentsPath() async => path;
}

Uint8List _shape() {
  final b = ByteData(128)
    ..setUint32(0, 9994)
    ..setUint32(24, 64)
    ..setUint32(28, 1000, Endian.little)
    ..setUint32(32, 1, Endian.little)
    ..setUint32(100, 1)
    ..setUint32(104, 10)
    ..setUint32(108, 1, Endian.little)
    ..setFloat64(112, 90.44, Endian.little)
    ..setFloat64(120, 23.68, Endian.little);
  return b.buffer.asUint8List();
}

Uint8List _dbf() {
  final bytes = Uint8List(71), data = ByteData.sublistView(bytes);
  bytes[0] = 3;
  data.setUint32(4, 1, Endian.little);
  data.setUint16(8, 65, Endian.little);
  data.setUint16(10, 5, Endian.little);
  bytes.setRange(32, 36, ascii.encode('TYPE'));
  bytes[43] = 67;
  bytes[48] = 4;
  bytes[64] = 13;
  bytes[65] = 32;
  bytes.setRange(66, 70, ascii.encode('Well'));
  bytes[70] = 26;
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late AppDatabase db;
  late StudyAreaStore store;
  late Project project;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('project_transfer_');
    db = AppDatabase.forTesting();
    store = StudyAreaStore(baseDir: Directory('${directory.path}/source'));
    final id = await db.insertProject(const ProjectsCompanion(
        name: Value('CARE'), externalId: Value('care-id')));
    project = (await db.getProjectById(id))!;
    PathProviderPlatform.instance = _Paths('${directory.path}/target');
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('single SHP discovers mixed-case companion files from its folder',
      () async {
    final shape = File('${directory.path}/sites.SHP');
    await shape.writeAsBytes(_shape());
    await File('${directory.path}/SITES.DBF').writeAsBytes(_dbf());
    final files = <String, Uint8List>{'sites.SHP': await shape.readAsBytes()};
    await ProjectVectorLayerService.addShapefileCompanions(files, [shape.path]);
    final layers = await ProjectVectorLayerService.parseFiles(files);
    expect((layers.single['features'] as List).single['properties']['TYPE'],
        'Well');
    expect(layers.single['warning'], isNot(contains('No .dbf')));
    final geometryOnly =
        await ProjectVectorLayerService.parseFiles({'sites.shp': _shape()});
    expect(geometryOnly.single['warning'], contains('No .dbf'));
    expect(geometryOnly.single['features'], hasLength(1));
  });

  test(
      'project settings source appears in Study Area without adding survey history or resurrecting deletions',
      () async {
    final service = ProjectVectorLayerService(db);
    final layers =
        await ProjectVectorLayerService.parseFiles({'sites.shp': _shape()});
    await service.save(project.id, layers);
    final layerId = ProjectVectorLayerService.studyLayerId(layers.single);
    final workspace =
        await ProjectWorkspaceService(db).select(project.id, layerId: layerId);
    expect(workspace.layers.map((layer) => layer.id), contains(layerId));
    await service.ensureStudySites(project, layerId, store);
    final sites = await store.loadSites();
    expect(sites, hasLength(1));
    expect(sites.single.layerId, layerId);
    expect(sites.single.latitude, 23.68);
    expect(sites.single.hasChanges, false);
    expect(await db.getSurveySessionsByProject(project.id), isEmpty);
    await store.deleteSites({sites.single.id});
    await service.ensureStudySites(project, layerId, store);
    expect(await store.loadSites(), isEmpty);
    await service.save(project.id, []);
    expect(
        (await ProjectWorkspaceService(db).load(project.id))
            .layers
            .map((layer) => layer.id),
        isNot(contains(layerId)));
  });

  test(
      'full mbproj round trip preserves credentials, source files, responses, photos and verification state',
      () async {
    final vectors = ProjectVectorLayerService(db);
    final layers =
        await ProjectVectorLayerService.parseFiles({'sites.shp': _shape()});
    await vectors.save(project.id, layers);
    final layerId = ProjectVectorLayerService.studyLayerId(layers.single);
    await ProjectWorkspaceService(db).select(project.id, layerId: layerId);
    await vectors.ensureStudySites(project, layerId, store);
    final site = (await store.loadSites()).single;
    site.status = StudyAreaStatus.completed;
    await store.updateSite(site, author: 'Collector');
    await StudyAreaOutboxService(db).enqueue(site, 'Collector');
    final photo = File('${directory.path}/photos/test.jpg');
    await photo.parent.create(recursive: true);
    await photo.writeAsBytes([1, 2, 3, 4]);
    await db.insertSurveySession(SurveySessionsCompanion(
        projectId: Value(project.id),
        title: const Value('Test survey'),
        status: const Value('saved'),
        externalId: const Value('survey-id'),
        responses: Value(jsonEncode({
          'answers': {
            'name': 'Facility',
            'photo': jsonEncode({'path': photo.path})
          },
          'photo': {'path': photo.path}
        }))));
    await db.upsertSyncConfig(
        projectId: project.id,
        syncEndpointUrl: 'https://example.test/exec',
        syncApiKey: 'team-key');
    final exporter = ProjectExporter(db, studyAreaStore: store);
    final definition =
        await exporter.buildData(project, includeSyncConnection: true);
    expect(definition.project.containsKey('field_data'), false);
    final file = File('${directory.path}/care.mbproj');
    await file.writeAsBytes(await exporter.buildPackageBytes(project,
        includeSyncConnection: true, includeResponses: true));
    final target = AppDatabase.forTesting();
    addTearDown(target.close);
    final importer = ProjectImporter(target, tempBase: directory);
    final validated = await importer.validateAndExtract(file);
    try {
      final imported = await importer.commit(validated, newCopy: false);
      final restored = (await target.getProjectById(imported.projectId))!;
      expect((await target.getSyncConfig(restored.id))!.syncApiKey, 'team-key');
      final restoredLayers =
          await ProjectVectorLayerService(target).load(restored.id);
      expect(restoredLayers.single['source_files'], isNotEmpty);
      final sessions = await target.getSurveySessionsByProject(restored.id);
      expect(sessions, hasLength(2));
      final response = jsonDecode(sessions
          .firstWhere((session) => session.title == 'Test survey')
          .responses);
      final restoredPhoto = response['photo']['path'] as String;
      expect(restoredPhoto, isNot(photo.path));
      expect(await File(restoredPhoto).readAsBytes(), [1, 2, 3, 4]);
      expect(jsonDecode(response['answers']['photo'])['path'], restoredPhoto);
      final targetStore =
          StudyAreaStore(baseDir: Directory('${directory.path}/target'));
      await ProjectVectorLayerService(target)
          .ensureStudySites(restored, layerId, targetStore);
      expect((await targetStore.loadSites()).single.status,
          StudyAreaStatus.completed);
      final copy = await importer.commitQrData(definition, newCopy: true);
      expect(await target.getSurveySessionsByProject(copy.projectId), isEmpty);
      final copiedProject = (await target.getProjectById(copy.projectId))!;
      await ProjectVectorLayerService(target)
          .ensureStudySites(copiedProject, layerId, targetStore);
      final copiedSites = (await targetStore.loadSites()).where(
          (point) => point.projectExternalId == copiedProject.externalId);
      expect(copiedSites.single.id, '${copiedProject.externalId}:${site.id}');
      expect(copiedSites.single.status, StudyAreaStatus.pending);
    } finally {
      await validated.discard();
    }
  });

  test('sharing a study-import source preserves its original point identity',
      () async {
    final layers =
        await ProjectVectorLayerService.parseFiles({'sites.shp': _shape()});
    layers.single.addAll({
      'study_layer_id': 'shyampur',
      'study_site_ids': ['original-96'],
      'study_source_project_id': project.externalId
    });
    final vectors = ProjectVectorLayerService(db);
    await vectors.save(project.id, layers);
    await vectors.ensureStudySites(project, 'shyampur', store);
    expect((await store.loadSites()).single.id, 'original-96');
    final definition = await ProjectExporter(db).buildData(project);
    final target = AppDatabase.forTesting();
    addTearDown(target.close);
    final imported =
        await ProjectImporter(target).commitQrData(definition, newCopy: false);
    final restoredProject = (await target.getProjectById(imported.projectId))!;
    final targetStore =
        StudyAreaStore(baseDir: Directory('${directory.path}/second-device'));
    await ProjectVectorLayerService(target)
        .ensureStudySites(restoredProject, 'shyampur', targetStore);
    expect((await targetStore.loadSites()).single.id, 'original-96');
  });
}
