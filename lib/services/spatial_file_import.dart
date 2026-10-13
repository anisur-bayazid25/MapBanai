import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:mapbanai/services/study_area_service.dart';

class SpatialFileImport {
  static const extensions = {
    'geojson',
    'json',
    'gpkg',
    'geopackage',
    'shp',
    'zip',
    'csv',
    'xlsx',
    'kml',
    'kmz'
  };
  static bool supports(String path) {
    final extension = p.extension(path).toLowerCase();
    return extension.isNotEmpty && extensions.contains(extension.substring(1));
  }

  static Future<List<StudyAreaSite>> read(File file) async {
    if (!supports(file.path))
      throw const FormatException(
          'Choose GeoJSON, GeoPackage, a zipped shapefile, SHP, CSV, Excel or KML/KMZ.');
    if (p.extension(file.path).toLowerCase() != '.zip') {
      if (p.extension(file.path).toLowerCase() == '.shp' &&
          !File(p.setExtension(file.path, '.dbf')).existsSync()) {
        throw const FormatException(
            'Shapefile attributes are missing. ZIP the SHP, DBF, PRJ and CPG files together and import that ZIP.');
      }
      return StudyAreaService.importFromFile(file);
    }
    if (await file.length() > 100 * 1024 * 1024)
      throw const FormatException('ZIP exceeds 100 MB.');
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final dir = await Directory.systemTemp.createTemp('mapbanai_spatial_');
    try {
      var total = 0;
      final extracted = <File>[];
      final paths = <String>{};
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final relative = entry.name.replaceAll('\\', '/');
        if (relative.startsWith('/') ||
            relative.split('/').contains('..') ||
            relative.contains(':'))
          throw const FormatException('Unsafe ZIP path.');
        final destination = p.normalize(p.join(dir.path, relative));
        if (!p.isWithin(dir.path, destination) ||
            !paths.add(destination.toLowerCase()))
          throw const FormatException('Unsafe or duplicate ZIP entry.');
        total += entry.size;
        if (total > 200 * 1024 * 1024)
          throw const FormatException('Unpacked ZIP exceeds 200 MB.');
        final output = File(destination);
        await output.parent.create(recursive: true);
        await output.writeAsBytes(entry.content as List<int>);
        extracted.add(output);
      }
      final shapes = extracted
          .where((f) => p.extension(f.path).toLowerCase() == '.shp')
          .toList();
      if (shapes.isEmpty)
        throw const FormatException(
            'ZIP must contain a shapefile with its DBF and PRJ companions.');
      final result = <StudyAreaSite>[];
      for (final shape in shapes) {
        final sites = await read(shape);
        if (shapes.length > 1) {
          for (final site in sites) {
            result.add(StudyAreaSite.fromJson({
              ...site.toJson(),
              'id': '${p.relative(shape.path, from: dir.path)}:${site.id}',
              'attributes': {
                ...site.attributes,
                'layer': site.attributes['layer'] ??
                    p.basenameWithoutExtension(shape.path)
              }
            }));
          }
        } else {
          result.addAll(sites);
        }
      }
      return result;
    } finally {
      await dir.delete(recursive: true);
    }
  }
}
