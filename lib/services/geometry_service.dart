import 'dart:math' as math;

import 'package:mapbanai/services/measure_units.dart';

/// Geodesic and planar geometry helpers for recorded GPS tracks.
class GeometryService {
  static const double _earthRadiusM = 6371000;

  /// Great-circle distance between two coordinates (Haversine).
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Total length of an ordered polyline in meters.
  static double polylineLengthM(List<({double lat, double lon})> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += distanceMeters(
        points[i - 1].lat,
        points[i - 1].lon,
        points[i].lat,
        points[i].lon,
      );
    }
    return total;
  }

  /// Perimeter of a closed polygon in meters. The path is implicitly
  /// closed (last vertex connects to the first).
  static double polygonPerimeterM(List<({double lat, double lon})> points) {
    if (points.length < 3) return 0;
    final open = polylineLengthM(points);
    return open +
        distanceMeters(
          points.last.lat,
          points.last.lon,
          points.first.lat,
          points.first.lon,
        );
  }

  /// Planar area of a polygon in square meters using the shoelace
  /// formula on an equirectangular projection (accurate for small areas).
  static double polygonAreaM2(List<({double lat, double lon})> points) {
    if (points.length < 3) return 0;

    final meanLat = points.fold<double>(
          0,
          (sum, p) => sum + _toRad(p.lat),
        ) /
        points.length;

    const mPerDegLat = 111320.0;
    final mPerDegLon = 111320.0 * math.cos(meanLat);

    double sum = 0;
    for (int i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      final x1 = a.lon * mPerDegLon;
      final y1 = a.lat * mPerDegLat;
      final x2 = b.lon * mPerDegLon;
      final y2 = b.lat * mPerDegLat;
      sum += x1 * y2 - x2 * y1;
    }
    return (sum.abs() / 2);
  }

  static String formatDistance(double meters) {
    return MeasureUnits.formatDistance(meters, DistanceUnit.auto);
  }

  static String formatArea(double squareMeters) {
    return MeasureUnits.formatArea(squareMeters, AreaUnit.auto);
  }

  static double _toRad(double degrees) => degrees * math.pi / 180;
}