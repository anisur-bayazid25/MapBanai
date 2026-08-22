import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/webmap_data_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.forTesting();
    tempDir = Directory.systemTemp.createTempSync('webmap-test-');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<String> createTempPhoto(String name) async {
    // Create a small valid JPEG for thumbnail generation
    final image = img.Image(width: 10, height: 10);
    img.fill(image, color: img.ColorRgb8(100, 150, 200));
    final bytes = Uint8List.fromList(img.encodeJpg(image));
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  test('builds FeatureCollection with correct count, geometry types and properties', () async {
    final projectId = await db.into(db.projects).insert(
          ProjectsCompanion.insert(name: 'WebMapTestProj'),
        );
    final project = await db.getProjectById(projectId);

    // GIS point with photo
    final photoPath = await createTempPhoto('point.jpg');
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Point Feature'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'feature_type': 'point',
        'latitude': 23.78,
        'longitude': 90.40,
        'user_name': 'Tester',
        'photo': {'path': photoPath},
      })),
    ));

    // GIS line
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Line Feature'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'feature_type': 'line',
        'user_name': 'Tester2',
        'vertices': [
          {'latitude': 23.0, 'longitude': 90.0},
          {'latitude': 23.1, 'longitude': 90.1},
        ],
      })),
    ));

    // GIS polygon
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Polygon Feature'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'feature_type': 'polygon',
        'user_name': 'Tester3',
        'vertices': [
          {'latitude': 0, 'longitude': 0},
          {'latitude': 0, 'longitude': 1},
          {'latitude': 1, 'longitude': 1},
        ],
      })),
    ));

    // Survey response with geopoint answer (location_point)
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Survey with geopoint'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'form_name': 'TestForm',
        'user_name': 'SurveyorA',
        'answers': {
          'site_name': 'Site 1',
          'location_point': '23.5 90.5 0 0', // ODK geopoint string
          'notes': 'hello',
        },
      })),
    ));

    // Survey response without location - should be excluded
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('No location'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'form_name': 'TestForm2',
        'answers': {'site_name': 'No loc'},
      })),
    ));

    // Draft should be excluded
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Draft feature'),
      status: const drift.Value('draft'),
      responses: drift.Value(jsonEncode({
        'feature_type': 'point',
        'latitude': 0,
        'longitude': 0,
      })),
    ));

    final service = WebMapDataService(db);
    // Project-wise: only this project's data
    final geojson = await service.buildFeatureCollectionForProject(projectId);
    // Also verify legacy all-projects still works (same count when only one project exists)
    final allGeojson = await service.buildFeatureCollection();
    expect((allGeojson['features'] as List), hasLength(4));

    expect(geojson['type'], 'FeatureCollection');
    final features = geojson['features'] as List;
    // Should have 4: point, line, polygon, survey geopoint
    expect(features, hasLength(4));

    // Check geometry types
    final geomTypes = features.map((f) => (f as Map)['geometry']['type'] as String).toSet();
    expect(geomTypes, containsAll(['Point', 'LineString', 'Polygon']));
    // Survey geopoint should be Point
    final pointFeatures = features.where((f) => (f as Map)['geometry']['type'] == 'Point').toList();
    expect(pointFeatures.length, greaterThanOrEqualTo(2)); // GIS point + survey point

    // Check properties for GIS point
    final gisPoint = features.firstWhere((f) => (f as Map)['properties']['geometry_type'] == 'point') as Map;
    final props = gisPoint['properties'] as Map;
    expect(props['surveyor'], 'Tester');
    expect(props['geometry_type'], 'point');
    expect(props['project_name'], project?.name ?? 'WebMapTestProj');
    expect(props.containsKey('thumbnail_base64'), isTrue, reason: 'photo thumbnail should be embedded');
    expect(props['photo_path'], 'point.jpg');
    // thumbnail should be base64 string, not full file
    final thumb = props['thumbnail_base64'] as String;
    expect(thumb.isNotEmpty, isTrue);
    expect(thumb.length < 100 * 1024 * 1.4, isTrue, reason: 'thumbnail base64 should be capped');

    // Check survey geopoint feature
    final surveyFeature = features.firstWhere((f) => (f as Map)['properties']['form_name'] == 'TestForm') as Map;
    final sProps = surveyFeature['properties'] as Map;
    expect(sProps['surveyor'], 'SurveyorA');
    expect(sProps['answers'], isA<Map>());
    expect((sProps['answers'] as Map)['site_name'], 'Site 1');
    expect(sProps['geometry_type'], 'geopoint');
    expect(surveyFeature['geometry']['type'], 'Point');
    expect(surveyFeature['geometry']['coordinates'], [90.5, 23.5]);

    // Ensure draft and no-location excluded
    // All features should have id (stable UUID)
    for (final f in features) {
      final p = (f as Map)['properties'] as Map;
      expect(p['id'], isNotNull);
      expect((p['id'] as String).isNotEmpty, isTrue);
    }
  });

  test('survey photo inside answers is included as thumbnail, not full file', () async {
    final projectId = await db.into(db.projects).insert(
          ProjectsCompanion.insert(name: 'PhotoSurveyProj'),
        );
    final photoPath = await createTempPhoto('survey_photo.jpg');

    // Survey response with PhotoQuestion answer stored as JSON string
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projectId),
      title: const drift.Value('Survey with photo'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'form_name': 'PhotoForm',
        'user_name': 'Photographer',
        'answers': {
          'site_name': 'Site X',
          'site_photo': jsonEncode({'path': photoPath, 'thumb': '${photoPath}_thumb'}),
          'location_point': '12.0 77.0 0 0',
        },
      })),
    ));

    final service = WebMapDataService(db);
    final geojson = await service.buildFeatureCollection();
    final features = geojson['features'] as List;
    expect(features, hasLength(1));
    final props = (features.first as Map)['properties'] as Map;
    expect(props['photo_path'], 'survey_photo.jpg');
    expect(props.containsKey('thumbnail_base64'), isTrue);
    // Should not contain full base64
    expect(props.containsKey('base64'), isFalse);
    final thumbB64 = props['thumbnail_base64'] as String;
    // Thumbnail should be decodable and not the full file (base64 of full file would be larger)
    final thumbBytes = base64Decode(thumbB64);
    final originalBytes = await File(photoPath).readAsBytes();
    final originalB64 = base64Encode(originalBytes);
    expect(thumbB64, isNot(equals(originalB64)), reason: 'should be thumbnail, not full file');
    expect(thumbBytes.isNotEmpty, isTrue);
  });

  test('project-wise generation isolates data per project', () async {
    final projA = await db.into(db.projects).insert(ProjectsCompanion.insert(name: 'ProjA'));
    final projB = await db.into(db.projects).insert(ProjectsCompanion.insert(name: 'ProjB'));

    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projA),
      title: const drift.Value('A point'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'feature_type': 'point',
        'latitude': 1,
        'longitude': 1,
      })),
    ));
    await db.insertSurveySession(SurveySessionsCompanion(
      projectId: drift.Value(projB),
      title: const drift.Value('B point'),
      status: const drift.Value('saved'),
      responses: drift.Value(jsonEncode({
        'feature_type': 'point',
        'latitude': 2,
        'longitude': 2,
      })),
    ));

    final svc = WebMapDataService(db);
    final geoA = await svc.buildFeatureCollectionForProject(projA);
    final geoB = await svc.buildFeatureCollectionForProject(projB);
    final geoAll = await svc.buildFeatureCollection();

    expect((geoA['features'] as List), hasLength(1));
    expect((geoB['features'] as List), hasLength(1));
    expect((geoAll['features'] as List), hasLength(2));
    expect(((geoA['features'] as List).first as Map)['properties']['project_name'], 'ProjA');
    expect(((geoB['features'] as List).first as Map)['properties']['project_name'], 'ProjB');
  });
}
