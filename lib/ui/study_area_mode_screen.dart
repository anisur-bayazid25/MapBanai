import 'dart:async';
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
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StudyAreaModeScreen extends StatefulWidget {
  const StudyAreaModeScreen({super.key});

  @override
  State<StudyAreaModeScreen> createState() => _StudyAreaModeScreenState();
}

class _StudyAreaModeScreenState extends State<StudyAreaModeScreen> {
  final StudyAreaStore _store = StudyAreaStore();
  final LocationService _locationService = LocationService();
  MapLibreMapController? _controller;
  bool _styleReady = false;
  String _selectedBasemapId = 'osm';
  List<StudyAreaSite> _sites = [];
  StudyAreaSite? _selectedSite;
  final Map<String, Circle> _circles = {};

  // GPS
  StreamSubscription<Position>? _posSub;
  Position? _currentPos;
  double? _distanceM;
  double? _bearingDeg;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
    _startLocation();
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    final sites = await _store.loadSites();
    if (!mounted) return;
    setState(() {
      _sites = sites;
      _isLoading = false;
    });
    if (_styleReady) _refreshMapMarkers();
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

  Future<void> _refreshMapMarkers() async {
    final controller = _controller;
    if (!_styleReady || controller == null) return;
    // Clear existing
    for (final c in _circles.values) {
      try {
        await controller.removeCircle(c);
      } catch (_) {}
    }
    _circles.clear();
    for (final site in _sites) {
      try {
        final color = site.status.mapColor;
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
      } catch (_) {}
    }
    if (mounted) setState(() {});
    // Auto fit bounds if sites exist and no selection.
    if (_sites.isNotEmpty && _selectedSite == null) {
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
    if (annotation is Circle) {
      final siteId = annotation.data?['site_id']?.toString();
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
        'csv', 'geojson', 'json', 'kml', 'kmz', 'gpkg', 'xlsx', 'shp',
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
      if (imported.isEmpty) {
        _showSnack('No sites found in file. Check format and lat/lon columns.');
        return;
      }
      // Ask replace/append
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import sites'),
          content: Text(
              'Found ${imported.length} sites in ${file.name}. How to add them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'append'),
              child: const Text('Append'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'replace'),
              child: const Text('Replace all'),
            ),
          ],
        ),
      );
      if (action == null || action == 'cancel') return;
      if (action == 'replace') {
        await _store.saveSites(imported);
      } else {
        await _store.addSites(imported, replace: false);
      }
      await _loadSites();
      _showSnack('Imported ${imported.length} sites (${action})');
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnack('Import failed: $e');
    }
  }

  Future<void> _editSite(StudyAreaSite site) async {
    final updated = await showDialog<StudyAreaSite>(
      context: context,
      builder: (context) => _EditSiteDialog(site: site),
    );
    if (updated == null) return;
    await _store.updateSite(updated);
    await _loadSites();
    setState(() => _selectedSite = updated);
    _updateBearingDistance();
    _showSnack('Site updated');
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
      } else {
        final bytes = StudyAreaService.toExcelBytes(_sites);
        file = File('${dir.path}/study_area_$stamp.xlsx');
        await file.writeAsBytes(bytes, flush: true);
      }
      await Share.shareXFiles([XFile(file.path)],
          text: 'MapBanai Study Area export');
      _showSnack('Export ready: ${file.path.split(Platform.pathSeparator).last}');
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
        content: Text('Remove all ${_sites.length} sites? This cannot be undone.'),
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
    await _store.clear();
    setState(() {
      _selectedSite = null;
      _distanceM = null;
      _bearingDeg = null;
    });
    await _loadSites();
    _showSnack('All sites cleared');
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

  void _showBasemapDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Basemap'),
        children: Basemap.defaults.map((basemap) {
          return RadioListTile<String>(
            title: Text(basemap.name),
            value: basemap.id,
            groupValue: _selectedBasemapId,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedBasemapId = value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
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
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF1565C0)),
            onPressed: _importSites,
          ),
          IconButton(
            tooltip: 'Export sites',
            icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF2E7D32)),
            onPressed: _exportSites,
          ),
          IconButton(
            tooltip: 'Basemap',
            icon: const Icon(Icons.map_outlined),
            onPressed: _showBasemapDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clearAll();
              if (v == 'fit') _fitBounds();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'fit', child: Text('Fit all sites')),
              const PopupMenuItem(value: 'clear', child: Text('Clear all sites')),
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
            onStyleLoadedCallback: _onStyleLoaded,
            styleString: _buildStyleString(basemap),
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.normal,
            compassEnabled: true,
            annotationConsumeTapEvents: const [
              AnnotationType.circle,
            ],
          ),
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

  Widget _buildHeaderCard() {
    final pending = _sites.where((s) => s.status == StudyAreaStatus.pending).length;
    final completed =
        _sites.where((s) => s.status == StudyAreaStatus.completed).length;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.explore_outlined,
                  color: Color(0xFFE65100), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_sites.length} sites',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE53935), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('Pending: $pending',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 12),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('Completed: $completed',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Export sites',
              icon: const Icon(Icons.file_upload_outlined, size: 20, color: Color(0xFF2E7D32)),
              onPressed: _exportSites,
            ),
          ],
        ),
      ),
    );
  }

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
                    color: site.status == StudyAreaStatus.completed
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE53935),
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
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
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
  final _newKeyCtrl = TextEditingController();
  final _newValCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(text: widget.site.latitude.toString());
    _lonCtrl = TextEditingController(text: widget.site.longitude.toString());
    _status = widget.site.status;
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
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
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
                items: const [
                  DropdownMenuItem(
                      value: StudyAreaStatus.pending, child: Text('Pending (Red)')),
                  DropdownMenuItem(
                      value: StudyAreaStatus.completed, child: Text('Completed (Green)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
            if (lat == null || lon == null) {
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
            final updated = StudyAreaSite(
              id: widget.site.id,
              latitude: lat,
              longitude: lon,
              attributes: attrs,
              status: _status,
            );
            Navigator.pop(context, updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
