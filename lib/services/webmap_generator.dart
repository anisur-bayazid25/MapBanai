import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:path_provider/path_provider.dart';

/// Generates a self-contained HTML webmap from local survey data.
///
/// Inlines Leaflet CSS/JS (no CDN), embeds the GeoJSON FeatureCollection,
/// and writes the result to `webmap_<timestamp>.html` in the app documents
/// directory. The HTML is portable and works offline for data, but the
/// OSM tile layer needs internet (noted via banner).
class WebMapGenerator {
  final AppDatabase? _db;
  final WebMapDataService? _dataService;

  WebMapGenerator({AppDatabase? db, WebMapDataService? dataService})
      : _db = db,
        _dataService = dataService;

  /// Builds the HTML string. If [featureCollection] is null, it is fetched
  /// via [WebMapDataService] (requires [db] or [dataService]).
  /// [leafletCss] and [leafletJs] can be injected for tests to avoid asset loading.
  Future<String> generateHtml({
    Map<String, dynamic>? featureCollection,
    int? projectId,
    String? leafletCss,
    String? leafletJs,
  }) async {
    final fc = featureCollection ??
        await (_dataService ?? WebMapDataService(_db!))
            .buildFeatureCollectionForProject(projectId);

    final css = leafletCss ?? await _loadLeafletCss();
    final js = leafletJs ?? await _loadLeafletJs();

    final geoJsonStr = jsonEncode(fc);
    // Extract distinct values for filters
    final features = (fc['features'] as List?) ?? [];
    final formNames = <String>{};
    final surveyors = <String>{};
    for (final f in features) {
      if (f is Map) {
        final props = f['properties'] as Map?;
        if (props != null) {
          final fn = props['form_name']?.toString().trim() ?? '';
          final geom = props['geometry_type']?.toString().trim() ?? '';
          final label = fn.isNotEmpty ? fn : geom;
          if (label.isNotEmpty) formNames.add(label);
          final sv = props['surveyor']?.toString().trim() ?? '';
          if (sv.isNotEmpty) surveyors.add(sv);
        }
      }
    }

    final formOptions = formNames
        .map((v) =>
            '<option value="${_escapeHtml(v)}">${_escapeHtml(v)}</option>')
        .join('\n');
    final surveyorOptions = surveyors
        .map((v) =>
            '<option value="${_escapeHtml(v)}">${_escapeHtml(v)}</option>')
        .join('\n');

    String template;
    try {
      template = await rootBundle.loadString('assets/webmap/atlas.html');
    } catch (_) {
      template = await File('assets/webmap/atlas.html').readAsString();
    }
    String studio;
    try {
      studio = await rootBundle.loadString('assets/webmap/map_studio.js');
    } catch (_) {
      studio = await File('assets/webmap/map_studio.js').readAsString();
    }
    Future<String> asset(String path) async {
      try {
        return await rootBundle.loadString(path);
      } catch (_) {
        return File(path).readAsString();
      }
    }

    final symbols = await asset('assets/webmap/map_symbols.js');
    final fonts = await asset('assets/webmap/fonts.css');
    return template
        .replaceAll('__MAP_SYMBOLS_JS__', symbols)
        .replaceAll('__MAP_FONT_CSS__', fonts)
        .replaceAll('__MAP_STUDIO_JS__', studio)
        .replaceAll('__LEAFLET_CSS__', css)
        .replaceAll('__LEAFLET_JS__', js)
        .replaceAll('__FORM_OPTIONS__', formOptions)
        .replaceAll('__SURVEYOR_OPTIONS__', surveyorOptions)
        .replaceAll('__GEOJSON__', geoJsonStr.replaceAll('<', r'\u003c'));
  }

  Future<String> _loadLeafletCss() async {
    try {
      return await rootBundle.loadString('assets/leaflet/leaflet.css');
    } catch (_) {
      try {
        return await File('assets/leaflet/leaflet.css').readAsString();
      } catch (_) {
        return '/* leaflet css not found */';
      }
    }
  }

  Future<String> _loadLeafletJs() async {
    try {
      return await rootBundle.loadString('assets/leaflet/leaflet.js');
    } catch (_) {
      try {
        return await File('assets/leaflet/leaflet.js').readAsString();
      } catch (_) {
        return '// leaflet js not found';
      }
    }
  }

  String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Writes the generated HTML to a timestamped file in the app documents directory.
  Future<File> writeToFile(String html, {Directory? directory}) async {
    final dir = directory ?? await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}${Platform.pathSeparator}webmap_$stamp.html');
    await file.writeAsString(html, flush: true);
    return file;
  }
}
