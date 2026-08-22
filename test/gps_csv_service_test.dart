import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/gps_csv_service.dart';
import 'package:mapbanai/services/gps_log_store.dart';

void main() {
  test('parseCsvContent handles quoted notes and coordinates', () {
    const csv = '''
id,surveyor,timestamp,latitude,longitude,altitude_m,accuracy_m,notes
1,Alice,2026-08-17T12:00:00Z,23.8103000,90.4125000,35.70,4.20,"Culvert, under road"
2,Bob,2026-08-17T12:05:00Z,23.8200000,90.4200000,36.00,5.00,
''';
    final readings = GpsCsvService.parseCsvContent(csv);
    expect(readings.length, 2);
    expect(readings[0].notes, 'Culvert, under road');
    expect(readings[0].latitude, closeTo(23.8103, 1e-6));
  });

  test('toFeatureCollection creates LineString + points', () {
    const csv = '''
id,surveyor,timestamp,latitude,longitude,altitude_m,accuracy_m,notes
1,Alice,2026-08-17T12:00:00Z,23.81,90.41,10,5,first
2,Alice,2026-08-17T12:01:00Z,23.82,90.42,11,5,second
3,Alice,2026-08-17T12:02:00Z,23.83,90.43,12,5,third
''';
    final readings = GpsCsvService.parseCsvContent(csv);
    final fc = GpsCsvService.toFeatureCollection(readings, logName: 'TestLog');
    final features = fc['features'] as List;
    // 1 LineString + 3 Points
    expect(features.length, 4);
    expect((features.first as Map)['geometry']['type'], 'LineString');
  });

  test('generateWebMapHtml contains GeoJSON and Leaflet placeholder', () async {
    const csv = '''
id,surveyor,timestamp,latitude,longitude,altitude_m,accuracy_m,notes
1,Alice,2026-08-17T12:00:00Z,23.81,90.41,10,5,first
2,Alice,2026-08-17T12:01:00Z,23.82,90.42,11,5,second
''';
    final readings = GpsCsvService.parseCsvContent(csv);
    final html = await GpsCsvService.generateWebMapHtml(readings, logName: 'MyTrack');
    expect(html, contains('FeatureCollection'));
    expect(html, contains('gps_track'));
    expect(html, contains('MyTrack'));
  });

  test('stats calculates distance and duration', () {
    const csv = '''
id,surveyor,timestamp,latitude,longitude,altitude_m,accuracy_m,notes
1,Alice,2026-08-17T12:00:00Z,23.81,90.41,10,5,
2,Alice,2026-08-17T12:05:00Z,23.82,90.42,10,5,
''';
    final readings = GpsCsvService.parseCsvContent(csv);
    final s = GpsCsvService.stats(readings);
    expect(s['count'], 2);
    expect(s['distance_m'], greaterThan(1000));
    expect(s['duration_s'], 300);
  });

  test('parseFile reads from GpsLogStore file', () async {
    final temp = await Directory.systemTemp.createTemp('gps_csv_test');
    final store = GpsLogStore(baseDir: temp);
    await store.createLogFile(99);
    // Append via store's method requires Position, so write raw CSV
    final path = await store.filePath(99);
    await File(path).writeAsString(
        'id,surveyor,timestamp,latitude,longitude,altitude_m,accuracy_m,notes\n1,Test,2026-08-17T12:00:00Z,23.81,90.41,10,5,hello\n');
    final readings = await GpsCsvService.parseFile(path);
    expect(readings.length, 1);
    expect(readings.first.surveyor, 'Test');
    temp.deleteSync(recursive: true);
  });
}
