import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all verification statuses and legacy records survive persistence', () {
    expect(StudyAreaStatusX.fromString('yes'), StudyAreaStatus.completed);
    for (final status in StudyAreaStatus.values) {
      final site = StudyAreaSite.fromJson(
          {'id': 'a', 'latitude': 23, 'longitude': 90, 'status': status.name});
      expect(site.status, status);
      expect(StudyAreaSite.fromJson(site.toJson()).status, status);
    }
  });

  test('polygon revisions keep original baseline and typed properties', () {
    final geometry = {
      'type': 'Polygon',
      'coordinates': [
        [
          [90, 23],
          [91, 23],
          [91, 24],
          [90, 23]
        ]
      ]
    };
    final site = StudyAreaService.parseGeoJson(jsonEncode({
      'type': 'Feature',
      'id': 'stable',
      'properties': {
        'name': 'Old',
        'count': 12,
        'active': true,
        'extra': {'x': 1}
      },
      'geometry': geometry
    })).single;
    final edited = site.revised(
        latitude: 23,
        longitude: 90,
        attributes: {...site.attributes, 'name': 'New'},
        status: StudyAreaStatus.verified,
        changeNote: 'Confirmed on site');
    expect(edited.status, StudyAreaStatus.updated);
    final restored = StudyAreaService.parseGeoJson(StudyAreaService.toGeoJson(
        [StudyAreaSite.fromJson(edited.toJson())])).single;
    expect(restored.id, 'stable');
    expect(restored.currentGeometry, geometry);
    expect(restored.original!['attributes']['name'], 'Old');
    expect(restored.toGeoJsonFeature()['properties']['count'], 12);
    expect(restored.toGeoJsonFeature()['properties']['extra'], {'x': 1});
    expect(restored.updatedAt, isNotNull);
    expect(restored.changeNote, 'Confirmed on site');
    final editedAgain = restored.revised(
        latitude: 23,
        longitude: 90,
        attributes: {...restored.attributes, 'name': 'Newest'},
        status: StudyAreaStatus.updated);
    expect(editedAgain.original!['attributes']['name'], 'Old');
    expect(
        () => site.revised(
            latitude: 24,
            longitude: 90,
            attributes: site.attributes,
            status: StudyAreaStatus.updated),
        throwsFormatException);
  });

  test(
      'CSV and XLSX exports retain full geometry, multiline fields and baseline',
      () {
    final site =
        StudyAreaSite(id: '001', latitude: 23, longitude: 90, attributes: {
      'notes': 'line 1\nline 2, "quoted"'
    }, geometry: {
      'type': 'LineString',
      'coordinates': [
        [90, 23],
        [91, 24]
      ]
    }).revised(
            latitude: 23,
            longitude: 90,
            attributes: {'notes': 'changed\nline'},
            status: StudyAreaStatus.updated);
    for (final restored in [
      StudyAreaService.parseCsv(StudyAreaService.toCsv([site])).single,
      StudyAreaService.parseXlsxBytes(StudyAreaService.toExcelBytes([site]))
          .single
    ]) {
      expect(restored.id, '001');
      expect(restored.currentGeometry, site.currentGeometry);
      expect(restored.original, site.original);
      expect(restored.attributes['notes'], 'changed\nline');
    }
  });

  test('KML preserves lines and polygon holes', () {
    const kml =
        '<kml><Placemark><name>line</name><LineString><coordinates>90,23 91,24</coordinates></LineString></Placemark><Placemark><name>area</name><Polygon><outerBoundaryIs><LinearRing><coordinates>90,23 91,23 91,24 90,23</coordinates></LinearRing></outerBoundaryIs><innerBoundaryIs><LinearRing><coordinates>90.2,23.2 90.4,23.2 90.4,23.4 90.2,23.2</coordinates></LinearRing></innerBoundaryIs></Polygon></Placemark></kml>';
    final sites = StudyAreaService.parseKml(kml);
    expect(sites[0].currentGeometry['type'], 'LineString');
    expect(sites[0].currentGeometry['coordinates'], [
      [90, 23],
      [91, 24]
    ]);
    expect((sites[1].currentGeometry['coordinates'] as List).length, 2);
  });

  test(
      'serialized writes keep concurrent additions and reject duplicate imports',
      () async {
    final dir = await Directory.systemTemp.createTemp('study_revision_');
    addTearDown(() => dir.delete(recursive: true));
    final store = StudyAreaStore(baseDir: dir);
    await Future.wait([
      for (var i = 0; i < 20; i++)
        store.updateSite(StudyAreaSite(id: '$i', latitude: 23, longitude: 90))
    ]);
    expect((await store.loadSites()).length, 20);
    await expectLater(
        store.addSites([StudyAreaSite(id: '1', latitude: 24, longitude: 91)]),
        throwsFormatException);
    expect(
        (await store.loadSites()).firstWhere((s) => s.id == '1').latitude, 23);
    await store
        .updateSite(StudyAreaSite(id: '21', latitude: 23, longitude: 90));
    expect((await store.loadSites()).length, 21);
  });

  test('corrupt baseline is preserved and blocks saving', () async {
    final dir = await Directory.systemTemp.createTemp('study_corrupt_');
    addTearDown(() => dir.delete(recursive: true));
    final store = StudyAreaStore(baseDir: dir);
    final file = File(await store.filePath());
    await file.writeAsString('broken data');
    await expectLater(store.loadSites(), throwsFormatException);
    await expectLater(store.saveSites([]), throwsFormatException);
    expect(await file.readAsString(), 'broken data');
  });
}
