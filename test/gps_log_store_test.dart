import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/services/gps_log_store.dart';

void main() {
  late Directory tempDir;
  late GpsLogStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gps_log_test');
    store = GpsLogStore(baseDir: tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Position position(double lat, double lng) => Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.utc(2026, 8, 17, 12, 0, 0),
    accuracy: 4.2,
    altitude: 35.7,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
    floor: null,
    isMocked: false,
  );

  test('writes header on creation and auto-increments row ids', () async {
    await store.createLogFile(1);

    final first = await store.appendReading(
      logId: 1,
      surveyor: 'Alice',
      position: position(45.501688, -73.567357),
    );
    final second = await store.appendReading(
      logId: 1,
      surveyor: 'Alice',
      position: position(45.502100, -73.568000),
    );

    expect(first.id, 1);
    expect(second.id, 2);

    final lines = await File(await store.filePath(1)).readAsLines();
    expect(lines, hasLength(3));
    expect(lines[0], GpsLogStore.header);
    expect(lines[1], startsWith('1,Alice,'));
    expect(lines[1], contains('45.5016880'));
    expect(lines[1], contains('35.70'));
    expect(lines[1], contains('4.20'));
    expect(await store.readingCount(1), 2);
  });

  test('row ids survive restarts (derived from file lines)', () async {
    await store.createLogFile(7);
    await store.appendReading(
      logId: 7,
      surveyor: '',
      position: position(1, 2),
    );
    await store.appendReading(
      logId: 7,
      surveyor: '',
      position: position(3, 4),
    );

    final fresh = GpsLogStore(baseDir: tempDir);
    final next = await fresh.appendReading(
      logId: 7,
      surveyor: 'Bob',
      position: position(5, 6),
    );
    expect(next.id, 3);
  });

  test('escapes surveyor names with commas', () async {
    await store.createLogFile(2);
    await store.appendReading(
      logId: 2,
      surveyor: 'Doe, John',
      position: position(10, 20),
    );

    final line = (await File(await store.filePath(2)).readAsLines())[1];
    expect(line, contains('"Doe, John"'));
  });

  test('stores optional notes on a manually captured waypoint', () async {
    await store.createLogFile(9);
    final reading = await store.appendReading(
      logId: 9,
      surveyor: 'Alice',
      position: position(23.81, 90.41),
      notes: 'Culvert under road',
    );

    expect(reading.notes, 'Culvert under road');

    final line = (await File(await store.filePath(9)).readAsLines())[1];
    expect(line, endsWith('Culvert under road'));
    expect(line, contains('23.8100000'));
  });

  test('lastReadingTime returns the last row timestamp', () async {
    await store.createLogFile(3);
    final t = DateTime.utc(2026, 8, 17, 9, 30);
    await store.appendReading(
      logId: 3,
      surveyor: '',
      position: position(10, 20),
      timestamp: t,
    );
    expect(await store.lastReadingTime(3), t);
  });

  test('deleteFile removes the CSV', () async {
    await store.createLogFile(4);
    expect(File(await store.filePath(4)).existsSync(), isTrue);
    await store.deleteFile(4);
    expect(File(await store.filePath(4)).existsSync(), isFalse);
    expect(await store.readingCount(4), 0);
  });
}