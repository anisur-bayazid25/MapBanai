import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart' as excel_lib;
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:xml/xml.dart';

/// Status of a study area site.
enum StudyAreaStatus {
  pending,
  completed,
  verified,
  updated,
  newFeature,
  notFound,
  needsReview
}

extension StudyAreaStatusX on StudyAreaStatus {
  static StudyAreaStatus fromString(String? raw) {
    if (raw == null) return StudyAreaStatus.pending;
    final v = raw.trim().toLowerCase();
    for (final status in StudyAreaStatus.values) {
      if (status.name.toLowerCase() == v) return status;
    }
    if (v == 'new') return StudyAreaStatus.newFeature;
    if (v == 'not_found') return StudyAreaStatus.notFound;
    if (v == 'needs_review') return StudyAreaStatus.needsReview;
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

  String get label => switch (this) {
        StudyAreaStatus.pending => 'Pending verification',
        StudyAreaStatus.completed ||
        StudyAreaStatus.verified ||
        StudyAreaStatus.updated =>
          'Verification Complete',
        StudyAreaStatus.newFeature => 'Pending verification',
        StudyAreaStatus.notFound => 'Location Removed',
        StudyAreaStatus.needsReview => 'Needs review',
      };

  String get colorHex => switch (this) {
        StudyAreaStatus.pending => '#E53935',
        StudyAreaStatus.completed ||
        StudyAreaStatus.verified ||
        StudyAreaStatus.updated =>
          '#2E7D32',
        StudyAreaStatus.newFeature => '#E53935',
        StudyAreaStatus.notFound => '#616161',
        StudyAreaStatus.needsReview => '#F9A825',
      };

  /// Legacy outcomes are folded into the three field verification states.
  StudyAreaStatus get verificationStatus => switch (this) {
        StudyAreaStatus.completed ||
        StudyAreaStatus.verified ||
        StudyAreaStatus.updated =>
          StudyAreaStatus.completed,
        StudyAreaStatus.newFeature => StudyAreaStatus.pending,
        StudyAreaStatus.notFound => StudyAreaStatus.needsReview,
        _ => this,
      };

  /// Material color value for map circle.
  String get mapColor => colorHex;
}

/// A single site point in Study Area Mode.
class StudyAreaRevision {
  final String id;
  final String? parentId;
  final DateTime timestamp;
  final String author;
  final String action;
  final Map<String, dynamic>? before;
  final Map<String, dynamic> after;
  final String? visitId;
  final int? sessionId;
  final int? formId;
  final int? projectId;
  final String? projectExternalId;
  final String? photoPath;

  StudyAreaRevision(
      {required this.id,
      this.parentId,
      required this.timestamp,
      required this.author,
      this.action = 'edit',
      this.before,
      required this.after,
      this.visitId,
      this.sessionId,
      this.formId,
      this.projectId,
      this.projectExternalId,
      this.photoPath});

  Map<String, dynamic> toJson() => {
        'id': id,
        'parent_id': parentId,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'author': author,
        'action': action,
        'before': before,
        'after': after,
        'visit_id': visitId,
        'session_id': sessionId,
        'form_id': formId,
        'project_id': projectId,
        'project_external_id': projectExternalId,
        'photo_path': photoPath
      };

  factory StudyAreaRevision.fromJson(Map<String, dynamic> json) =>
      StudyAreaRevision(
          id: json['id'] as String,
          parentId: json['parent_id'] as String?,
          timestamp: DateTime.parse(json['timestamp'] as String),
          author: json['author']?.toString() ?? 'Unknown',
          action: json['action']?.toString() ?? 'edit',
          before: json['before'] is Map
              ? Map<String, dynamic>.from(json['before'])
              : null,
          after: Map<String, dynamic>.from(json['after'] as Map),
          visitId: json['visit_id'] as String?,
          sessionId: (json['session_id'] as num?)?.toInt(),
          formId: (json['form_id'] as num?)?.toInt(),
          projectId: (json['project_id'] as num?)?.toInt(),
          projectExternalId: json['project_external_id'] as String?,
          photoPath: json['photo_path'] as String?);
}

/// Stable comparison ignores map key order while retaining field types.
String studyAreaCanonicalJson(dynamic value) {
  dynamic sorted(dynamic item) {
    if (item is Map) {
      final keys = item.keys.map((k) => k.toString()).toList()..sort();
      return {for (final key in keys) key: sorted(item[key])};
    }
    if (item is List) return item.map(sorted).toList();
    return item;
  }

  return jsonEncode(sorted(value));
}

class StudyAreaSite {
  final String id;
  // Deterministic UUID keeps legacy/imported IDs linked across devices and exports.
  String get featureUuid =>
      const Uuid().v5(Uuid.NAMESPACE_URL, 'mapbanai:feature:$id');
  double latitude;
  double longitude;
  Map<String, String> attributes;
  StudyAreaStatus status;
  Map<String, dynamic>? geometry;
  Map<String, dynamic>? sourceProperties;
  Map<String, dynamic>? original;
  DateTime? updatedAt;
  String changeNote;
  int revision;
  String? revisionId;
  List<StudyAreaRevision> history;
  int? projectId;
  String? projectExternalId;
  String layerId;
  Map<String, dynamic> formAnswers;
  Map<String, dynamic>? formSnapshot;

  StudyAreaSite({
    required this.id,
    required this.latitude,
    required this.longitude,
    Map<String, String>? attributes,
    this.status = StudyAreaStatus.pending,
    this.geometry,
    this.sourceProperties,
    this.original,
    this.updatedAt,
    this.changeNote = '',
    this.revision = 0,
    this.revisionId,
    List<StudyAreaRevision>? history,
    this.projectId,
    this.projectExternalId,
    this.layerId = 'default',
    Map<String, dynamic>? formAnswers,
    this.formSnapshot,
  })  : attributes = attributes ?? {},
        formAnswers = formAnswers ?? {},
        history = history ?? [] {
    revisionId ??= revisionToken;
  }

  Map<String, dynamic> stateSnapshot() => {
        'id': id,
        'project_id': projectId,
        'project_external_id': projectExternalId,
        'layer_id': layerId,
        'feature_uuid': featureUuid,
        'form_answers': formAnswers,
        'form_snapshot': formSnapshot,
        'latitude': latitude,
        'longitude': longitude,
        'geometry': currentGeometry,
        'attributes': attributes,
        'source_properties': sourceProperties,
        'status': status.name,
        'change_note': changeNote
      };

  String get revisionToken =>
      revisionId ??
      sha256
          .convert(utf8.encode(studyAreaCanonicalJson(comparisonSnapshot())))
          .toString();

  /// Local database IDs differ between phones; they never define lineage.
  Map<String, dynamic> comparisonSnapshot() =>
      stateSnapshot()..remove('project_id');
  bool get hasChanges => history.isNotEmpty
      ? history.any((r) => r.action != 'import')
      : original != null ||
          updatedAt != null ||
          status == StudyAreaStatus.newFeature;

  Map<String, dynamic> get currentGeometry =>
      geometry ??
      {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      };

  /// Keeps the first imported baseline when revisiting a feature repeatedly.
  StudyAreaSite revised(
      {required double latitude,
      required double longitude,
      required Map<String, String> attributes,
      required StudyAreaStatus status,
      String changeNote = ''}) {
    final moved = this.latitude != latitude || this.longitude != longitude;
    if (moved && currentGeometry['type'] != 'Point') {
      throw const FormatException(
          'Use Redraw geometry to change line/polygon vertices.');
    }
    final changed =
        moved || jsonEncode(this.attributes) != jsonEncode(attributes);
    return StudyAreaSite(
        id: id,
        latitude: latitude,
        longitude: longitude,
        attributes: attributes,
        status: changed && status == StudyAreaStatus.verified
            ? StudyAreaStatus.updated
            : status,
        geometry: moved
            ? {
                'type': 'Point',
                'coordinates': [longitude, latitude]
              }
            : currentGeometry,
        sourceProperties: sourceProperties,
        revision: revision,
        revisionId: revisionToken,
        history: List.from(history),
        projectId: projectId,
        projectExternalId: projectExternalId,
        layerId: layerId,
        formAnswers: Map.from(formAnswers),
        formSnapshot: formSnapshot,
        original: original ??
            {
              'geometry': currentGeometry,
              'source_properties': sourceProperties,
              'attributes': Map<String, String>.from(this.attributes),
              'status': this.status.name
            },
        updatedAt: DateTime.now().toUtc(),
        changeNote: changeNote);
  }

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
        'geometry': currentGeometry,
        'source_properties': sourceProperties,
        'original': original,
        'updated_at': updatedAt?.toIso8601String(),
        'change_note': changeNote,
        'revision': revision,
        'revision_id': revisionToken,
        'history': history.map((r) => r.toJson()).toList(),
        'project_id': projectId,
        'project_external_id': projectExternalId,
        'layer_id': layerId,
        'feature_uuid': featureUuid,
        'form_answers': formAnswers,
        'form_snapshot': formSnapshot,
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
      // Preserve the original outcome in storage so older visit and revision
      // records remain lossless. The UI normalizes legacy outcomes for display.
      status: StudyAreaStatusX.fromString(json['status']?.toString()),
      sourceProperties: json['source_properties'] is Map
          ? Map<String, dynamic>.from(json['source_properties'])
          : null,
      geometry: json['geometry'] is Map
          ? Map<String, dynamic>.from(json['geometry'])
          : null,
      original: json['original'] is Map
          ? Map<String, dynamic>.from(json['original'])
          : null,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      changeNote: json['change_note']?.toString() ?? '',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      revisionId: json['revision_id']?.toString(),
      history: (json['history'] as List? ?? [])
          .map((r) =>
              StudyAreaRevision.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
      projectId: (json['project_id'] as num?)?.toInt(),
      projectExternalId: json['project_external_id'] as String?,
      layerId: json['layer_id']?.toString() ?? 'default',
      formAnswers:
          Map<String, dynamic>.from(json['form_answers'] as Map? ?? {}),
      formSnapshot: json['form_snapshot'] is Map
          ? Map<String, dynamic>.from(json['form_snapshot'])
          : null,
    );
  }

  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'id': id,
      'geometry': currentGeometry,
      'properties': {
        for (final entry in attributes.entries)
          entry.key: sourceProperties?.containsKey(entry.key) == true &&
                  (sourceProperties![entry.key]?.toString() ?? '') ==
                      entry.value
              ? sourceProperties![entry.key]
              : entry.value,
        'id': id,
        'feature_uuid': featureUuid,
        'status': status.name,
        'latitude': latitude,
        'longitude': longitude,
        'mapbanai_revision': {
          'original': original,
          'updated_at': updatedAt?.toIso8601String(),
          'change_note': changeNote,
          'revision': revision,
          'revision_id': revisionToken,
          'history': history.map((r) => r.toJson()).toList(),
          'project_id': projectId,
          'project_external_id': projectExternalId,
          'layer_id': layerId,
          'feature_uuid': featureUuid,
          'form_answers': formAnswers,
          'form_snapshot': formSnapshot,
          'attributes': attributes,
          'source_properties': sourceProperties,
        },
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
    'ycoord',
    'lat_deg',
    'latdd',
    'lat_dd',
    'latitude_deg',
    'latitude_dd',
    'lat_decimal',
    'decimal_latitude',
    'dd_lat',
    'point_y',
    'northing_lat',
  ];
  static const List<String> _lonAliases = [
    'longitude',
    'lon',
    'lng',
    'long',
    'x',
    'x_coord',
    'xcoord',
    'lon_deg',
    'londd',
    'lon_dd',
    'longitude_deg',
    'longitude_dd',
    'long_deg',
    'lng_deg',
    'decimal_longitude',
    'dd_lon',
    'dd_long',
    'point_x',
    'easting_lon',
  ];

  /// Column names that typically hold WKT geometry strings.
  static const List<String> _wktAliases = [
    'wkt',
    'wkt_geometry',
    'geometry_wkt',
    'geometry',
    'geom',
    'the_geom',
    'shape',
    'shape_wkt',
    'point',
    'wkt_point',
  ];
  static final RegExp _wktPointRegex = RegExp(
    r'POINT\s*Z?M?\s*\(\s*([-+]?\d+(?:\.\d+)?)\s+([-+]?\d+(?:\.\d+)?)',
    caseSensitive: false,
  );

  /// Extracts `[lon, lat]` from common WKT point forms:
  /// `POINT (90.41 23.81)`, `POINT Z (90.41 23.81 12)`, `POINT ZM (...)`.
  /// Returns null when [input] is not a WKT point.
  static List<double>? parseWktPoint(String input) {
    final m = _wktPointRegex.firstMatch(input.trim());
    if (m == null) return null;
    final lon = double.tryParse(m.group(1)!);
    final lat = double.tryParse(m.group(2)!);
    if (lon == null || lat == null) return null;
    return [lon, lat];
  }

  /// True when [name] is one of the known WKT/geometry column names
  /// (case-insensitive).
  static bool isWktColumn(String name) =>
      _wktAliases.contains(name.trim().toLowerCase());

  /// Shared per-row site builder used by CSV/XLSX parsers so both accept
  /// plain lat/lon columns, synonym column names, or a WKT geometry column.
  static StudyAreaSite? _siteFromRow({
    required List<String> headers,
    required int latCol,
    required int lonCol,
    required int statusCol,
    required int wktCol,
    required String Function(int col) cell,
    required String idPrefix,
    required int rowNumber,
  }) {
    String latStr = latCol >= 0 ? cell(latCol).trim() : '';
    String lonStr = lonCol >= 0 ? cell(lonCol).trim() : '';
    double? lat = double.tryParse(latStr);
    double? lon = double.tryParse(lonStr);

    // Fallback 1: lat/lon cells may themselves hold a WKT string.
    if ((lat == null || lon == null)) {
      final fromCell = parseWktPoint('$latStr $lonStr');
      if (fromCell != null) {
        lon = fromCell[0];
        lat = fromCell[1];
      }
    }
    // Fallback 2: dedicated WKT/geometry column.
    if (lat == null || lon == null) {
      if (wktCol >= 0) {
        final fromWkt = parseWktPoint(cell(wktCol));
        if (fromWkt != null) {
          lon = fromWkt[0];
          lat = fromWkt[1];
        }
      }
    }
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      return null;
    }

    final attrs = <String, String>{};
    for (int c = 0; c < headers.length; c++) {
      if (c == latCol || c == lonCol || c == wktCol) continue;
      final key = headers[c].trim();
      if (key.isEmpty) continue;
      attrs[key] = cell(c).trim();
    }

    String rawStatus =
        statusCol >= 0 ? cell(statusCol).trim() : (attrs['status'] ?? '');
    if (rawStatus.isEmpty) {
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
        '$idPrefix$rowNumber';
    final id = idVal.trim().isEmpty
        ? '${idPrefix}${rowNumber}_${lat}_$lon'
        : idVal.trim();
    Map<String, dynamic>? decodedMap(String key) {
      final raw = attrs[key];
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    }

    return StudyAreaSite(
      id: id,
      latitude: lat,
      longitude: lon,
      attributes: attrs,
      status: status,
      geometry: decodedMap('geometry_json'),
      original: decodedMap('original_json'),
      updatedAt: DateTime.tryParse(attrs['updated_at'] ?? ''),
      changeNote: attrs['change_note'] ?? '',
    );
  }

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
  static List<double>? _firstCoordinate(dynamic coordinates) {
    if (coordinates is! List || coordinates.isEmpty) return null;
    if (coordinates.length >= 2 &&
        coordinates[0] is num &&
        coordinates[1] is num) {
      return [
        (coordinates[0] as num).toDouble(),
        (coordinates[1] as num).toDouble()
      ];
    }
    for (final child in coordinates) {
      final found = _firstCoordinate(child);
      if (found != null) return found;
    }
    return null;
  }

  static List<double>? _geometryCoordinate(Map geometry) {
    final point = _firstCoordinate(geometry['coordinates']);
    if (point != null) return point;
    for (final child
        in geometry['geometries'] is List ? geometry['geometries'] : []) {
      if (child is Map) {
        final result = _geometryCoordinate(child);
        if (result != null) return result;
      }
    }
    return null;
  }

  static String toGeoJson(List<StudyAreaSite> sites,
          {bool changedOnly = false}) =>
      const JsonEncoder.withIndent('  ').convert({
        'type': 'FeatureCollection',
        'features': sites
            .where((s) => !changedOnly || s.hasChanges)
            .map((s) => s.toGeoJsonFeature())
            .toList(),
        'mapbanai_exchange': {
          'version': 1,
          'changed_only': changedOnly,
          'exported_at': DateTime.now().toUtc().toIso8601String()
        },
      });

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
    int wktCol = -1;

    for (int i = 0; i < lowerHeaders.length; i++) {
      final h = lowerHeaders[i];
      if (latCol == -1 && _latAliases.contains(h)) latCol = i;
      if (lonCol == -1 && _lonAliases.contains(h)) lonCol = i;
      if (statusCol == -1 && _statusAliases.contains(h)) statusCol = i;
      if (wktCol == -1 && _wktAliases.contains(h)) wktCol = i;
    }
    // Fallback: look for headers containing lat/lon substrings.
    if (latCol == -1) {
      for (int i = 0; i < lowerHeaders.length; i++) {
        if (i != wktCol && lowerHeaders[i].contains('lat')) {
          latCol = i;
          break;
        }
      }
    }
    if (lonCol == -1) {
      for (int i = 0; i < lowerHeaders.length; i++) {
        final h = lowerHeaders[i];
        if ((h.contains('lon') || h.contains('lng') || h == 'x') &&
            i != wktCol) {
          lonCol = i;
          break;
        }
      }
    }

    // A WKT geometry column alone is enough.
    if ((latCol == -1 || lonCol == -1) && wktCol == -1) {
      throw FormatException(
          'CSV must contain latitude and longitude columns (or a WKT '
          'geometry column). Found: ${headers.join(', ')}');
    }

    final sites = <StudyAreaSite>[];
    for (int r = headerIdx + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((c) => c.trim().isEmpty)) continue;
      // Pad row to headers length.
      while (row.length < headers.length) row.add('');
      String cell(int c) => c < row.length ? row[c] : '';
      final site = _siteFromRow(
        headers: headers,
        latCol: latCol,
        lonCol: lonCol,
        statusCol: statusCol,
        wktCol: wktCol,
        cell: cell,
        idPrefix: 'site_',
        rowNumber: r,
      );
      if (site != null) sites.add(site);
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
    var row = <String>[];
    final value = StringBuffer();
    var quoted = false;
    for (var i = 0; i < content.length; i++) {
      final ch = content[i];
      if (ch == '"') {
        if (quoted && i + 1 < content.length && content[i + 1] == '"') {
          value.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == ',' && !quoted) {
        row.add(value.toString());
        value.clear();
      } else if ((ch == '\n' || ch == '\r') && !quoted) {
        row.add(value.toString());
        value.clear();
        rows.add(row);
        row = [];
        if (ch == '\r' && i + 1 < content.length && content[i + 1] == '\n') i++;
      } else {
        value.write(ch);
      }
    }
    if (quoted) throw const FormatException('Unclosed quoted CSV field');
    if (value.isNotEmpty || row.isNotEmpty) {
      row.add(value.toString());
      rows.add(row);
    }
    return rows;
  }

  // ── GeoJSON ──────────────────────────────────────────────────────

  static List<StudyAreaSite> parseGeoJson(String content) {
    final decoded = jsonDecode(content);
    List<dynamic> features;
    if (decoded is Map<String, dynamic>) {
      if (decoded['type'] == 'FeatureCollection' &&
          decoded['features'] is List) {
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

      final props = f['properties'] is Map
          ? Map<String, dynamic>.from(f['properties'] as Map)
          : <String, dynamic>{};
      // Also consider top-level id.
      if (f['id'] != null && !props.containsKey('id')) {
        props['id'] = f['id'];
      }

      double? lon;
      double? lat;
      final geom = f['geometry'];
      if (geom is Map) {
        final first = _geometryCoordinate(geom);
        if (first != null) {
          lon = first[0];
          lat = first[1];
        }
      }
      // Fallback: a WKT point stored in a property (e.g. "wkt", "geom").
      if (lat == null || lon == null) {
        for (final v in props.values) {
          final fromWkt = parseWktPoint(v?.toString() ?? '');
          if (fromWkt != null) {
            lon = fromWkt[0];
            lat = fromWkt[1];
            break;
          }
        }
      }
      if (lat == null || lon == null) continue;
      if (!lat.isFinite ||
          !lon.isFinite ||
          lat < -90 ||
          lat > 90 ||
          lon < -180 ||
          lon > 180) continue;

      final attrs = <String, String>{};
      String rawStatus = '';
      for (final entry in props.entries) {
        final k = entry.key.toString();
        final v = entry.value?.toString() ?? '';
        if (k != 'mapbanai_revision') attrs[k] = v;
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
      final idVal = f['id']?.toString() ??
          props['id']?.toString() ??
          props['site_id']?.toString() ??
          props['name']?.toString() ??
          'geojson_${idx}';
      final id =
          idVal.trim().isEmpty ? 'geojson_${idx}_${lat}_${lon}' : idVal.trim();

      final metadata = props['mapbanai_revision'] is Map
          ? Map<String, dynamic>.from(props['mapbanai_revision'])
          : <String, dynamic>{};
      sites.add(StudyAreaSite(
        id: id,
        latitude: lat,
        longitude: lon,
        attributes: metadata['attributes'] is Map
            ? (metadata['attributes'] as Map)
                .map((k, v) => MapEntry(k.toString(), v.toString()))
            : attrs,
        status: status,
        sourceProperties: metadata.containsKey('source_properties')
            ? (metadata['source_properties'] is Map
                ? Map<String, dynamic>.from(metadata['source_properties'])
                : null)
            : props,
        geometry: geom is Map ? Map<String, dynamic>.from(geom) : null,
        original: metadata['original'] is Map
            ? Map<String, dynamic>.from(metadata['original'])
            : null,
        updatedAt: DateTime.tryParse(metadata['updated_at']?.toString() ?? ''),
        changeNote: metadata['change_note']?.toString() ?? '',
        revision: (metadata['revision'] as num?)?.toInt() ?? 0,
        revisionId: metadata['revision_id']?.toString(),
        history: (metadata['history'] as List? ?? [])
            .map((r) =>
                StudyAreaRevision.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        projectId: (metadata['project_id'] as num?)?.toInt(),
        projectExternalId: metadata['project_external_id'] as String?,
        layerId: metadata['layer_id']?.toString() ?? 'default',
        formAnswers:
            Map<String, dynamic>.from(metadata['form_answers'] as Map? ?? {}),
        formSnapshot: metadata['form_snapshot'] is Map
            ? Map<String, dynamic>.from(metadata['form_snapshot'])
            : null,
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
      // Attributes first (needed for both display and the WKT fallback).
      final name = pm.findElements('name').firstOrNull?.innerText.trim() ?? '';
      final desc =
          pm.findElements('description').firstOrNull?.innerText.trim() ?? '';
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

      List<List<double>> coordinates(XmlElement element) {
        final text =
            element.findAllElements('coordinates').firstOrNull?.innerText ?? '';
        return text
            .trim()
            .split(RegExp(r'\s+'))
            .where((v) => v.isNotEmpty)
            .map((v) => v.split(',').map(double.parse).toList())
            .toList();
      }

      Map<String, dynamic>? readGeometry(XmlElement element) {
        final type = element.name.local;
        if (type == 'Point') {
          final points = coordinates(element);
          return points.isEmpty
              ? null
              : {'type': 'Point', 'coordinates': points.first};
        }
        if (type == 'LineString')
          return {'type': 'LineString', 'coordinates': coordinates(element)};
        if (type == 'Polygon')
          return {
            'type': 'Polygon',
            'coordinates':
                element.findAllElements('LinearRing').map(coordinates).toList()
          };
        final geometries = element.childElements
            .map(readGeometry)
            .whereType<Map<String, dynamic>>()
            .toList();
        if (geometries.isEmpty) return null;
        if (geometries.length == 1) return geometries.first;
        final types = geometries.map((g) => g['type']).toSet();
        if (types.length == 1 &&
            const ['Point', 'LineString', 'Polygon'].contains(types.first)) {
          return {
            'type': 'Multi${types.first}',
            'coordinates': geometries.map((g) => g['coordinates']).toList()
          };
        }
        return {'type': 'GeometryCollection', 'geometries': geometries};
      }

      final geometry = readGeometry(pm);
      final reference = geometry == null ? null : _geometryCoordinate(geometry);
      double? lon = reference?[0];
      double? lat = reference?[1];
      // ...or from a WKT string inside the attributes (some tools embed
      // "POINT (lon lat)" in ExtendedData instead of real geometry).
      if (lat == null || lon == null) {
        for (final entry in attrs.entries) {
          final fromWkt = parseWktPoint(entry.value);
          if (fromWkt != null) {
            lon = fromWkt[0];
            lat = fromWkt[1];
            break;
          }
        }
      }
      if (lat == null ||
          lon == null ||
          !lat.isFinite ||
          !lon.isFinite ||
          lat < -90 ||
          lat > 90 ||
          lon < -180 ||
          lon > 180) {
        continue;
      }

      String rawStatus = '';
      for (final entry in attrs.entries) {
        if (_statusAliases.contains(entry.key.toLowerCase())) {
          rawStatus = entry.value;
          break;
        }
      }
      final status = StudyAreaStatusX.fromString(rawStatus);
      final idVal =
          pm.getAttribute('id') ?? attrs['id'] ?? attrs['site_id'] ?? name;
      final id =
          idVal.trim().isEmpty ? 'kml_${idx}_${lat}_${lon}' : idVal.trim();

      sites.add(StudyAreaSite(
        id: id,
        latitude: lat,
        longitude: lon,
        attributes: attrs,
        status: status,
        geometry: geometry,
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

  // ── Shapefile (.shp geometry only) ──────────────────────────────

  /// Imports shape geometries and adjacent DBF attributes. Geographic WGS84
  /// coordinates are required; a supplied projected PRJ is rejected.
  static List<StudyAreaSite> parseShapefile(File file) {
    if (!file.existsSync()) {
      throw FileSystemException('Shapefile file not found', file.path);
    }
    final base = file.path.substring(0, file.path.lastIndexOf('.'));
    final projection = File('$base.prj');
    if (projection.existsSync()) {
      final prj = projection.readAsStringSync().toUpperCase();
      if (prj.contains('PROJCS') ||
          prj.contains('PROJCRS') ||
          !(prj.contains('WGS_1984') ||
              prj.contains('WGS 84') ||
              prj.contains('WGS84'))) {
        throw const FormatException(
            'Reproject shapefile to WGS84 (EPSG:4326) before importing.');
      }
    }
    final sites = parseShapefileBytes(file.readAsBytesSync());
    final dbf = File('$base.dbf');
    if (dbf.existsSync()) {
      final bytes = dbf.readAsBytesSync();
      if (bytes.length < 32)
        throw const FormatException('Invalid shapefile attribute table');
      final bd = ByteData.sublistView(bytes);
      final count = bd.getUint32(4, Endian.little);
      final header = bd.getUint16(8, Endian.little);
      final recordLength = bd.getUint16(10, Endian.little);
      final cpg = File('$base.cpg');
      final encoding =
          cpg.existsSync() ? cpg.readAsStringSync().trim().toUpperCase() : '';
      String decode(List<int> bytes) =>
          encoding == 'UTF-8' || encoding == 'UTF8' || encoding == '65001'
              ? utf8.decode(bytes)
              : latin1.decode(bytes);
      final fields = <({String name, String type, int length})>[];
      for (var offset = 32;
          offset + 32 <= header && bytes[offset] != 13;
          offset += 32) {
        final name = latin1.decode(bytes
            .sublist(offset, offset + 11)
            .takeWhile((v) => v != 0)
            .toList());
        fields.add((
          name: name,
          type: String.fromCharCode(bytes[offset + 11]),
          length: bytes[offset + 16]
        ));
      }
      for (final site in sites) {
        final index = int.tryParse(site.id.replaceFirst('shp_', ''));
        if (index == null || index < 1 || index > count) continue;
        var offset = header + (index - 1) * recordLength + 1;
        if (offset + recordLength - 1 > bytes.length)
          throw const FormatException('Truncated shapefile attribute table');
        final attrs = <String, String>{};
        final raw = <String, dynamic>{};
        for (final field in fields) {
          final value =
              decode(bytes.sublist(offset, offset + field.length)).trim();
          offset += field.length;
          attrs[field.name] = value;
          raw[field.name] = field.type == 'N' || field.type == 'F'
              ? num.tryParse(value) ?? value
              : value;
        }
        site.attributes = attrs;
        site.sourceProperties = raw;
      }
    }
    return sites.map((site) {
      final importedId = site.attributes['id'] ??
          site.attributes['site_id'] ??
          site.attributes['fid'];
      if (importedId == null || importedId.trim().isEmpty) return site;
      return StudyAreaSite(
          id: importedId.trim(),
          latitude: site.latitude,
          longitude: site.longitude,
          geometry: site.geometry,
          attributes: site.attributes,
          sourceProperties: site.sourceProperties,
          status: StudyAreaStatusX.fromString(site.attributes['status']));
    }).toList();
  }

  static List<StudyAreaSite> parseShapefileBytes(Uint8List bytes) {
    if (bytes.length < 108) {
      throw FormatException('Invalid .shp file (too small)');
    }
    final bd = ByteData.sublistView(bytes);
    int beInt32(int o) =>
        (bytes[o] << 24) |
        (bytes[o + 1] << 16) |
        (bytes[o + 2] << 8) |
        bytes[o + 3];
    final sites = <StudyAreaSite>[];
    int off = 100; // skip the 100-byte file header
    int idx = 0;
    while (off + 8 <= bytes.length) {
      final recNum = beInt32(off);
      final contentLen = beInt32(off + 4) * 2; // words → bytes
      if (contentLen < 4 || off + 8 + contentLen > bytes.length) break;
      final recOff = off + 8;
      final shapeType = bd.getInt32(recOff, Endian.little);
      idx++;
      Map<String, dynamic>? geometry;
      double? lon;
      double? lat;
      switch (shapeType) {
        case 1: // Point
        case 11: // PointZ
        case 21: // PointM
          if (contentLen >= 20) {
            lon = bd.getFloat64(recOff + 4, Endian.little);
            lat = bd.getFloat64(recOff + 12, Endian.little);
          }
          break;
        case 8: // MultiPoint
        case 18: // MultiPointZ
        case 28: // MultiPointM
          final numPoints = bd.getInt32(recOff + 36, Endian.little);
          if (numPoints > 0 && contentLen >= 40 + numPoints * 16) {
            geometry = {
              'type': 'MultiPoint',
              'coordinates': List.generate(
                  numPoints,
                  (i) => [
                        bd.getFloat64(recOff + 40 + i * 16, Endian.little),
                        bd.getFloat64(recOff + 48 + i * 16, Endian.little)
                      ])
            };
            lon = bd.getFloat64(recOff + 40, Endian.little);
            lat = bd.getFloat64(recOff + 48, Endian.little);
          }
          break;
        case 3: // PolyLine
        case 13:
        case 23:
        case 5: // Polygon
        case 15:
        case 25:
          final numParts = bd.getInt32(recOff + 36, Endian.little);
          final numPoints = bd.getInt32(recOff + 40, Endian.little);
          final pointsStart = recOff + 44 + numParts * 4;
          if (numPoints > 0 &&
              numParts > 0 &&
              pointsStart + numPoints * 16 <= recOff + contentLen) {
            final starts = List.generate(numParts,
                (i) => bd.getInt32(recOff + 44 + i * 4, Endian.little));
            starts.add(numPoints);
            final parts = <List<List<double>>>[];
            for (var part = 0; part < numParts; part++) {
              if (starts[part] < 0 ||
                  starts[part + 1] > numPoints ||
                  starts[part] > starts[part + 1])
                throw const FormatException('Invalid shape parts');
              parts.add([
                for (var i = starts[part]; i < starts[part + 1]; i++)
                  [
                    bd.getFloat64(pointsStart + i * 16, Endian.little),
                    bd.getFloat64(pointsStart + i * 16 + 8, Endian.little)
                  ]
              ]);
            }
            if (shapeType == 5 || shapeType == 15 || shapeType == 25) {
              final polygons = <List<List<List<double>>>>[];
              for (final ring in parts) {
                var area = 0.0;
                for (var i = 0; i < ring.length - 1; i++) {
                  area +=
                      ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1];
                }
                if (area < 0 || polygons.isEmpty)
                  polygons.add([ring]);
                else
                  polygons.last.add(ring);
              }
              geometry = polygons.length == 1
                  ? {'type': 'Polygon', 'coordinates': polygons.first}
                  : {'type': 'MultiPolygon', 'coordinates': polygons};
            } else {
              geometry = parts.length == 1
                  ? {'type': 'LineString', 'coordinates': parts.first}
                  : {'type': 'MultiLineString', 'coordinates': parts};
            }
            lon = bd.getFloat64(pointsStart, Endian.little);
            lat = bd.getFloat64(pointsStart + 8, Endian.little);
          }
          break;
        default:
          break;
      }
      if (lon != null &&
          lat != null &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180) {
        sites.add(StudyAreaSite(
          id: 'shp_${recNum != 0 ? recNum : idx}',
          latitude: lat,
          longitude: lon,
          attributes: const {},
          geometry: geometry,
        ));
      }
      off += 8 + contentLen;
    }
    return sites;
  }

  // ── GeoPackage ───────────────────────────────────────────────────

  /// Imports WGS84 feature layers with standard WKB geometries and envelopes.
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

  static Future<List<StudyAreaSite>> parseGeoPackageBytes(
      Uint8List bytes) async {
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
      if (entry['srs_id'] != null && entry['srs_id'] != 4326) {
        throw FormatException(
            'GeoPackage $table uses CRS ${entry['srs_id']}. Reproject it to WGS84 (EPSG:4326) before importing.');
      }
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
      final candidates = [
        geomCol,
        'geometry',
        'geom',
        'the_geom',
        'wkb_geometry'
      ];
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
          final geometry = _parseGpkgGeometry(bytes);
          final point = geometry == null ? null : _geometryCoordinate(geometry);
          if (point == null) continue;
          final lat = point[1];
          final lon = point[0];
          if (!lat.isFinite ||
              !lon.isFinite ||
              lat < -90 ||
              lat > 90 ||
              lon < -180 ||
              lon > 180) continue;

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
          final id = idVal.trim().isEmpty
              ? '${table}_${idx}_${lat}_${lon}'
              : idVal.trim();
          sites.add(StudyAreaSite(
            id: id,
            latitude: lat,
            longitude: lon,
            attributes: attrs,
            status: status,
            geometry: geometry,
          ));
        }
      } catch (_) {
        continue;
      }
      if (sites.isNotEmpty) break; // Use first table that yields points.
    }
    return sites;
  }

  /// Parses standard WKB geometry after an optional GeoPackage envelope.
  static Map<String, dynamic>? _parseGpkgGeometry(Uint8List blob) {
    try {
      var offset = 0;
      if (blob.length >= 8 && blob[0] == 0x47 && blob[1] == 0x50) {
        final envelope = (blob[3] >> 1) & 7;
        if (envelope > 4) return null;
        offset = 8 + [0, 32, 48, 48, 64][envelope];
      }
      final bd = ByteData.sublistView(blob);
      Map<String, dynamic> readGeometry() {
        final endian = bd.getUint8(offset++) == 1 ? Endian.little : Endian.big;
        final raw = bd.getUint32(offset, endian);
        offset += 4;
        final type = (raw & 0x0fffffff) % 1000;
        final dimensions = 2 +
            ((raw & 0x80000000 != 0 ||
                    (raw & 0x0fffffff) ~/ 1000 == 1 ||
                    (raw & 0x0fffffff) ~/ 1000 == 3)
                ? 1
                : 0) +
            ((raw & 0x40000000 != 0 || (raw & 0x0fffffff) ~/ 1000 >= 2)
                ? 1
                : 0);
        if (raw & 0x20000000 != 0) offset += 4;
        int count() {
          final value = bd.getUint32(offset, endian);
          offset += 4;
          if (value > blob.length ~/ 8)
            throw const FormatException('Invalid WKB count');
          return value;
        }

        List<double> point() {
          final result = <double>[];
          for (var i = 0; i < dimensions; i++) {
            result.add(bd.getFloat64(offset, endian));
            offset += 8;
          }
          return result;
        }

        switch (type) {
          case 1:
            return {'type': 'Point', 'coordinates': point()};
          case 2:
            final n = count();
            return {
              'type': 'LineString',
              'coordinates': List.generate(n, (_) => point())
            };
          case 3:
            final n = count();
            return {
              'type': 'Polygon',
              'coordinates': List.generate(n, (_) {
                final vertices = count();
                return List.generate(vertices, (_) => point());
              })
            };
          case 4:
          case 5:
          case 6:
            final n = count();
            final children = List.generate(n, (_) => readGeometry());
            return {
              'type': {
                4: 'MultiPoint',
                5: 'MultiLineString',
                6: 'MultiPolygon'
              }[type],
              'coordinates': children.map((g) => g['coordinates']).toList()
            };
          case 7:
            final n = count();
            return {
              'type': 'GeometryCollection',
              'geometries': List.generate(n, (_) => readGeometry())
            };
          default:
            throw const FormatException('Unsupported WKB geometry');
        }
      }

      return readGeometry();
    } on RangeError {
      return null;
    } on FormatException {
      return null;
    }
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
      case 'shp':
        if (file != null) {
          return parseShapefile(file);
        }
        return parseShapefileBytes(bytes);
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
      int wktCol = -1;
      for (int i = 0; i < lowerHeaders.length; i++) {
        final h = lowerHeaders[i];
        if (latCol == -1 && _latAliases.contains(h)) latCol = i;
        if (lonCol == -1 && _lonAliases.contains(h)) lonCol = i;
        if (statusCol == -1 && _statusAliases.contains(h)) statusCol = i;
        if (wktCol == -1 && _wktAliases.contains(h)) wktCol = i;
      }
      if (latCol == -1) {
        for (int i = 0; i < lowerHeaders.length; i++) {
          if (i != wktCol && lowerHeaders[i].contains('lat')) {
            latCol = i;
            break;
          }
        }
      }
      if (lonCol == -1) {
        for (int i = 0; i < lowerHeaders.length; i++) {
          final h = lowerHeaders[i];
          if ((h.contains('lon') || h.contains('lng') || h == 'x') &&
              i != wktCol) {
            lonCol = i;
            break;
          }
        }
      }
      // A WKT geometry column alone is enough.
      if ((latCol == -1 || lonCol == -1) && wktCol == -1) {
        throw FormatException(
            'XLSX must contain latitude and longitude columns (or a WKT '
            'geometry column). Found: ${headers.join(', ')}');
      }
      final sites = <StudyAreaSite>[];
      for (int r = 1; r < table.rows.length; r++) {
        final row = table.rows[r];
        if (row.every((c) => c?.value == null)) continue;
        String cell(int idx) =>
            idx < row.length ? (row[idx]?.value?.toString().trim() ?? '') : '';
        final site = _siteFromRow(
          headers: headers,
          latCol: latCol,
          lonCol: lonCol,
          statusCol: statusCol,
          wktCol: wktCol,
          cell: cell,
          idPrefix: 'xlsx_',
          rowNumber: r,
        );
        if (site != null) sites.add(site);
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
    final headers = [
      'id',
      'latitude',
      'longitude',
      'status',
      'geometry_json',
      'updated_at',
      'change_note',
      'original_json',
      ...attrKeys
    ];
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
        } else if (low == 'geometry_json') {
          row.add(jsonEncode(s.currentGeometry));
        } else if (low == 'original_json') {
          row.add(s.original == null ? '' : jsonEncode(s.original));
        } else if (low == 'updated_at') {
          row.add(s.updatedAt?.toIso8601String() ?? '');
        } else if (low == 'change_note') {
          row.add(s.changeNote);
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
    final headers = [
      'id',
      'latitude',
      'longitude',
      'status',
      'geometry_json',
      'updated_at',
      'change_note',
      'original_json',
      ...attrKeys
    ];
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
          final val = switch (low) {
            'geometry_json' => jsonEncode(s.currentGeometry),
            'original_json' => s.original == null ? '' : jsonEncode(s.original),
            'updated_at' => s.updatedAt?.toIso8601String() ?? '',
            'change_note' => s.changeNote,
            _ => s.attributes[h] ?? '',
          };
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

  /// Portable map: Leaflet and feature data are embedded; basemap tiles need internet.
  static Future<String> toHtml(List<StudyAreaSite> sites) async {
    final css = await rootBundle.loadString('assets/leaflet/leaflet.css');
    final js = await rootBundle.loadString('assets/leaflet/leaflet.js');
    final data = toGeoJson(sites).replaceAll('<', r'\u003c');
    final colors = jsonEncode(
        {for (final s in StudyAreaStatus.values) s.name: s.colorHex});
    return '''<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>MapBanai Study Area</title><style>$css

html,body,#map{height:100%;margin:0}#legend{position:absolute;bottom:20px;left:10px;z-index:1000;background:white;padding:12px;font:14px sans-serif;max-width:80%}</style></head><body><div id="map"></div><div id="legend">Map tiles require internet. Feature data works offline.<br><label>Status <select id="status"><option value="">All features</option></select></label></div><script>$js</script><script>

const data=$data, colors=$colors;

const map=L.map('map').setView([23.81,90.41],12);

L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'© OpenStreetMap contributors'}).addTo(map);

const select=document.getElementById('status');

Object.keys(colors).forEach(s=>{const o=document.createElement('option');o.value=s;o.textContent=s;o.style.color=colors[s];select.appendChild(o)});

let layer;

function render(){if(layer)map.removeLayer(layer);layer=L.geoJSON(data,{filter:f=>!select.value||f.properties.status===select.value,style:f=>({color:colors[f.properties.status]||'#E53935',weight:3,fillOpacity:0.25}),pointToLayer:(f,ll)=>L.circleMarker(ll,{radius:7,color:colors[f.properties.status]||'#E53935'}),onEachFeature:(f,l)=>{const box=document.createElement('div');Object.entries(f.properties).forEach(([key,value])=>{const row=document.createElement('div');row.textContent=key+': '+(typeof value==='object'?JSON.stringify(value):value);box.appendChild(row)});l.bindPopup(box)}}).addTo(map);if(layer.getBounds().isValid())map.fitBounds(layer.getBounds(),{padding:[20,20]})}

select.onchange=render;render();

</script></body></html>''';
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
