import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('backup-test-');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('createBackup writes a database + settings snapshot', () async {
    final db = AppDatabase.forTesting();
    final backup = BackupService(db);

    final path = await backup.createBackup();
    expect(path, isNotNull);
    final dir = Directory(path!);
    expect(dir.existsSync(), isTrue);
    expect(File(p.join(path, 'mapbanai.db')).existsSync(), isTrue);
    expect(File(p.join(path, 'prefs.json')).existsSync(), isTrue);
    expect(await backup.hasBackups(), isTrue);

    await db.close();
  });

  test('restoreLatest replaces the live database file', () async {
    final db = AppDatabase.forTesting();
    final backup = BackupService(db);
    final path = await backup.createBackup();
    expect(path, isNotNull);

    // Simulate a fresh install: live (app-private) database exists, restore
    // must overwrite it with the snapshot.
    final docs =
        (await PathProviderPlatform.instance.getApplicationDocumentsPath()) ??
            p.join(tempDir.path, 'docs');
    final live = File(p.join(docs, 'mapbanai.db'));
    await live.writeAsBytes(List<int>.filled(16, 0));
    final snapshotBytes =
        await File(p.join(path!, 'mapbanai.db')).readAsBytes();

    expect(await backup.restoreLatest(), isTrue);

    final restored =
        live.existsSync() ? await live.readAsBytes() : const <int>[];
    expect(restored, snapshotBytes);
    expect(restored, isNot(isEmpty));

    await db.close();
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempDir);

  final Directory tempDir;

  @override
  Future<String> getApplicationDocumentsPath() async =>
      p.join(tempDir.path, 'docs');
}