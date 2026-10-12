import 'package:mapbanai/ui/common/basemap_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/study_area_merge_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StudyAreaModeScreen extends StatefulWidget {
  const StudyAreaModeScreen(
      {super.key,
      this.store,
      this.initialSelectedSiteId,
      this.projectId,
      this.projectExternalId});

  final StudyAreaStore? store;
  final String? initialSelectedSiteId;
  final int? projectId;
  final String? projectExternalId;

  @override
  State<StudyAreaModeScreen> createState() => _StudyAreaModeScreenState();
}

class _StudyAreaModeScreenState extends State<StudyAreaModeScreen> {
  late final StudyAreaStore _store = widget.store ?? StudyAreaStore();
  final LocationService _locationService = LocationService();
  MapLibreMapController? _controller;
  bool _styleReady = false;
  String _selectedBasemapId = 'osm';
  MapStyleChoice? _offlineBasemap;
  String _fieldworker = 'Local fieldworker';
  List<StudyAreaSite> _sites = [];
  StudyAreaSite? _selectedSite;
  final Map<String, Circle> _circles = {};

  // GPS
  StreamSubscription<Position>? _posSub;
  Position? _currentPos;
  double? _distanceM;
  double? _bearingDeg;

  bool _isLoading = true;
  StudyAreaStatus? _filter;
  String? _drawType;
  StudyAreaSite? _drawingSite;
  final List<LatLng> _draft = [];
  final List<Line> _lines = [];
  final List<Fill> _fills = [];

  @override
  void initState() {
    super.initState();
    _loadSites();
    _loadOperator();
    _startLocation();
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    List<StudyAreaSite> sites;
    try {
      sites = await _store.loadSites();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Cannot load study area: $e. Stored data was preserved.');
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _sites = sites
          .where((s) =>
              widget.projectId == null ||
              (s.projectExternalId != null && widget.projectExternalId != null
                  ? s.projectExternalId == widget.projectExternalId
                  : s.projectId == null || s.projectId == widget.projectId))
          .toList();
      if (_selectedSite == null && widget.initialSelectedSiteId != null) {
        _selectedSite = _sites
            .where((s) => s.id == widget.initialSelectedSiteId)
            .firstOrNull;
      }
      _isLoading = false;
    });
    if (_styleReady) _refreshMapMarkers();
  }

  Future<void> _loadOperator() async {
    final name = await _store.getOperatorName();
    if (mounted) setState(() => _fieldworker = name);
  }

  Future<void> _editOperator() async {
    final controller = TextEditingController(text: _fieldworker);
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Fieldworker name'),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        labelText: 'Name used in change history')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: const Text('Save'))
                ]));
    // Dispose after the dialog route animation has finished using its field.
    if (name == null || name.isEmpty) return;
    await _store.setOperatorName(name);
    if (mounted) setState(() => _fieldworker = name);
  }

  void _showHistory(StudyAreaSite site) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('History: ${site.displayName}'),
                content: SizedBox(
                    width: 520,
                    height: 450,
                    child: site.history.isEmpty
                        ? const Text(
                            'No recorded changes yet. Imported baseline is preserved when the first edit is saved.')
                        : ListView(
                            children: site.history.reversed
                                .map((revision) => ExpansionTile(title: Text('${revision.action} • ${revision.author}'), subtitle: Text('${revision.timestamp.toLocal()}${revision.visitId == null ? '' : '\nVisit: ${revision.visitId}'}'), children: [
                                      if (revision.before != null) ...[
                                        const Text('Before',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        SelectableText(
                                            const JsonEncoder.withIndent('  ')
                                                .convert(revision.before))
                                      ],
                                      const Text('After',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SelectableText(
                                          const JsonEncoder.withIndent('  ')
                                              .convert(revision.after)),
                                      if (revision.sessionId != null)
                                        Text(
                                            'Survey response: ${revision.sessionId}'),
                                      if (revision.photoPath != null)
                                        Text('Photo: ${revision.photoPath}')
                                    ]))
                                .toList())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'))
                ]));
  }

  Future<void> _startLocation() async {
    final granted = await _locationService.ensurePermission();
    if (!granted || !mounted) return;
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _currentPos = pos);
      _updateBearingDistance();
    });
  }

  void _updateBearingDistance() {
    final pos = _currentPos;
    final site = _selectedSite;
    if (pos == null || site == null) {
      setState(() {
        _distanceM = null;
        _bearingDeg = null;
      });
      return;
    }
    final d = StudyAreaService.distanceMeters(
        pos.latitude, pos.longitude, site.latitude, site.longitude);
    final b = StudyAreaService.bearingDegrees(
        pos.latitude, pos.longitude, site.latitude, site.longitude);
    setState(() {
      _distanceM = d;
      _bearingDeg = b;
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onFeatureTapped.add(_onFeatureTapped);
  }

  void _onStyleLoaded() {
    _styleReady = true;
    _refreshMapMarkers();
  }

  Future<void> _mapUpdates = Future.value();

  Future<void> _refreshMapMarkers() {
    _mapUpdates =
        _mapUpdates.then((_) => _renderMapMarkers()).catchError((Object error) {
      _showSnack('Map preview failed: $error. Stored features are retained.');
    });
    return _mapUpdates;
  }

  Future<void> _renderMapMarkers() async {
    final controller = _controller;
    if (!mounted || !_styleReady || controller == null) return;
    // Clear existing
    for (final c in _circles.values) {
      try {
        await controller.removeCircle(c);
      } catch (_) {}
    }
    _circles.clear();
    for (final line in _lines) {
      try {
        await controller.removeLine(line);
      } catch (_) {}
    }
    for (final fill in _fills) {
      try {
        await controller.removeFill(fill);
      } catch (_) {}
    }
    _lines.clear();
    _fills.clear();
    for (final site
        in _sites.where((s) => _filter == null || s.status == _filter)) {
      try {
        final color = site.status.mapColor;
        List<LatLng> points(dynamic values) => (values as List)
            .map((v) =>
                LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble()))
            .toList();
        final data = {'site_id': site.id};
        Future<void> drawGeometry(Map geom) async {
          final coords = geom['coordinates'];
          if (geom['type'] == 'GeometryCollection') {
            for (final child in geom['geometries'] as List) {
              await drawGeometry(child as Map);
            }
          } else if (geom['type'] == 'Point' || geom['type'] == 'MultiPoint') {
            final vertices =
                geom['type'] == 'Point' ? [coords] : coords as List;
            for (final vertex in vertices) {
              final circle = await controller.addCircle(
                  CircleOptions(
                      geometry: LatLng((vertex[1] as num).toDouble(),
                          (vertex[0] as num).toDouble()),
                      circleRadius: 8,
                      circleColor: color,
                      circleStrokeColor: '#FFFFFF',
                      circleStrokeWidth: 2),
                  data);
              _circles['${site.id}_${_circles.length}'] = circle;
            }
          } else if (geom['type'] == 'LineString' ||
              geom['type'] == 'MultiLineString') {
            final lines =
                geom['type'] == 'LineString' ? [coords] : coords as List;
            for (final line in lines) {
              _lines.add(await controller.addLine(
                  LineOptions(
                      geometry: points(line), lineColor: color, lineWidth: 3),
                  data));
            }
          } else if (geom['type'] == 'Polygon' ||
              geom['type'] == 'MultiPolygon') {
            final polygons =
                geom['type'] == 'Polygon' ? [coords] : coords as List;
            for (final polygon in polygons) {
              _fills.add(await controller.addFill(
                  FillOptions(
                      geometry: (polygon as List).map(points).toList(),
                      fillColor: color,
                      fillOpacity: 0.25,
                      fillOutlineColor: color),
                  data));
            }
          }
        }

        await drawGeometry(site.currentGeometry);
        if (site.currentGeometry['type'] != 'Point' &&
            site.currentGeometry['type'] != 'MultiPoint') {
          final circle = await controller.addCircle(
            CircleOptions(
              geometry: LatLng(site.latitude, site.longitude),
              circleRadius: 8,
              circleColor: color,
              circleStrokeWidth: 2,
              circleStrokeColor: '#FFFFFF',
              draggable: false,
            ),
            {'site_id': site.id},
          );
          _circles[site.id] = circle;
        }
      } catch (_) {}
    }
    if (_drawType != null && _draft.length >= 2) {
      _lines.add(await controller.addLine(LineOptions(geometry: [
        ..._draft,
        if (_drawType == 'Polygon' && _draft.length >= 3) _draft.first
      ], lineColor: '#FF6F00', lineWidth: 4)));
    }
    if (mounted) setState(() {});
    // Auto fit bounds if sites exist and no selection.
    if (_sites.isNotEmpty && _selectedSite == null && _drawType == null) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_sites.isEmpty || _controller == null) return;
    if (_sites.length == 1) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(_sites.first.latitude, _sites.first.longitude), 15),
      );
      return;
    }
    double minLat = _sites.first.latitude;
    double maxLat = _sites.first.latitude;
    double minLon = _sites.first.longitude;
    double maxLon = _sites.first.longitude;
    for (final s in _sites) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLon) minLon = s.longitude;
      if (s.longitude > maxLon) maxLon = s.longitude;
    }
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;
    _controller!.animateCamera(
      CameraUpdate.newLatLng(LatLng(centerLat, centerLon)),
    );
  }

  void _onFeatureTapped(dynamic point, LatLng coordinates, String id,
      String layerId, Annotation? annotation) {
    if (_drawType != null) return;
    if (annotation != null) {
      final data = switch (annotation) {
        Circle c => c.data,
        Line l => l.data,
        Fill f => f.data,
        _ => null
      };
      final siteId = data?['site_id']?.toString();
      if (siteId == null) return;
      final site = _sites.where((s) => s.id == siteId).firstOrNull;
      if (site == null) return;
      setState(() {
        _selectedSite = site;
      });
      _updateBearingDistance();
    }
  }

  Future<void> _importSites() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'csv',
        'geojson',
        'json',
        'kml',
        'kmz',
        'gpkg',
        'xlsx',
        'shp',
      ],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) {
      _showSnack('Could not read file path');
      return;
    }
    final ioFile = File(path);
    if (!ioFile.existsSync()) {
      _showSnack('File not found');
      return;
    }
    final ext = path.split('.').last.toLowerCase();
    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loadingDialogOpen = true;
    try {
      List<StudyAreaSite> imported = [];
      if (ext == 'csv') {
        final text = await ioFile.readAsString();
        imported = StudyAreaService.parseCsv(text);
      } else if (ext == 'geojson' || ext == 'json') {
        final text = await ioFile.readAsString();
        final trimmed = text.trimLeft();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          imported = StudyAreaService.parseGeoJson(text);
        } else {
          imported = StudyAreaService.parseCsv(text);
        }
      } else if (ext == 'kml') {
        final text = await ioFile.readAsString();
        imported = StudyAreaService.parseKml(text);
      } else if (ext == 'kmz') {
        final bytes = await ioFile.readAsBytes();
        imported = StudyAreaService.parseKmzBytes(bytes);
      } else if (ext == 'shp') {
        imported = StudyAreaService.parseShapefile(ioFile);
      } else if (ext == 'gpkg') {
        imported = await StudyAreaService.parseGeoPackage(ioFile);
      } else if (ext == 'xlsx') {
        final bytes = await ioFile.readAsBytes();
        imported = StudyAreaService.parseXlsxBytes(bytes);
      } else {
        // Fallback try all
        try {
          final text = await ioFile.readAsString();
          imported = StudyAreaService.parseCsv(text);
        } catch (_) {
          imported = await StudyAreaService.parseGeoPackage(ioFile);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      loadingDialogOpen = false;
      if (imported.isEmpty) {
        _showSnack('No sites found in file. Check format and lat/lon columns.');
        return;
      }
      for (final site in imported) {
        if (site.projectExternalId == null ||
            site.projectExternalId == widget.projectExternalId) {
          site.projectId = widget.projectId;
          site.projectExternalId ??= widget.projectExternalId;
        } else {
          site.projectId = null;
        }
      }
      final preview = await _store.previewMerge(imported);
      if (!mounted) return;
      final choices = await showDialog<Map<String, StudyAreaMergeChoice>>(
          context: context,
          builder: (_) => StudyAreaMergeReviewDialog(preview: preview));
      if (choices == null) return;
      final merged = await _store.applyMerge(preview,
          resolutions: choices, author: _fieldworker);
      await _loadSites();
      _showSnack(
          'Imported ${merged.added} new features, updated ${merged.updated}, kept ${merged.kept} local versions.');
    } catch (e) {
      if (mounted && loadingDialogOpen) Navigator.of(context).pop();
      _showSnack('Import failed: $e');
    }
  }

  Future<bool> _editSite(StudyAreaSite site) async {
    var draft = site;
    while (mounted) {
      final updated = await showDialog<StudyAreaSite>(
          context: context, builder: (context) => _EditSiteDialog(site: draft));
      if (updated == null) return false;
      try {
        await _store.updateSite(updated,
            expectedRevision: site.revision,
            expectedRevisionId: site.revisionToken,
            author: _fieldworker);
      } on StudyAreaConflict {
        final preview = await _store.previewMerge([updated]);
        if (!mounted) return false;
        final choices = await showDialog<Map<String, StudyAreaMergeChoice>>(
            context: context,
            builder: (_) => StudyAreaMergeReviewDialog(preview: preview));
        if (choices == null) return false;
        try {
          await _store.applyMerge(preview,
              resolutions: choices, author: _fieldworker);
        } catch (e) {
          _showSnack('Conflict resolution failed: $e');
          draft = updated;
          continue;
        }
        await _loadSites();
        if (!mounted) return true;
        setState(() =>
            _selectedSite = _sites.where((s) => s.id == site.id).firstOrNull);
        return true;
      } catch (e) {
        _showSnack('Save failed: $e. Your edits are retained.');
        draft = updated;
        continue;
      }
      await _loadSites();
      if (!mounted) return true;
      setState(() => _selectedSite = updated);
      _updateBearingDistance();
      _showSnack('Feature saved');
      return true;
    }
    return false;
  }

  void _startDrawing(String type, {StudyAreaSite? site}) {
    _draft.clear();
    if (site != null) {
      final coordinates = site.currentGeometry['coordinates'];
      final values =
          type == 'Polygon' ? (coordinates as List).first : coordinates;
      for (final value in values as List) {
        _draft.add(
            LatLng((value[1] as num).toDouble(), (value[0] as num).toDouble()));
      }
      if (type == 'Polygon' && _draft.length > 1 && _draft.first == _draft.last)
        _draft.removeLast();
    }
    setState(() {
      _drawType = type;
      _drawingSite = site;
      _selectedSite = null;
    });
    _refreshMapMarkers();
  }

  Future<void> _saveDrawing() async {
    final type = _drawType;
    if (type == null || _draft.length < (type == 'Polygon' ? 3 : 2)) {
      _showSnack('Add at least ${type == 'Polygon' ? 3 : 2} vertices.');
      return;
    }
    final points = _draft.map((p) => [p.longitude, p.latitude]).toList();
    if (_draft.map((p) => '${p.longitude},${p.latitude}').toSet().length <
        (type == 'Polygon' ? 3 : 2)) {
      _showSnack('Use distinct vertices.');
      return;
    }
    if (type == 'Polygon') {
      var area = 0.0;
      for (var i = 0; i < points.length; i++) {
        final next = points[(i + 1) % points.length];
        area += points[i][0] * next[1] - next[0] * points[i][1];
      }
      if (area.abs() < 1e-12) {
        _showSnack('Polygon vertices must enclose an area.');
        return;
      }
      points.add(List<double>.from(points.first));
    }
    final geometry = <String, dynamic>{
      'type': type,
      'coordinates': type == 'Polygon'
          ? [
              points,
              if (_drawingSite?.currentGeometry['type'] == 'Polygon')
                ...(_drawingSite!.currentGeometry['coordinates'] as List)
                    .skip(1)
            ]
          : points
    };
    final previous = _drawingSite;
    final site = StudyAreaSite(
        id: previous?.id ?? 'new_${DateTime.now().microsecondsSinceEpoch}',
        latitude: _draft.first.latitude,
        longitude: _draft.first.longitude,
        geometry: geometry,
        attributes: previous == null
            ? {'name': 'New feature'}
            : Map.from(previous.attributes),
        sourceProperties: previous?.sourceProperties,
        revision: previous?.revision ?? 0,
        revisionId: previous?.revisionId,
        history: previous?.history,
        projectId: previous?.projectId ?? widget.projectId,
        projectExternalId:
            previous?.projectExternalId ?? widget.projectExternalId,
        original: previous == null
            ? null
            : previous.original ??
                {
                  'geometry': previous.currentGeometry,
                  'attributes': Map.from(previous.attributes),
                  'status': previous.status.name
                },
        updatedAt: DateTime.now().toUtc(),
        changeNote: previous?.changeNote ?? '',
        status: previous == null
            ? StudyAreaStatus.newFeature
            : StudyAreaStatus.updated);
    final saved = await _editSite(site);
    if (!mounted || !saved) return;
    setState(() {
      _drawType = null;
      _drawingSite = null;
      _draft.clear();
    });
    _refreshMapMarkers();
  }

  Future<void> _addSite(LatLng coordinates, {Position? gps}) async {
    final site = StudyAreaSite(
        id: 'new_${DateTime.now().microsecondsSinceEpoch}',
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        status: StudyAreaStatus.newFeature,
        projectId: widget.projectId,
        projectExternalId: widget.projectExternalId,
        updatedAt: DateTime.now().toUtc(),
        attributes: {
          'name': 'New feature',
          if (gps != null) 'gps_accuracy_m': gps.accuracy.toString(),
          if (gps != null)
            'gps_captured_at': gps.timestamp.toUtc().toIso8601String()
        });
    await _editSite(site);
  }

  Future<void> _deleteSite(StudyAreaSite site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete site'),
        content: Text('Delete "${site.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.deleteSite(site.id);
    setState(() => _selectedSite = null);
    await _loadSites();
    _showSnack('Site deleted');
  }

  Future<void> _exportSites() async {
    if (_sites.isEmpty) {
      _showSnack('No sites to export');
      return;
    }
    final format = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Export sites'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'changes'),
              child: ListTile(
                  leading: const Icon(Icons.difference_outlined),
                  title: const Text('Changed features only (GeoJSON)'),
                  subtitle: Text(
                      '${_sites.where((s) => s.hasChanges).length} features, full history for team merge'))),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'geojson'),
              child: const ListTile(
                  leading: Icon(Icons.map_outlined),
                  title: Text('Updated map (GeoJSON)'),
                  subtitle:
                      Text('Full geometry, attributes and revision baseline'))),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'html'),
              child: const ListTile(
                  leading: Icon(Icons.public),
                  title: Text('Portable HTML map'),
                  subtitle: Text('View and filter features in a browser'))),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: const ListTile(
              leading: Icon(Icons.table_chart_outlined),
              title: Text('CSV'),
              subtitle: Text('Excel-compatible CSV'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'xlsx'),
            child: const ListTile(
              leading: Icon(Icons.grid_on_outlined),
              title: Text('Excel (XLSX)'),
              subtitle: Text('Native Excel workbook'),
            ),
          ),
        ],
      ),
    );
    if (format == null) return;
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final dir = await getTemporaryDirectory();
      late File file;
      if (format == 'csv') {
        final csv = StudyAreaService.toCsv(_sites);
        file = File('${dir.path}/study_area_$stamp.csv');
        await file.writeAsString(csv, flush: true);
      } else if (format == 'geojson' ||
          format == 'html' ||
          format == 'changes') {
        file = File(
            '${dir.path}/study_area_${format == 'changes' ? 'changes_' : ''}$stamp.${format == 'changes' ? 'geojson' : format}');
        await file.writeAsString(
            format == 'geojson' || format == 'changes'
                ? StudyAreaService.toGeoJson(_sites,
                    changedOnly: format == 'changes')
                : await StudyAreaService.toHtml(_sites),
            flush: true);
      } else {
        final bytes = StudyAreaService.toExcelBytes(_sites);
        file = File('${dir.path}/study_area_$stamp.xlsx');
        await file.writeAsBytes(bytes, flush: true);
      }
      await Share.shareXFiles([XFile(file.path)],
          text: 'MapBanai Study Area export');
      _showSnack(
          'Export ready: ${file.path.split(Platform.pathSeparator).last}');
    } catch (e) {
      _showSnack('Export failed: $e');
    }
  }

  Future<void> _clearAll() async {
    if (_sites.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all sites'),
        content:
            Text('Remove all ${_sites.length} sites? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _store.deleteSites(_sites.map((site) => site.id).toSet());
    } catch (error) {
      _showSnack('Could not clear sites: $error');
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedSite = null;
      _distanceM = null;
      _bearingDeg = null;
    });
    await _loadSites();
    _showSnack('Displayed sites cleared');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _buildStyleString(Basemap basemap) {
    return '''

    {

      "version": 8,

      "sources": {

        "basemap": {

          "type": "raster",

          "tiles": ["${basemap.url}"],

          "tileSize": 256,

          "attribution": "${basemap.attribution}"

        }

      },

      "layers": [

        {

          "id": "basemap",

          "type": "raster",

          "source": "basemap",

          "minzoom": 0,

          "maxzoom": 22

        }

      ]

    }

    ''';
  }

  Future<void> _showBasemapDialog() async {
    final choice =
        await showBasemapPicker(context, selectedId: _selectedBasemapId);
    if (choice == null || !mounted) return;
    setState(() {
      _selectedBasemapId = choice.id;
      _offlineBasemap = choice;
    });
    if (choice.bounds != null) {
      await _controller
          ?.animateCamera(CameraUpdate.newLatLngBounds(choice.bounds!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final basemap = Basemap.defaults.firstWhere(
      (b) => b.id == _selectedBasemapId,
      orElse: () => Basemap.defaults.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Area Mode'),
        actions: [
          IconButton(
            tooltip: 'Import sites',
            icon: const Icon(Icons.file_download_outlined,
                color: Color(0xFF1565C0)),
            onPressed: _importSites,
          ),
          IconButton(
            tooltip: 'Export sites',
            icon: const Icon(Icons.file_upload_outlined,
                color: Color(0xFF2E7D32)),
            onPressed: _exportSites,
          ),
          IconButton(
            tooltip: 'Basemap',
            icon: const Icon(Icons.map_outlined),
            onPressed: _showBasemapDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'operator') _editOperator();
              if (v == 'line') _startDrawing('LineString');
              if (v == 'polygon') _startDrawing('Polygon');
              if (v == 'clear') _clearAll();
              if (v == 'fit') _fitBounds();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'operator', child: Text('Fieldworker: $_fieldworker')),
              const PopupMenuItem(
                  value: 'line', child: Text('Add line (tap vertices)')),
              const PopupMenuItem(
                  value: 'polygon', child: Text('Add polygon (tap vertices)')),
              const PopupMenuItem(value: 'fit', child: Text('Fit all sites')),
              const PopupMenuItem(
                  value: 'clear', child: Text('Clear all sites')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _currentPos != null
                  ? LatLng(_currentPos!.latitude, _currentPos!.longitude)
                  : const LatLng(23.8103, 90.4125),
              zoom: 12,
            ),
            onMapCreated: _onMapCreated,
            onMapClick: (_, coordinates) {
              if (_drawType != null) {
                setState(() => _draft.add(coordinates));
                _refreshMapMarkers();
              }
            },
            onMapLongClick: (_, coordinates) {
              if (_drawType == null) _addSite(coordinates);
            },
            onStyleLoadedCallback: _onStyleLoaded,
            styleString: _offlineBasemap?.style ?? _buildStyleString(basemap),
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.normal,
            compassEnabled: true,
            annotationConsumeTapEvents: const [
              AnnotationType.circle,
              AnnotationType.line,
              AnnotationType.fill,
            ],
          ),
          Positioned(
              left: 8,
              bottom: 8,
              child: OfflineBasemapNotice(choice: _offlineBasemap)),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_sites.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.location_off_outlined,
                          size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'No sites yet',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Import sites from CSV, GeoJSON, KML/KMZ, SHP, GeoPackage or Excel. Lat/Lon, X/Y and WKT columns are recognized.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _importSites,
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Import sites'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildHeaderCard(),
          ),
          if (_drawType != null)
            Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              '$_drawType: ${_draft.length} vertices. Tap map to add vertices.'),
                          Wrap(spacing: 8, children: [
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    _drawType = null;
                                    _drawingSite = null;
                                    _draft.clear();
                                  });
                                  _refreshMapMarkers();
                                },
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () {
                                  if (_draft.isNotEmpty)
                                    setState(() => _draft.removeLast());
                                  _refreshMapMarkers();
                                },
                                child: const Text('Undo')),
                            FilledButton(
                                onPressed: _saveDrawing,
                                child: const Text('Save feature'))
                          ]),
                        ])))),
          if (_selectedSite != null)
            Positioned(
              left: 12,
              right: 72,
              bottom: 12,
              child: _buildSelectedPanel(),
            ),
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'add_sa',
                  tooltip: 'Add feature at GPS',
                  onPressed: () {
                    final pos = _currentPos;
                    if (pos == null ||
                        DateTime.now().difference(pos.timestamp).inSeconds >
                            60) {
                      _showSnack(
                          'Wait for a current GPS fix, or long-press the map to add a point.');
                      return;
                    }
                    _addSite(LatLng(pos.latitude, pos.longitude), gps: pos);
                  },
                  child: const Icon(Icons.add_location_alt_outlined),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'locate_sa',
                  tooltip: 'Center on GPS',
                  onPressed: () {
                    final pos = _currentPos;
                    if (pos == null) {
                      _showSnack('Waiting for GPS fix');
                      return;
                    }
                    _controller?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                          LatLng(pos.latitude, pos.longitude), 16),
                    );
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fit_sa',
                  tooltip: 'Fit all sites',
                  onPressed: _fitBounds,
                  child: const Icon(Icons.center_focus_strong_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _sites.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _importSites,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Import'),
            ),
    );
  }

  Widget _buildHeaderCard() => Card(
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_sites.length} features • Long-press map to add',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                DropdownButton<StudyAreaStatus>(
                    value: _filter,
                    isExpanded: true,
                    hint: const Text('All verification statuses'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All features')),
                      ...StudyAreaStatus.values.map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                              '${status.label}: ${_sites.where((s) => s.status == status).length}',
                              style: TextStyle(
                                  color: Color(int.parse(
                                      status.colorHex.replaceFirst('#', 'FF'),
                                      radix: 16))))))
                    ],
                    onChanged: (value) {
                      setState(() => _filter = value);
                      _refreshMapMarkers();
                    }),
              ])));

  Widget _buildSelectedPanel() {
    final site = _selectedSite!;
    final pos = _currentPos;
    final dist = _distanceM;
    final bear = _bearingDeg;
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                        site.status.colorHex.replaceFirst('#', 'FF'),
                        radix: 16)),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    site.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(site.status.label,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: site.status == StudyAreaStatus.completed
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  side: BorderSide(
                      color: site.status == StudyAreaStatus.completed
                          ? Colors.green.shade200
                          : Colors.red.shade200),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _selectedSite = null;
                    _distanceM = null;
                    _bearingDeg = null;
                  }),
                ),
              ],
            ),
            Text(
              '${site.latitude.toStringAsFixed(6)}, ${site.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            if (site.attributes.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...site.attributes.entries.take(4).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            e.key,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value.isEmpty ? '—' : e.value,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (site.attributes.length > 4)
                Text('+ ${site.attributes.length - 4} more attributes',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
            if (site.currentGeometry['type'] == 'LineString' ||
                site.currentGeometry['type'] == 'Polygon')
              TextButton.icon(
                  onPressed: () => _startDrawing(
                      site.currentGeometry['type'] as String,
                      site: site),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Redraw geometry')),
            TextButton.icon(
                onPressed: () => _showHistory(site),
                icon: const Icon(Icons.history),
                label: Text('Revision history (${site.history.length})')),
            const Divider(height: 16),
            if (pos == null)
              Row(
                children: [
                  Icon(Icons.gps_off, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text('Waiting for GPS fix…',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade700)),
                ],
              )
            else if (dist != null && bear != null) ...[
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade50,
                        ),
                        child: const Icon(Icons.navigation_outlined,
                            size: 14, color: Colors.grey),
                      ),
                      Transform.rotate(
                        angle: bear * math.pi / 180,
                        child: Icon(Icons.navigation,
                            size: 28, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StudyAreaService.formatDistance(dist),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          StudyAreaService.formatBearing(bear),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        Text(
                          'From GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editSite(site),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    onPressed: () => _deleteSite(site),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  if (pos != null) {
                    _controller?.animateCamera(
                      CameraUpdate.newLatLng(
                          LatLng(site.latitude, site.longitude)),
                    );
                  }
                },
                icon: const Icon(Icons.center_focus_strong_outlined, size: 16),
                label: const Text('Center on site'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _EditSiteDialog extends StatefulWidget {
  final StudyAreaSite site;

  const _EditSiteDialog({required this.site});

  @override
  State<_EditSiteDialog> createState() => _EditSiteDialogState();
}

class _EditSiteDialogState extends State<_EditSiteDialog> {
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late StudyAreaStatus _status;
  late List<MapEntry<String, TextEditingController>> _attrControllers;
  final _noteCtrl = TextEditingController();
  final _newKeyCtrl = TextEditingController();
  final _newValCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(text: widget.site.latitude.toString());
    _lonCtrl = TextEditingController(text: widget.site.longitude.toString());
    _status = widget.site.status;
    _noteCtrl.text = widget.site.changeNote;
    _attrControllers = widget.site.attributes.entries
        .map((e) => MapEntry(e.key, TextEditingController(text: e.value)))
        .toList();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    for (final e in _attrControllers) {
      e.value.dispose();
    }
    _noteCtrl.dispose();
    _newKeyCtrl.dispose();
    _newValCtrl.dispose();
    super.dispose();
  }

  void _addAttribute() {
    final key = _newKeyCtrl.text.trim();
    if (key.isEmpty) return;
    if (_attrControllers.any((e) => e.key.toLowerCase() == key.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attribute "$key" already exists')),
      );
      return;
    }
    setState(() {
      _attrControllers.add(
          MapEntry(key, TextEditingController(text: _newValCtrl.text.trim())));
      _newKeyCtrl.clear();
      _newValCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit site ${widget.site.id}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latCtrl,
                      enabled: widget.site.currentGeometry['type'] == 'Point',
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lonCtrl,
                      enabled: widget.site.currentGeometry['type'] == 'Point',
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StudyAreaStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: StudyAreaStatus.values
                    .map((status) => DropdownMenuItem(
                        value: status, child: Text(status.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 12),
              if (widget.site.currentGeometry['type'] != 'Point')
                const Text(
                    'Full line/polygon geometry is retained. Coordinates show its reference vertex.',
                    style: TextStyle(fontSize: 12)),
              if (widget.site.original != null)
                ExpansionTile(
                    title: const Text('Original imported data'),
                    children: [
                      SelectableText(widget.site.original.toString())
                    ]),
              TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Verification / change note'),
                  maxLines: 2),
              const SizedBox(height: 12),
              Text('Attributes',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_attrControllers.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('No attributes',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
              for (int i = 0; i < _attrControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          _attrControllers[i].key,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _attrControllers[i].value,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _attrControllers[i].value.dispose();
                            _attrControllers.removeAt(i);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newKeyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'New key',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _newValCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addAttribute,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final lat = double.tryParse(_latCtrl.text.trim());
            final lon = double.tryParse(_lonCtrl.text.trim());
            if (lat == null || lon == null || !lat.isFinite || !lon.isFinite) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid coordinates')),
              );
              return;
            }
            if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coordinates out of range')),
              );
              return;
            }
            final attrs = {
              for (final e in _attrControllers) e.key: e.value.text.trim()
            };
            final updated = widget.site.revised(
              latitude: lat,
              longitude: lon,
              attributes: attrs,
              status: _status,
              changeNote: _noteCtrl.text.trim(),
            );
            Navigator.pop(context, updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
