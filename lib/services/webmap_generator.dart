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
    String? leafletCss,
    String? leafletJs,
  }) async {
    final fc = featureCollection ??
        await (_dataService ?? WebMapDataService(_db!)).buildFeatureCollection();

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

    final formOptions = formNames.map((v) => '<option value="${_escapeHtml(v)}">$v</option>').join('\n');
    final surveyorOptions = surveyors.map((v) => '<option value="${_escapeHtml(v)}">$v</option>').join('\n');

    // Build HTML
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MapBanai WebMap</title>
<style>
$css
</style>
<style>
  html, body { margin:0; padding:0; height:100%; font-family: sans-serif; }
  #map { height: 100vh; width: 100%; }
  #banner { position:absolute; top:8px; left:50%; transform:translateX(-50%); z-index:1000; background:#fff3cd; border:1px solid #ffe69c; padding:6px 12px; border-radius:6px; font-size:12px; }
  #sidebar { position:absolute; top:60px; left:10px; z-index:1000; background:white; padding:12px; border-radius:8px; box-shadow:0 2px 6px rgba(0,0,0,0.2); width:220px; max-height:70vh; overflow:auto; }
  #sidebar h3 { margin:0 0 8px 0; font-size:14px; }
  #sidebar label { font-size:12px; display:block; margin:4px 0; }
  #sidebar select, #sidebar input { width:100%; font-size:12px; padding:4px; }
  #legend { position:absolute; bottom:10px; right:10px; z-index:1000; background:white; padding:8px 12px; border-radius:6px; box-shadow:0 2px 6px rgba(0,0,0,0.2); font-size:12px; }
  .dot { display:inline-block; width:12px; height:12px; border-radius:50%; margin-right:6px; vertical-align:middle; }
  .line { display:inline-block; width:16px; height:3px; margin-right:6px; vertical-align:middle; }
  .poly { display:inline-block; width:12px; height:12px; margin-right:6px; vertical-align:middle; border:1px solid #333; }
  table.popup-table { border-collapse:collapse; font-size:12px; }
  table.popup-table th, table.popup-table td { border:1px solid #ddd; padding:4px 6px; text-align:left; }
  table.popup-table th { background:#f5f5f5; }
  img.thumb { max-width:200px; max-height:150px; display:block; margin-top:6px; border-radius:4px; }
</style>
</head>
<body>
<div id="banner">Map tiles require internet; your data works offline</div>
<div id="map"></div>
<div id="sidebar">
  <h3>Filters</h3>
  <label>Form / Type
    <select id="filter-form"><option value="">All</option>
$formOptions
    </select>
  </label>
  <label>Surveyor
    <select id="filter-surveyor"><option value="">All</option>
$surveyorOptions
    </select>
  </label>
  <label>From <input type="date" id="filter-from"></label>
  <label>To <input type="date" id="filter-to"></label>
  <button id="filter-clear" style="margin-top:8px; width:100%;">Clear filters</button>
  <div style="margin-top:8px; font-size:11px; color:#666;">Showing <span id="filter-count">${features.length}</span> of ${features.length}</div>
</div>
<div id="legend">
  <div><span class="dot" style="background:#e53935"></span> Point / Geopoint</div>
  <div><span class="line" style="background:#1565c0"></span> Line</div>
  <div><span class="poly" style="background:#2e7d32; opacity:0.6"></span> Polygon</div>
</div>
<script>
$js
</script>
<script>
const geojsonData = $geoJsonStr;

const map = L.map('map').setView([23.81, 90.41], 7);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; OpenStreetMap contributors',
  maxZoom: 19
}).addTo(map);

function styleFor(feature) {
  const t = (feature.properties && feature.properties.geometry_type) || '';
  if (t === 'point' || t === 'geopoint') return {color:'#e53935'};
  if (t === 'line') return {color:'#1565c0', weight:4, opacity:0.9};
  if (t === 'polygon') return {color:'#1b5e20', fillColor:'#2e7d32', fillOpacity:0.35, weight:2};
  return {};
}

function popupFor(feature) {
  const p = feature.properties || {};
  let html = '<table class="popup-table">';
  const keys = ['form_name','geometry_type','surveyor','submitted_at','project_name','id'];
  // Add known keys first, then answers flattened
  for (const k of keys) {
    if (p[k] != null && String(p[k]).trim() !== '') {
      html += '<tr><th>' + k + '</th><td>' + escapeHtml(String(p[k])) + '</td></tr>';
    }
  }
  if (p.answers && typeof p.answers === 'object') {
    for (const ak in p.answers) {
      const av = p.answers[ak];
      html += '<tr><th>' + escapeHtml(ak) + '</th><td>' + escapeHtml(String(av)) + '</td></tr>';
    }
  }
  // Also include any other top-level props not yet shown
  for (const k in p) {
    if (keys.includes(k) || k === 'answers' || k === 'thumbnail_base64' || k === 'photo_path' || k === 'photo_relative_path') continue;
    if (p[k] != null && String(p[k]).trim() !== '') {
      html += '<tr><th>' + escapeHtml(k) + '</th><td>' + escapeHtml(String(p[k])) + '</td></tr>';
    }
  }
  if (p.photo_path) html += '<tr><th>photo</th><td>' + escapeHtml(p.photo_path) + '</td></tr>';
  html += '</table>';
  if (p.thumbnail_base64) {
    html += '<img class="thumb" src="data:image/jpeg;base64,' + p.thumbnail_base64 + '" />';
  }
  return html;
}
function escapeHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}

let geoLayer;
function renderFiltered() {
  const formVal = document.getElementById('filter-form').value;
  const survVal = document.getElementById('filter-surveyor').value;
  const fromVal = document.getElementById('filter-from').value;
  const toVal = document.getElementById('filter-to').value;
  const fromDate = fromVal ? new Date(fromVal) : null;
  const toDate = toVal ? new Date(toVal) : null;
  if (toDate) toDate.setHours(23,59,59,999);

  const filtered = {
    type: 'FeatureCollection',
    features: geojsonData.features.filter(f => {
      const p = f.properties || {};
      const formLabel = (p.form_name && String(p.form_name).trim() !== '') ? String(p.form_name) : String(p.geometry_type||'');
      if (formVal && formLabel !== formVal) return false;
      if (survVal && String(p.surveyor||'') !== survVal) return false;
      if (fromDate || toDate) {
        const d = p.submitted_at ? new Date(p.submitted_at) : null;
        if (!d || isNaN(d)) return false;
        if (fromDate && d < fromDate) return false;
        if (toDate && d > toDate) return false;
      }
      return true;
    })
  };
  if (geoLayer) map.removeLayer(geoLayer);
  geoLayer = L.geoJSON(filtered, {
    pointToLayer: function(feature, latlng) {
      return L.circleMarker(latlng, {radius:7, color:'#e53935', fillColor:'#e53935', fillOpacity:0.9, weight:2});
    },
    style: styleFor,
    onEachFeature: function(feature, layer) {
      layer.bindPopup(popupFor(feature));
    }
  }).addTo(map);
  document.getElementById('filter-count').textContent = filtered.features.length;
  if (filtered.features.length) {
    try { map.fitBounds(geoLayer.getBounds().pad(0.2)); } catch(e) {}
  }
}
document.getElementById('filter-form').addEventListener('change', renderFiltered);
document.getElementById('filter-surveyor').addEventListener('change', renderFiltered);
document.getElementById('filter-from').addEventListener('change', renderFiltered);
document.getElementById('filter-to').addEventListener('change', renderFiltered);
document.getElementById('filter-clear').addEventListener('click', function(){
  document.getElementById('filter-form').value='';
  document.getElementById('filter-surveyor').value='';
  document.getElementById('filter-from').value='';
  document.getElementById('filter-to').value='';
  renderFiltered();
});
renderFiltered();
</script>
</body>
</html>
''';
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
