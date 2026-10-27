import 'dart:typed_data';
import 'package:mapbanai/ui/workflow_requirements_screen.dart';
import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/workflow_requirements_service.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_collection_service.dart';
import 'package:mapbanai/ui/study_area_hub_screen.dart';
import 'package:mapbanai/ui/study_area_mode_screen.dart';
import 'package:mapbanai/ui/study_collection_form_screen.dart';
import 'package:mapbanai/ui/study_workflow_setup_screen.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'gis_mode_save_test.dart' as fakes;
import 'study_area_screen_test.dart' show MemoryStudyAreaStore;

class WorkflowMapFake extends fakes.FakeMaplibrePlatform {
  final updates = <Map<String, dynamic>>[];
  @override
  Future<bool?> animateCamera(CameraUpdate update,
          {Duration? duration}) async =>
      true;
  @override
  Future<void> addImage(String name, Uint8List bytes,
      [bool sdf = false]) async {}
  @override
  Future<void> removeLayer(String id) async {}
  @override
  Future<void> setLayerProperties(
      String id, Map<String, dynamic> properties) async {}
  @override
  Future<void> setGeoJsonSource(String id, Map<String, dynamic> source) async {
    updates.add(jsonDecode(jsonEncode(source)) as Map<String, dynamic>);
    await super.setGeoJsonSource(id, source);
  }
}

void main() {
  late AppDatabase db;
  late Directory directory;
  late fakes.FakeGeolocatorPlatform gps;
  late ProjectWorkspaceService service;
  late int projectId;
  late StoredForm form;
  late StudyAreaSite site;
  late CollectionRound round;
  late MemoryStudyAreaStore store;
  late WorkflowMapFake map;
  setUp(() async {
    db = AppDatabase.forTesting();
    directory = Directory.systemTemp.createTempSync('mapbanai-workflow-ui-');
    PathProviderPlatform.instance =
        fakes.FakePathProviderPlatform(directory.path);
    gps = fakes.FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = gps;
    PermissionHandlerPlatform.instance = fakes.FakePermissionHandlerPlatform();
    map = WorkflowMapFake();
    MapLibrePlatform.createInstance = () => map;
    projectId = await db
        .insertProject(const ProjectsCompanion(name: Value('Dhaka fieldwork')));
    final schema =
        SurveyForm(id: 'salt', name: 'Salinity', description: '', questions: [
      Question(
          name: 'salt',
          label: 'Salinity (ppt)',
          type: QuestionType.decimal,
          required: true)
    ]);
    await db.insertStoredForm(StoredFormsCompanion(
        projectId: Value(projectId),
        name: Value(schema.name),
        json: Value(jsonEncode(schema.toJson()))));
    form = (await db.getStoredFormsForProject(projectId)).single;
    service = ProjectWorkspaceService(db);
    final workspace = await service.addLayer(projectId, 'Salinity stations',
        workflow: StudyWorkflow.recurring);
    round =
        await service.addRound(projectId, workspace.layerId, 'Dry season 2027');
    site = StudyAreaSite(
        id: 'site-1',
        projectId: projectId,
        projectExternalId: workspace.project.externalId,
        layerId: workspace.layerId,
        latitude: 23.7,
        longitude: 90.4,
        attributes: {'name': 'Station 1'});
    store = MemoryStudyAreaStore()..sites.add(site);
  });
  tearDown(() async {
    await gps.positions.close();
    await db.close();
    directory.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, Widget screen,
      {Size size = const Size(360, 800),
      double scale = 1,
      String language = 'en'}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: screen));
    await fakes.pumpFrames(tester, 20);
  }

  testWidgets('Study Area opens a hub with all three workflows',
      (tester) async {
    await pump(tester, StudyAreaHubScreen(database: db, projectId: projectId));
    for (final workflow in StudyWorkflow.values)
      expect(find.text(workflow.title), findsOneWidget);
    await tester.tap(find.text('Recurring Collection'));
    await fakes.pumpFrames(tester);
    expect(find.byType(StudyWorkflowSetupScreen), findsOneWidget);
    expect(find.text('Collection round'), findsOneWidget);
    expect(find.text('Dry season 2027'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'new workflow setup opens selected context without needing to touch dropdowns',
      (tester) async {
    StudyWorkflowSelection? selected;
    await pump(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      selected = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => StudyWorkflowSetupScreen(
                                  database: db,
                                  projectId: projectId,
                                  workflow: StudyWorkflow.recurring)));
                    },
                    child: const Text('Choose')))));
    await tester.tap(find.text('Choose'));
    await fakes.pumpFrames(tester);
    await tester.ensureVisible(find.text('Open map'));
    await tester.tap(find.text('Open map'));
    await fakes.pumpFrames(tester, 20);
    expect(selected?.round?.id, round.id);
    expect(selected?.workspace.layerId, site.layerId);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [const Size(320, 568), const Size(640, 360)]) {
    testWidgets(
        'compact recurring map leaves controls reachable at $size with large text',
        (tester) async {
      await pump(
          tester,
          StudyAreaModeScreen(
              database: db,
              store: store,
              projectId: projectId,
              initialSelectedSiteId: site.id,
              workflow: StudyWorkflow.recurring,
              collectionRound: round,
              compactControls: true),
          size: size,
          scale: 2);
      expect(find.byType(MapLibreMap), findsOneWidget);
      expect(find.text('Not collected'), findsOneWidget);
      expect(find.byTooltip('Study workspace'), findsOneWidget);
      expect(find.byTooltip('Open in Google Maps'), findsOneWidget);
      expect(find.text('Study layer'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byTooltip('Needs review').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Needs review').last);
      await fakes.pumpFrames(tester, 20);
      expect(find.text('Needs review'), findsWidgets);
      expect(
          (await StudyCollectionService(db).statuses(projectId, site.layerId,
              StudyWorkflow.recurring, round))[site.id],
          StudyAreaStatus.needsReview);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'observation form saves a separate measurement and turns round green',
      (tester) async {
    await pump(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StudyCollectionFormScreen(
                                database: db,
                                projectId: projectId,
                                site: site,
                                workflow: StudyWorkflow.recurring,
                                round: round,
                                form: form))),
                    child: const Text('Collect')))));
    await tester.tap(find.text('Collect'));
    await fakes.pumpFrames(tester);
    await tester.enterText(find.byType(TextField), '5.7');
    await tester.ensureVisible(find.text('Save responses'));
    await tester.tap(find.text('Save responses'));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 250)));
    await fakes.pumpFrames(tester, 30);
    expect(
        (await StudyCollectionService(db).statuses(
            projectId, site.layerId, StudyWorkflow.recurring, round))[site.id],
        StudyAreaStatus.completed);
    expect(store.sites.single.formAnswers, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('nearest unvisited list selects a named site without GPS',
      (tester) async {
    await pump(
        tester,
        StudyAreaModeScreen(
            database: db,
            projectId: projectId,
            workflow: StudyWorkflow.recurring,
            collectionRound: round,
            store: store,
            compactControls: true));
    expect(find.byTooltip('Open in Google Maps'), findsOneWidget);
    await tester.tap(find.byTooltip('Nearest unvisited sites'));
    await fakes.pumpFrames(tester);
    expect(find.text('No recent GPS location. Sites are sorted by name.'),
        findsOneWidget);
    await tester.tap(find.text('Station 1').last);
    await fakes.pumpFrames(tester);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.byTooltip('Open in Google Maps'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('workflow requirements save all three workflow switches',
      (tester) async {
    await pump(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => WorkflowRequirementsScreen(
                                database: db, projectId: projectId))),
                    child: const Text('Configure')))));
    await tester.tap(find.text('Configure'));
    await fakes.pumpFrames(tester);
    final toggle = find.byKey(const ValueKey('questionnaire-recurring'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    final photo = find.byKey(const ValueKey('photo-visits'));
    await tester.ensureVisible(photo);
    await tester.pumpAndSettle();
    await tester.tap(photo);
    await tester.ensureVisible(find.text('Save requirements'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save requirements'));
    await fakes.pumpFrames(tester);
    final saved = await WorkflowRequirementsService(db).load(projectId);
    expect(saved[StudyWorkflow.recurring]!.questionnaire, false);
    expect(saved[StudyWorkflow.visits]!.photo, true);
    expect(saved[StudyWorkflow.verification]!.photo, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('optional questionnaire completes an observation without a form',
      (tester) async {
    await WorkflowRequirementsService(db).save(projectId, {
      StudyWorkflow.recurring:
          const WorkflowRequirements(questionnaire: false, photo: false)
    });
    await pump(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StudyCollectionFormScreen(
                                database: db,
                                projectId: projectId,
                                site: site,
                                workflow: StudyWorkflow.recurring,
                                round: round))),
                    child: const Text('Visit')))));
    await tester.tap(find.text('Visit'));
    await fakes.pumpFrames(tester);
    await tester.tap(find.text('Mark done'));
    await fakes.pumpFrames(tester);
    expect(
        (await StudyCollectionService(db).statuses(
            projectId, site.layerId, StudyWorkflow.recurring, round))[site.id],
        StudyAreaStatus.completed);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final workflow in StudyWorkflow.values) {
    testWidgets('Google Maps action is available in ${workflow.name}',
        (tester) async {
      if (workflow != StudyWorkflow.recurring) {
        final context =
            await service.addLayer(projectId, 'Sites', workflow: workflow);
        site.layerId = context.layerId;
      }
      await service.select(projectId,
          workflow: workflow, layerId: site.layerId, formId: form.id);
      await pump(
          tester,
          StudyAreaModeScreen(
              database: db,
              projectId: projectId,
              store: store,
              workflow: workflow,
              collectionRound:
                  workflow == StudyWorkflow.recurring ? round : null,
              initialSelectedSiteId: site.id,
              compactControls: true));
      expect(find.byTooltip('Open in Google Maps'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Bangla requirements fit narrow screens with large text',
      (tester) async {
    await pump(
        tester, WorkflowRequirementsScreen(database: db, projectId: projectId),
        size: const Size(320, 568), scale: 2, language: 'bn');
    expect(find.text('Workflow requirements'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('photo-visits')), 250,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('status updates preserve existing map annotations',
      (tester) async {
    await pump(
        tester,
        StudyAreaModeScreen(
            database: db,
            projectId: projectId,
            store: store,
            workflow: StudyWorkflow.recurring,
            collectionRound: round,
            initialSelectedSiteId: site.id,
            compactControls: true));
    map.onMapStyleLoadedPlatform.call(null);
    await fakes.pumpFrames(tester, 30);
    expect(
        map.sources.values
            .any((source) => (source['features'] as List).isNotEmpty),
        true);
    map.updates.clear();
    final action = find.byTooltip('Needs review').last;
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await fakes.pumpFrames(tester, 30);
    expect(map.updates, isNotEmpty);
    expect(
        map.updates.every((source) => (source['features'] as List).isNotEmpty),
        true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
