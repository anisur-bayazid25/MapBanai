/// Parsing and formatting of geographic coordinates.
///
/// Used by the one-tap clipboard capture ("copy coordinates into the app"),
/// supporting common field formats:
///  - decimal degrees: `45.5017, -73.5673` (also `;`, parentheses, unicode minus)
///  - DMS: `45°30'06"N 73°34'02"W`
///  - labeled: `lat: 45.5017, lng: -73.5673`
library;

class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate(this.latitude, this.longitude);

  bool get isValid =>
      latitude >= -90 && latitude <= 90 &&
      longitude >= -180 && longitude <= 180;

  String toDisplayString() => formatCoordinate(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) =>
      GeoCoordinate(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is GeoCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => toDisplayString();
}

/// Extracts all coordinate pairs from arbitrary clipboard/text content.
///
/// Returns an empty list when nothing parseable is found.
List<GeoCoordinate> extractCoordinates(String text) {
  if (text.trim().isEmpty) return [];

  final results = <GeoCoordinate>[];
  final seen = <String>{};

  void add(double lat, double lng) {
    final coordinate = GeoCoordinate(lat, lng);
    final key = '${coordinate.latitude},${coordinate.longitude}';
    if (coordinate.isValid && seen.add(key)) {
      results.add(coordinate);
    }
  }

  // 1. Labeled form: lat: 45.50, lng: -73.56 (also lng/lon/longitude keys)
  final labeled = RegExp(
    r'lat(?:itude)?\s*[:=]\s*([-\u2212+]?\d{1,3}(?:\.\d+)?)\s*[,;]?\s*'
    r'(?:lng|lon|long|longitude)\s*[:=]\s*([-\u2212+]?\d{1,3}(?:\.\d+)?)',
    caseSensitive: false,
  );
  for (final match in labeled.allMatches(text)) {
    final lat = double.tryParse(_normalizeSign(match.group(1)!));
    final lng = double.tryParse(_normalizeSign(match.group(2)!));
    if (lat != null && lng != null) add(lat, lng);
  }

  // 2. DMS pairs: 45°30'06"N 73°34'02"W
  final dms = RegExp(
    '([0-9]{1,3})[°ºo]([0-9]{1,2})[\'’]([0-9]{1,2}(?:[.,][0-9]+)?)[”"]?'
    '([NSEW])\\s*[,;]?\\s*'
    '([0-9]{1,3})[°ºo]([0-9]{1,2})[\'’]([0-9]{1,2}(?:[.,][0-9]+)?)[”"]?'
    '([NSEW])',
    caseSensitive: false,
  );
  for (final match in dms.allMatches(text)) {
    final lat = _dmsToDecimal(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      double.parse(match.group(3)!.replaceAll(',', '.')),
      match.group(4)!,
    );
    final lng = _dmsToDecimal(
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
      double.parse(match.group(7)!.replaceAll(',', '.')),
      match.group(8)!,
    );
    if (lat != null && lng != null) add(lat, lng);
  }

  // 3. Decimal pairs: 45.5017, -73.5673 | (45.5017; -73.5673) | 45.5017 -73.5673
  final decimal = RegExp(
    r'\(?\s*([-\u2212+]?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*'
    r'([-\u2212+]?\d{1,3}(?:\.\d+)?)\s*\)?',
  );
  for (final match in decimal.allMatches(text)) {
    final lat = double.tryParse(_normalizeSign(match.group(1)!));
    final lng = double.tryParse(_normalizeSign(match.group(2)!));
    if (lat != null && lng != null) add(lat, lng);
  }

  return results;
}

/// Replaces the unicode minus sign with an ASCII hyphen so [double.tryParse]
/// can read it.
String _normalizeSign(String value) => value.replaceAll('\u2212', '-');

/// Converts DMS components with a compass direction to decimal degrees.
double? _dmsToDecimal(int degrees, int minutes, double seconds, String dir) {
  if (minutes > 59 || seconds >= 60) return null;
  var value = degrees + (minutes / 60) + (seconds / 3600);
  if (dir.toUpperCase() == 'S' || dir.toUpperCase() == 'W') {
    value = -value;
  }
  return value;
}

/// Formats a coordinate for display/copying, e.g. `45.501701, -73.567253`.
String formatCoordinate(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
