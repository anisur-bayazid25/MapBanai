import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

/// A single exported GIS feature (point / line / polygon) with attributes.
class GisExportFeature {
  final String type;
  final int sessionId;
  final String project;
  final String id;
  final String name;
  final String notes;
  final double? accuracyM;
  final double? lengthM;
  final double? areaM2;
  final String? recordedAt;
  final Map<String, dynamic> fields;

  /// Longitude/latitude pairs.
  final List<List<double>> coordinates;

  const GisExportFeature({
    required this.type,
    required this.sessionId,
    required this.project,
    required this.id,
    required this.name,
    required this.notes,
    required this.coordinates,
    this.accuracyM,
    this.lengthM,
    this.areaM2,
    this.recordedAt,
    this.fields = const {},
  });

  String get wkt {
    final parts = [
      for (final c in coordinates) '${c[0]} ${c[1]}',
    ].join(', ');
    return switch (type) {
      'point' => 'POINT ($parts)',
      'line' => 'LINESTRING ($parts)',
      'polygon' => 'POLYGON ((${_closedParts.join(', ')}))',
      _ => '',
    };
  }

  /// Coordinates with the ring closed (first point appended) for polygons.
  List<List<double>> get closedCoords {
    final result = [for (final c in coordinates) List<double>.from(c)];
    if (type == 'polygon' &&
        result.isNotEmpty &&
        (result.first[0] != result.last[0] || result.first[1] != result.last[1])) {
      result.add(List<double>.from(result.first));
    }
    return result;
  }

  List<String> get _closedParts {
    return [
      for (final c in closedCoords) '${c[0]} ${c[1]}',
    ];
  }
}

/// Builds CSV / KML / GeoJSON / GeoPackage exports of the captured GIS
/// features (points, lines and polygons stored in survey sessions).
class GisExportService {
  /// Extracts GIS features from survey sessions. [projectNames] maps project
  /// ids to names. Sessions without a `feature_type` are skipped.
  static List<GisExportFeature> extractFeatures(
    List<SurveySessionDatum> sessions,
    Map<int, String> projectNames,
  ) {
    final features = <GisExportFeature>[];
    for (final session in sessions) {
      Map<String, dynamic> responses;
      try {
        responses = jsonDecode(session.responses) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final feature = _featureFrom(
        session,
        responses,
        projectNames[session.projectId] ?? '',
      );
      if (feature != null) features.add(feature);
    }
    return features;
  }

  static GisExportFeature? _featureFrom(
    SurveySessionDatum session,
    Map<String, dynamic> responses,
    String projectName,
  ) {
    final type = responses['feature_type'];
    if (type != 'point' && type != 'line' && type != 'polygon') {
      return null;
    }
    final coordinates = <List<double>>[];
    if (type == 'point') {
      final lat = responses['latitude'];
      final lon = responses['longitude'];
      if (lat is! num || lon is! num) return null;
      coordinates.add([lon.toDouble(), lat.toDouble()]);
    } else {
      final rawVertices = responses['vertices'];
      if (rawVertices is! List) return null;
      for (final v in rawVertices) {
        if (v is Map && v['latitude'] is num && v['longitude'] is num) {
          coordinates.add([
            (v['longitude'] as num).toDouble(),
            (v['latitude'] as num).toDouble(),
          ]);
        }
      }
      if (coordinates.length < 2) return null;
      if (type == 'polygon' && coordinates.length < 3) return null;
    }

    return GisExportFeature(
      type: type,
      sessionId: session.id,
      project: projectName,
      id: responses['id']?.toString() ?? '',
      name: responses['name']?.toString() ?? '',
      notes: responses['notes']?.toString() ?? '',
      coordinates: coordinates,
      accuracyM: (responses['accuracy_m'] as num?)?.toDouble(),
      lengthM: (responses['length_m'] as num?)?.toDouble(),
      areaM2: (responses['area_m2'] as num?)?.toDouble(),
      recordedAt: responses['recorded_at']?.toString(),
      fields: (responses['fields'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  // ── GeoJSON ──────────────────────────────────────────────────

  static String toGeoJson(List<GisExportFeature> features) {
    final collection = {
      'type': 'FeatureCollection',
      'generated_at': DateTime.now().toIso8601String(),
      'features': [
        for (final feature in features) _geoJsonFeature(feature),
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(collection);
  }

  static Map<String, dynamic> _geoJsonFeature(GisExportFeature feature) {
    final coordinates = feature.type == 'polygon'
        ? [feature.closedCoords]
        : feature.coordinates;
    final geometryType = switch (feature.type) {
      'point' => 'Point',
      'line' => 'LineString',
      'polygon' => 'Polygon',
      _ => 'GeometryCollection',
    };
    return {
      'type': 'Feature',
      'geometry': {'type': geometryType, 'coordinates': coordinates},
      'properties': {
        'session_id': feature.sessionId,
        'project': feature.project,
        'id': feature.id,
        'name': feature.name,
        'notes': feature.notes,
        'feature_type': feature.type,
        if (feature.accuracyM != null) 'accuracy_m': feature.accuracyM,
        if (feature.lengthM != null) 'length_m': feature.lengthM,
        if (feature.areaM2 != null) 'area_m2': feature.areaM2,
        if (feature.recordedAt != null) 'recorded_at': feature.recordedAt,
        if (feature.fields.isNotEmpty) 'fields': feature.fields,
      },
    };
  }

  // ── CSV ──────────────────────────────────────────────────────

  static String toCsv(List<GisExportFeature> features) {
    final fieldKeys = <String>[];
    for (final feature in features) {
      for (final key in feature.fields.keys) {
        if (!fieldKeys.contains(key)) fieldKeys.add(key);
      }
    }
    final headers = <String>[
      'session_id',
      'project',
      'type',
      'id',
      'name',
      'notes',
      'geometry_wkt',
      'accuracy_m',
      'length_m',
      'area_m2',
      'recorded_at',
      ...fieldKeys,
    ];
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(headers.map(_escapeCsv).join(','));
    for (final feature in features) {
      final row = [
        feature.sessionId.toString(),
        feature.project,
        feature.type,
        feature.id,
        feature.name,
        feature.notes,
        feature.wkt,
        feature.accuracyM?.toString() ?? '',
        feature.lengthM?.toString() ?? '',
        feature.areaM2?.toString() ?? '',
        feature.recordedAt ?? '',
        for (final key in fieldKeys) feature.fields[key]?.toString() ?? '',
      ];
      buffer.writeln(row.map(_escapeCsv).join(','));
    }
    return buffer.toString();
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

  // ── KML ──────────────────────────────────────────────────────

  static String toKml(List<GisExportFeature> features) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<kml xmlns="http://www.opengis.net/kml/2.2" '
        'xmlns:gx="http://www.google.com/kml/ext/2.2">',
      )
      ..writeln('  <Document>')
      ..writeln('    <name>MapBanai GIS export</name>');
    for (final feature in features) {
      buffer.writeln('    <Placemark>');
      buffer.writeln(
        '      <name>${_escapeXml(feature.name.isEmpty ? '${feature.type} ${feature.id}' : feature.name)}</name>',
      );
      if (feature.notes.isNotEmpty) {
        buffer.writeln('      <description>${_escapeXml(feature.notes)}</description>');
      }
      final data = <String, String>{
        'session_id': feature.sessionId.toString(),
        'project': feature.project,
        'id': feature.id,
        if (feature.accuracyM != null)
          'accuracy_m': feature.accuracyM.toString(),
        if (feature.lengthM != null) 'length_m': feature.lengthM.toString(),
        if (feature.areaM2 != null)
          'area_m2': '${feature.areaM2}',
        if (feature.recordedAt != null) 'recorded_at': feature.recordedAt ?? '',
        for (final entry in feature.fields.entries)
          'field_${entry.key}': entry.value.toString(),
      };
      for (final entry in data.entries) {
        buffer.writeln(
          '      <ExtendedData><Data name="${_escapeXml(entry.key)}">'
          '<value>${_escapeXml(entry.value)}</value></Data></ExtendedData>',
        );
      }
      final coords = [
        for (final c in feature.coordinates)
          '${c[0]},${c[1]},0',
      ].join(' ');
      buffer.writeln('      <Geometry>');
      switch (feature.type) {
        case 'point':
          buffer.writeln('        <Point><coordinates>$coords</coordinates></Point>');
        case 'line':
          buffer.writeln(
            '        <LineString><coordinates>$coords</coordinates></LineString>',
          );
        case 'polygon':
          final ring = [
            for (final c in feature.closedCoords) '${c[0]},${c[1]},0',
          ].join(' ');
          buffer.writeln(
            '        <Polygon><outerBoundaryIs><LinearRing>'
            '<coordinates>$ring</coordinates></LinearRing>'
            '</outerBoundaryIs></Polygon>',
          );
      }
      buffer.writeln('      </Geometry>');
      buffer.writeln('    </Placemark>');
    }
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    return buffer.toString();
  }

  static String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  // ── GeoPackage ───────────────────────────────────────────────

  /// Writes a minimal but valid GeoPackage (SQLite) with the features in a
  /// `mapbanai_features` table (EPSG:4326 geometry blobs, WGS84).
  static Future<File> toGeoPackage(
    List<GisExportFeature> features,
    File outputFile,
  ) async {
    const wgs84 =
        'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,'
        '298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",'
        '0.0174532925199433]]';
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final feature in features) {
      for (final c in feature.coordinates) {
        if (c[0] < minX) minX = c[0];
        if (c[1] < minY) minY = c[1];
        if (c[0] > maxX) maxX = c[0];
        if (c[1] > maxY) maxY = c[1];
      }
    }
    final hasBounds = features.isNotEmpty;

    final db = sqlite3.open(outputFile.path);
    try {
      db.execute(
        'CREATE TABLE gpkg_spatial_ref_sys ('
        'srs_name TEXT NOT NULL, srs_id INTEGER PRIMARY KEY, '
        'organization TEXT NOT NULL, organization_coordsys_id INTEGER NOT NULL, '
        'definition TEXT NOT NULL, description TEXT)',
      );
      db.execute(
        'INSERT INTO gpkg_spatial_ref_sys '
        '(srs_name, srs_id, organization, organization_coordsys_id, definition) '
        'VALUES (?, ?, ?, ?, ?)',
        ['WGS 84 geodetic', 4326, 'EPSG', 4326, wgs84],
      );
      db.execute(
        'CREATE TABLE gpkg_contents ('
        'table_name TEXT NOT NULL PRIMARY KEY, '
        'data_type TEXT NOT NULL, identifier TEXT UNIQUE, '
        'description TEXT, last_change TEXT NOT NULL, '
        'min_x DOUBLE, min_y DOUBLE, max_x DOUBLE, max_y DOUBLE, '
        'srs_id INTEGER)',
      );
      db.execute(
        'INSERT INTO gpkg_contents '
        '(table_name, data_type, identifier, description, last_change, '
        'min_x, min_y, max_x, max_y, srs_id) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'mapbanai_features',
          'features',
          'mapbanai_features',
          'MapBanai GIS features',
          DateTime.now().toUtc().toIso8601String(),
          hasBounds ? minX : null,
          hasBounds ? minY : null,
          hasBounds ? maxX : null,
          hasBounds ? maxY : null,
          4326,
        ],
      );
      db.execute(
        'CREATE TABLE gpkg_geometry_columns ('
        'table_name TEXT NOT NULL, column_name TEXT NOT NULL, '
        'geometry_type_name TEXT NOT NULL, srs_id INTEGER NOT NULL, '
        'z TINYINT NOT NULL, m TINYINT NOT NULL, '
        'CONSTRAINT pk_geom_cols PRIMARY KEY (table_name, column_name))',
      );
      db.execute(
        'CREATE TABLE mapbanai_features ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'session_id INTEGER, project TEXT, type TEXT, feature_id TEXT, '
        'name TEXT, notes TEXT, recorded_at TEXT, accuracy_m REAL, '
        'length_m REAL, area_m2 REAL, fields TEXT, geometry BLOB)',
      );
      db.execute(
        'INSERT INTO gpkg_geometry_columns '
        '(table_name, column_name, geometry_type_name, srs_id, z, m) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['mapbanai_features', 'geometry', 'GEOMETRY', 4326, 0, 0],
      );

      final statement = db.prepare(
        'INSERT INTO mapbanai_features (session_id, project, type, '
        'feature_id, name, notes, recorded_at, accuracy_m, length_m, '
        'area_m2, fields, geometry) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '
        '?, ?)',
      );
      try {
        for (final feature in features) {
          final geometry = _geometryBlob(feature);
          statement.execute([
            feature.sessionId,
            feature.project,
            feature.type,
            feature.id,
            feature.name,
            feature.notes,
            feature.recordedAt,
            feature.accuracyM,
            feature.lengthM,
            feature.areaM2,
            feature.fields.isEmpty ? null : jsonEncode(feature.fields),
            geometry,
          ]);
        }
      } finally {
        statement.dispose();
      }
      return outputFile;
    } finally {
      db.dispose();
    }
  }

  /// Builds a GeoPackage geometry blob: GP header + little-endian WKB.
  static Uint8List _geometryBlob(GisExportFeature feature) {
    final wkb = _wkb(feature);
    final bytes = ByteData(8 + wkb.lengthInBytes);
    // Magic: 'GP' + version 0 + flags (little endian, no envelope).
    bytes.setUint8(0, 0x47);
    bytes.setUint8(1, 0x50);
    bytes.setUint8(2, 0x00);
    bytes.setUint8(3, 0x08);
    bytes.setUint32(4, 4326, Endian.little);
    final source = wkb.buffer.asUint8List(wkb.offsetInBytes, wkb.lengthInBytes);
    for (var i = 0; i < source.length; i++) {
      bytes.setUint8(8 + i, source[i]);
    }
    return bytes.buffer.asUint8List();
  }

  static ByteData _wkb(GisExportFeature feature) {
    final coords = feature.type == 'polygon'
        ? feature.closedCoords
        : feature.coordinates;
    final isPolygon = feature.type == 'polygon';
    final type = switch (feature.type) {
      'point' => 1,
      'line' => 2,
      _ => 3,
    };

    // WKB layout: 1 (byteOrder) + 4 (type) then, depending on type:
    // Point: 16 * n; LineString has a 4-byte point count; Polygon has a
    // 4-byte ring count + 4-byte point count.
    final extra = type == 1 ? 0 : (isPolygon ? 8 : 4);

    final data = ByteData(5 + extra + coords.length * 16);
    var offset = 0;
    data.setUint8(offset++, 0x01); // little endian
    data.setUint32(offset, type, Endian.little);
    offset += 4;
    if (isPolygon) {
      data.setUint32(offset, 1, Endian.little); // one ring
      offset += 4;
    }
    if (type != 1) {
      data.setUint32(offset, coords.length, Endian.little);
      offset += 4;
    }
    for (final c in coords) {
      data.setFloat64(offset, c[0], Endian.little);
      offset += 8;
      data.setFloat64(offset, c[1], Endian.little);
      offset += 8;
    }
    return data.buffer.asByteData();
  }
}

/// Structural interface so the service does not depend on drift rows
/// directly in its public API.
class SurveySessionDatum {
  final int id;
  final int projectId;
  final String responses;

  const SurveySessionDatum({
    required this.id,
    required this.projectId,
    required this.responses,
  });
}