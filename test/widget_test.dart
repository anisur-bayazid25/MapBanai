import 'package:flutter/material.dart';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/app.dart';
import 'package:mapbanai/data/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  setUp(() {
    AppDatabase.useInProcessFileForTesting = true;
    directory = Directory.systemTemp.createTempSync('mapbanai-widget-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return directory.path;
        }
        if (call.method == 'getTemporaryDirectory') {
          return directory.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    AppDatabase.useInProcessFileForTesting = false;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      null,
    );
    directory.deleteSync(recursive: true);
  });

  testWidgets('MapBanai home screen shows mode options and project actions',
      (tester) async {
    await tester.pumpWidget(const MapBanaiApp());

    // The home header shows the logo image and the tagline.
    expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.runtimeType.toString() == 'Image' &&
              widget.toStringDeep().contains('AssetImage'),
        ),
        findsAtLeastNWidgets(1));
    expect(find.text('Easy Geospatial Data Collection'), findsOneWidget);
    expect(find.text('Survey Mode'), findsOneWidget);
    expect(find.text('GIS Mode'), findsOneWidget);
    // "Open" was renamed to "Project Settings" in v2.4.1.
    expect(find.text('Project settings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('survey session save persists a project relationship', () async {
    final database = AppDatabase();

    final projectName = 'Test Project ${DateTime.now().microsecondsSinceEpoch}';
    final projectId = await database.insertProject(
      ProjectsCompanion(
        name: Value(projectName),
        isActive: const Value(true),
      ),
    );

    expect(await database.getProjectIdByName(projectName), equals(projectId));

    await database.insertSurveySession(
      SurveySessionsCompanion(
        projectId: Value(projectId),
        title: Value('Erosion near culvert'),
        status: const Value('saved'),
      ),
    );

    final sessions = await database.getSurveySessions();
    expect(sessions.any((session) => session.title == 'Erosion near culvert'),
        isTrue);

    await database.close();
  });
}
