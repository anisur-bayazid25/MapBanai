import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/coordinate_utils.dart';

void main() {
  group('extractCoordinates', () {
    test('extracts comma-separated decimal pairs', () {
      final coords = extractCoordinates('45.5017, -73.5673');
      expect(coords, hasLength(1));
      expect(coords.first.latitude, closeTo(45.5017, 1e-9));
      expect(coords.first.longitude, closeTo(-73.5673, 1e-9));
    });

    test('extracts multiple pairs from one message', () {
      final coords = extractCoordinates(
        'First: 45.50, -73.50 Second: 46.00, -74.00',
      );
      expect(coords, hasLength(2));
    });

    test('deduplicates repeated pairs', () {
      final coords = extractCoordinates('45.50, -73.50\n45.50, -73.50');
      expect(coords, hasLength(1));
    });

    test('extracts from labeled text', () {
      final coords = extractCoordinates('lat: 45.5017, lng: -73.5673');
      expect(coords, hasLength(1));
      expect(coords.first.latitude, closeTo(45.5017, 1e-9));
      expect(coords.first.longitude, closeTo(-73.5673, 1e-9));
    });

    test('extracts DMS coordinates', () {
      final coords = extractCoordinates(
        '45°30\'06"N 73°34\'02"W',
      );
      expect(coords, hasLength(1));
      expect(coords.first.latitude, closeTo(45.5016667, 1e-6));
      expect(coords.first.longitude, closeTo(-73.5672222, 1e-6));
    });

    test('extracts DMS with south and east indicators', () {
      final coords = extractCoordinates(
        "33°51'31\"S 151°12'53\"E",
      );
      expect(coords, hasLength(1));
      expect(coords.first.latitude, closeTo(-33.8586111, 1e-6));
      expect(coords.first.longitude, closeTo(151.2147222, 1e-6));
    });

    test('handles parentheses and semicolons', () {
      final coords = extractCoordinates('(45.5017; -73.5673)');
      expect(coords, hasLength(1));
      expect(coords.first.latitude, closeTo(45.5017, 1e-9));
    });

    test('accepts unicode minus', () {
      final coords = extractCoordinates('45.5, −73.5');
      expect(coords, hasLength(1));
      expect(coords.first.longitude, closeTo(-73.5, 1e-9));
    });

    test('rejects out-of-range values', () {
      final coords = extractCoordinates('95.0, -73.5');
      expect(coords, isEmpty);
    });

    test('rejects nonsense text', () {
      final coords = extractCoordinates(
        'Call me maybe on Tuesday, ok?',
      );
      expect(coords, isEmpty);
    });

    test('returns empty for blank input', () {
      expect(extractCoordinates(''), isEmpty);
      expect(extractCoordinates('   '), isEmpty);
    });
  });

  group('formatCoordinate', () {
    test('formats to 6 decimals', () {
      expect(
        formatCoordinate(45.5017012, -73.5672531),
        '45.501701, -73.567253',
      );
    });
  });

  group('GeoCoordinate', () {
    test('isValid checks ranges', () {
      expect(const GeoCoordinate(0, 0).isValid, isTrue);
      expect(const GeoCoordinate(90, 180).isValid, isTrue);
      expect(const GeoCoordinate(-90.0001, 0).isValid, isFalse);
      expect(const GeoCoordinate(0, -180.5).isValid, isFalse);
    });

    test('JSON round-trip', () {
      const coordinate = GeoCoordinate(45.5, -73.5);
      final restored = GeoCoordinate.fromJson(coordinate.toJson());
      expect(restored, coordinate);
    });
  });
}
