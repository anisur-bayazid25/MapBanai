import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:sqlite3/sqlite3.dart';
import 'package:xml/xml.dart';

/// Status of a study area site.
enum StudyAreaStatus { pending, completed }

extension StudyAreaStatusX on StudyAreaStatus {
  static StudyAreaStatus fromString(String? raw) {
    if (raw == null) return StudyAreaStatus.pending;
    final v = raw.trim().toLowerCase();
    if (v == 'completed' ||
        v == 'complete' ||
        v == 'done' ||
        v == 'yes' ||
        v == 'true' ||
        v == '1' ||
        v == 'green' ||
        v == 'finished' ||
        v == 'closed') {
      return StudyAreaStatus.completed;
    }
    return StudyAreaStatus.pending;
  }

  String get label => this == StudyAreaStatus.completed ? 'Completed' : 'Pending';

  String get colorHex =>
      this == StudyAreaStatus.completed ? '#2E7D32' : '#E53935';

  /// Material color value for map circle.
  String get mapColor =>
      this == StudyAreaStatus.completed ? '#2E7D32' : '#E53935';
}

/// A single site point in Study Area Mode.
class StudyAreaSite {
  final String id;
  double latitude;
  double longitude;
  Map<String, String> attributes;
  StudyAreaStatus status;

  StudyAreaSite({
    required this.id,
    required this.latitude,
    required this.longitude,
    Map<String, String>? attributes,
    this.status = StudyAreaStatus.pending,
  }) : attributes = attributes ?? {};

  String get displayName =>
      attributes['name'] ??
      attributes['site_name'] ??
      attributes['site_id'] ??
      attributes['id'] ??
      attributes['label'] ??
      id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'attributes': attributes,
        'status': status.name,
      };

  factory StudyAreaSite.fromJson(Map<String, dynamic> json) {
    return StudyAreaSite(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      attributes: (json['attributes'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {},
      status: StudyAreaStatusX.fromString(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {
        'id': id,
        'status': status.name,
        'latitude': latitude,
        'longitude': longitude,
        ...attributes,
      },
    };
  }
}

/// Result of an import operation.
class StudyAreaImportResult {
  final List<StudyAreaSite> sites;
  final List<String> warnings;

  StudyAreaImportResult(this.sites, {this.warnings = const []});
}

/// Core service for Study Area Mode: parsing, geospatial math and export.
class StudyAreaService {
  // Column name aliases (lowercase).
  static const List<String> _latAliases = [
    'latitude',
    'lat',
    'y',
    'y_coord',
    'lat_deg',
    'latitude_deg',
    'lat_decimal',
  ];
  static const List<String> _lonAliases = [
    'longitude',
    'lon',
    'lng',
    'long',
    'x',
    'x_coord',
    'lon_deg',
    'longitude_deg',
    'long_deg',
    'lng_deg',
  ];
  static const List<String> _statusAliases = [
    'status',
    'state',
    'progress',
    'completed',
    'done',
    'is_completed',
    'site_status',
    'visit_status',
  ];

  /// Haversine distance in meters.
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Initial bearing from (lat1,lon1) to (lat2,lon2) in degrees 0..360.
  static double bearingDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = _toRad(lat1);
    final phi2 = _toRad(lat2);
    final dLambda = _toRad(lon2 - lon1);
    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    final theta = math.atan2(y, x);
    return (theta * 180 / math.pi + 360) % 360;
  }

  static String bearingCardinal(double bearing) {
    final idx = ((bearing + 22.5) / 45).floor() % 8;
    const eight = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return eight[idx % 8];
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(1)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  static String formatBearing(double bearing) {
    return '${bearing.toStringAsFixed(1)}° ${bearingCardinal(bearing)}';
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  // ── CSV parsing ──────────────────────────────────────────────────

  /// Parses CSV content (UTF-8 string) into sites. Supports quoted fields.
  static List<StudyAreaSite> parseCsv(String content) {
    final rows = _parseCsvRows(content);
    if (rows.isEmpty) return [];
    // Find header row: first non-empty row.
    int headerIdx = 0;
    while (headerIdx < rows.length &&
        rows[headerIdx].every((c) => c.trim().isEmpty)) {
      headerIdx++;
    }
    if (headerIdx >= rows.length) return [];
    final headers = rows[headerIdx].map((e) => e.trim()).toList();
    final lowerHeaders = headers.map((e) => e.toLowerCase()).toList();

    int latCol = -1;
    int lonCol = -1;
    int statusCol = -1;

    for (int i = 0; i < lowerHeaders.length; i++) {
      final h = lowerHeaders[i];
      if (latCol == -1 && _latAliases.contains(h)) latCol = i;
      if (lonCol == -1 && _lonAliases.contains(h)) lonCol = i;
      if (statusCol == -1 && _statusAliases.contains(h)) statusCol = i;
    }
    // Fallback: look for headers containing lat/lon substrings.
    if (latCol == -1) {
      for (int i = 0; i < lowerHeaders.length; i++) {
        if (lowerHeaders[i].contains('lat')) {
          latCol = i;
          break;
        }
      }
    }
    if (lonCol == -1) {
      for (int i = 0; i < lowerHeaders.length; i++) {
        final h = lowerHeaders[i];
        if (h.contains('lon') || h.contains('lng') || h == 'x') {
          lonCol = i;
          break;
        }
      }
    }

    if (latCol == -1 || lonCol == -1) {
      throw FormatException(
          'CSV must contain latitude and longitude columns (found: ${headers.join(', ')})');
    }

    final sites = <StudyAreaSite>[];
    for (int r = headerIdx + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((c) => c.trim().isEmpty)) continue;
      // Pad row to headers length.
      while (row.length < headers.length) row.add('');
      final latStr = row.length > latCol ? row[latCol].trim() : '';
      final lonStr = row.length > lonCol ? row[lonCol].trim() : '';
      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat == null || lon == null) continue;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

      final attrs = <String, String>{};
      for (int c = 0; c < headers.length; c++) {
        if (c == latCol || c == lonCol) continue;
        final key = headers[c].trim();
        if (key.isEmpty) continue;
        final val = c < row.length ? row[c].trim() : '';
        attrs[key] = val;
      }

      String rawStatus = '';
      if (statusCol != -1 && statusCol < row.length) {
        rawStatus = row[statusCol];
      } else {
        // Look for any attribute that looks like status.
        for (final entry in attrs.entries) {
          if (_statusAliases.contains(entry.key.toLowerCase())) {
            rawStatus = entry.value;
            break;
          }
        }
      }
      final status = StudyAreaStatusX.fromString(rawStatus);

      final idVal = attrs['id'] ??
          attrs['site_id'] ??
          attrs['site'] ??
          attrs['fid'] ??
          'site_${r}';
      final id = idVal.trim().isEmpty ? 'site_${r}_${lat}_${lon}' : idVal.trim();

      sites.add(StudyAreaSite(
        id: id,
        latitude: lat,
        longitude: lon,
        attributes: attrs,
        status: status,
      ));
    }
    return sites;
  }

  static List<StudyAreaSite> parseCsvBytes(Uint8List bytes) {
    // Strip UTF-8 BOM if present.
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = String.fromCharCodes(bytes);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    return parseCsv(text);
  }

  /// Minimal CSV row parser handling quoted fields, commas and escaped quotes.
  static List<List<String>> _parseCsvRows(String content) {
    final rows = <List<String>>[];
    final lines = content.split(RegExp(r'\r?\n'));
    for (final rawLine in lines) {
      if (rawLine.trim().isEmpty && rows.isEmpty) continue;
      // If line is empty after header, keep as empty row to allow skipping.
      final row = <String>[];
      final buf = StringBuffer();
      bool inQuotes = false;
      for (int i = 0; i < rawLine.length; i++) {
        final ch = rawLine[i];
        if (ch == '"') {
          if (inQuotes && i + 1 < rawLine.length && rawLine[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (ch == ',' && !inQuotes) {
          row.add(buf.toString());
          buf.clear();
        } else {
          buf.write(ch);
        }
      }
      row.add(buf.toString());
      // Only add if not completely empty line after header detection.
      // Keep rows that have at least one non-empty or we are past header.
      rows.add(row);
    }
    // Remove trailing empty rows.
    while (rows.isNotEmpty && rows.last.every((c) => c.trim().isEmpty)) {
      rows.removeLast();
    }
    return rows;
  }

  // ── GeoJSON ──────────────────────────────────────────────────────

  static List<StudyAreaSite> parseGeoJson(String content) {
    final decoded = jsonDecode(content);
    List<dynamic> features;
    if (decoded is Map<String, dynamic>) {
      if (decoded['type'] == 'FeatureCollection' && decoded['features'] is List) {
        features = decoded['features'] as List;
      } else if (decoded['type'] == 'Feature') {
        features = [decoded];
      } else if (decoded['geometry'] != null) {
        features = [decoded];
      } else {
        // Try to find features array anywhere.
        features = [];
      }
    } else if (decoded is List) {
      features = decoded;
    } else {
      throw FormatException('Invalid GeoJSON structure');
    }

    final sites = <StudyAreaSite>[];
    for (int idx = 0; idx < features.length; idx++) {
      final f = features[idx];
      if (f is! Map) continue;
      final geom = f['geometry'];
      if (geom is! Map) continue;
      final type = geom['type']?.toString();
      if (type != 'Point') continue;
      final coords = geom['coordinates'];
      if (coords is! List || coords.length < 2) continue;
      final lon = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lon == null || lat == null) continue;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

      final props = f['properties'] is Map
          ? Map<String, dynamic>.from(f['properties'] as Map)
          : <String, dynamic>{};
      // Also consider top-level id.
      if (f['id'] != null && !props.containsKey('id')) {
        props['id'] = f['id'];
      }

      final attrs = <String, String>{};
      String rawStatus = '';
      for (final entry in props.entries) {
        final k = entry.key.toString();
        final v = entry.value?.toString() ?? '';
        attrs[k] = v;
        if (_statusAliases.contains(k.toLowerCase())) {
          rawStatus = v;
        }
      }
      // Fallback: check status in props case-insensitive.
      if (rawStatus.isEmpty) {
        for (final k in props.keys) {
          if (k.toString().toLowerCase() == 'status') {
            rawStatus = props[k]?.toString() ?? '';
            break;
          }
        }
      }
      final status = StudyAreaStatusX.fromString(rawStatus);
      final idVal = props['id']?.toString() ??
          props['site_id']?.toString() ??
          props['name']?.toString() ??
          'geojson_${idx}';
      final id = idVal.trim().isEmpty ? 'geojson_${idx}_${lat}_${lon}' : idVal.trim();

      sites.add(StudyAreaSite(
        id: id,
        latitude: lat,
        longitude: lon,
        attributes: attrs,
        status: status,
      ));
    }
    if (sites.isEmpty && features.isNotEmpty) {
      // If no points found but features existed, it may be that file has no point features.
      // Return empty list rather than error - caller can warn.
    }
    return sites;
  }

  // ── KML ──────────────────────────────────────────────────────────

  static List<StudyAreaSite> parseKml(String content) {
    final doc = XmlDocument.parse(content);
    final placemarks = doc.findAllElements('Placemark');
    final sites = <StudyAreaSite>[];
    int idx = 0;
    for (final pm in placemarks) {
      idx++;
      // Extract coordinates from Point or any Geometry.
      XmlElement? point = pm.findElements('Point').firstOrNull;
      // Also search recursively for Point if not direct child.
      if (point == null) {
        final points = pm.findAllElements('Point');
        if (points.isNotEmpty) point = points.first;
      }
      if (point == null) continue;
      final coordEl = point.findElements('coordinates').firstOrNull;
      if (coordEl == null) continue;
      final coordText = coordEl.innerText.trim();
      if (coordText.isEmpty) continue;
      // KML coordinates may have multiple points (LineString) but for Point take first.
      final firstCoord = coordText.split(RegExp(r'\s+')).first;
      final parts = firstCoord.split(',');
      if (parts.length < 2) continue;
      final lon = double.tryParse(parts[0].trim());
      final lat = double.tryParse(parts[1].trim());
      if (lon == null || lat == null) continue;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

      final name = pm.findElements('name').firstOrNull?.innerText.trim() ?? '';
      final desc = pm.findElements('description').firstOrNull?.innerText.trim() ?? '';

      final attrs = <String, String>{};
      if (name.isNotEmpty) attrs['name'] = name;
      if (desc.isNotEmpty) attrs['description'] = desc;

      // ExtendedData Data elements.
      for (final data in pm.findAllElements('Data')) {
        final key = data.getAttribute('name') ?? '';
        final val = data.findElements('value').firstOrNull?.innerText ?? '';
        if (key.isNotEmpty) attrs[key] = val;
      }
      for (final simple in pm.findAllElements('SimpleData')) {
        final key = simple.getAttribute('name') ?? '';
        final val = simple.innerText;
        if (key.isNotEmpty) attrs[key] = val;
      }

      String rawStatus = '';
      for (final entry in attrs.entries) {
        if (_statusAliases.contains(entry.key.toLowerCase())) {
          rawStatus = entry.value;
          break;
        }
      }
      final status = StudyAreaStatusX.fromString(rawStatus);
      final idVal = attrs['id'] ?? attrs['site_id'] ?? name;
      final id = idVal.trim().isEmpty ? 'kml_${idx}_${lat}_${lon}' : idVal.trim();

      sites.add(StudyAreaSite(
        id: id,
        latitude: lat,
        longitude: lon,
        attributes: attrs,
        status: status,
      ));
    }
    return sites;
  }

  // ── KMZ (zipped KML) ─────────────────────────────────────────────

  static List<StudyAreaSite> parseKmzBytes(Uint8List bytes) {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw FormatException('Invalid KMZ file (not a valid ZIP)');
    }
    ArchiveFile? kmlFile;
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final lower = f.name.toLowerCase();
      if (lower.endsWith('.kml')) {
        // Prefer doc.kml but take first match otherwise.
        if (lower == 'doc.kml' || lower.endsWith('/doc.kml')) {
          kmlFile = f;
          break;
        }
        kmlFile ??= f;
      }
    }
    if (kmlFile == null) {
      throw FormatException('KMZ does not contain a KML file');
    }
    final raw = kmlFile.content as List<int>;
    final text = utf8.decode(raw, allowMalformed: true);
    return parseKml(text);
  }

  // ── GeoPackage ───────────────────────────────────────────────────

  /// Parses a GeoPackage file on disk. Supports point layers stored as
  /// GeoPackage geometry blobs (GP header + WKB).
  static Future<List<StudyAreaSite>> parseGeoPackage(File file) async {
    if (!file.existsSync()) {
      throw FileSystemException('GeoPackage file not found', file.path);
    }
    // sqlite3 requires a path; open read-only.
    final db = sqlite3.open(file.path);
    try {
      return _parseGeoPackageDb(db);
    } finally {
      db.dispose();
    }
  }

  static Future<List<StudyAreaSite>> parseGeoPackageBytes(Uint8List bytes) async {
    final tempDir = await Directory.systemTemp.createTemp('study_area_gpkg_');
    final tempFile = File('${tempDir.path}/temp.gpkg');
    await tempFile.writeAsBytes(bytes, flush: true);
    try {
      return await parseGeoPackage(tempFile);
    } finally {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  static List<StudyAreaSite> _parseGeoPackageDb(Database db) {
    final sites = <StudyAreaSite>[];
    // Discover feature tables via gpkg_contents.
    List<Map<String, dynamic>> tables = [];
    try {
      final rs = db.select(
          "SELECT table_name, srs_id FROM gpkg_contents WHERE data_type = 'features'");
      for (final row in rs) {
        tables.add({
          'table': row['table_name'] as String,
          'srs_id': row['srs_id'],
        });
      }
    } catch (_) {
      // Fallback: list all tables.
      final rs = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'gpkg_%' AND name NOT LIKE 'sqlite_%'");
      for (final row in rs) {
        tables.add({'table': row['name'] as String, 'srs_id': 4326});
      }
    }

    if (tables.isEmpty) {
      // Last resort: try mapbanai_features.
      tables = [
        {'table': 'mapbanai_features', 'srs_id': 4326}
      ];
    }

    for (final entry in tables) {
      final table = entry['table'] as String;
      // Safely quote table name.
      final safeTable = table.replaceAll('"', '""');
      // Discover geometry column.
      String? geomCol;
      try {
        final gcol = db.select(
            "SELECT column_name FROM gpkg_geometry_columns WHERE table_name = ?",
            [table]);
        if (gcol.isNotEmpty) geomCol = gcol.first['column_name'] as String;
      } catch (_) {}
      geomCol ??= 'geometry';
      // Also try 'geom'
      final candidates = [geomCol, 'geometry', 'geom', 'the_geom', 'wkb_geometry'];
      String? workingGeom;
      for (final cand in candidates) {
        try {
          db.select('SELECT "$cand" FROM "$safeTable" LIMIT 1');
          workingGeom = cand;
          break;
        } catch (_) {}
      }
      if (workingGeom == null) continue;

      // Get column names for attributes.
      List<String> colNames = [];
      try {
        final pragma = db.select('PRAGMA table_info("$safeTable")');
        colNames = [for (final r in pragma) r['name'] as String];
      } catch (_) {}

      try {
        final rows = db.select('SELECT * FROM "$safeTable"');
        for (int idx = 0; idx < rows.length; idx++) {
          final row = rows[idx];
          final geomBlob = row[workingGeom];
          if (geomBlob == null) continue;
          Uint8List bytes;
          if (geomBlob is Uint8List) {
            bytes = geomBlob;
          } else if (geomBlob is List<int>) {
            bytes = Uint8List.fromList(geomBlob);
          } else {
            continue;
          }
          final point = _parseGpkgPoint(bytes);
          if (point == null) continue;
          final lat = point[1];
          final lon = point[0];
          if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

          final attrs = <String, String>{};
          for (final col in colNames) {
            if (col == workingGeom) continue;
            final val = row[col];
            if (val != null) attrs[col] = val.toString();
          }
          String rawStatus = '';
          for (final e in attrs.entries) {
            if (_statusAliases.contains(e.key.toLowerCase())) {
              rawStatus = e.value;
              break;
            }
          }
          final status = StudyAreaStatusX.fromString(rawStatus);
          final idVal = attrs['id'] ??
              attrs['site_id'] ??
              attrs['fid'] ??
              attrs['feature_id'] ??
              '${table}_$idx';
          final id =
              idVal.trim().isEmpty ? '${table}_${idx}_${lat}_${lon}' : idVal.trim();
          sites.add(StudyAreaSite(
            id: id,
            latitude: lat,
            longitude: lon,
            attributes: attrs,
            status: status,
          ));
        }
      } catch (_) {
        continue;
      }
      if (sites.isNotEmpty) break; // Use first table that yields points.
    }
    return sites;
  }

  /// Parses a GeoPackage geometry blob (GP header + WKB). Returns [lon, lat] for Point.
  static List<double>? _parseGpkgPoint(Uint8List blob) {
    if (blob.length < 8) return null;
    // Check magic 'GP' if present.
    int wkbOffset = 0;
    if (blob[0] == 0x47 && blob[1] == 0x50) {
      // Modern GP header: magic 2 + version 1 + flags 1 + srs_id 4 = 8.
      wkbOffset = 8;
      // Validate little endian flag? For now assume little endian WKB.
    }
    if (blob.length < wkbOffset + 5) return null;
    final wkb = blob.sublist(wkbOffset);
    // WKB: byteOrder 1, type 4 bytes, then coords.
    final byteOrder = wkb[0];
    final isLittle = byteOrder == 1;
    if (wkb.length < 5) return null;
    final type = isLittle
        ? (wkb[1] | (wkb[2] << 8) | (wkb[3] << 16) | (wkb[4] << 24))
        : ((wkb[1] << 24) | (wkb[2] << 16) | (wkb[3] << 8) | wkb[4]);
    // Mask out Z/M flags (high bits). GeoPackage uses standard WKB types; type & 0xFF gives base.
    final baseType = type & 0xFF;
    // Some WKB encodes type with envelope flags in high bits; still point is 1.
    if (baseType != 1) {
      // For non-point, try to extract first coordinate if it's a line/polygon?
      // We treat as unsupported for study area but try to parse as point anyway if length matches point.
      if (wkb.length >= 21) {
        // Attempt to read as point even if type says otherwise (fallback).
      } else {
        return null;
      }
    }
    if (wkb.length < 21) return null;
    final bd = ByteData.sublistView(wkb);
    // After 1+4 header, coords: double lon, double lat.
    final lon = bd.getFloat64(5, isLittle ? Endian.little : Endian.big);
    final lat = bd.getFloat64(13, isLittle ? Endian.little : Endian.big);
    return [lon, lat];
  }

  // ── Generic dispatcher ───────────────────────────────────────────

  static Future<List<StudyAreaSite>> importFromFile(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();
    return _importFromBytes(bytes, ext, file);
  }

  static Future<List<StudyAreaSite>> _importFromBytes(
      Uint8List bytes, String ext, File? file) async {
    switch (ext) {
      case 'csv':
        return parseCsvBytes(bytes);
      case 'geojson':
      case 'json':
        // Try GeoJSON first; if fails try CSV fallback.
        try {
          final text = utf8.decode(bytes);
          final trimmed = text.trimLeft();
          if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
            return parseGeoJson(text);
          }
        } catch (_) {}
        // Fallback to CSV if it looks like CSV.
        return parseCsvBytes(bytes);
      case 'kml':
        return parseKml(utf8.decode(bytes, allowMalformed: true));
      case 'kmz':
        return parseKmzBytes(bytes);
      case 'gpkg':
      case 'geopackage':
      case 'sqlite':
      case 'db':
        if (file != null) {
          return await parseGeoPackage(file);
        } else {
          return await parseGeoPackageBytes(bytes);
        }
      case 'xlsx':
        return parseXlsxBytes(bytes);
      default:
        // Guess by content.
        final text = utf8.decode(bytes, allowMalformed: true).trimLeft();
        if (text.startsWith('<?xml') && text.contains('<kml')) {
          return parseKml(text);
        }
        if (text.startsWith('{') || text.startsWith('[')) {
          try {
            return parseGeoJson(text);
          } catch (_) {}
        }
        // Try zip signature - could be KMZ, XLSX, or zipped gpkg confusion
        if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
          // Try KMZ first (ZIP containing KML)
          try {
            return parseKmzBytes(bytes);
          } catch (_) {}
          // Then XLSX
          try {
            return parseXlsxBytes(bytes);
          } catch (_) {}
        }
        return parseCsvBytes(bytes);
    }
  }

  // ── Excel import (for completeness) ──────────────────────────────

  static List<StudyAreaSite> parseXlsxBytes(Uint8List bytes) {
    // Use archive to unzip and read first sheet as CSV-like.
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      // Quick check if it's XLSX: contains xl/workbook.xml
      final isXlsx = archive.files.any((f) => f.name == 'xl/workbook.xml');
      if (!isXlsx) throw FormatException('Not an XLSX file');
      // Use our XlsxWorkbookReader for parsing.
      // Inline minimal: read first sheet rows as CSV.
      // Import from xlsx_reader.dart logic but avoid circular dependency: replicate via excel package.
      final excel = excel_lib.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) throw FormatException('XLSX has no sheets');
      final firstSheetName = excel.tables.keys.first;
      final table = excel.tables[firstSheetName];
      if (table == null || table.rows.isEmpty) return [];
      final headers = table.rows.first
          .map((c) => c?.value?.toString().trim() ?? '')
          .toList();
      final lowerHeaders = headers.map((e) => e.toLowerCase()).toList();
      int latCol = -1;
      int lonCol = -1;
      int statusCol = -1;
      for (int i = 0; i < lowerHeaders.length; i++) {
        final h = lowerHeaders[i];
        if (latCol == -1 && _latAliases.contains(h)) latCol = i;
        if (lonCol == -1 && _lonAliases.contains(h)) lonCol = i;
        if (statusCol == -1 && _statusAliases.contains(h)) statusCol = i;
      }
      if (latCol == -1) {
        for (int i = 0; i < lowerHeaders.length; i++) {
          if (lowerHeaders[i].contains('lat')) {
            latCol = i;
            break;
          }
        }
      }
      if (lonCol == -1) {
        for (int i = 0; i < lowerHeaders.length; i++) {
          final h = lowerHeaders[i];
          if (h.contains('lon') || h.contains('lng') || h == 'x') {
            lonCol = i;
            break;
          }
        }
      }
      if (latCol == -1 || lonCol == -1) {
        throw FormatException(
            'XLSX must contain latitude and longitude columns (found: ${headers.join(', ')})');
      }
      final sites = <StudyAreaSite>[];
      for (int r = 1; r < table.rows.length; r++) {
        final row = table.rows[r];
        if (row.every((c) => c?.value == null)) continue;
        String cell(int idx) => idx < row.length
            ? (row[idx]?.value?.toString().trim() ?? '')
            : '';
        final latStr = cell(latCol);
        final lonStr = cell(lonCol);
        final lat = double.tryParse(latStr);
        final lon = double.tryParse(lonStr);
        if (lat == null || lon == null) continue;
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;
        final attrs = <String, String>{};
        for (int c = 0; c < headers.length; c++) {
          if (c == latCol || c == lonCol) continue;
          final key = headers[c].trim();
          if (key.isEmpty) continue;
          attrs[key] = cell(c);
        }
        String rawStatus = statusCol != -1 ? cell(statusCol) : '';
        if (rawStatus.isEmpty) {
          for (final e in attrs.entries) {
            if (_statusAliases.contains(e.key.toLowerCase())) {
              rawStatus = e.value;
              break;
            }
          }
        }
        final status = StudyAreaStatusX.fromString(rawStatus);
        final idVal = attrs['id'] ??
            attrs['site_id'] ??
            attrs['site'] ??
            'xlsx_${r}';
        final id = idVal.trim().isEmpty
            ? 'xlsx_${r}_${lat}_${lon}'
            : idVal.trim();
        sites.add(StudyAreaSite(
          id: id,
          latitude: lat,
          longitude: lon,
          attributes: attrs,
          status: status,
        ));
      }
      return sites;
    } catch (e) {
      rethrow;
    }
  }

  // ── Export ───────────────────────────────────────────────────────

  static String toCsv(List<StudyAreaSite> sites) {
    if (sites.isEmpty) {
      return 'id,latitude,longitude,status\n';
    }
    // Collect all attribute keys.
    final keys = <String>{};
    for (final s in sites) {
      keys.addAll(s.attributes.keys);
    }
    final attrKeys = keys.toList()..sort();
    // Ensure core keys are first for readability, but attrKeys already sorted.
    final headers = ['id', 'latitude', 'longitude', 'status', ...attrKeys];
    // Avoid duplicating status if already in attrs.
    final dedupedHeaders = <String>[];
    final seen = <String>{};
    for (final h in headers) {
      if (seen.add(h.toLowerCase())) dedupedHeaders.add(h);
    }
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(dedupedHeaders.map(_escapeCsv).join(','));
    for (final s in sites) {
      // Build row: need to handle status column - if attribute already has status, use site.status
      final row = <String>[];
      for (final h in dedupedHeaders) {
        final low = h.toLowerCase();
        if (low == 'id') {
          row.add(s.id);
        } else if (low == 'latitude' || low == 'lat') {
          row.add(s.latitude.toStringAsFixed(7));
        } else if (low == 'longitude' || low == 'lon' || low == 'lng') {
          row.add(s.longitude.toStringAsFixed(7));
        } else if (low == 'status') {
          row.add(s.status.name);
        } else {
          row.add(s.attributes[h] ?? '');
        }
      }
      buffer.writeln(row.map(_escapeCsv).join(','));
    }
    return buffer.toString();
  }

  static Uint8List toExcelBytes(List<StudyAreaSite> sites) {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Sheet1'];
    if (sites.isEmpty) {
      sheet.appendRow([
        excel_lib.TextCellValue('id'),
        excel_lib.TextCellValue('latitude'),
        excel_lib.TextCellValue('longitude'),
        excel_lib.TextCellValue('status'),
      ]);
      return Uint8List.fromList(excel.encode()!);
    }
    final keys = <String>{};
    for (final s in sites) {
      keys.addAll(s.attributes.keys);
    }
    final attrKeys = keys.toList()..sort();
    final headers = ['id', 'latitude', 'longitude', 'status', ...attrKeys];
    final dedupedHeaders = <String>[];
    final seen = <String>{};
    for (final h in headers) {
      if (seen.add(h.toLowerCase())) dedupedHeaders.add(h);
    }
    sheet.appendRow(
        dedupedHeaders.map((h) => excel_lib.TextCellValue(h)).toList());
    for (final s in sites) {
      final row = <excel_lib.CellValue>[];
      for (final h in dedupedHeaders) {
        final low = h.toLowerCase();
        if (low == 'id') {
          row.add(excel_lib.TextCellValue(s.id));
        } else if (low == 'latitude' || low == 'lat') {
          row.add(excel_lib.TextCellValue(s.latitude.toStringAsFixed(7)));
        } else if (low == 'longitude' || low == 'lon' || low == 'lng') {
          row.add(excel_lib.TextCellValue(s.longitude.toStringAsFixed(7)));
        } else if (low == 'status') {
          row.add(excel_lib.TextCellValue(s.status.name));
        } else {
          final val = s.attributes[h] ?? '';
          // Try numeric?
          final numVal = double.tryParse(val);
          if (numVal != null && val.trim().isNotEmpty) {
            row.add(excel_lib.DoubleCellValue(numVal));
          } else {
            row.add(excel_lib.TextCellValue(val));
          }
        }
      }
      sheet.appendRow(row);
    }
    // Auto-fit not needed.
    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
