import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class GISMapScreen extends StatefulWidget {
  const GISMapScreen({super.key});

  @override
  State<GISMapScreen> createState() => _GISMapScreenState();
}

class _GISMapScreenState extends State<GISMapScreen> {
  MapLibreMapController? _controller;
  final LocationService _locationService = LocationService();
  Stream<Position>? _positionStream;
  LatLng? _currentLocation;
  bool _followMe = false;
  String _selectedBasemapId = 'osm';
  final Set<String> _visibleLayers = {'survey_points', 'survey_lines', 'survey_polygons'};

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  Future<void> _startLocationStream() async {
    try {
      _positionStream = await _locationService.getPositionStream();
      _positionStream?.listen((position) {
        if (!mounted) return;
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
        });
        if (_followMe && _controller != null) {
          _controller!.animateCamera(CameraUpdate.newLatLng(newLocation));
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: $e')),
      );
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    _addSourcesAndLayers();
    if (_currentLocation != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 16));
    }
  }

  void _addSourcesAndLayers() {
    if (_controller == null) return;
    _addSurveySources();
  }

  void _addSurveySources() {
    // TODO: Load survey data from database and add as GeoJSON sources
  }

  void _onStyleLoaded() {
    _addSourcesAndLayers();
  }

  void _toggleFollowMe() {
    setState(() {
      _followMe = !_followMe;
    });
    if (_followMe && _currentLocation != null && _controller != null) {
      _controller!.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 16));
    }
  }

  void _onBasemapChanged(String basemapId) {
    setState(() {
      _selectedBasemapId = basemapId;
    });
    // The maplibre_gl package handles basemap via style URL
    // For now we use a single style and change tile source
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectName = context.watch<ProjectState>().selectedProject;
    final basemap = Basemap.defaults.firstWhere(
      (b) => b.id == _selectedBasemapId,
      orElse: () => Basemap.defaults.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('GIS Mode - $projectName'),
        actions: [
          IconButton(
            tooltip: 'Basemap',
            icon: const Icon(Icons.map_outlined),
            onPressed: _showBasemapDialog,
          ),
          IconButton(
            tooltip: 'Layers',
            icon: const Icon(Icons.layers_outlined),
            onPressed: _showLayerDialog,
          ),
          IconButton(
            tooltip: _followMe ? 'Stop following' : 'Follow me',
            icon: Icon(_followMe ? Icons.my_location : Icons.my_location_outlined),
            onPressed: _toggleFollowMe,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(24.7433, 90.3983),
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            styleString: _buildStyleString(basemap),
          ),
          if (_currentLocation != null)
            Positioned(
              bottom: 80,
              left: 16,
              child: _buildGPSIndicator(),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
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

  Widget _buildGPSIndicator() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gps_fixed,
              color: _currentLocation != null ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _currentLocation != null
                  ? 'GPS: ${_currentLocation!.latitude.toStringAsFixed(5)}, ${_currentLocation!.longitude.toStringAsFixed(5)}'
                  : 'GPS: Searching...',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Info',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap a feature on the map to see details',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
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
                _onBasemapChanged(value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showLayerDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SimpleDialog(
          title: const Text('Map Layers'),
          children: [
            for (final layer in ['survey_points', 'survey_lines', 'survey_polygons'])
              CheckboxListTile(
                title: Text(layer.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')),
                value: _visibleLayers.contains(layer),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _visibleLayers.add(layer);
                    } else {
                      _visibleLayers.remove(layer);
                    }
                  });
                  _updateLayerVisibility();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _updateLayerVisibility() {
    if (_controller == null) return;
    for (final layer in _visibleLayers) {
      _controller!.setLayerVisibility(layer, _visibleLayers.contains(layer));
    }
  }
}