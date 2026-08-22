import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/webmap_generator.dart';

void main() {
  test('generated HTML contains feature count, valid GeoJSON and filter options', () async {
    final featureCollection = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [90.4, 23.8],
          },
          'properties': {
            'id': '1',
            'project_name': 'ProjA',
            'surveyor': 'Alice',
            'submitted_at': '2025-01-01T10:00:00.000Z',
            'form_name': 'FormA',
            'geometry_type': 'point',
            'answers': {'q1': 'yes'},
          },
        },
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              [90.0, 23.0],
              [90.1, 23.1],
            ],
          },
          'properties': {
            'id': '2',
            'project_name': 'ProjA',
            'surveyor': 'Bob',
            'submitted_at': '2025-01-02T10:00:00.000Z',
            'form_name': 'FormB',
            'geometry_type': 'line',
            'answers': {},
          },
        },
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [0, 0],
                [0, 1],
                [1, 1],
                [1, 0],
                [0, 0],
              ]
            ],
          },
          'properties': {
            'id': '3',
            'project_name': 'ProjA',
            'surveyor': 'Alice',
            'submitted_at': '2025-01-03T10:00:00.000Z',
            'form_name': 'FormA',
            'geometry_type': 'polygon',
            'answers': {},
          },
        },
      ],
    };

    final generator = WebMapGenerator();
    final html = await generator.generateHtml(
      featureCollection: featureCollection,
      leafletCss: '/* leaflet css */',
      leafletJs: '// leaflet js',
    );

    // Banner and inlined assets
    expect(html, contains('Map tiles require internet; your data works offline'));
    expect(html, contains('/* leaflet css */'));
    expect(html, contains('// leaflet js'));

    // Embedded GeoJSON is valid JSON and has correct feature count
    final geoJsonMatch = RegExp(r'const geojsonData = (\{.*?\});', dotAll: true).firstMatch(html);
    expect(geoJsonMatch, isNotNull);
    final embedded = jsonDecode(geoJsonMatch!.group(1)!) as Map<String, dynamic>;
    expect(embedded['type'], 'FeatureCollection');
    expect((embedded['features'] as List), hasLength(3));
    // Also check that the HTML contains the count somewhere (legend or filter)
    expect(html, contains('3'));

    // Filter UI present and will be populated from GeoJSON (form_name/surveyor values)
    // The new HTML uses a dynamic multi-select for filterQuestion values, not hard-coded options
    // Check that the GeoJSON itself contains the distinct values and the filter UI elements exist
    expect(html, contains('id="filterQuestion"'));
    expect(html, contains('id="multiselectList"'));
    expect(html, contains('FormA'));
    expect(html, contains('FormB'));
    expect(html, contains('Alice'));
    expect(html, contains('Bob'));

    // Legend present (now with counts and symbology)
    expect(html, contains('Points:'));
    expect(html, contains('Lines:'));
    expect(html, contains('Polygons:'));

    // OSM tile layer present
    expect(html, contains('tile.openstreetmap.org'));
  });

  test('writeToFile creates timestamped html file', () async {
    final tempDir = await Directory.systemTemp.createTemp('webmap-gen-');
    try {
      final generator = WebMapGenerator();
      final html = await generator.generateHtml(
        featureCollection: {
          'type': 'FeatureCollection',
          'features': [],
        },
        leafletCss: 'css',
        leafletJs: 'js',
      );
      final file = await generator.writeToFile(html, directory: tempDir);
      expect(file.existsSync(), isTrue);
      expect(file.path, contains('webmap_'));
      expect(file.path, endsWith('.html'));
      final content = await file.readAsString();
      expect(content, contains('FeatureCollection'));
    } finally {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    }
  });
}
