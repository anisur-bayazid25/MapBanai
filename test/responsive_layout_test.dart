import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/home_screen.dart';
import 'package:mapbanai/ui/photo_capture_screen.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/ui/study_area_mode_screen.dart';
import 'package:mapbanai/ui/point_record_screen.dart';
import 'package:mapbanai/ui/line_record_screen.dart';
import 'package:mapbanai/ui/polygon_record_screen.dart';
import 'package:mapbanai/ui/gps_mode_screen.dart';
import 'package:mapbanai/ui/geometry_capture_screen.dart';
import 'package:mapbanai/services/update_checker.dart';
import 'package:mapbanai/ui/common/update_dialog.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

import 'gis_mode_save_test.dart' as fakes;
import 'study_area_screen_test.dart' show MemoryStudyAreaStore;

final _previewKey = GlobalKey();

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String> getApplicationDocumentsPath() async => path;
  @override
  Future<String> getTemporaryPath() async => path;
  @override
  Future<String> getExternalStoragePath() async => path;
  @override
  Future<List<String>> getExternalStoragePaths(
          {StorageDirectory? type}) async =>
      [path];
}

Future<void> _pump(WidgetTester tester, Widget screen,
    {required Size size,
    required double scale,
    String language = 'en',
    ProjectState? project}) async {
  // A high pixel density must produce the same logical layout as a low one.
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final originalError = FlutterError.onError;
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
    originalError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalError);
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: project ?? ProjectState(),
    child: MaterialApp(
      theme: ThemeData(
          useMaterial3: true,
          fontFamily: const bool.fromEnvironment('MAPBANAI_LAYOUT_PREVIEWS')
              ? 'Roboto'
              : null),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(key: _previewKey, child: screen),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase database;
  late Directory directory;
  late PathProviderPlatform originalPaths;
  late int projectId;
  const projectName = 'CARE GIS October 2026 — Riverbank monitoring team';

  setUpAll(() async {
    const fontDir = String.fromEnvironment('MAPBANAI_PREVIEW_FONT_DIR');
    if (const bool.fromEnvironment('MAPBANAI_LAYOUT_PREVIEWS') &&
        fontDir.isNotEmpty) {
      final fonts = FontLoader('Roboto')
        ..addFont(File('$fontDir/roboto-regular.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)));
      await fonts.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(File('$fontDir/materialicons-regular.otf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)));
      await icons.load();
    }
  });

  setUp(() async {
    AppDatabase.useInProcessFileForTesting = true;
    directory = Directory.systemTemp.createTempSync('mapbanai-layout-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    database = AppDatabase.forTesting();
    await database.createProject(projectName);
    projectId = (await database.getProjectByName(projectName))!.id;
    await database.setSetting('user_name', 'Layout tester');
  });
  tearDown(() async {
    AppDatabase.useInProcessFileForTesting = false;
    await database.close();
    PathProviderPlatform.instance = originalPaths;
    directory.deleteSync(recursive: true);
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(412, 915),
    const Size(640, 360),
    const Size(800, 1024)
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final language in ['en', 'bn']) {
        testWidgets(
            'home $size text $scale $language keeps labels and actions usable',
            (tester) async {
          final project = ProjectState()
            ..setSelectedProject(projectName, projectId: projectId);
          await _pump(tester, HomeScreen(database: database),
              size: size, scale: scale, language: language, project: project);
          // Finish the best-effort startup backup timer before unmounting.
          await tester.pump(const Duration(seconds: 11));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final l10n = lookupAppLocalizations(Locale(language));
          expect(tester.getTopLeft(find.text(l10n.studyAreaModeTitle)).dy,
              lessThan(tester.getTopLeft(find.text(l10n.gisModeTitle)).dy));
          final settings = find.ancestor(
              of: find.text(l10n.projectSettings),
              matching: find.byWidgetPredicate((w) => w is OutlinedButton));
          await tester.ensureVisible(settings);
          await tester.pumpAndSettle();
          // A full action gets a readable width rather than one third of a phone.
          expect(tester.getSize(settings).width, greaterThanOrEqualTo(180));
          final label = tester.widget<Text>(find.text(l10n.projectSettings));
          expect(label.maxLines, isNull);
          expect(label.overflow, isNot(TextOverflow.ellipsis));
          final import = find.ancestor(
              of: find.text(l10n.importProject),
              matching: find.byWidgetPredicate((w) => w is OutlinedButton));
          await tester.ensureVisible(import);
          await tester.pumpAndSettle();
          expect(tester.getRect(import).overlaps(Offset.zero & size), isTrue);
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('MAPBANAI_LAYOUT_PREVIEWS') &&
              size == const Size(360, 800) &&
              scale == 1.5 &&
              language == 'en') {
            final boundary = _previewKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final png =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final output =
                  File('.dart_tool/layout-previews/home-360-text150.png');
              await output.parent.create(recursive: true);
              await output.writeAsBytes(png!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  testWidgets('project controls reflow with large text in a narrow viewport',
      (tester) async {
    await _pump(
        tester, ProjectDetailScreen(projectId: projectId, database: database),
        size: const Size(320, 568), scale: 2);
    await tester.scrollUntilVisible(find.text('Test Connection'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        tester
            .getRect(find.text('Test Connection'))
            .overlaps(const Rect.fromLTWH(0, 0, 320, 568)),
        isTrue);
  });

  testWidgets('photo controls are reachable on a short landscape screen',
      (tester) async {
    await _pump(tester, const PhotoCaptureScreen(),
        size: const Size(568, 320), scale: 2);
    await tester.ensureVisible(find.text('Open camera'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        tester
            .getRect(find.text('Open camera'))
            .overlaps(const Rect.fromLTWH(0, 0, 568, 320)),
        isTrue);
  });

  testWidgets('survey long choices and media controls fit large text',
      (tester) async {
    final form = SurveyForm(
        id: 'layout',
        name: 'Field form',
        description: '',
        questions: [
          Question(
              name: 'condition',
              label: 'Condition',
              type: QuestionType.select_one,
              choices: [
                Choice(
                    name: 'long',
                    label:
                        'Riverbank needs urgent inspection by the field team')
              ]),
          Question(name: 'photo', label: 'Photo', type: QuestionType.image),
          Question(
              name: 'geometry', label: 'Geometry', type: QuestionType.geoshape),
        ]);
    await _pump(
        tester,
        Scaffold(
            body: SurveyFormRenderer(
                form: form, initialAnswers: const {'condition': 'long'})),
        size: const Size(320, 568),
        scale: 2);
    await tester.ensureVisible(find.text('Draw on map'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(640, 360)]) {
    testWidgets(
        'study map workspace and selected feature fit $size at large text',
        (tester) async {
      final oldGps = GeolocatorPlatform.instance;
      final oldPermissions = PermissionHandlerPlatform.instance;
      final oldMapFactory = MapLibrePlatform.createInstance;
      final gps = fakes.FakeGeolocatorPlatform();
      GeolocatorPlatform.instance = gps;
      PermissionHandlerPlatform.instance =
          fakes.FakePermissionHandlerPlatform();
      MapLibrePlatform.createInstance = () => fakes.FakeMaplibrePlatform();
      addTearDown(() async {
        GeolocatorPlatform.instance = oldGps;
        PermissionHandlerPlatform.instance = oldPermissions;
        MapLibrePlatform.createInstance = oldMapFactory;
        await gps.positions.close();
      });
      final store = MemoryStudyAreaStore();
      store.sites.add(StudyAreaSite(
          id: 'layout',
          projectId: projectId,
          latitude: 23.7,
          longitude: 90.4,
          attributes: {'name': 'Long facility name for the survey team'}));
      await _pump(
          tester,
          StudyAreaModeScreen(
              database: database,
              store: store,
              projectId: projectId,
              initialSelectedSiteId: 'layout'),
          size: size,
          scale: 2);
      await fakes.pumpFrames(tester, 20);
      expect(tester.takeException(), isNull);
      expect(find.byType(MapLibreMap), findsOneWidget);
      expect(find.text('Location changed'), findsOneWidget);
      await tester.ensureVisible(find.text('Location changed'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final entry in <String, Widget>{
    'point': const PointRecordScreen(projectName: projectName),
    'line': const LineRecordScreen(projectName: projectName),
    'polygon': const PolygonRecordScreen(projectName: projectName),
    'GPS': const GpsModeScreen(),
  }.entries) {
    testWidgets('${entry.key} controls fit a short screen with large text',
        (tester) async {
      final oldGps = GeolocatorPlatform.instance;
      final oldPermissions = PermissionHandlerPlatform.instance;
      PermissionHandlerPlatform.instance =
          fakes.FakePermissionHandlerPlatform();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('mapbanai/compass'), (_) async => null);
      final gps = fakes.FakeGeolocatorPlatform();
      GeolocatorPlatform.instance = gps;
      addTearDown(() async {
        GeolocatorPlatform.instance = oldGps;
        PermissionHandlerPlatform.instance = oldPermissions;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('mapbanai/compass'), null);
        await gps.positions.close();
      });
      await _pump(tester, entry.value, size: const Size(568, 320), scale: 2);
      await fakes.pumpFrames(tester, 12);
      gps.emit(fakes.testFix());
      await fakes.pumpFrames(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
  }

  testWidgets(
      'point geometry controls scroll in Bangla landscape with large text',
      (tester) async {
    MapLibrePlatform.createInstance = () => fakes.FakeMaplibrePlatform();
    await _pump(
        tester,
        const GeometryCaptureScreen(geometryType: 'Point', initialGeometry: {
          'type': 'Point',
          'coordinates': [90.4, 23.7]
        }),
        size: const Size(640, 360),
        scale: 2,
        language: 'bn');
    await tester.scrollUntilVisible(find.text('জ্যামিতি সংরক্ষণ'), 100,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        tester
            .getRect(find.text('জ্যামিতি সংরক্ষণ'))
            .overlaps(const Rect.fromLTWH(0, 0, 640, 360)),
        isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('update dialog scrolls at large text in landscape',
      (tester) async {
    await _pump(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showUpdateDialog(
                        context,
                        const UpdateInfo(
                            version: '2.7.0',
                            downloadUrl: 'https://example.com/app.apk',
                            releaseNotes: 'Layout and download improvements.')),
                    child: const Text('Update')))),
        size: const Size(568, 320),
        scale: 2);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Open in browser'), findsOneWidget);
  });
}
