import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/ui/survey_form_detail_screen.dart';
import 'package:mapbanai/ui/survey_history_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'helpers/test_utils.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String> getApplicationDocumentsPath() async => path;
}

Future<int> seedProject(AppDatabase db, String name) async {
  return db.insertProject(
    ProjectsCompanion(
      name: drift.Value(name),
      isActive: const drift.Value(true),
    ),
  );
}

Future<StoredForm> seedStoredForm(AppDatabase db, int projectId) async {
  final form = sampleSurveyForm();
await db.insertStoredForm(
      StoredFormsCompanion(
        projectId: drift.Value(projectId),
        name: drift.Value(form.name),
        description: drift.Value(form.description),
        json: drift.Value(jsonEncode(form.toJson())),
        version: const drift.Value(1),
      ),
    );
    final stored = await db.getStoredFormByName(form.name, projectId: projectId);
  expect(stored, isNotNull);
  return stored!;
}

Future<SurveySession> seedSurveyDraft(
  AppDatabase db,
  int projectId, {
  Map<String, dynamic>? answers,
}) async {
  final id = await db.insertSurveySession(
    SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Draft survey — Demo Form'),
      status: const drift.Value('draft'),
      responses: drift.Value(jsonEncode({
        'form_id': 'demo_form',
        'form_name': 'Demo Form',
        'user_name': '',
        'answers': answers ?? <String, dynamic>{},
      })),
    ),
  );
  final session = await db.getSurveySession(id);
  expect(session, isNotNull);
  return session!;
}

Future<SurveySession> seedGisDraft(AppDatabase db, int projectId) async {
  final id = await db.insertSurveySession(
    SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Draft line • 2 pts'),
      status: const drift.Value('draft'),
      responses: drift.Value(jsonEncode({
        'draft': true,
        'feature_type': 'line',
        'recorder': {'running': true, 'vertices': []},
      })),
    ),
  );
  final session = await db.getSurveySession(id);
  expect(session, isNotNull);
  return session!;
}

Future<SurveySession> seedSavedSurvey(AppDatabase db, int projectId) async {
  final id = await db.insertSurveySession(
    SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Culvert near bridge'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'form_id': 'demo_form',
        'form_name': 'Demo Form',
        'user_name': '',
        'answers': {'site_name': 'Culvert near bridge'},
      })),
    ),
  );
  final session = await db.getSurveySession(id);
  expect(session, isNotNull);
  return session!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    AppDatabase.useInProcessFileForTesting = true;
    tempDir = await Directory.systemTemp.createTemp('mapbanai_drafts');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    AppDatabase.useInProcessFileForTesting = false;
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('drafts are separated from collected data in counts', () async {
    final db = AppDatabase();
    final projectId = await seedProject(db, 'River Basin');

    await seedSavedSurvey(db, projectId);
    await seedGisDraft(db, projectId);
    await seedSurveyDraft(db, projectId);

    final drafts = await db.getDraftSurveySessions();
    expect(drafts, hasLength(2));
    expect(drafts.every((s) => s.status == 'draft'), isTrue);

    final counts = await db.responseCountsForProject(projectId);
    expect(counts.survey, 1, reason: 'draft survey must not count as collected');
    expect(counts.gis, 0, reason: 'draft feature must not count as collected');

    expect(await db.surveySessionCountForProject(projectId), 1);

    // Updating a draft to saved moves it into the collected counts.
    final savedId = await db.insertSurveySession(
      SurveySessionsCompanion(
        projectId: drift.Value(projectId),
title: const drift.Value('Draft line • 2 pts'),
        status: const drift.Value('draft'),
        responses: drift.Value(jsonEncode({
          'draft': true,
          'feature_type': 'line',
        })),
      ),
    );
    await db.updateSurveySession(savedId, status: 'saved');
    final countsAfter = await db.responseCountsForProject(projectId);
    expect(countsAfter.gis, 1);
    await db.close();
  });

  testWidgets('Save as draft in the form detail keeps a resumable row',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase();
    final projectId = await seedProject(db, 'River Basin');
    final stored = await seedStoredForm(db, projectId);

    await tester.pumpWidget(
      MaterialApp(
        home: SurveyFormDetailScreen(
          row: stored,
          projectName: 'River Basin',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run survey'));
    await tester.pumpAndSettle();

    expect(find.text('Save as draft'), findsOneWidget);

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));

    await tester.enterText(
      find.byType(TextField).at(0),
      'Draft site near river',
    );
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.pump();

    await tester.tap(find.text('Save as draft'));
    await tester.pumpAndSettle();

    final drafts = await db.getDraftSurveySessions();
    expect(drafts, hasLength(1));
    final responses =
        jsonDecode(drafts.single.responses) as Map<String, dynamic>;
    final answers = responses['answers'] as Map<String, dynamic>;
    expect(answers['site_name'], 'Draft site near river');
    expect(answers['height_m'], 12);
    await db.close();
  });

  testWidgets('history lists drafts, hides them from saved, deletes and resumes',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase();
    final projectId = await seedProject(db, 'River Basin');
    await seedStoredForm(db, projectId);
    await seedSavedSurvey(db, projectId);
    await seedSurveyDraft(db, projectId);
    await seedGisDraft(db, projectId);
    await db.close();

    await tester.pumpWidget(
      const MaterialApp(home: SurveyHistoryScreen()),
    );
    await tester.pumpAndSettle();

    // Drafts appear in their own section; the saved one is grouped by project.
    expect(find.text('Drafts (2)'), findsOneWidget);
    expect(find.text('Culvert near bridge'), findsOneWidget);
    // Collapsible project header now includes the session count.
    expect(find.textContaining('River Basin'), findsWidgets);
    expect(find.textContaining('draft'), findsWidgets);

    // Delete the GIS draft (identified by its card, regardless of order).
    final gisCard = find.ancestor(
      of: find.text('Draft line • 2 pts'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(
        of: gisCard,
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete draft'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Drafts (1)'), findsOneWidget);

    // Resume the remaining survey draft.
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(find.text('Resume survey draft'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Resumed site');
    await tester.enterText(find.byType(TextField).at(1), '7');
    await tester.pump();

    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();

    final db2 = AppDatabase();
    final drafts = await db2.getDraftSurveySessions();
    expect(drafts, isEmpty, reason: 'finished draft must no longer be a draft');
    final saved = await db2.getSurveySessions();
    expect(
      saved.any((s) => s.title == 'Resumed site' && s.status == 'saved'),
      isTrue,
      reason: 'the resumed draft must be promoted to a saved response',
    );
    await db2.close();

    // History refreshed after returning from the resumed draft.
    expect(find.text('Drafts'), findsNothing);
    expect(find.text('Resumed site'), findsOneWidget);
  });
}