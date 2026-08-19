import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/gis_export_service.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mapbanai_gpkg_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  List<GisExportFeature> sampleFeatures() => const [
        GisExportFeature(
          type: 'point',
          sessionId: 1,
          project: 'Test Project',
          id: 'P1',
          name: 'Well head',
          notes: 'Old hand pump',
          coordinates: [
            [90.4125, 23.8103],
          ],
          accuracyM: 5.2,
          recordedAt: '2026-08-19T10:00:00Z',
        ),
        GisExportFeature(
          type: 'line',
          sessionId: 2,
          project: 'Test Project',
          id: 'L1',
          name: 'Boundary',
          notes: '',
          coordinates: [
            [90.4100, 23.8100],
            [90.4150, 23.8120],
            [90.4180, 23.8110],
          ],
          lengthM: 812.4,
          recordedAt: '2026-08-19T10:05:00Z',
        ),
      ];

  test('toGeoPackage writes a valid readable GeoPackage', () async {
    final file = File('${tempDir.path}/export.gpkg');
    await GisExportService.toGeoPackage(sampleFeatures(), file);

    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));

    final db = sqlite3.open(file.path);
    try {
      final integrity = db
          .select('PRAGMA integrity_check')
          .first
          .values
          .first
          .toString();
      expect(integrity, 'ok');

      final srs = db.select(
        'SELECT srs_name, srs_id, organization, definition '
        'FROM gpkg_spatial_ref_sys WHERE srs_id = 4326',
      );
      expect(srs.length, 1);
      expect(srs.first['srs_name'], 'WGS 84 geodetic');
      expect(srs.first['definition'], contains('GEOGCS'));

      final contents = db.select(
        'SELECT table_name, data_type, identifier, last_change, '
        'min_x, min_y, max_x, max_y, srs_id FROM gpkg_contents',
      );
      expect(contents.length, 1);
      final row = contents.first;
      expect(row['table_name'], 'mapbanai_features');
      expect(row['data_type'], 'features');
      expect(row['srs_id'], 4326);
      expect(row['last_change'], isNotEmpty);
      expect(row['min_x'], 90.41);
      expect(row['max_x'], 90.418);
      expect(row['min_y'], 23.81);
      expect(row['max_y'], 23.812);

      final geomCols = db.select('SELECT * FROM gpkg_geometry_columns');
      expect(geomCols.length, 1);
      expect(geomCols.first['column_name'], 'geometry');
      expect(geomCols.first['srs_id'], 4326);

      final features = db.select('SELECT * FROM mapbanai_features');
      expect(features.length, 2);

      for (final feature in features) {
        final blob = feature['geometry'] as Uint8List;
        expect(blob.length, greaterThan(8));
        expect(blob[0], 0x47); // 'G'
        expect(blob[1], 0x50); // 'P'
        expect(blob[2], 0x00); // version 0
        expect(blob[3], 0x08); // little endian, no envelope, non-empty
        final srsFromBlob = ByteData.sublistView(blob).getUint32(4, Endian.little);
        expect(srsFromBlob, 4326);
      }

      // WKB payload starts with little-endian marker byte.
      final pointBlob =
          features.first['geometry'] as Uint8List;
      expect(pointBlob[8], 0x01);
    } finally {
      db.dispose();
    }
  });

  test('toGeoPackage works with an empty feature list', () async {
    final file = File('${tempDir.path}/empty.gpkg');
    await GisExportService.toGeoPackage(const [], file);

    final db = sqlite3.open(file.path);
    try {
      final integrity = db
          .select('PRAGMA integrity_check')
          .first
          .values
          .first
          .toString();
      expect(integrity, 'ok');
      expect(db.select('SELECT COUNT(*) AS c FROM mapbanai_features').first['c'], 0);
      final contents = db.select('SELECT * FROM gpkg_contents');
      expect(contents.first['min_x'], isNull);
      expect(contents.first['last_change'], isNotEmpty);
    } finally {
      db.dispose();
    }
  });
}