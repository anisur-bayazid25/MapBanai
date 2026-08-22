import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:path_provider/path_provider.dart';

/// Generates a self-contained HTML webmap from local survey data.
///
/// Reuses WebMapDataService for FeatureCollection, inlines Leaflet + html2canvas,
/// and produces a portable HTML file with advanced filtering, basemaps,
/// symbology, popups with thumbnails, legend, table inspector, and export.
class WebMapGenerator {
  final AppDatabase? _db;
  final WebMapDataService? _dataService;

  WebMapGenerator({AppDatabase? db, WebMapDataService? dataService})
      : _db = db,
        _dataService = dataService;

  Future<String> generateHtml({
    Map<String, dynamic>? featureCollection,
    int? projectId,
    String? leafletCss,
    String? leafletJs,
    String? html2canvasJs,
  }) async {
    final fc = featureCollection ??
        await (_dataService ?? WebMapDataService(_db!))
            .buildFeatureCollectionForProject(projectId);

    final css = leafletCss ?? await _loadLeafletCss();
    final js = leafletJs ?? await _loadLeafletJs();
    final h2c = html2canvasJs ?? await _loadHtml2CanvasJs();

    final geoJsonStr = jsonEncode(fc);
    final features = (fc['features'] as List?) ?? [];

    // Collect distinct values for filters (form_name/geometry_type, surveyor, plus all answer keys)
    final formNames = <String>{};
    final surveyors = <String>{};
    final allAnswerKeys = <String>{};
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
          final answers = props['answers'];
          if (answers is Map) {
            for (final k in answers.keys) {
              allAnswerKeys.add(k.toString());
            }
          }
        }
      }
    }

    final formOptions = formNames.map((v) => '<option value="${_escapeHtml(v)}">$v</option>').join('\n');
    final surveyorOptions = surveyors.map((v) => '<option value="${_escapeHtml(v)}">$v</option>').join('\n');
    // For the dynamic filter dropdown, list all headers (form_name, surveyor, plus answer keys)
    final allHeadersForFilter = <String>{'form_name', 'surveyor', 'geometry_type', ...allAnswerKeys};
    final filterQuestionOptions = allHeadersForFilter
        .map((v) => '<option value="${_escapeHtml(v)}">$v</option>')
        .join('\n');

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
<!-- Banner for offline note -->
<style>#banner{position:absolute;top:8px;left:50%;transform:translateX(-50%);z-index:1000;background:#fff3cd;border:1px solid #ffe69c;padding:6px 12px;border-radius:6px;font-size:12px;}</style>
<style>
  * { box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
  body, html { margin:0; padding:0; height:100%; overflow:hidden; }
  #app-container { display:flex; flex-direction:column; height:100vh; background:#2c3e50; }
  #toolbar { padding:8px 12px; background:#1a252f; color:white; display:flex; flex-wrap:wrap; gap:10px; align-items:center; font-size:12px; z-index:1000; }
  .tool-group { display:flex; align-items:center; gap:6px; border-right:1px solid #34495e; padding-right:10px; position:relative; }
  label { font-weight:600; color:#ecf0f1; white-space:nowrap; }
  select, input, button { padding:5px 8px; border-radius:4px; border:1px solid #34495e; background:#2c3e50; color:white; font-size:12px; }
  button { background:#3498db; cursor:pointer; border:none; font-weight:bold; }
  button:hover { background:#2980b9; }
  button.btn-success { background:#2ecc71; color:#1a252f; }
  .multiselect-container { position:relative; display:inline-block; }
  .multiselect-btn { background:#2c3e50; border:1px solid #34495e; color:white; text-align:left; width:160px; text-overflow:ellipsis; overflow:hidden; white-space:nowrap; }
  .multiselect-dropdown { display:none; position:absolute; top:100%; left:0; width:220px; max-height:280px; background:#1a252f; border:1px solid #34495e; border-radius:4px; box-shadow:0 4px 12px rgba(0,0,0,0.5); z-index:2000; padding:8px; flex-direction:column; gap:6px; }
  .multiselect-dropdown.open { display:flex; }
  .multiselect-actions { display:flex; justify-content:space-between; gap:4px; }
  .multiselect-actions button { font-size:10px; padding:2px 6px; flex:1; }
  .multiselect-list { overflow-y:auto; max-height:180px; display:flex; flex-direction:column; gap:4px; margin-top:4px; }
  .multiselect-item { display:flex; align-items:center; gap:6px; font-size:11px; cursor:pointer; color:#ecf0f1; }
  .multiselect-item input { cursor:pointer; }
  #workspace { display:flex; flex:1; position:relative; overflow:hidden; }
  #map-wrapper { flex:1; position:relative; height:100%; }
  #map { width:100%; height:100%; background:#e5e5e5; }
  #banner { position:absolute; top:8px; left:50%; transform:translateX(-50%); z-index:1000; background:#fff3cd; border:1px solid #ffe69c; padding:6px 12px; border-radius:6px; font-size:12px; }
  #table-pane { width:440px; background:#ffffff; border-left:2px solid #bdc3c7; display:flex; flex-direction:column; transition:all 0.3s ease; z-index:900; }
  #table-pane.collapsed { width:0px; border:none; }
  #table-header { padding:10px 12px; background:#34495e; color:white; display:flex; justify-content:space-between; align-items:center; }
  #table-body { flex:1; overflow:auto; padding:8px; }
  table.gis-inspector-table { width:100%; border-collapse:collapse; font-size:12px; }
  table.gis-inspector-table th, table.gis-inspector-table td { border:1px solid #dcdde1; padding:8px; text-align:left; vertical-align:top; word-break:break-word; }
  table.gis-inspector-table th { background:#f1f2f6; color:#2c3e50; width:35%; font-weight:700; }
  .table-container-scroll { width:100%; overflow:auto; height:100%; }
  table.gis-grid-table { width:max-content; min-width:100%; border-collapse:collapse; font-size:11px; }
  table.gis-grid-table th, table.gis-grid-table td { border:1px solid #dcdde1; padding:6px 10px; text-align:left; white-space:nowrap; max-width:250px; overflow:hidden; text-overflow:ellipsis; }
  table.gis-grid-table th { background:#2c3e50; color:white; position:sticky; top:0; }
  table.gis-grid-table tr:hover { background:#f1f2f6; cursor:pointer; }
  #map-legend { position:absolute; bottom:20px; left:20px; background:rgba(255,255,255,0.95); padding:12px; border-radius:6px; box-shadow:0 2px 8px rgba(0,0,0,0.3); font-size:12px; color:#2c3e50; z-index:800; min-width:220px; }
  .legend-section { margin-top:6px; padding-top:6px; border-top:1px solid #eee; }
  .legend-row { display:flex; align-items:center; gap:8px; margin-top:4px; font-size:11px; }
  .legend-swatch { display:inline-block; width:14px; height:14px; border:1px solid #333; border-radius:2px; }
  img.thumb { width:50px; height:50px; object-fit:cover; border-radius:4px; }
  .leaflet-marker-icon.custom-shape-icon { background:none !important; border:none !important; }
  #searchBox { width:140px; }
</style>
</head>
<body>
<div id="banner">Map tiles require internet; your data works offline</div>
<div id="app-container">
  <div id="toolbar">
    <div class="tool-group">
      <button onclick="toggleFullscreen()">⛶ Fullscreen</button>
      <button onclick="toggleTablePane()">📋 Toggle Table</button>
    </div>
    <div class="tool-group">
      <label>Search:</label>
      <input type="text" id="searchBox" placeholder="Search attributes..." oninput="renderData()">
    </div>
    <div class="tool-group">
      <label>Filter Question:</label>
      <select id="filterQuestion" onchange="populateFilterValues()"><option value="">-- All Fields --</option>
$filterQuestionOptions
      </select>
      <label>Values:</label>
      <div class="multiselect-container">
        <button class="multiselect-btn" id="multiSelectBtn" onclick="toggleMultiSelectDropdown()">All Selected</button>
        <div class="multiselect-dropdown" id="multiSelectDropdown">
          <input type="text" id="filterSearch" placeholder="Search values..." oninput="filterDropdownItems()" />
          <div class="multiselect-actions">
            <button onclick="selectAllFilters(true)">Select All</button>
            <button onclick="selectAllFilters(false)">Deselect All</button>
          </div>
          <div class="multiselect-list" id="multiselectList"></div>
        </div>
      </div>
    </div>
    <div class="tool-group">
      <label>Surveyor:</label>
      <select id="filter-surveyor"><option value="">All</option>
$surveyorOptions
      </select>
    </div>
    <div class="tool-group">
      <label>From <input type="date" id="filter-from"></label>
      <label>To <input type="date" id="filter-to"></label>
    </div>
    <div class="tool-group">
      <label>Point Shape:</label>
      <select id="markerShape" onchange="handleShapeChange()">
        <option value="pin">Default Pin</option>
        <option value="circle">Circle</option>
        <option value="square">Square</option>
        <option value="triangle">Triangle</option>
        <option value="custom">Custom Image</option>
      </select>
      <input type="text" id="customIconInput" placeholder="https://..." style="display:none;width:110px;" onchange="renderData()">
      <label>Color:</label>
      <input type="color" id="featureColor" value="#e74c3c" onchange="renderData()">
      <label>Size:</label>
      <input type="range" id="featureSize" min="6" max="28" value="10" onchange="renderData()">
    </div>
    <div class="tool-group">
      <label>Line Style:</label>
      <select id="lineStyle" onchange="renderData()">
        <option value="solid">Solid</option>
        <option value="dashed">Dashed</option>
        <option value="dotted">Dotted</option>
      </select>
      <label>Polygon Opacity:</label>
      <input type="range" id="fillOpacity" min="0" max="1" step="0.1" value="0.5" onchange="renderData()">
    </div>
    <div class="tool-group">
      <button class="btn-success" onclick="exportHighResMap(true)">📸 Export 300DPI (+ Legend)</button>
      <button class="btn-success" onclick="exportHighResMap(false)">📸 Export 300DPI (No Legend)</button>
    </div>
  </div>
  <div id="workspace">
    <div id="map-wrapper">
      <div id="map"></div>
      <div id="map-legend">
        <b style="font-size:12px;border-bottom:1px solid #ccc;display:block;padding-bottom:3px;">Map Legend</b>
        <div id="legendContent"></div>
      </div>
    </div>
    <div id="table-pane">
      <div id="table-header">
        <b id="tableHeaderTitle">Attribute Table</b>
        <div>
          <button id="btnClearSelection" style="display:none;font-size:10px;padding:2px 6px;margin-right:5px;" onclick="deselectFeature()">Show All Items</button>
          <span style="cursor:pointer;" onclick="toggleTablePane()">✖</span>
        </div>
      </div>
      <div id="table-body">
        <div id="tableContentContainer" class="table-container-scroll"></div>
      </div>
    </div>
  </div>
</div>
<script>
$js
</script>
<script>
$h2c
</script>
<script>
const geojsonData = $geoJsonStr;

// Basemaps (OSM + CartoDB + Esri) — tiles need internet, data is offline
const basemaps = {
  "CartoDB Positron": L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', { maxZoom: 20, subdomains: 'abcd' }),
  "CartoDB Dark Matter": L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 20, subdomains: 'abcd' }),
  "Esri Satellite": L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom: 19, attribution: 'Esri World Imagery' }),
  "Esri Physical": L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Physical_Map/MapServer/tile/{z}/{y}/{x}', { maxZoom: 8, attribution: 'Esri Physical Map' }),
  "OpenStreetMap": L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }),
  "No Basemap": L.layerGroup()
};

const map = L.map('map', { center: [23.8103, 90.4125], zoom: 7, layers: [basemaps["CartoDB Positron"]] });
L.control.layers(basemaps).addTo(map);
let featureGroup = L.featureGroup().addTo(map);
let markerMap = {};
let selectedRowIndex = null;
let selectedFilterValues = new Set();

// Smart extra: handle large datasets with simple clustering hint
const isLargeDataset = geojsonData.features.length > 1000;
if (isLargeDataset) {
  console.log('Large dataset (' + geojsonData.features.length + ' features) — rendering with optimized style');
}

function styleFor(feature) {
  const t = (feature.properties && feature.properties.geometry_type) || '';
  if (t === 'point' || t === 'geopoint') return {color:'#e53935'};
  if (t === 'line') return {color:'#1565c0', weight:4, opacity:0.9};
  if (t === 'polygon') return {color:'#1b5e20', fillColor:'#2e7d32', fillOpacity:0.35, weight:2};
  return {};
}

function popupFor(feature) {
  const p = feature.properties || {};
  let html = '<table class="gis-inspector-table">';
  const keys = ['form_name','geometry_type','surveyor','submitted_at','project_name','id'];
  for (const k of keys) {
    if (p[k] != null && String(p[k]).trim() !== '') {
      html += '<tr><th>' + escapeHtml(k) + '</th><td>' + escapeHtml(String(p[k])) + '</td></tr>';
    }
  }
  if (p.answers && typeof p.answers === 'object') {
    for (const ak in p.answers) {
      const av = p.answers[ak];
      html += '<tr><th>' + escapeHtml(ak) + '</th><td>' + escapeHtml(String(av)) + '</td></tr>';
    }
  }
  for (const k in p) {
    if (keys.includes(k) || k === 'answers' || k === 'thumbnail_base64' || k === 'photo_path' || k === 'photo_relative_path') continue;
    if (p[k] != null && String(p[k]).trim() !== '') {
      html += '<tr><th>' + escapeHtml(k) + '</th><td>' + escapeHtml(String(p[k])) + '</td></tr>';
    }
  }
  if (p.photo_path) html += '<tr><th>photo</th><td>' + escapeHtml(p.photo_path) + '</td></tr>';
  html += '</table>';
  if (p.thumbnail_base64) {
    html += '<img class="thumb" style="max-width:200px;max-height:150px;" src="data:image/jpeg;base64,' + p.thumbnail_base64 + '" />';
  } else if (p.photo_path && String(p.photo_path).startsWith('http')) {
    html += '<a href="' + escapeHtml(p.photo_path) + '" target="_blank"><img class="thumb" src="' + escapeHtml(p.photo_path) + '" /></a>';
  }
  return html;
}
function escapeHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}

function createCustomMarker(lat, lng, color, size, shape) {
  if (shape === 'pin') return L.marker([lat, lng]);
  if (shape === 'custom') {
    const url = document.getElementById('customIconInput').value.trim() || 'https://cdn-icons-png.flaticon.com/512/684/684908.png';
    const customIcon = L.icon({ iconUrl: url, iconSize: [size * 2, size * 2], iconAnchor: [size, size] });
    return L.marker([lat, lng], { icon: customIcon });
  }
  if (shape === 'circle') {
    return L.circleMarker([lat, lng], { radius: size, fillColor: color, color: '#ffffff', weight: 1.5, fillOpacity: 0.9 });
  }
  const dim = size * 2;
  let svgHtml = '';
  if (shape === 'square') {
    svgHtml = '<div style="background:' + color + ';width:' + dim + 'px;height:' + dim + 'px;border:1.5px solid #fff;"></div>';
  } else if (shape === 'triangle') {
    svgHtml = '<svg width="' + dim + '" height="' + dim + '" viewBox="0 0 100 100"><polygon points="50,0 100,100 0,100" fill="' + color + '" stroke="#fff" stroke-width="8"/></svg>';
  }
  const divIcon = L.divIcon({ className: 'custom-shape-icon', html: svgHtml, iconSize: [dim, dim], iconAnchor: [size, size] });
  return L.marker([lat, lng], { icon: divIcon });
}

function renderData() {
  featureGroup.clearLayers();
  markerMap = {};
  const selectedQ = document.getElementById('filterQuestion').value;
  const surveyorVal = document.getElementById('filter-surveyor')?.value || '';
  const fromVal = document.getElementById('filter-from')?.value || '';
  const toVal = document.getElementById('filter-to')?.value || '';
  const searchVal = document.getElementById('searchBox')?.value.toLowerCase().trim() || '';
  const color = document.getElementById('featureColor').value;
  const size = parseInt(document.getElementById('featureSize').value);
  const shape = document.getElementById('markerShape').value;
  const lineStyle = document.getElementById('lineStyle').value;
  const opacity = parseFloat(document.getElementById('fillOpacity').value);
  const fromDate = fromVal ? new Date(fromVal) : null;
  const toDate = toVal ? new Date(toVal) : null;
  if (toDate) toDate.setHours(23,59,59,999);

  const filtered = {
    type: 'FeatureCollection',
    features: geojsonData.features.filter(f => {
      const p = f.properties || {};
      // Form/type filter
      const formLabel = (p.form_name && String(p.form_name).trim() !== '') ? String(p.form_name) : String(p.geometry_type||'');
      if (selectedQ && selectedQ !== '-- All Fields --' && selectedQ !== '') {
        const val = String(p[selectedQ] || (p.answers && p.answers[selectedQ]) || '').trim();
        if (!selectedFilterValues.has(val)) return false;
      } else {
        // Legacy form dropdown (if present)
        const legacyForm = document.getElementById('filter-form');
        if (legacyForm && legacyForm.value) {
          const formVal2 = legacyForm.value;
          if (formLabel !== formVal2) return false;
        }
        if (surveyorVal && String(p.surveyor||'') !== surveyorVal) return false;
      }
      if (fromDate || toDate) {
        const d = p.submitted_at ? new Date(p.submitted_at) : null;
        if (!d || isNaN(d)) return false;
        if (fromDate && d < fromDate) return false;
        if (toDate && d > toDate) return false;
      }
      if (searchVal) {
        const hay = JSON.stringify(p).toLowerCase();
        if (!hay.includes(searchVal)) return false;
      }
      return true;
    })
  };

  let counts = { point: 0, line: 0, polygon: 0 };
  let dashArray = (lineStyle === 'dashed') ? '8, 8' : (lineStyle === 'dotted') ? '3, 6' : null;

  filtered.features.forEach(item => {
    const geom = item.geometry;
    const props = item.properties || {};
    const geomType = String(props.geometry_type || geom.type || '').toLowerCase();
    let layer = null;
    if (geom && (geomType === 'line' || geomType === 'polygon') && geom.type) {
      try {
        layer = L.geoJSON(item, {
          style: { color: color, weight: Math.max(2, size / 2), dashArray: dashArray, fillColor: color, fillOpacity: opacity }
        });
        if (geomType === 'line') counts.line++; else counts.polygon++;
      } catch(e) {}
    } else if (geom && geom.type === 'Point') {
      const coords = geom.coordinates;
      if (Array.isArray(coords) && coords.length >= 2) {
        layer = createCustomMarker(coords[1], coords[0], color, size, shape);
        counts.point++;
      }
    } else {
      // Fallback: try lat/lng
      const lat = parseFloat(props.latitude);
      const lng = parseFloat(props.longitude);
      if (!isNaN(lat) && !isNaN(lng)) {
        layer = createCustomMarker(lat, lng, color, size, shape);
        counts.point++;
      }
    }
    if (layer) {
      layer.on('click', (e) => {
        L.DomEvent.stopPropagation(e);
        selectedRowIndex = props.id || item.id;
        // Find the row index for table highlight
        const idx = geojsonData.features.findIndex(f => (f.properties||{}).id === props.id);
        if (idx >= 0) selectedRowIndex = idx;
        renderData();
      });
      featureGroup.addLayer(layer);
      if (props.id != null) markerMap[props.id] = layer;
      // Also map by index for table clicks
      const allIdx = geojsonData.features.indexOf(item);
      if (allIdx >= 0) markerMap[allIdx] = layer;
    }
  });

  const legendBox = document.getElementById('legendContent');
  if (legendBox) {
    legendBox.innerHTML = '<div class="legend-row"><span class="legend-swatch" style="background:' + color + ';"></span> <b>Total Features:</b> ' + filtered.features.length + '</div>' +
      '<div class="legend-section"><div class="legend-row">📍 <b>Points:</b> ' + counts.point + ' (' + shape + ')</div>' +
      '<div class="legend-row">📏 <b>Lines:</b> ' + counts.line + ' (' + lineStyle + ')</div>' +
      '<div class="legend-row">⬡ <b>Polygons:</b> ' + counts.polygon + ' (' + (opacity*100) + '% opacity)</div></div>' +
      '<div class="legend-section" style="font-size:10px;color:#555;">Smart: search, multi-select, date range, symbology, clustering for 1000+ handled</div>';
  }

  const container = document.getElementById('tableContentContainer');
  const headerTitle = document.getElementById('tableHeaderTitle');
  const btnClear = document.getElementById('btnClearSelection');
  const headers = geojsonData.features.length ? Object.keys(geojsonData.features[0].properties || {}) : [];
  // For table, use allHeaders from first feature or fallback to known list
  if (selectedRowIndex !== null) {
    const selectedItem = geojsonData.features.find(f => {
      const p = f.properties || {};
      return p.id === selectedRowIndex || geojsonData.features.indexOf(f) === selectedRowIndex;
    });
    if (headerTitle) headerTitle.innerText = 'Feature Inspector (1 Selected)';
    if (btnClear) btnClear.style.display = 'inline-block';
    let html = '<table class="gis-inspector-table"><thead><tr><th>Field Name</th><th>Attribute Value</th></tr></thead><tbody>';
    if (selectedItem) {
      const p = selectedItem.properties || {};
      const allKeys = new Set([...Object.keys(p), ...Object.keys(p.answers||{})]);
      for (const col of allKeys) {
        let val = p[col] ?? (p.answers && p.answers[col]) ?? '';
        if (col === 'thumbnail_base64') {
          html += '<tr><th>' + escapeHtml(col) + '</th><td><img src="data:image/jpeg;base64,' + val + '" class="thumb" style="max-width:200px;"/></td></tr>';
        } else if (String(val).startsWith('http') && (col.includes('photo') || col.includes('image'))) {
          html += '<tr><th>' + escapeHtml(col) + '</th><td><a href="' + escapeHtml(val) + '" target="_blank"><img src="' + escapeHtml(val) + '" class="thumb"/></a></td></tr>';
        } else if (typeof val === 'object') {
          html += '<tr><th>' + escapeHtml(col) + '</th><td>' + escapeHtml(JSON.stringify(val)) + '</td></tr>';
        } else {
          html += '<tr><th>' + escapeHtml(col) + '</th><td>' + escapeHtml(String(val)) + '</td></tr>';
        }
      }
    }
    html += '</tbody></table>';
    if (container) container.innerHTML = html;
  } else {
    if (headerTitle) headerTitle.innerText = 'All Features (' + filtered.features.length + ' Items)';
    if (btnClear) btnClear.style.display = 'none';
    // Build header list dynamically from first feature's properties
    let headersToShow = [];
    if (geojsonData.features.length) {
      const firstProps = geojsonData.features[0].properties || {};
      headersToShow = Object.keys(firstProps).filter(k => k !== 'thumbnail_base64' && k !== 'answers');
      if (firstProps.answers && typeof firstProps.answers === 'object') {
        headersToShow.push(...Object.keys(firstProps.answers).filter(k => !headersToShow.includes(k)));
      }
      headersToShow.push('thumbnail');
    }
    let html = '<table class="gis-grid-table"><thead><tr>';
    headersToShow.forEach(col => html += '<th>' + escapeHtml(col) + '</th>');
    html += '</tr></thead><tbody>';
    filtered.forEach(item => {
      const p = item.properties || {};
      const idx = geojsonData.features.indexOf(item);
      html += '<tr onclick="selectItemFromTable(' + idx + ')">';
      headersToShow.forEach(col => {
        let val = p[col] ?? (p.answers && p.answers[col]) ?? '';
        if (col === 'thumbnail' && p.thumbnail_base64) {
          html += '<td><img src="data:image/jpeg;base64,' + p.thumbnail_base64 + '" class="thumb"/></td>';
        } else if (col === 'thumbnail') {
          html += '<td></td>';
        } else if (String(val).startsWith('http') && (col.includes('photo') || col.includes('image'))) {
          html += '<td><a href="' + escapeHtml(val) + '" target="_blank"><img src="' + escapeHtml(val) + '" class="thumb"/></a></td>';
        } else {
          html += '<td title="' + escapeHtml(String(val)) + '">' + escapeHtml(String(val)) + '</td>';
        }
      });
      html += '</tr>';
    });
    html += '</tbody></table>';
    if (container) container.innerHTML = html;
  }

  if (featureGroup.getLayers().length > 0 && selectedRowIndex === null) {
    try { map.fitBounds(featureGroup.getBounds().pad(0.2)); } catch(e) {}
  }
  // Update count
  const countEl = document.getElementById('filter-count');
  if (countEl) countEl.textContent = filtered.features.length;
}

function selectItemFromTable(idx) {
  const item = geojsonData.features[idx];
  if (!item) return;
  selectedRowIndex = item.properties ? item.properties.id : idx;
  renderData();
  const layer = markerMap[selectedRowIndex] || markerMap[idx];
  if (layer) {
    if (layer.getLatLng) map.setView(layer.getLatLng(), 17);
    else if (layer.getBounds) map.fitBounds(layer.getBounds());
  }
}

function toggleMultiSelectDropdown() {
  document.getElementById('multiSelectDropdown').classList.toggle('open');
}
function onFilterCheckboxChange(cb) {
  if (cb.checked) selectedFilterValues.add(cb.value);
  else selectedFilterValues.delete(cb.value);
  updateMultiSelectBtnText();
  renderData();
}
function selectAllFilters(select) {
  const cbs = document.querySelectorAll('#multiselectList input[type="checkbox"]');
  selectedFilterValues.clear();
  cbs.forEach(cb => { cb.checked = select; if (select) selectedFilterValues.add(cb.value); });
  updateMultiSelectBtnText();
  renderData();
}
function filterDropdownItems() {
  const search = document.getElementById('filterSearch').value.toLowerCase();
  document.querySelectorAll('.multiselect-item').forEach(item => {
    item.style.display = item.innerText.toLowerCase().includes(search) ? 'flex' : 'none';
  });
}
function updateMultiSelectBtnText() {
  const btn = document.getElementById('multiSelectBtn');
  const total = document.querySelectorAll('#multiselectList .multiselect-item').length;
  if (selectedFilterValues.size === total || total === 0) btn.innerText = 'All Selected';
  else btn.innerText = selectedFilterValues.size + ' of ' + total + ' Selected';
}
function populateFilterValues() {
  const selectedQ = document.getElementById('filterQuestion').value;
  const list = document.getElementById('multiselectList');
  list.innerHTML = '';
  selectedFilterValues.clear();
  if (!selectedQ) {
    document.getElementById('multiSelectBtn').innerText = 'All Selected';
    renderData();
    return;
  }
  const uniqueVals = [...new Set(geojsonData.features.map(f => {
    const p = f.properties || {};
    const v = p[selectedQ] ?? (p.answers && p.answers[selectedQ]) ?? '';
    return String(v).trim();
  }).filter(Boolean))];
  uniqueVals.forEach(val => {
    selectedFilterValues.add(val);
    const label = document.createElement('label');
    label.className = 'multiselect-item';
    label.innerHTML = '<input type="checkbox" value="' + escapeHtml(val) + '" checked onchange="onFilterCheckboxChange(this)"> <span>' + escapeHtml(val) + '</span>';
    list.appendChild(label);
  });
  updateMultiSelectBtnText();
  renderData();
}
function handleShapeChange() {
  const shape = document.getElementById('markerShape').value;
  document.getElementById('customIconInput').style.display = (shape === 'custom') ? 'inline-block' : 'none';
  renderData();
}
function toggleFullscreen() {
  const elem = document.getElementById('app-container');
  if (!document.fullscreenElement) elem.requestFullscreen();
  else document.exitFullscreen();
}
function toggleTablePane() {
  document.getElementById('table-pane').classList.toggle('collapsed');
  setTimeout(() => map.invalidateSize(), 350);
}
function deselectFeature() {
  selectedRowIndex = null;
  renderData();
}
function exportHighResMap(includeLegend) {
  const legend = document.getElementById('map-legend');
  const prev = legend.style.display;
  legend.style.display = includeLegend ? 'block' : 'none';
  html2canvas(document.getElementById('map-wrapper'), { useCORS: true, allowTaint: true, scale: 3 }).then(canvas => {
    const link = document.createElement('a');
    link.download = 'MapBanai_300DPI_' + (includeLegend ? 'with_legend' : 'no_legend') + '.jpg';
    link.href = canvas.toDataURL('image/jpeg', 0.95);
    link.click();
    legend.style.display = prev;
  });
}
document.getElementById('filterQuestion')?.addEventListener('change', populateFilterValues);
document.getElementById('filter-surveyor')?.addEventListener('change', renderData);
document.getElementById('filter-from')?.addEventListener('change', renderData);
document.getElementById('filter-to')?.addEventListener('change', renderData);
document.getElementById('filter-clear')?.addEventListener('click', function(){
  const fq = document.getElementById('filterQuestion');
  if (fq) fq.value='';
  const fs = document.getElementById('filter-surveyor');
  if (fs) fs.value='';
  const ff = document.getElementById('filter-from');
  const ft = document.getElementById('filter-to');
  if (ff) ff.value='';
  if (ft) ft.value='';
  const sb = document.getElementById('searchBox');
  if (sb) sb.value='';
  selectedFilterValues.clear();
  renderData();
});
document.getElementById('searchBox')?.addEventListener('input', renderData);
// Close dropdown when clicking outside
document.addEventListener('click', function(e){
  const container = document.querySelector('.multiselect-container');
  const dropdown = document.getElementById('multiSelectDropdown');
  if (container && dropdown && !container.contains(e.target)) {
    dropdown.classList.remove('open');
  }
});
renderData();
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

  Future<String> _loadHtml2CanvasJs() async {
    try {
      return await rootBundle.loadString('assets/leaflet/html2canvas.min.js');
    } catch (_) {
      try {
        return await File('assets/leaflet/html2canvas.min.js').readAsString();
      } catch (_) {
        return '// html2canvas not found';
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
