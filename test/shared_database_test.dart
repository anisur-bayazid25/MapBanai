import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _Documents extends PathProviderPlatform {
  final String path;
  _Documents(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late PathProviderPlatform previousPaths;
  final handles = <AppDatabase>[];
  AppDatabase open() {
    final db = AppDatabase();
    handles.add(db);
    return db;
  }

  setUp(() {
    directory = Directory.systemTemp.createTempSync('mapbanai-shared-db-');
    previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Documents(directory.path);
  });
  tearDown(() async {
    for (final handle in handles) {
      await handle.close();
    }
    handles.clear();
    PathProviderPlatform.instance = previousPaths;
    directory.deleteSync(recursive: true);
  });

  test('concurrent first launch creates schema once and shares writes',
      () async {
    final clients = List.generate(8, (_) => open());
    await Future.wait([
      for (var i = 0; i < clients.length; i++)
        clients[i].createProject('Project $i')
    ]);
    for (final client in clients) {
      expect(await client.getProjects(), hasLength(8));
    }
    await Future.wait([
      for (var i = 0; i < clients.length; i++)
        clients[i].setSetting('setting-$i', 'value-$i')
    ]);
    expect(await clients.first.getSetting('setting-7'), 'value-7');
  });

  test('closing one screen keeps peers alive and propagates watched changes',
      () async {
    final first = open(), second = open();
    await first.getProjects();
    final update = second
        .select(second.projects)
        .watch()
        .firstWhere((rows) => rows.any((p) => p.name == 'Visible'))
        .timeout(const Duration(seconds: 5));
    await first.createProject('Visible');
    expect((await update).single.name, 'Visible');
    await first.close();
    await first.close();
    await second.setSetting('language', 'bn');
    expect(await second.getSetting('language'), 'bn');
  });

  test('last close releases the file and reopening preserves settings',
      () async {
    final first = open(), second = open();
    await first.setSetting('language', 'bn');
    await Future.wait([first.close(), second.close()]);
    final file = File('${directory.path}/mapbanai.db');
    final moved = await file.rename('${directory.path}/saved.db');
    await moved.rename(file.path);
    final reopened = open();
    expect(await reopened.getSetting('language'), 'bn');
  });

  test('package import works while settings and home use other handles',
      () async {
    final home = open(), settings = open(), importerDb = open();
    await Future.wait([
      home.getProjects(),
      settings.getSetting('language'),
      importerDb.getProjects()
    ]);
    await home.createProject('Shared project');
    final project = (await home.getProjects()).single;
    final bytes = await ProjectExporter(home).buildPackageBytes(project);
    final file = File('${directory.path}/test.mbproj');
    await file.writeAsBytes(bytes);
    final importer = ProjectImporter(importerDb);
    final validated = await importer.validateAndExtract(file);
    final result = await importer.commit(validated, newCopy: true);
    expect(await home.getProjectById(result.projectId), isNotNull);
    expect(await settings.getProjects(), hasLength(2));
  });
}
