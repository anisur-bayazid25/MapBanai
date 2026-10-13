import 'dart:convert';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/study_area_mode_screen.dart';
import 'package:mapbanai/ui/geometry_capture_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import 'gis_mode_save_test.dart' as fakes;

class MemoryStudyAreaStore extends StudyAreaStore {
  final List<StudyAreaSite> sites = [];
  @override
  Future<List<StudyAreaSite>> loadSites() async => List.from(sites);
  @override
  Future<String> getOperatorName() async => 'Test fieldworker';
  @override
  Future<void> updateSite(StudyAreaSite site,
      {int? expectedRevision,
      String? expectedRevisionId,
      String author = 'Local fieldworker',
      String? visitId,
      int? sessionId,
      int? formId,
      String? photoPath}) async {
    sites.removeWhere((s) => s.id == site.id);
    sites.add(StudyAreaSite.fromJson(site.toJson()));
  }
}

void main() {
  late Directory directory;
  late fakes.FakeGeolocatorPlatform gps;
  late fakes.FakeMaplibrePlatform map;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('study_screen_');
    PathProviderPlatform.instance =
        fakes.FakePathProviderPlatform(directory.path);
    gps = fakes.FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = gps;
    PermissionHandlerPlatform.instance = fakes.FakePermissionHandlerPlatform();
    map = fakes.FakeMaplibrePlatform();
    MapLibrePlatform.createInstance = () => map;
  });
  tearDown(() async {
    await gps.positions.close();
    await directory.delete(recursive: true);
  });

  testWidgets('view-only map shows sites without importing or editing controls',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final store = MemoryStudyAreaStore();
    store.sites.add(StudyAreaSite(
        id: 'preview',
        latitude: 23.68,
        longitude: 90.44,
        attributes: {'name': 'Facility', 'layer': 'Toilet'}));
    await tester.pumpWidget(MaterialApp(
        home: StudyAreaModeScreen(store: store, database: db, viewOnly: true)));
    await fakes.pumpFrames(tester, 20);
    expect(find.text('1 / 1 features'), findsOneWidget);
    expect(find.text('Categories & colors'), findsOneWidget);
    expect(find.byTooltip('Record survey at GPS'), findsNothing);
    final import = tester.widget<IconButton>(find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Import sites'));
    expect(import.onPressed, isNull);
    expect(find.text('Import'), findsNothing);
    expect(await db.getProjects(), isEmpty);
  });

  testWidgets(
      'verified feature saves without opening its required-question survey',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final projectId =
        await db.insertProject(ProjectsCompanion.insert(name: 'Field project'));
    final form = SurveyForm(
        id: 'required',
        name: 'Required questionnaire',
        description: '',
        questions: [
          Question(
              name: 'detail',
              label: 'Required detail',
              type: QuestionType.text,
              required: true)
        ]);
    await db.insertStoredForm(StoredFormsCompanion(
        projectId: drift.Value(projectId),
        name: drift.Value(form.name),
        json: drift.Value(jsonEncode(form.toJson()))));
    final store = MemoryStudyAreaStore();
    store.sites.add(StudyAreaSite(
        id: 'existing',
        latitude: 23.68,
        longitude: 90.44,
        projectId: projectId,
        status: StudyAreaStatus.verified,
        formAnswers: {'previous': 'retain'}));
    await tester.pumpWidget(MaterialApp(
        home: StudyAreaModeScreen(
            store: store,
            database: db,
            projectId: projectId,
            initialSelectedSiteId: 'existing')));
    await fakes.pumpFrames(tester, 20);
    await tester.tap(find.text('Edit'));
    await fakes.pumpFrames(tester);
    expect(find.text('Fill questionnaire (optional)'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await fakes.pumpFrames(tester, 20);
    expect(find.text('Required detail'), findsNothing);
    expect(store.sites.single.status, StudyAreaStatus.verified);
    expect(store.sites.single.formAnswers, {'previous': 'retain'});
  });

  testWidgets('draw polygon, undo, save and expose map export choices',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final projectId = await db.insertProject(
        const ProjectsCompanion(name: drift.Value("Test project")));
    final survey = SurveyForm(
        id: 'field',
        name: 'Field questionnaire',
        description: '',
        questions: []);
    await db.insertStoredForm(StoredFormsCompanion(
        projectId: drift.Value(projectId),
        name: drift.Value(survey.name),
        json: drift.Value(jsonEncode(survey.toJson()))));
    final store = MemoryStudyAreaStore();
    await tester.pumpWidget(MaterialApp(
        home: StudyAreaModeScreen(
            store: store, database: db, projectId: projectId)));
    await fakes.pumpFrames(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await fakes.pumpFrames(tester);
    await tester.tap(find.text('Add polygon (tap vertices)'));
    await fakes.pumpFrames(tester);
    for (final point in [
      const LatLng(23, 90),
      const LatLng(23, 91),
      const LatLng(24, 91),
      const LatLng(24, 90)
    ]) {
      map.onMapClickPlatform
          .call({'point': const Point(1.0, 1.0), 'latLng': point});
      await fakes.pumpFrames(tester, 2);
    }
    expect(find.text('Polygon: 4 vertices. Tap map to add vertices.'),
        findsOneWidget);
    await tester.tap(find.text('Undo'));
    await fakes.pumpFrames(tester);
    expect(find.text('Polygon: 3 vertices. Tap map to add vertices.'),
        findsOneWidget);
    await tester.tap(find.text('Save feature'));
    await fakes.pumpFrames(tester);
    expect(
        find.byType(DropdownButtonFormField<StudyAreaStatus>), findsOneWidget);
    expect(find.text('New feature'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await fakes.pumpFrames(tester, 20);
    await tester.tap(find.text('Save responses'));
    await fakes.pumpFrames(tester, 20);
    final sites = await store.loadSites();
    expect(sites, hasLength(1));
    expect(sites.single.status, StudyAreaStatus.newFeature);
    expect(sites.single.currentGeometry['type'], 'Polygon');
    expect(sites.single.currentGeometry['coordinates'], [
      [
        [90.0, 23.0],
        [91.0, 23.0],
        [91.0, 24.0],
        [90.0, 23.0]
      ]
    ]);
    await tester.tap(find.byTooltip('Export sites').first);
    await fakes.pumpFrames(tester);
    expect(find.text('Updated map (GeoJSON)'), findsOneWidget);
    expect(find.text('Portable HTML map'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Excel (XLSX)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'survey geometry capture returns a closed polygon and keeps imported holes',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final hole = [
      [90.2, 23.2],
      [90.3, 23.2],
      [90.3, 23.3],
      [90.2, 23.2]
    ];
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GeometryCaptureScreen(
                                      geometryType: 'Polygon',
                                      initialGeometry: {
                                        'type': 'Polygon',
                                        'coordinates': [
                                          [
                                            [90, 23],
                                            [91, 23],
                                            [91, 24],
                                            [90, 23]
                                          ],
                                          hole
                                        ]
                                      })));
                    },
                    child: const Text('Capture'))))));
    await tester.tap(find.text('Capture'));
    await fakes.pumpFrames(tester);
    expect(find.text('3 vertices • Tap map to add vertices'), findsOneWidget);
    await tester.tap(find.text('Save geometry'));
    await fakes.pumpFrames(tester);
    expect(result!['type'], 'Polygon');
    expect(result!['coordinates'], [
      [
        [90.0, 23.0],
        [91.0, 23.0],
        [91.0, 24.0],
        [90.0, 23.0]
      ],
      hole
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
