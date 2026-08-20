import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/services/geometry_service.dart';
import 'package:mapbanai/services/track_recorder.dart';

Position _pos(double lat, double lon, {double accuracy = 3}) {
  return Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime.now(),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  group('GeometryService', () {
    test('haversine distance between known points', () {
      // One arc-minute of latitude ≈ 1852 m (nautical mile).
      final d = GeometryService.distanceMeters(0, 0, 0, 1 / 60);
      expect(d, closeTo(1852, 40));
    });

    test('distance of zero for identical points', () {
      expect(GeometryService.distanceMeters(23.8, 90.4, 23.8, 90.4), 0);
    });

    test('symmetry', () {
      final ab = GeometryService.distanceMeters(10, 20, 30, 40);
      final ba = GeometryService.distanceMeters(30, 40, 10, 20);
      expect(ab, closeTo(ba, 0.001));
    });

    test('polyline length sums segments', () {
      final points = [
        (lat: 0.0, lon: 0.0),
        (lat: 0.0, lon: 0.01),
        (lat: 0.0, lon: 0.02),
      ];
      final d = GeometryService.polylineLengthM(points);
      expect(d, closeTo(2 * 1113.2, 40));
    });

    test('polyline with <2 points is 0', () {
      expect(
        GeometryService.polylineLengthM([(lat: 0.0, lon: 0.0)]),
        0,
      );
      expect(GeometryService.polylineLengthM([]), 0);
    });

    test('polygon perimeter closes the loop', () {
      // Square: 0.01° x 0.01° ≈ 1113 m per side.
      final square = [
        (lat: 0.0, lon: 0.0),
        (lat: 0.0, lon: 0.01),
        (lat: 0.01, lon: 0.01),
        (lat: 0.01, lon: 0.0),
      ];
      final perimeter = GeometryService.polygonPerimeterM(square);
      expect(perimeter, closeTo(4 * 1113.2, 80));
    });

    test('polygon area of 1km box ≈ 1.24 km²', () {
      final square = [
        (lat: 0.0, lon: 0.0),
        (lat: 0.0, lon: 0.01),
        (lat: 0.01, lon: 0.01),
        (lat: 0.01, lon: 0.0),
      ];
      final area = GeometryService.polygonAreaM2(square);
      expect(area, closeTo(1240000, 120000));
    });

    test('invalid polygon has zero area/perimeter', () {
      expect(
        GeometryService.polygonAreaM2([(lat: 0.0, lon: 0.0)]),
        0,
      );
      expect(
        GeometryService.polygonPerimeterM([
          (lat: 0.0, lon: 0.0),
          (lat: 0.0, lon: 0.01),
        ]),
        0,
      );
    });

    test('formatters', () {
      expect(GeometryService.formatDistance(500), '500.0 m');
      expect(GeometryService.formatDistance(1200), '1.20 km');
      expect(GeometryService.formatArea(2500), '2500.0 m²');
      expect(GeometryService.formatArea(15000), '1.50 ha');
    });
  });

  group('TrackRecorder', () {
    test('ignores fixes while not recording', () {
      final recorder = TrackRecorder();
      expect(recorder.add(_pos(0, 0)), isFalse);
      expect(recorder.vertices, isEmpty);
    });

    test('accepts first fix and rejects when paused', () {
      final recorder = TrackRecorder()..start();
      expect(recorder.add(_pos(0, 0)), isTrue);
      recorder.pause();
      expect(recorder.add(_pos(0, 0.01)), isFalse);
      expect(recorder.vertices.length, 1);
    });

    test('rejects fixes with accuracy above threshold', () {
      final recorder = TrackRecorder()..start();
      expect(recorder.add(_pos(0, 0, accuracy: 21)), isFalse);
      expect(recorder.add(_pos(0, 0, accuracy: 20)), isTrue);
    });

    test('rejects fixes closer than minimum distance', () {
      final recorder = TrackRecorder(minDistanceM: 100)..start();
      expect(recorder.add(_pos(0, 0)), isTrue);
      // ~55 m away: below the 100 m minimum.
      expect(recorder.add(_pos(0, 0.0005)), isFalse);
    });

    test('rejects fixes faster than minimum interval', () async {
      final recorder = TrackRecorder()..start();
      expect(recorder.add(_pos(0, 0)), isTrue);
      // 1.5s < 2s minimum interval, but far enough in distance.
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(recorder.add(_pos(0, 0.01)), isFalse);
    });

    test('resume continues collecting', () {
      final recorder = TrackRecorder()..start();
      recorder.pause();
      recorder.resume();
      // resume() clears paused state; next fix far enough away is accepted
      expect(recorder.running, isTrue);
      expect(recorder.paused, isFalse);
    });

    test('undo removes last vertex', () {
      final recorder = TrackRecorder(minIntervalS: 0)..start();
      recorder.add(_pos(0, 0));
      recorder.add(_pos(0, 0.01));
      expect(recorder.vertices.length, 2);
      recorder.undo();
      expect(recorder.vertices.length, 1);
      recorder.undo();
      expect(recorder.vertices, isEmpty);
      recorder.undo(); // no-op
      expect(recorder.vertices, isEmpty);
    });

    test('reset clears state', () {
      final recorder = TrackRecorder()..start();
      recorder.add(_pos(0, 0));
      recorder.reset();
      expect(recorder.vertices, isEmpty);
      expect(recorder.running, isFalse);
      expect(recorder.latest, isNull);
    });

    test('distance accumulates over vertices', () {
      final recorder = TrackRecorder(minIntervalS: 0)..start();
      recorder.add(_pos(0, 0));
      recorder.add(_pos(0, 0.01));
      recorder.add(_pos(0, 0.02));
      expect(recorder.totalDistanceM, closeTo(2 * 1113.2, 40));
    });

    test('elapsed grows while running and pauses stop it', () async {
      final recorder = TrackRecorder()..start();
      await Future.delayed(const Duration(milliseconds: 1100));
      final t1 = recorder.elapsed;
      expect(t1.inMilliseconds >= 1000, isTrue);
      recorder.pause();
      final p1 = recorder.elapsed;
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(recorder.elapsed.inMilliseconds, closeTo(p1.inMilliseconds, 60));
      recorder.resume();
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(recorder.elapsed.inMilliseconds > p1.inMilliseconds, isTrue);
    });

    test('serialize/restore round-trips vertices and running state', () {
      final source = TrackRecorder(
        minIntervalS: 0,
        minDistanceM: 0,
      )..start();
      source.add(_pos(0, 0));
      source.add(_pos(0, 0.01));
      source.add(_pos(0, 0.02));
      expect(source.vertices, hasLength(3));

      final restored = TrackRecorder(minIntervalS: 0, minDistanceM: 0);
      restored.restore(source.serialize());

      expect(restored.running, isTrue);
      expect(restored.paused, isFalse);
      expect(restored.vertices, hasLength(3));
      expect(restored.vertices[1].longitude, closeTo(0.01, 1e-9));
      expect(restored.vertices[2].latitude, closeTo(0.0, 1e-9));
      expect(restored.totalDistanceM, closeTo(source.totalDistanceM, 1e-6));
      // Undo/append continues cleanly after restore.
      restored.add(_pos(0, 0.03));
      expect(restored.vertices, hasLength(4));
    });

    test('serialize/restore preserves a paused recording', () {
      final source = TrackRecorder(minIntervalS: 0, minDistanceM: 0)..start();
      source.add(_pos(0, 0));
      source.pause();

      final restored = TrackRecorder(minIntervalS: 0, minDistanceM: 0);
      restored.restore(source.serialize());

      expect(restored.running, isTrue);
      expect(restored.paused, isTrue);
      expect(restored.vertices, hasLength(1));
    });
  });
}