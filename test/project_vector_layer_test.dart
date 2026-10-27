import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_template_service.dart';
import 'package:mapbanai/services/webmap_data_service.dart';

Uint8List pointShape([double x = 90.4, double y = 23.8]) {
  final bytes = Uint8List(128), d = ByteData.sublistView(bytes);
  d.setUint32(0, 9994);
  d.setUint32(24, 64);
  d.setUint32(28, 1000, Endian.little);
  d.setUint32(32, 1, Endian.little);
  d.setUint32(100, 1);
  d.setUint32(104, 10);
  d.setUint32(108, 1, Endian.little);
  d.setFloat64(112, x, Endian.little);
  d.setFloat64(120, y, Endian.little);
  return bytes;
}

Uint8List attributes() {
  final bytes = Uint8List(71), d = ByteData.sublistView(bytes);
  bytes[0] = 3;
  d.setUint32(4, 1, Endian.little);
  d.setUint16(8, 65, Endian.little);
  d.setUint16(10, 5, Endian.little);
  bytes.setRange(32, 36, ascii.encode('TYPE'));
  bytes[43] = 67;
  bytes[48] = 4;
  bytes[64] = 13;
  bytes[65] = 32;
  bytes.setRange(66, 70, ascii.encode('Well'));
  bytes[70] = 26;
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'multiple loose shapefiles and zipped sidecars retain attributes in worker',
      () async {
    final archive = Archive()
      ..addFile(ArchiveFile('../Water.shp', 128, pointShape()))
      ..addFile(ArchiveFile('../Water.dbf', 71, attributes()));
    final result = await ProjectVectorLayerService.parseFiles({
      'Streets.SHP': pointShape(),
      'Streets.DBF': attributes(),
      'Streets.PRJ': Uint8List.fromList(utf8.encode('GEOGCS["WGS 84"]')),
      'water.zip': Uint8List.fromList(ZipEncoder().encode(archive)!)
    });
    expect(result.length, 2);
    expect(result[0]['features'][0]['properties']['TYPE'], 'Well');
    expect(result[0]['warning'], '');
    expect(result[1]['warning'], contains('assumed WGS84'));
    expect(result[0]['features'][0]['geometry']['coordinates'], [90.4, 23.8]);
    expect(result[0]['id'], isNot(result[1]['id']));
  });
  test(
      'rejects truncated shapes and projected coordinates without partial import',
      () {
    for (final files in [
      {'bad.shp': Uint8List.sublistView(pointShape(), 0, 125)},
      {'bad.shp': pointShape(500000, 2600000)},
      {
        'bad.shp': pointShape(),
        'bad.prj': Uint8List.fromList(utf8.encode('PROJCS["UTM"]'))
      },
      {'good.shp': pointShape(), 'bad.shp': pointShape(500000, 2600000)},
    ]) {
      expect(() => ProjectVectorLayerService.parseFilesSync(files),
          throwsFormatException);
    }
  });
  test('GeoJSON multipart geometry validates every vertex', () {
    final Map<String, dynamic> valid = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'name': 'Canal'},
          'geometry': {
            'type': 'MultiLineString',
            'coordinates': [
              [
                [90.4, 23.8],
                [90.41, 23.81]
              ]
            ]
          }
        }
      ]
    };
    final parsed = ProjectVectorLayerService.parseFilesSync(
        {'canals.geojson': Uint8List.fromList(utf8.encode(jsonEncode(valid)))});
    expect(parsed.single['features'].length, 1);
    valid['features'][0]['geometry']['coordinates'][0][1][0] = 500000.0;
    expect(
        () => ProjectVectorLayerService.parseFilesSync({
              'bad.geojson': Uint8List.fromList(utf8.encode(jsonEncode(valid)))
            }),
        throwsFormatException);
  });
  test(
      'project layers persist, package round trip includes them, templates omit geometry',
      () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final a = await db.insertProject(const ProjectsCompanion(name: Value('A'))),
        b = await db.insertProject(const ProjectsCompanion(name: Value('B')));
    final service = ProjectVectorLayerService(db),
        layers = ProjectVectorLayerService.parseFilesSync(
            {'sites.shp': pointShape()});
    layers[0]['visible'] = false;
    layers[0]['color'] = '#123456';
    await service.save(a, layers);
    expect(await service.load(b), isEmpty);
    expect((await service.load(a)).single['visible'], false);
    final data =
        await WebMapDataService(db).buildFeatureCollectionForProject(a);
    expect(data['features'], isEmpty);
    expect(data['vector_layers'].length, 1);
    expect(data['project_name'], 'A');
    final package =
        await ProjectExporter(db).buildData((await db.getProjectById(a))!);
    final copy = await ProjectImporter(db).commitData(package, newCopy: true);
    expect((await service.load(copy.projectId)).single['color'], '#123456');
    final templates = ProjectTemplateService(db);
    await templates.save(a, 'Project style');
    expect(
        (await templates.list()).single['layers']['vector_overlays'], isNull);
    layers[0]['opacity'] = 2;
    await expectLater(service.save(a, layers), throwsFormatException);
    expect((await service.load(a)).single['opacity'], .8);
  });
}
