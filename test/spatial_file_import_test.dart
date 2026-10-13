import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/spatial_file_import.dart';
import 'package:mapbanai/services/study_area_store.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('spatial_test_');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  test('unknown/no extension is rejected without crashing', () {
    expect(SpatialFileImport.supports('shared-file'), false);
    expect(SpatialFileImport.supports('MAP.GEOJSON'), true);
    expect(SpatialFileImport.supports('map.gpkg'), true);
  });
  test('GeoJSON imports independent of Android MIME filtering', () async {
    final file = File('${directory.path}/map.geojson');
    await file.writeAsString(
        '{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[90.44,23.68]},"properties":{"name":"Facility"}}]}');
    final sites = await SpatialFileImport.read(file);
    expect(sites.single.latitude, 23.68);
    expect(sites.single.displayName, 'Facility');
  });
  test('zipped shapefile preserves companion attributes', () async {
    final shape = ByteData(128);
    shape.setInt32(100, 1, Endian.big);
    shape.setInt32(104, 10, Endian.big);
    shape.setInt32(108, 1, Endian.little);
    shape.setFloat64(112, 90.44, Endian.little);
    shape.setFloat64(120, 23.68, Endian.little);
    final dbf = Uint8List(86);
    final header = ByteData.sublistView(dbf);
    header.setUint32(4, 1, Endian.little);
    header.setUint16(8, 65, Endian.little);
    header.setUint16(10, 21, Endian.little);
    dbf.setRange(32, 36, 'name'.codeUnits);
    dbf[43] = 67;
    dbf[48] = 20;
    dbf[64] = 13;
    dbf[65] = 32;
    dbf.fillRange(66, 86, 32);
    dbf.setRange(66, 74, 'Facility'.codeUnits);
    final archive = Archive()
      ..addFile(
          ArchiveFile('nested/sites.shp', 128, shape.buffer.asUint8List()))
      ..addFile(ArchiveFile('nested/sites.dbf', 86, dbf));
    final file = File('${directory.path}/map.zip');
    await file.writeAsBytes(ZipEncoder().encode(archive)!);
    final sites = await SpatialFileImport.read(file);
    expect(sites.single.attributes['name'], 'Facility');
    expect(sites.single.longitude, 90.44);
  });
  test('GeoPackage with WGS84 point geometry imports', () async {
    final file = File('${directory.path}/sites.gpkg');
    final database = sqlite3.open(file.path);
    final wkb = ByteData(21)
      ..setUint8(0, 1)
      ..setUint32(1, 1, Endian.little)
      ..setFloat64(5, 90.44, Endian.little)
      ..setFloat64(13, 23.68, Endian.little);
    database.execute(
        "CREATE TABLE gpkg_contents (table_name TEXT, data_type TEXT, srs_id INTEGER)");
    database
        .execute("INSERT INTO gpkg_contents VALUES ('sites','features',4326)");
    database.execute(
        "CREATE TABLE gpkg_geometry_columns (table_name TEXT,column_name TEXT)");
    database.execute(
        "INSERT INTO gpkg_geometry_columns VALUES ('sites','geometry')");
    database.execute("CREATE TABLE sites (id TEXT,name TEXT,geometry BLOB)");
    database.execute("INSERT INTO sites VALUES ('site1','Facility',?)",
        [wkb.buffer.asUint8List()]);
    database.dispose();
    final sites = await SpatialFileImport.read(file);
    expect(sites.single.longitude, 90.44);
    expect(sites.single.attributes['name'], 'Facility');
  });

  test('ZIP rejects traversal and unsupported archives', () async {
    final archive = Archive()..addFile(ArchiveFile('../escape.shp', 1, [0]));
    final file = File('${directory.path}/bad.zip');
    await file.writeAsBytes(ZipEncoder().encode(archive)!);
    await expectLater(SpatialFileImport.read(file), throwsFormatException);
  });
  test('project and study-layer identity survives merge and disk reload',
      () async {
    final file = File('${directory.path}/map.csv');
    await file
        .writeAsString('id,latitude,longitude,name\na,23.68,90.44,Facility\n');
    final sites = await SpatialFileImport.read(file);
    sites.single.projectId = 7;
    sites.single.projectExternalId = 'project-uuid';
    sites.single.layerId = 'shyampur';
    final store = StudyAreaStore(baseDir: directory);
    await store.applyMerge(await store.previewMerge(sites), localProjectId: 7);
    final saved = (await store.loadSites()).single;
    expect(saved.projectId, 7);
    expect(saved.projectExternalId, 'project-uuid');
    expect(saved.layerId, 'shyampur');
    saved.projectId = null;
    await store.saveSites([saved]);
    final repeat = await store.previewMerge(sites);
    expect(repeat.additions, 0);
    await store.applyMerge(repeat, localProjectId: 7);
    expect((await store.loadSites()).single.projectId, 7);
  });
}
