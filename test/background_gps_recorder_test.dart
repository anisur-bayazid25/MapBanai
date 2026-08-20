import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/services/background_gps_recorder.dart';
import 'package:mapbanai/services/gps_log_store.dart';
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

Position fix({double lat = 23.8103, double lon = 90.4125}) => Position(
  latitude: lat,
  longitude: lon,
  timestamp: DateTime.utc(2026, 8, 17, 12, 0, 0),
  accuracy: 4.2,
  altitude: 20.0,
  altitudeAccuracy: 2,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  floor: null,
  isMocked: false,
);

void main() {
  late Directory tempDir;
  late FakeGeolocatorPlatform geolocator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mapbanai_bg_gps');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    PermissionHandlerPlatform.instance = FakePermissionHandlerPlatform();
    geolocator = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = geolocator;
    await BackgroundGps.instance.stop();
  });

  tearDown(() async {
    await BackgroundGps.instance.stop();
    await geolocator.positions.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('start/stop flips recording state and exposes the active log', () async {
    final bg = BackgroundGps.instance;
    expect(bg.isRecording, isFalse);

    final ok = await bg.start(logId: 7, logName: 'Site A walk', surveyor: '');
    expect(ok, isTrue);
    expect(bg.isRecording, isTrue);
    expect(bg.activeLogId, 7);
    expect(bg.activeLogName, 'Site A walk');

    await bg.stop();
    expect(bg.isRecording, isFalse);
    expect(bg.activeLogId, isNull);
  });

  test('incoming fixes are streamed into the log CSV', () async {
    final ok = await BackgroundGps.instance.start(
      logId: 1,
      logName: 'Track',
      surveyor: 'Alice',
    );
    expect(ok, isTrue);

    geolocator.emit(fix(lat: 23.8103, lon: 90.4125));
    await Future.delayed(const Duration(milliseconds: 100));

    expect(BackgroundGps.instance.latest?.latitude, closeTo(23.8103, 1e-9));

    final store = GpsLogStore(baseDir: await GpsLogStore.defaultLogsDir());
    expect(await store.readingCount(1), 1);
    expect(await store.lastReadingTime(1), isNotNull);
  });

  test('pause stops appends but keeps the stream alive', () async {
    final bg = BackgroundGps.instance;
    await bg.start(logId: 2, logName: 'Track', surveyor: 'Alice');

    geolocator.emit(fix(lat: 10.0, lon: 20.0));
    await Future.delayed(const Duration(milliseconds: 100));

    bg.setPaused(true);
    geolocator.emit(fix(lat: 11.0, lon: 21.0));
    await Future.delayed(const Duration(milliseconds: 100));

    final store = GpsLogStore(baseDir: await GpsLogStore.defaultLogsDir());
    expect(await store.readingCount(2), 1,
        reason: 'paused recordings must not append further fixes');
    expect(bg.latest?.latitude, closeTo(11.0, 1e-9),
        reason: 'the live readout still updates while paused');

    bg.setPaused(false);
    await Future.delayed(const Duration(milliseconds: 1100));
    geolocator.emit(fix(lat: 12.0, lon: 22.0));
    await Future.delayed(const Duration(milliseconds: 100));

    expect(await store.readingCount(2), 2);
  });

  test('notifies listeners on fix arrival and stop', () async {
    final bg = BackgroundGps.instance;
    var notifications = 0;
    void listener() => notifications++;
    bg.addListener(listener);
    addTearDown(() => bg.removeListener(listener));

    await bg.start(logId: 3, logName: 'Track', surveyor: '');
    geolocator.emit(fix());
    await Future.delayed(const Duration(milliseconds: 100));
    expect(notifications, greaterThan(0));

    await bg.stop();
    expect(notifications, greaterThan(0));
  });
}