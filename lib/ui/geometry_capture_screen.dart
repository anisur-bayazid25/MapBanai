import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/ui/common/basemap_picker.dart';

/// Captures a WGS84 GeoJSON geometry for survey or study-area forms.
/// A successful route returns the geometry map; cancellation returns null.
class GeometryCaptureScreen extends StatefulWidget {
  const GeometryCaptureScreen(
      {super.key, required this.geometryType, this.initialGeometry});

  final String geometryType;
  final Map<String, dynamic>? initialGeometry;

  @override
  State<GeometryCaptureScreen> createState() => _GeometryCaptureScreenState();
}

class _GeometryCaptureScreenState extends State<GeometryCaptureScreen> {
  final List<LatLng> _points = [];
  final List<Circle> _markers = [];
  MapLibreMapController? _map;
  Line? _line;
  Fill? _fill;
  bool _styleReady = false;
  bool _gettingGps = false;
  MapStyleChoice? _offlineBasemap;
  Future<void> _renderQueue = Future.value();

  @override
  void initState() {
    super.initState();
    final geometry = widget.initialGeometry;
    final coordinates = geometry?['coordinates'];
    final values = geometry?['type'] == 'Polygon' &&
            coordinates is List &&
            coordinates.isNotEmpty
        ? coordinates.first
        : geometry?['type'] == 'Point'
            ? [coordinates]
            : coordinates;
    if (values is List) {
      for (final value in values) {
        if (value is List &&
            value.length >= 2 &&
            value[0] is num &&
            value[1] is num) {
          final lat = (value[1] as num).toDouble();
          final lon = (value[0] as num).toDouble();
          if (lat.isFinite &&
              lon.isFinite &&
              lat >= -90 &&
              lat <= 90 &&
              lon >= -180 &&
              lon <= 180) {
            _points.add(LatLng(lat, lon));
          }
        }
      }
      if (widget.geometryType == 'Polygon' &&
          _points.length > 1 &&
          _points.first == _points.last) {
        _points.removeLast();
      }
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _addPoint(LatLng point) {
    setState(() {
      if (widget.geometryType == 'Point') {
        _points.clear();
      }
      _points.add(point);
    });
    _scheduleRender();
  }

  void _scheduleRender() {
    _renderQueue =
        _renderQueue.then((_) => _render()).catchError((Object error) {
      _message('Map preview could not update. Geometry is retained: $error');
    });
  }

  Future<void> _render() async {
    final map = _map;
    if (!mounted || !_styleReady || map == null) return;
    final points = List<LatLng>.from(_points);
    for (final marker in _markers) {
      await map.removeCircle(marker);
    }
    _markers.clear();
    if (_line != null) {
      await map.removeLine(_line!);
      _line = null;
    }
    if (_fill != null) {
      await map.removeFill(_fill!);
      _fill = null;
    }
    for (final point in points) {
      _markers.add(await map.addCircle(CircleOptions(
          geometry: point,
          circleRadius: 6,
          circleColor: '#1565C0',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2)));
    }
    if (points.length >= 2) {
      final outline = [
        ...points,
        if (widget.geometryType == 'Polygon' && points.length >= 3) points.first
      ];
      _line = await map.addLine(
          LineOptions(geometry: outline, lineWidth: 3, lineColor: '#1565C0'));
    }
    if (widget.geometryType == 'Polygon' && points.length >= 3) {
      _fill = await map.addFill(FillOptions(
          geometry: [points], fillColor: '#1565C0', fillOpacity: 0.2));
    }
  }

  Future<void> _gps({required bool addVertex}) async {
    setState(() => _gettingGps = true);
    try {
      if (!await LocationService().ensurePermission()) {
        _message('Allow location permission to use GPS.');
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _message('Turn on location services.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20));
      if (!mounted) return;
      if (!LocationService.isUsablePhotoFix(position, DateTime.now(),
          maximumAccuracy: 25)) {
        _message(
            'Wait for a fresh, accurate GPS fix (within 25 m and 30 seconds), or tap the map manually.');
        return;
      }
      final point = LatLng(position.latitude, position.longitude);
      if (addVertex) _addPoint(point);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(point, 17));
      _message('GPS accuracy: ${position.accuracy.toStringAsFixed(1)} m');
    } catch (error) {
      _message('GPS unavailable: $error');
    } finally {
      if (mounted) setState(() => _gettingGps = false);
    }
  }

  void _save() {
    final type = widget.geometryType;
    final minimum = type == 'Point'
        ? 1
        : type == 'Polygon'
            ? 3
            : 2;
    final unique = _points.map((p) => '${p.longitude},${p.latitude}').toSet();
    if (_points.length < minimum || unique.length < minimum) {
      _message('Add at least $minimum distinct vertices.');
      return;
    }
    final coordinates = _points.map((p) => [p.longitude, p.latitude]).toList();
    if (type == 'Polygon') {
      var area = 0.0;
      for (var i = 0; i < coordinates.length; i++) {
        final next = coordinates[(i + 1) % coordinates.length];
        area += coordinates[i][0] * next[1] - next[0] * coordinates[i][1];
      }
      if (area.abs() < 1e-12) {
        _message('Polygon vertices must enclose an area.');
        return;
      }
      coordinates.add(List<double>.from(coordinates.first));
    }
    final oldRings = (widget.initialGeometry?['type'] == 'Polygon')
        ? (widget.initialGeometry?['coordinates'])
        : null;
    Navigator.pop(context, <String, dynamic>{
      'type': type,
      'coordinates': type == 'Polygon'
          ? [coordinates, if (oldRings is List) ...oldRings.skip(1)]
          : type == 'Point'
              ? coordinates.first
              : coordinates
    });
  }

  @override
  Widget build(BuildContext context) {
    final basemap = Basemap.defaults
        .firstWhere((b) => b.id == 'osm', orElse: () => Basemap.defaults.first);
    final style = jsonEncode({
      'version': 8,
      'sources': {
        'basemap': {
          'type': 'raster',
          'tiles': [basemap.url],
          'tileSize': 256,
          'attribution': basemap.attribution
        }
      },
      'layers': [
        {'id': 'basemap', 'type': 'raster', 'source': 'basemap'}
      ]
    });
    return Scaffold(
        appBar: AppBar(
            actions: [
              IconButton(
                  tooltip: 'Basemap',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () async {
                    final choice = await showBasemapPicker(context,
                        selectedId: _offlineBasemap?.id ?? 'osm');
                    if (choice == null || !mounted) return;
                    setState(() {
                      _offlineBasemap = choice;
                      _styleReady = false;
                    });
                    if (choice.bounds != null)
                      await _map?.animateCamera(
                          CameraUpdate.newLatLngBounds(choice.bounds!));
                  })
            ],
            title: Text(widget.geometryType == 'Polygon'
                ? 'Collect area'
                : widget.geometryType == 'Point'
                    ? 'Collect point'
                    : 'Collect line')),
        body: Stack(children: [
          MapLibreMap(
              initialCameraPosition: CameraPosition(
                  target: _points.isEmpty
                      ? const LatLng(23.8103, 90.4125)
                      : _points.first,
                  zoom: _points.isEmpty ? 12 : 16),
              styleString: _offlineBasemap?.style ?? style,
              onMapCreated: (map) => _map = map,
              onStyleLoadedCallback: () {
                _styleReady = true;
                _scheduleRender();
              },
              onMapClick: (_, point) => _addPoint(point),
              compassEnabled: true),
          Positioned(
              left: 8,
              top: 8,
              child: OfflineBasemapNotice(choice: _offlineBasemap)),
          Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                            '${_points.length} vertices • Tap map to add vertices'),
                        const Text(
                            'Map tiles need internet. Saved geometry stays on this device.',
                            style: TextStyle(fontSize: 11)),
                        Wrap(spacing: 8, children: [
                          TextButton.icon(
                              onPressed: _gettingGps
                                  ? null
                                  : () => _gps(addVertex: false),
                              icon: const Icon(Icons.my_location),
                              label: const Text('Locate')),
                          TextButton.icon(
                              onPressed: _gettingGps
                                  ? null
                                  : () => _gps(addVertex: true),
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text('GPS vertex')),
                          TextButton(
                              onPressed: _points.isEmpty
                                  ? null
                                  : () {
                                      setState(() => _points.removeLast());
                                      _scheduleRender();
                                    },
                              child: const Text('Undo')),
                          TextButton(
                              onPressed: _points.isEmpty
                                  ? null
                                  : () {
                                      setState(() => _points.clear());
                                      _scheduleRender();
                                    },
                              child: const Text('Clear')),
                          FilledButton(
                              onPressed: _save,
                              child: const Text('Save geometry')),
                        ]),
                        if (_gettingGps) const LinearProgressIndicator(),
                      ])))),
        ]));
  }
}
