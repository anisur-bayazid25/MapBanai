import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/ui/gis_mode_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String> getApplicationDocumentsPath() async => path;
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  final StreamController<Position> positions = StreamController.broadcast();

  void emit(Position position) => positions.add(position);

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return positions.stream;
  }

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position?> getLastKnownPosition(
      {bool forceLocationManager = false}) async {
    return null;
  }
}

class FakePermissionHandlerPlatform extends PermissionHandlerPlatform {
  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      PermissionStatus.granted;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
      List<Permission> permissions) async {
    return {
      for (final permission in permissions)
        permission: PermissionStatus.granted,
    };
  }
}

class FakeMaplibrePlatform implements MapLibrePlatform {
  final Map<String, Map<String, dynamic>> sources = {};
  int viewId = 1;
  int _viewsBuilt = 0;

  @override
  final onInfoWindowTappedPlatform = ArgumentCallbacks<String>();
  @override
  final onFeatureTappedPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onFeatureHoverPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onFeatureDraggedPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onCameraMoveStartedPlatform = ArgumentCallbacks<void>();
  @override
  final onCameraMovePlatform = ArgumentCallbacks<CameraPosition>();
  @override
  final onCameraIdlePlatform = ArgumentCallbacks<CameraPosition?>();
  @override
  final onMapStyleLoadedPlatform = ArgumentCallbacks<void>();
  @override
  final onMapClickPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onMapLongClickPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onCameraTrackingChangedPlatform =
      ArgumentCallbacks<MyLocationTrackingMode>();
  @override
  final onCameraTrackingDismissedPlatform = ArgumentCallbacks<void>();
  @override
  final onMapIdlePlatform = ArgumentCallbacks<void>();
  @override
  final onUserLocationUpdatedPlatform = ArgumentCallbacks<UserLocation>();

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    // The real native view is created once per widget; later rebuilds
    // re-render into the same view without firing the callback again.
    if (_viewsBuilt == 0) {
      onPlatformViewCreated(viewId++);
    }
    _viewsBuilt++;
    return const SizedBox.expand();
  }

  @override
  Future<void> addGeoJsonSource(String sourceId, Map<String, dynamic> geojson,
      {String? promoteId}) async {
    sources[sourceId] = geojson;
  }

  @override
  Future<void> setGeoJsonSource(
      String sourceId, Map<String, dynamic> geojson) async {
    sources[sourceId] = geojson;
  }

  @override
  Future<void> addSymbolLayer(String sourceId, String layerId,
      Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {}

  @override
  Future<void> addCircleLayer(String sourceId, String layerId,
      Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {}

  @override
  Future<void> addLineLayer(String sourceId, String layerId,
      Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {}

  @override
  Future<void> addFillLayer(String sourceId, String layerId,
      Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Position testFix({
  double lat = 23.8103,
  double lon = 90.4125,
  double accuracy = 5.0,
  double altitude = 20.0,
}) {
  return Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime.utc(2026, 8, 17, 12, 0, 0),
    accuracy: accuracy,
    altitude: altitude,
    altitudeAccuracy: 2,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
    floor: null,
    isMocked: false,
  );
}

Future<void> pumpFrames(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<AppDatabase> createProjectInTempDirectory(
    Directory tempDir, String name) async {
  final db = AppDatabase();
  await db.createProject(name);
  await db.close();
  return db;
}

/// Taps the Add Point tool, waits for the draft circle, taps Finish, fills
/// nothing, and taps "Save feature" in the sheet.
Future<void> savePoint(
  WidgetTester tester,
  FakeMaplibrePlatform fake,
) async {
  await tester.tap(find.byTooltip('Add Point'));
  await pumpFrames(tester);

  await tester.tap(find.text('Finish'));
  await pumpFrames(tester);

  expect(find.text('Save feature'), findsOneWidget);
  final saveButton = tester.widget<FilledButton>(
    find.ancestor(
      of: find.text('Save feature'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    ),
  );
  saveButton.onPressed!.call();
  await pumpFrames(tester, 12);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('file-backed AppDatabase round trip works outside the widget zone',
      () async {
    final dir = await Directory.systemTemp.createTemp('mapbanai_probe');
    PathProviderPlatform.instance = FakePathProviderPlatform(dir.path);
    final db = AppDatabase();
    await db.createProject('Probe');
    await db.close();
    final db2 = AppDatabase();
    final projects = await db2.getProjects();
    await db2.close();
    expect(projects, hasLength(1));
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  late Directory tempDir;
  late FakeGeolocatorPlatform geolocator;
  late FakePermissionHandlerPlatform permissions;
  late FakeMaplibrePlatform fake;

  setUp(() async {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    AppDatabase.useInProcessFileForTesting = true;
    tempDir = await Directory.systemTemp.createTemp('mapbanai_gis_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    geolocator = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = geolocator;
    permissions = FakePermissionHandlerPlatform();
    PermissionHandlerPlatform.instance = permissions;
    fake = FakeMaplibrePlatform();
    MapLibrePlatform.createInstance = () => fake;
    await createProjectInTempDirectory(tempDir, 'Test Project');
  });

  tearDown(() async {
    AppDatabase.useInProcessFileForTesting = false;
    geolocator.positions.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('saving a point keeps exactly one feature with its row in the DB',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: GisModeScreen(projectName: 'Test Project')),
    );
    await pumpFrames(tester);
    geolocator.emit(testFix());
    await pumpFrames(tester);
    fake.onMapStyleLoadedPlatform.call(null);
    await pumpFrames(tester, 12);

    await savePoint(tester, fake);

    for (final source in fake.sources.values) {
      expect(
        (source['features'] as List).length,
        lessThanOrEqualTo(1),
        reason: 'no source should accumulate duplicate/ghost features',
      );
    }
    final saved = fake.sources.values
        .where((source) => (source['features'] as List).isNotEmpty)
        .toList();
    expect(saved, hasLength(1));
    final feature =
        (saved.single['features'] as List).single as Map<String, dynamic>;
    final coordinates =
        (feature['geometry'] as Map<String, dynamic>)['coordinates'] as List;
    expect(coordinates[1], closeTo(23.8103, 1e-6));
    expect(coordinates[0], closeTo(90.4125, 1e-6));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final db = AppDatabase();
    final sessions = await db.getSurveySessions();
    expect(sessions, hasLength(1));
    final responses = jsonDecode(sessions.single.responses);
    expect((responses as Map<String, dynamic>)['feature_type'], 'point');
    await db.close();
  });

  testWidgets('saving a second point keeps both features on the map', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: GisModeScreen(projectName: 'Test Project')),
    );
    await pumpFrames(tester);
    geolocator.emit(testFix());
    await pumpFrames(tester);
    fake.onMapStyleLoadedPlatform.call(null);
    await pumpFrames(tester, 12);

    await savePoint(tester, fake);
    await tester.pump(const Duration(seconds: 5));
    geolocator.emit(testFix(lat: 23.8110, lon: 90.4130));
    await pumpFrames(tester);
    await savePoint(tester, fake);

    final saved = fake.sources.values
        .where((source) => (source['features'] as List).isNotEmpty)
        .toList();
    expect(saved, hasLength(1));
    expect((saved.single['features'] as List).length, 2,
        reason: 'both saved points must stay on the map');
  });
}
