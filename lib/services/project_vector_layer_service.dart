import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Reference geometry is project-owned and separate from survey observations.
class ProjectVectorLayerService {
  final AppDatabase db;
  ProjectVectorLayerService(this.db);
  static const maxBytes = 64 * 1024 * 1024;
  static const maxStoredBytes = 96 * 1024 * 1024;
  static const maxFeatures = 50000;
  static String studyLayerId(Map<String, dynamic> layer) =>
      (layer['study_layer_id'] ?? 'vector:${layer['id']}').toString();

  Future<void> linkExistingStudySites(
      Project project, StudyAreaStore store) async {
    final layers = await load(project.id);
    if (!layers.any((layer) =>
        layer['import_batch_id'] != null && layer['study_layer_id'] == null))
      return;
    final sites = await store.loadSites();
    var changed = false;
    for (final layer in layers) {
      if (layer['import_batch_id'] == null || layer['study_layer_id'] != null)
        continue;
      final matching = sites
          .where((site) =>
              (site.projectExternalId != null
                  ? site.projectExternalId == project.externalId
                  : site.projectId == project.id) &&
              site.importBatchId == layer['import_batch_id'])
          .firstOrNull;
      if (matching != null) {
        layer['study_layer_id'] = matching.layerId;
        final sourceSites = StudyAreaService.parseGeoJson(jsonEncode(
            {'type': 'FeatureCollection', 'features': layer['features']}));
        final owned = sites
            .where((site) => site.importBatchId == layer['import_batch_id'])
            .toList();
        layer['study_site_ids'] = sourceSites
            .map((source) =>
                owned
                    .where((site) =>
                        site.id == source.id ||
                        site.id.endsWith(':${source.id}'))
                    .firstOrNull
                    ?.id ??
                source.id)
            .toList();
        layer['study_source_project_id'] = project.externalId;
        changed = true;
      }
    }
    if (changed) await save(project.id, layers);
  }

  /// File pickers may return only the SHP. Read matching siblings when the
  /// original directory is accessible; multiple selection also works with SAF.
  static Future<void> addShapefileCompanions(
      Map<String, Uint8List> files, Iterable<String> paths) async {
    final names = files.keys.map((name) => name.toLowerCase()).toSet();
    for (final path
        in paths.where((path) => p.extension(path).toLowerCase() == '.shp')) {
      final base = p.basenameWithoutExtension(path).toLowerCase();
      try {
        await for (final item in Directory(p.dirname(path)).list()) {
          if (item is! File ||
              p.basenameWithoutExtension(item.path).toLowerCase() != base ||
              !['.dbf', '.shx', '.prj', '.cpg']
                  .contains(p.extension(item.path).toLowerCase())) continue;
          final name = p.basename(item.path);
          if (names.add(name.toLowerCase())) {
            if (await item.length() > maxBytes)
              throw const FormatException('Companion file exceeds 64 MB.');
            files[name] = await item.readAsBytes();
          }
        }
      } on FileSystemException {
        // Android document providers can expose a cached SHP with no siblings.
        // The parser reports missing companions in the import review.
      }
    }
  }

  /// Baseline features are map data, not collected survey responses. Initialize
  /// each source once locally so clearing points never recreates them on reopen.
  Future<void> ensureStudySites(
      Project project, String layerId, StudyAreaStore store) async {
    final seedKey = 'project_study_seed_${project.id}';
    final seed = await db.getSetting(seedKey);
    if (seed != null) {
      final restored = (jsonDecode(seed) as List)
          .map((site) =>
              StudyAreaSite.fromJson(Map<String, dynamic>.from(site as Map)))
          .toList();
      await store.replaceProjectSites(
          project.id, project.externalId!, restored);
      await (db.delete(db.appSettings)..where((row) => row.key.equals(seedKey)))
          .go();
    }
    final layers = await load(project.id);
    final matches = layers
        .where((layer) =>
            layer['role'] != 'road' && studyLayerId(layer) == layerId)
        .toList();
    if (matches.isEmpty) return;
    final key = 'project_vector_initialized_${project.id}';
    final raw = await db.getSetting(key);
    final initialized = raw == null
        ? <String>{}
        : (jsonDecode(raw) as List).map((id) => id.toString()).toSet();
    if (matches.every((layer) => initialized.contains(layer['id']))) return;
    final existing = await store.loadSites();
    final ids = existing.map((site) => site.id).toSet();
    var metadataChanged = false;
    for (final layer in matches) {
      final sourceId = layer['id'].toString();
      if (initialized.contains(sourceId)) continue;
      final batchId = (layer['import_batch_id'] ?? sourceId).toString();
      if (!existing.any((site) =>
          site.projectExternalId == project.externalId &&
          site.importBatchId == batchId)) {
        final parsed = StudyAreaService.parseGeoJson(jsonEncode(
            {'type': 'FeatureCollection', 'features': layer['features']}));
        final added = <StudyAreaSite>[];
        final canonicalIds = layer['study_site_ids'] as List?;
        final restoredIds = <String>[];
        for (var index = 0; index < parsed.length; index++) {
          var featureId = canonicalIds != null && index < canonicalIds.length
              ? canonicalIds[index].toString()
              : '${project.externalId}:$sourceId:$index';
          if (canonicalIds != null &&
              layer['study_source_project_id'] != null &&
              layer['study_source_project_id'] != project.externalId) {
            featureId = '${project.externalId}:$featureId';
          }
          restoredIds.add(featureId);
          final site = StudyAreaSite.fromJson({
            ...parsed[index].toJson(),
            'id': featureId,
            'project_id': project.id,
            'project_external_id': project.externalId,
            'layer_id': layerId,
            'import_batch_id': batchId,
            'import_file_name': layer['import_file_name'] ?? layer['name']
          });
          if (ids.add(site.id)) added.add(site);
        }
        if (added.isNotEmpty) await store.addSites(added);
        layer['study_site_ids'] = restoredIds;
        layer['study_source_project_id'] = project.externalId;
        metadataChanged = true;
      }
      initialized.add(sourceId);
    }
    if (metadataChanged) await save(project.id, layers);
    await db.setSetting(key, jsonEncode(initialized.toList()));
  }

  Future<List<Map<String, dynamic>>> load(int projectId) async {
    final raw = await db.getSetting('webmap_vectors_$projectId');
    if (raw == null) return [];
    return raw.length > 256 * 1024
        ? Isolate.run(() => _decodeLayers(raw))
        : _decodeLayers(raw);
  }

  static List<Map<String, dynamic>> _decodeLayers(String raw) =>
      (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<void> save(int projectId, List<Map<String, dynamic>> layers) async {
    if (layers.fold<int>(0, (n, l) => n + (l['features'] as List).length) >
        maxFeatures) {
      throw const FormatException(
          'A project supports up to 50,000 reference features.');
    }
    var coordinates = 0;
    final ids = <String>{};
    for (final layer in layers) {
      if (layer['workflows'] != null &&
          (layer['workflows'] is! List ||
              (layer['workflows'] as List).isEmpty ||
              (layer['workflows'] as List).any((mode) =>
                  !['verification', 'recurring', 'visits'].contains(mode))))
        throw const FormatException('Invalid study workflow assignment.');
      if (layer['id'] is! String ||
          !ids.add(layer['id'] as String) ||
          layer['name'] is! String ||
          layer['features'] is! List ||
          layer['opacity'] is! num ||
          !(layer['opacity'] as num).isFinite ||
          (layer['opacity'] as num) < 0 ||
          (layer['opacity'] as num) > 1 ||
          layer['color'] is! String ||
          !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(layer['color'] as String)) {
        throw const FormatException('Invalid vector layer settings.');
      }
      for (final feature in layer['features'] as List) {
        if (feature is! Map ||
            feature['type'] != 'Feature' ||
            feature['geometry'] is! Map) {
          throw const FormatException('Invalid vector feature.');
        }
        coordinates += _validateGeometry(feature['geometry'] as Map);
        if (coordinates > 2000000) {
          throw const FormatException(
              'Simplify reference layers to at most 2 million coordinates per project.');
        }
      }
    }
    final raw = jsonEncode(layers);
    if (utf8.encode(raw).length > maxStoredBytes) {
      throw const FormatException('Project reference files exceed 96 MB.');
    }
    await db.setSetting('webmap_vectors_$projectId', raw);
  }

  static Future<List<Map<String, dynamic>>> parseFiles(
      Map<String, Uint8List> files) async {
    final geopackages = <Map<String, dynamic>>[];
    final other = <String, Uint8List>{};
    final geopackageInputs = <String, Uint8List>{};
    for (final entry in files.entries) {
      final ext = p.extension(entry.key).toLowerCase();
      if (ext == '.zip') {
        final archive = ZipDecoder().decodeBytes(entry.value, verify: false);
        for (final item in archive.where((f) =>
            f.isFile &&
            ['.gpkg', '.geopackage']
                .contains(p.extension(f.name).toLowerCase()))) {
          geopackageInputs['${entry.key}/${item.name}'] =
              Uint8List.fromList(item.content as List<int>);
        }
        other[entry.key] = entry.value;
      } else if (ext != '.gpkg' && ext != '.geopackage') {
        other[entry.key] = entry.value;
        continue;
      } else {
        geopackageInputs[entry.key] = entry.value;
      }
    }
    for (final entry in geopackageInputs.entries) {
      final sites = await StudyAreaService.parseGeoPackageBytes(entry.value);
      if (sites.isEmpty)
        throw FormatException(
            '${p.basename(entry.key)} contains no supported features.');
      geopackages.add({
        'id': const Uuid().v4(),
        'name': p.basenameWithoutExtension(entry.key),
        'visible': true,
        'color': '#467ca1',
        'opacity': 0.8,
        'role': 'reference',
        'features': sites
            .map((site) => <String, dynamic>{
                  'type': 'Feature',
                  'geometry': site.currentGeometry,
                  'properties': site.sourceProperties ?? site.attributes,
                })
            .toList(),
      });
    }
    final parsed = other.isEmpty
        ? <Map<String, dynamic>>[]
        : await Isolate.run(() => parseFilesSync(other));
    final result = [...parsed, ...geopackages];
    if (result.isNotEmpty) {
      result.first['source_files'] = [
        for (final file in files.entries)
          {
            'name': p.basename(file.key),
            'bytes_base64': base64Encode(file.value)
          }
      ];
    }
    return result;
  }

  static List<Map<String, dynamic>> parseFilesSync(
      Map<String, Uint8List> files) {
    final expanded = <String, Uint8List>{};
    var size = 0;
    void add(String name, Uint8List bytes) {
      size += bytes.length;
      if (size > maxBytes) {
        throw const FormatException('Select files totalling at most 64 MB.');
      }
      final key = name.replaceAll('\\', '/').toLowerCase();
      if (expanded.containsKey(key)) {
        throw FormatException(
            'Duplicate file: $name. Use separate ZIP bundles.');
      }
      expanded[key] = bytes;
    }

    for (final entry in files.entries) {
      if (entry.value.length > maxBytes) {
        throw const FormatException('File exceeds 64 MB.');
      }
      if (p.extension(entry.key).toLowerCase() == '.zip') {
        final archive = ZipDecoder().decodeBytes(entry.value, verify: false);
        if (archive.length > 1000) {
          throw const FormatException('ZIP contains too many files.');
        }
        for (final file in archive) {
          if (!file.isFile ||
              ![
                '.shp',
                '.dbf',
                '.shx',
                '.prj',
                '.cpg',
                '.geojson',
                '.json',
                '.csv',
                '.xlsx',
                '.gpkg',
                '.geopackage'
              ].contains(p.extension(file.name).toLowerCase())) continue;
          if (size + file.size > maxBytes) {
            throw const FormatException('Unpacked files exceed 64 MB.');
          }
          final bytes = Uint8List.fromList(file.content as List<int>);
          if (bytes.length != file.size || getCrc32(bytes) != file.crc32) {
            throw const FormatException('Corrupt ZIP layer.');
          }
          add('${entry.key}/${file.name}', bytes);
        }
      } else {
        add(entry.key, entry.value);
      }
    }
    final layers = <Map<String, dynamic>>[];
    final directory = Directory.systemTemp.createTempSync('mapbanai_vectors_');
    final safeRoot = p.normalize(p.absolute(directory.path));
    try {
      for (final entry in expanded.entries) {
        final ext = p.extension(entry.key);
        if (!['.shp', '.geojson', '.json', '.csv', '.xlsx'].contains(ext))
          continue;
        List<Map<String, dynamic>> features;
        if (ext == '.shp') {
          _validateShp(entry.value);
          final base = entry.key.substring(0, entry.key.length - 4);
          final localBase = p.join(directory.path, 'layer_${layers.length}');
          for (final sidecar in ['.shp', '.dbf', '.shx', '.prj', '.cpg']) {
            final data = expanded['$base$sidecar'];
            if (data != null) File('$localBase$sidecar').writeAsBytesSync(data);
          }
          features = StudyAreaService.parseShapefile(File('$localBase.shp'))
              .map((site) => <String, dynamic>{
                    'type': 'Feature',
                    'geometry': site.currentGeometry,
                    'properties': site.sourceProperties,
                  })
              .toList();
        } else if (ext == '.csv' || ext == '.xlsx') {
          final sites = ext == '.csv'
              ? StudyAreaService.parseCsvBytes(entry.value)
              : StudyAreaService.parseXlsxBytes(entry.value);
          features = sites
              .map((site) => <String, dynamic>{
                    'type': 'Feature',
                    'geometry': site.currentGeometry,
                    'properties': site.sourceProperties ?? site.attributes,
                  })
              .toList();
        } else {
          final data = jsonDecode(utf8.decode(entry.value)) as Map;
          if (data['type'] == 'Feature') {
            features = [Map<String, dynamic>.from(data)];
          } else if (data['type'] == 'FeatureCollection' &&
              data['features'] is List) {
            features = (data['features'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else {
            throw const FormatException(
                'GeoJSON must contain a Feature or FeatureCollection.');
          }
        }
        if (features.isEmpty) {
          throw FormatException(
              '${p.basename(entry.key)} contains no supported geometry.');
        }
        for (final feature in features) {
          if (feature['type'] != 'Feature' || feature['geometry'] is! Map) {
            throw const FormatException('Invalid GeoJSON feature.');
          }
          _validateGeometry(feature['geometry'] as Map);
        }
        layers.add({
          'id': const Uuid().v4(),
          'name': p.basenameWithoutExtension(entry.key),
          'visible': true,
          'color': [
            '#467ca1',
            '#498a70',
            '#aa896a',
            '#8b79ae'
          ][layers.length % 4],
          'opacity': 0.8,
          'role': 'reference',
          'features': features,
          'warning': [
            if (ext == '.shp' &&
                !expanded.containsKey(
                    '${entry.key.substring(0, entry.key.length - 4)}.prj'))
              'No .prj: coordinates assumed WGS84.',
            if (ext == '.shp' &&
                !expanded.containsKey(
                    '${entry.key.substring(0, entry.key.length - 4)}.dbf'))
              'No .dbf: geometry only. Select the matching DBF file too, choose its folder, or import a ZIP to include names and attributes.'
          ].join(' '),
        });
        if (layers.fold<int>(0, (n, l) => n + (l['features'] as List).length) >
            maxFeatures) {
          throw const FormatException(
              'Select up to 50,000 features at a time.');
        }
      }
      if (layers.isEmpty) {
        throw const FormatException(
            'Select .shp and its companion files, a shapefile ZIP, or GeoJSON.');
      }
      return layers;
    } finally {
      // Only remove the exact temporary directory created by this invocation.
      if (p.normalize(p.absolute(directory.path)) == safeRoot &&
          p.isWithin(Directory.systemTemp.absolute.path, safeRoot)) {
        directory.deleteSync(recursive: true);
      }
    }
  }

  static int _validateGeometry(Map geometry) {
    if (geometry['type'] == 'GeometryCollection') {
      return (geometry['geometries'] as List)
          .fold<int>(0, (n, child) => n + _validateGeometry(child as Map));
    }
    if (![
      'Point',
      'MultiPoint',
      'LineString',
      'MultiLineString',
      'Polygon',
      'MultiPolygon'
    ].contains(geometry['type'])) {
      throw const FormatException('Unsupported vector geometry.');
    }
    var count = 0;
    void visit(dynamic coordinates) {
      if (coordinates is! List || coordinates.isEmpty) {
        throw const FormatException('Invalid coordinates.');
      }
      if (coordinates.first is num) {
        if (coordinates.length < 2 || coordinates[1] is! num) {
          throw const FormatException('Invalid coordinates.');
        }
        final x = (coordinates[0] as num).toDouble(),
            y = (coordinates[1] as num).toDouble();
        if (!x.isFinite || !y.isFinite || x.abs() > 180 || y.abs() > 90) {
          throw const FormatException(
              'Reproject vector layers to WGS84 (EPSG:4326).');
        }
        if (++count > 2000000) {
          throw const FormatException('Simplify this layer before importing.');
        }
      } else {
        for (final child in coordinates) {
          visit(child);
        }
      }
    }

    visit(geometry['coordinates']);
    return count;
  }

  static void _validateShp(Uint8List bytes) {
    if (bytes.length < 108) {
      throw const FormatException('Invalid shapefile header.');
    }
    final data = ByteData.sublistView(bytes);
    if (data.getUint32(0) != 9994 ||
        data.getUint32(28, Endian.little) != 1000 ||
        data.getUint32(24) * 2 != bytes.length) {
      throw const FormatException('Invalid or truncated shapefile.');
    }
    var offset = 100, records = 0;
    while (offset < bytes.length) {
      if (offset + 12 > bytes.length) {
        throw const FormatException('Truncated shapefile record.');
      }
      final length = data.getUint32(offset + 4) * 2,
          start = offset + 8,
          type = data.getInt32(start, Endian.little);
      if (length < 4 || start + length > bytes.length) {
        throw const FormatException('Truncated shapefile record.');
      }
      if (![0, 1, 11, 21, 3, 13, 23, 5, 15, 25, 8, 18, 28].contains(type)) {
        throw const FormatException('Unsupported shapefile geometry.');
      }
      void coordinate(int at) {
        final x = data.getFloat64(at, Endian.little),
            y = data.getFloat64(at + 8, Endian.little);
        if (!x.isFinite || !y.isFinite || x.abs() > 180 || y.abs() > 90) {
          throw const FormatException(
              'Reproject shapefile to WGS84 (EPSG:4326).');
        }
      }

      if ([1, 11, 21].contains(type)) {
        if (length < 20) throw const FormatException('Truncated point.');
        coordinate(start + 4);
      } else if (type != 0) {
        final multi = [8, 18, 28].contains(type);
        if (length < (multi ? 40 : 44)) {
          throw const FormatException('Truncated geometry.');
        }
        final parts = multi ? 0 : data.getInt32(start + 36, Endian.little),
            points = data.getInt32(start + (multi ? 36 : 40), Endian.little);
        final at = start + (multi ? 40 : 44) + parts * 4;
        if (parts < 0 ||
            points < 1 ||
            points > 2000000 ||
            at + points * 16 > start + length) {
          throw const FormatException('Invalid shape parts or points.');
        }
        for (var i = 0; i < points; i++) {
          coordinate(at + i * 16);
        }
      }
      if (type != 0 && ++records > maxFeatures) {
        throw const FormatException('Layer exceeds 50,000 features.');
      }
      offset = start + length;
    }
  }
}
