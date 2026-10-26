import 'package:mapbanai/services/study_feature_policy.dart';
import 'package:mapbanai/services/study_category_style.dart';
import 'package:mapbanai/services/road_routing_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/spatial_file_import.dart';
import 'package:mapbanai/ui/site_timeline_screen.dart';
import 'package:mapbanai/services/form_attribute_service.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/ui/common/project_workspace_bar.dart';
import 'package:mapbanai/ui/common/form_attribute_editor.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:provider/provider.dart';
import 'package:mapbanai/ui/common/basemap_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/study_area_merge_dialog.dart';
import 'package:mapbanai/ui/project_vector_layers_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class StudyAreaModeScreen extends StatefulWidget {
  const StudyAreaModeScreen(
      {super.key,
      this.store,
      this.initialSelectedSiteId,
      this.projectId,
      this.database,
      this.projectExternalId,
      this.initialImportPath,
      this.viewOnly = false});

  final String? initialImportPath;
  final bool viewOnly;
  final StudyAreaStore? store;
  final String? initialSelectedSiteId;
  final int? projectId;
  final AppDatabase? database;
  final String? projectExternalId;

  @override
  State<StudyAreaModeScreen> createState() => _StudyAreaModeScreenState();
}

class _StudyAreaModeScreenState extends State<StudyAreaModeScreen> {
  late final StudyAreaStore _store = widget.store ?? StudyAreaStore();
  late final AppDatabase _database = widget.database ?? AppDatabase();
  ProjectWorkspace? _workspace;
  final LocationService _locationService = LocationService();
  MapLibreMapController? _controller;
  bool _styleReady = false;
  String _selectedBasemapId = 'osm';
  MapStyleChoice? _offlineBasemap;
  String _fieldworker = 'Local fieldworker';
  List<StudyAreaSite> _sites = [];
  StudyAreaSite? _selectedSite;
  final Map<String, Circle> _circles = {};
  final List<Circle> _referenceCircles = [];
  final List<Line> _referenceLines = [];
  final List<Fill> _referenceFills = [];
  final List<Symbol> _referenceSymbols = [];
  List<Map<String, dynamic>> _referenceLayers = [];
  final List<Symbol> _symbols = [];
  final Set<String> _markerImages = {};
  StudyAreaSite? _movingSite;
  LatLng? _movingCoordinates;
  Line? _routeLine;
  String? _routeSiteId;
  double? _routeDistanceM;
  List<LatLng>? _routeCoordinates;

  // GPS
  StreamSubscription<Position>? _posSub;
  Position? _currentPos;

  bool _isLoading = true;
  StudyAreaStatus? _filter;
  StudyCategoryStyle _categoryStyle = StudyCategoryStyle();
  String? _categoryWorkspaceKey;
  String? _drawType;
  StudyAreaSite? _drawingSite;
  final List<LatLng> _draft = [];
  final List<Line> _lines = [];
  final List<Fill> _fills = [];

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
    _loadOperator();
    _startLocation();
  }

  Future<void> _loadWorkspace() async {
    try {
      int? id = widget.projectId;
      if (id == null) {
        try {
          id = context.read<ProjectState>().selectedProjectId;
        } catch (_) {}
      }
      if (id != null && !widget.viewOnly)
        _workspace = await ProjectWorkspaceService(_database).load(id);
      await _loadSites();
      if (widget.initialImportPath != null && !widget.viewOnly)
        await _importSites(pathOverride: widget.initialImportPath);
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Cannot load project: $error');
      }
    }
  }

  Future<void> _changeWorkspace(ProjectWorkspace workspace) async {
    if (!mounted) return;
    setState(() {
      _workspace = workspace;
      _selectedSite = null;
    });
    try {
      context.read<ProjectState>().setSelectedProject(workspace.project.name,
          projectId: workspace.project.id);
    } catch (_) {}
    await _loadSites();
    if (_sites.isNotEmpty) _fitBounds();
  }

  Future<void> _claimLegacy() async {
    final workspace = _workspace;
    if (workspace == null) {
      _showSnack('Select a project first');
      return;
    }
    final sites = (await _store.loadSites())
        .where((s) => s.projectId == null && s.projectExternalId == null)
        .toList();
    if (!mounted || sites.isEmpty) {
      _showSnack('No unassigned sites');
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Assign previous sites'),
                content: Text(
                    'Move ${sites.length} unassigned sites into ${workspace.project.name} / ${workspace.layer.name}? Their original data and history will be kept.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Assign'))
                ]));
    if (ok != true) return;
    await _store.assignUnclaimedSites(
        projectId: workspace.project.id,
        projectExternalId: workspace.project.externalId!,
        layerId: workspace.layerId);
    await _loadSites();
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
    try {
      _referenceLayers = _workspace == null || widget.viewOnly
          ? []
          : await ProjectVectorLayerService(_database)
              .load(_workspace!.project.id);
    } catch (_) {
      _referenceLayers = [];
    }
    final styleKey =
        'study_category:${_workspace?.project.externalId}:${_workspace?.layerId}';
    if (_categoryWorkspaceKey != styleKey) {
      _categoryWorkspaceKey = styleKey;
      final saved =
          widget.viewOnly ? null : await _database.getSetting(styleKey);
      try {
        _categoryStyle = saved == null
            ? StudyCategoryStyle()
            : StudyCategoryStyle.fromJson(jsonDecode(saved));
      } catch (_) {
        _categoryStyle = StudyCategoryStyle();
      }
    }
    if (!mounted) return;
    setState(() {
      _sites = widget.viewOnly
          ? sites
          : _workspace == null
              ? []
              : sites
                  .where((site) =>
                      GuidedVisitService.belongsToProject(
                          site, _workspace!.project) &&
                      site.layerId == _workspace!.layerId)
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
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    if (widget.database == null) _database.close();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onFeatureTapped.add(_onFeatureTapped);
  }

  Uint8List _markerImage(StudyAreaStatus status, String fillHex) {
    final image = img.Image(width: 44, height: 44, numChannels: 4);
    final fill = int.parse(fillHex.substring(1), radix: 16);
    final fillR = (fill >> 16) & 255,
        fillG = (fill >> 8) & 255,
        fillB = fill & 255;
    final borderHex = switch (status.verificationStatus) {
      StudyAreaStatus.pending => '#E53935',
      StudyAreaStatus.completed => '#2E7D32',
      StudyAreaStatus.needsReview => '#F9A825',
      _ => '#616161',
    };
    final border = int.parse(borderHex.substring(1), radix: 16);
    final borderR = (border >> 16) & 255,
        borderG = (border >> 8) & 255,
        borderB = border & 255;
    bool inside(double x, double y) {
      switch (status.verificationStatus) {
        case StudyAreaStatus.pending:
          final dx = x - 22, dy = y - 22;
          return dx * dx + dy * dy <= 19 * 19;
        case StudyAreaStatus.completed:
          return x >= 5 && x <= 39 && y >= 5 && y <= 39;
        case StudyAreaStatus.needsReview:
          final a = (22.0, 3.0), b = (41.0, 39.0), c = (3.0, 39.0);
          final d1 = (x - b.$1) * (a.$2 - b.$2) + (a.$1 - b.$1) * (y - b.$2);
          final d2 = (x - c.$1) * (b.$2 - c.$2) + (b.$1 - c.$1) * (y - c.$2);
          final d3 = (x - a.$1) * (c.$2 - a.$2) + (c.$1 - a.$1) * (y - a.$2);
          return !((d1 < 0 || d2 < 0 || d3 < 0) &&
              (d1 > 0 || d2 > 0 || d3 > 0));
        default:
          return false;
      }
    }

    bool borderPixel(double x, double y) {
      if (!inside(x, y)) return false;
      switch (status.verificationStatus) {
        case StudyAreaStatus.pending:
          final dx = x - 22, dy = y - 22;
          final d = dx * dx + dy * dy;
          return d >= 16 * 16;
        case StudyAreaStatus.completed:
          return x < 9 || x > 35 || y < 9 || y > 35;
        case StudyAreaStatus.needsReview:
          return !inside(x, y + 3) ||
              !inside(x, y - 3) ||
              !inside(x + 3, y) ||
              !inside(x - 3, y);
        default:
          return false;
      }
    }

    for (var y = 0; y < 44; y++) {
      for (var x = 0; x < 44; x++) {
        if (borderPixel(x.toDouble(), y.toDouble())) {
          image.setPixelRgba(x, y, borderR, borderG, borderB, 255);
        } else if (inside(x.toDouble(), y.toDouble())) {
          image.setPixelRgba(x, y, fillR, fillG, fillB, 255);
        }
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  Future<void> _markUnchanged(StudyAreaSite site) async {
    final updated = site.revised(
        latitude: site.latitude,
        longitude: site.longitude,
        attributes: Map.from(site.attributes),
        status: StudyAreaStatus.verified,
        changeNote: 'Location unchanged');
    await _saveVerificationUpdate(updated, successMessage: 'Marked unchanged');
  }

  Future<void> _saveVerificationUpdate(StudyAreaSite updated,
      {required String successMessage}) async {
    final workspace = _workspace;
    if (updated.projectId == null && workspace != null) {
      // Older imports can be matched to the open project by its external ID
      // while lacking the local database ID required by the sync outbox.
      updated.projectId = workspace.project.id;
    }
    if (updated.projectExternalId == null) {
      updated.projectExternalId = workspace?.project.externalId;
    }
    if (updated.layerId.isEmpty && workspace != null) {
      updated.layerId = workspace.layerId;
    }
    try {
      await _store.updateSite(updated,
          expectedRevision: updated.revision,
          expectedRevisionId: updated.revisionToken,
          author: _fieldworker);
      await StudyAreaOutboxService(_database).enqueue(updated, _fieldworker);
      await _loadSites();
      if (mounted) {
        setState(() => _selectedSite =
            _sites.where((s) => s.id == updated.id).firstOrNull);
        _showSnack(successMessage);
      }
    } on StudyAreaConflict {
      await _loadSites();
      if (mounted) {
        setState(() => _selectedSite =
            _sites.where((site) => site.id == updated.id).firstOrNull);
      }
      _showSnack(
          'This feature changed elsewhere. Reopen it and review the latest version.');
    } catch (error) {
      _showSnack('Could not save the feature: $error');
    }
  }

  void _beginMove(StudyAreaSite site) {
    if (site.currentGeometry['type'] != 'Point') {
      _showSnack(
          'Move is available for points. Use Redraw geometry for lines and areas.');
      return;
    }
    setState(() {
      _movingSite = site;
      _movingCoordinates = LatLng(site.latitude, site.longitude);
      _selectedSite = null;
      _routeSiteId = null;
      _routeCoordinates = null;
      _routeDistanceM = null;
    });
    _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(site.latitude, site.longitude), 18));
    _refreshMapMarkers();
  }

  void _cancelMove() {
    final site = _movingSite;
    setState(() {
      _movingSite = null;
      _movingCoordinates = null;
      _selectedSite = site;
    });
    _refreshMapMarkers();
  }

  Future<void> _saveMove() async {
    final site = _movingSite, coordinates = _movingCoordinates;
    if (site == null || coordinates == null) return;
    final updated = site.revised(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        attributes: Map.from(site.attributes),
        status: StudyAreaStatus.updated,
        changeNote: 'Location changed');
    setState(() {
      _movingSite = null;
      _movingCoordinates = null;
    });
    await _saveVerificationUpdate(updated, successMessage: 'Location updated');
    await _refreshMapMarkers();
  }

  Future<void> _showRoadRoute(StudyAreaSite site) async {
    final position = _currentPos, workspace = _workspace;
    if (position == null || workspace == null) {
      _showSnack(position == null
          ? 'Waiting for a GPS fix'
          : 'Select a project first');
      return;
    }
    try {
      final layers =
          await ProjectVectorLayerService(_database).load(workspace.project.id);
      final route = RoadRoutingService.shortestRoute(
          layers: layers,
          startLatitude: position.latitude,
          startLongitude: position.longitude,
          endLatitude: site.latitude,
          endLongitude: site.longitude);
      if (route == null) {
        _showSnack(
            'No connected road route found. Add a road layer in Project settings.');
        return;
      }
      setState(() {
        _routeSiteId = site.id;
        _routeDistanceM = route.distanceMeters;
        _routeCoordinates = route.coordinates
            .map((point) => LatLng(point[1], point[0]))
            .toList();
      });
      await _refreshMapMarkers();
      if (_routeCoordinates != null && _routeCoordinates!.isNotEmpty) {
        _controller?.animateCamera(CameraUpdate.newLatLngBounds(
            _boundsOf(_routeCoordinates!),
            left: 48,
            top: 200,
            right: 48,
            bottom: 300));
      }
    } catch (error) {
      _showSnack('Could not calculate a road route: $error');
    }
  }

  LatLngBounds _boundsOf(List<LatLng> points) {
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final point in points.skip(1)) {
      south = math.min(south, point.latitude);
      north = math.max(north, point.latitude);
      west = math.min(west, point.longitude);
      east = math.max(east, point.longitude);
    }
    return LatLngBounds(
        southwest: LatLng(south, west), northeast: LatLng(north, east));
  }

  Future<void> _manageProjectLayers() async {
    final workspace = _workspace;
    if (workspace == null) {
      _showSnack('Select a project first');
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProjectVectorLayersScreen(
            database: _database, projectId: workspace.project.id)));
    if (!mounted) return;
    await _loadSites();
  }

  void _onStyleLoaded() {
    _styleReady = true;
    _markerImages.clear();
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.setSymbolIconAllowOverlap(true));
      unawaited(controller.setSymbolIconIgnorePlacement(true));
    }
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
    // One platform operation per annotation type keeps large imported files
    // responsive when a point is selected or its status changes.
    await controller.clearCircles();
    await controller.clearSymbols();
    await controller.clearLines();
    await controller.clearFills();
    _circles.clear();
    _symbols.clear();
    _lines.clear();
    _fills.clear();
    _referenceCircles.clear();
    _referenceLines.clear();
    _referenceFills.clear();
    _referenceSymbols.clear();
    _routeLine = null;
    _categoryStyle.categories(_sites);
    List<LatLng> points(dynamic values) => (values as List)
        .map((v) => LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble()))
        .toList();
    final importedBatches =
        _sites.map((site) => site.importBatchId).whereType<String>().toSet();
    for (final layer
        in _referenceLayers.where((item) => item['visible'] != false)) {
      final batchId = layer['import_batch_id']?.toString();
      if (batchId != null && importedBatches.contains(batchId)) continue;
      final color = (layer['color'] ?? '#467ca1').toString();
      final opacity =
          ((layer['opacity'] as num?)?.toDouble() ?? 0.8).clamp(0.0, 1.0);
      final circles = <CircleOptions>[];
      final lines = <LineOptions>[];
      final fills = <FillOptions>[];
      for (final feature in layer['features'] as List? ?? const []) {
        if (feature is! Map || feature['geometry'] is! Map) continue;
        final geometry = feature['geometry'] as Map;
        final coords = geometry['coordinates'];
        try {
          switch (geometry['type']) {
            case 'LineString':
              lines.add(LineOptions(
                  geometry: points(coords),
                  lineColor: color,
                  lineOpacity: opacity,
                  lineWidth: 2));
              break;
            case 'MultiLineString':
              for (final line in coords as List)
                lines.add(LineOptions(
                    geometry: points(line),
                    lineColor: color,
                    lineOpacity: opacity,
                    lineWidth: 2));
              break;
            case 'Polygon':
              fills.add(FillOptions(
                  geometry: (coords as List).map(points).toList(),
                  fillColor: color,
                  fillOpacity: opacity * 0.2,
                  fillOutlineColor: color));
              break;
            case 'MultiPolygon':
              for (final polygon in coords as List)
                fills.add(FillOptions(
                    geometry: (polygon as List).map(points).toList(),
                    fillColor: color,
                    fillOpacity: opacity * 0.2,
                    fillOutlineColor: color));
              break;
            case 'Point':
              circles.add(CircleOptions(
                  geometry: LatLng((coords[1] as num).toDouble(),
                      (coords[0] as num).toDouble()),
                  circleRadius: 4,
                  circleColor: color,
                  circleOpacity: opacity,
                  circleStrokeColor: '#FFFFFF',
                  circleStrokeWidth: 1));
              break;
            case 'MultiPoint':
              for (final point in coords as List)
                circles.add(CircleOptions(
                    geometry: LatLng((point[1] as num).toDouble(),
                        (point[0] as num).toDouble()),
                    circleRadius: 4,
                    circleColor: color,
                    circleOpacity: opacity,
                    circleStrokeColor: '#FFFFFF',
                    circleStrokeWidth: 1));
              break;
          }
        } catch (_) {}
      }
      if (circles.isNotEmpty) {
        _referenceCircles.addAll(await controller.addCircles(circles));
      }
      if (lines.isNotEmpty) {
        _referenceLines.addAll(await controller.addLines(lines));
      }
      if (fills.isNotEmpty) {
        _referenceFills.addAll(await controller.addFills(fills));
      }
    }
    final symbolOptions = <SymbolOptions>[];
    final symbolData = <Map<String, dynamic>>[];
    final lineOptions = <LineOptions>[];
    final lineData = <Map<String, dynamic>>[];
    final fillOptions = <FillOptions>[];
    final fillData = <Map<String, dynamic>>[];
    for (final site in _sites.where((s) =>
        (_movingSite == null || s.id != _movingSite!.id) &&
        (_filter == null || s.status.verificationStatus == _filter) &&
        _categoryStyle.visible(s))) {
      try {
        final color = _categoryStyle.color(site);
        final data = {'site_id': site.id};
        Future<void> drawPoint(double lon, double lat) async {
          final status = site.status.verificationStatus;
          final colorHex = _categoryStyle.color(site);
          final imageName = 'mapbanai_${status.name}_${colorHex.substring(1)}';
          if (_markerImages.add(imageName)) {
            await controller.addImage(
                imageName, _markerImage(status, colorHex));
          }
          symbolOptions.add(SymbolOptions(
            geometry: LatLng(lat, lon),
            iconImage: imageName,
            iconSize: _categoryStyle.radius / 12,
            iconAnchor: 'center',
          ));
          symbolData.add(data);
        }

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
              await drawPoint(
                  (vertex[0] as num).toDouble(), (vertex[1] as num).toDouble());
            }
          } else if (geom['type'] == 'LineString' ||
              geom['type'] == 'MultiLineString') {
            final lines =
                geom['type'] == 'LineString' ? [coords] : coords as List;
            for (final line in lines) {
              lineOptions.add(LineOptions(
                  geometry: points(line), lineColor: color, lineWidth: 3));
              lineData.add(data);
            }
          } else if (geom['type'] == 'Polygon' ||
              geom['type'] == 'MultiPolygon') {
            final polygons =
                geom['type'] == 'Polygon' ? [coords] : coords as List;
            for (final polygon in polygons) {
              fillOptions.add(FillOptions(
                  geometry: (polygon as List).map(points).toList(),
                  fillColor: color,
                  fillOpacity: 0.25,
                  fillOutlineColor: color));
              fillData.add(data);
            }
          }
        }

        await drawGeometry(site.currentGeometry);
        if (site.currentGeometry['type'] != 'Point' &&
            site.currentGeometry['type'] != 'MultiPoint') {
          await drawPoint(site.longitude, site.latitude);
        }
      } catch (_) {}
    }
    if (_drawType != null && _draft.length >= 2) {
      lineOptions.add(LineOptions(geometry: [
        ..._draft,
        if (_drawType == 'Polygon' && _draft.length >= 3) _draft.first
      ], lineColor: '#FF6F00', lineWidth: 4));
    }
    final moving = _movingCoordinates;
    if (_movingSite != null && moving != null) {
      final imageName = 'mapbanai_moving_marker';
      if (_markerImages.add(imageName)) {
        await controller.addImage(
            imageName, _markerImage(StudyAreaStatus.completed, '#1565C0'));
      }
      symbolOptions.add(SymbolOptions(
        geometry: moving,
        iconImage: imageName,
        iconSize: 0.65,
        iconAnchor: 'center',
      ));
      symbolData.add({'site_id': _movingSite!.id});
    }
    if (symbolOptions.isNotEmpty) {
      _symbols.addAll(await controller.addSymbols(symbolOptions, symbolData));
    }
    if (lineOptions.isNotEmpty) {
      _lines.addAll(await controller.addLines(lineOptions, lineData));
    }
    if (fillOptions.isNotEmpty) {
      _fills.addAll(await controller.addFills(fillOptions, fillData));
    }
    if (_routeSiteId != null &&
        _routeLine == null &&
        _routeCoordinates != null) {
      _routeLine = await controller.addLine(LineOptions(
          geometry: _routeCoordinates!, lineColor: '#1565C0', lineWidth: 5));
    }
    if (mounted) setState(() {});
    // Auto fit bounds if sites exist and no selection.
    if (_sites.isNotEmpty &&
        _selectedSite == null &&
        _drawType == null &&
        _movingSite == null) {
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
        Symbol s => s.data,
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
        _movingSite = null;
        _routeSiteId = null;
        _routeDistanceM = null;
        _routeCoordinates = null;
      });
    }
  }

  Future<void> _importSites({String? pathOverride}) async {
    if (_workspace == null || widget.viewOnly) {
      _showSnack('Select a project first');
      return;
    }
    final result = pathOverride == null
        ? await FilePicker.platform.pickFiles(
            type: FileType.any,
            withData: false,
          )
        : null;
    final path = pathOverride ?? result?.files.firstOrNull?.path;
    if (path == null) return;
    final ioFile = File(path);
    if (!SpatialFileImport.supports(path)) {
      _showSnack('Select GeoJSON, GeoPackage, SHP/ZIP, CSV, Excel or KML/KMZ.');
      return;
    }
    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loadingDialogOpen = true;
    try {
      final imported = await SpatialFileImport.read(ioFile);
      if (!mounted) return;
      Navigator.of(context).pop();
      loadingDialogOpen = false;
      if (imported.isEmpty) {
        _showSnack('No sites found in file. Check format and lat/lon columns.');
        return;
      }
      final workspace = _workspace!;
      final fileBytes = Uint8List.fromList(await ioFile.readAsBytes());
      final layerInputs = <String, Uint8List>{};
      if (p.extension(path).toLowerCase() == '.shp') {
        final base = p.basenameWithoutExtension(path);
        for (final extension in ['.shp', '.dbf', '.shx', '.prj', '.cpg']) {
          final companion = File(p.setExtension(path, extension));
          if (await companion.exists()) {
            layerInputs['$base$extension'] =
                Uint8List.fromList(await companion.readAsBytes());
          }
        }
      } else {
        layerInputs[p.basename(path)] = fileBytes;
      }
      final batchId = const Uuid().v4();
      List<Map<String, dynamic>> projectLayers;
      try {
        projectLayers = await ProjectVectorLayerService.parseFiles(layerInputs);
      } on FormatException {
        if (!['.kml', '.kmz'].contains(p.extension(path).toLowerCase())) {
          rethrow;
        }
        projectLayers = [
          {
            'id': const Uuid().v4(),
            'name': p.basenameWithoutExtension(path),
            'visible': true,
            'color': '#467ca1',
            'opacity': 0.8,
            'role': 'study_area',
            'features': imported
                .map((site) => <String, dynamic>{
                      'type': 'Feature',
                      'geometry': site.currentGeometry,
                      'properties': site.sourceProperties ?? site.attributes,
                    })
                .toList(),
            'source_files': [
              {
                'name': p.basename(path),
                'bytes_base64': base64Encode(fileBytes)
              }
            ],
          }
        ];
      }
      final fileName = p.basename(path);
      for (final layer in projectLayers) {
        layer['role'] = 'study_area';
        layer['import_batch_id'] = batchId;
        layer['import_file_name'] = fileName;
      }
      final existing = await _store.loadSites();
      for (var i = 0; i < imported.length; i++) {
        var site = imported[i];
        if (site.projectExternalId != null &&
            site.projectExternalId != workspace.project.externalId) {
          throw const FormatException(
              'This file belongs to another project. Select that project before importing.');
        }
        if (site.projectExternalId != null &&
            site.layerId != workspace.layerId) {
          throw const FormatException(
              'This file belongs to another study layer. Select that layer before importing.');
        }
        if (site.projectExternalId == null) {
          final collision = existing.any((other) =>
              other.id == site.id &&
              (!GuidedVisitService.belongsToProject(other, workspace.project) ||
                  other.layerId != workspace.layerId));
          if (collision) {
            site = StudyAreaSite.fromJson({
              ...site.toJson(),
              'id':
                  '${workspace.project.externalId}:${workspace.layerId}:${site.id}'
            });
            imported[i] = site;
          }
        }
        site.projectId = workspace.project.id;
        site.projectExternalId = workspace.project.externalId;
        site.layerId = workspace.layerId;
        site.importBatchId = batchId;
        site.importFileName = fileName;
      }
      final preview = await _store.previewMerge(imported);
      if (!mounted) return;
      final choices = await showDialog<Map<String, StudyAreaMergeChoice>>(
          context: context,
          builder: (_) => StudyAreaMergeReviewDialog(preview: preview));
      if (choices == null) return;
      final vectorService = ProjectVectorLayerService(_database);
      final currentLayers = await vectorService.load(workspace.project.id);
      await vectorService
          .save(workspace.project.id, [...currentLayers, ...projectLayers]);
      final merged = await _store.applyMerge(preview,
          resolutions: choices,
          author: _fieldworker,
          localProjectId: workspace.project.id);
      final queuedSites = (await _store.loadSites())
          .where((site) =>
              site.importBatchId == batchId &&
              GuidedVisitService.belongsToProject(site, workspace.project) &&
              site.layerId == workspace.layerId)
          .toList();
      for (final site in queuedSites) {
        // External identity is authoritative across package imports/devices.
        site.projectId = workspace.project.id;
      }
      try {
        await StudyAreaOutboxService(_database)
            .enqueueBatch(queuedSites, _fieldworker);
      } catch (_) {
        _showSnack(
            'Map imported and saved. Some features could not enter the sync queue; retry Cloud Sync from Home.');
        return;
      }
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
      var fillSurvey = false;
      final isNew = !_sites.any((existing) => existing.id == site.id);
      final updated = await showDialog<StudyAreaSite>(
          context: context,
          builder: (context) => _EditSiteDialog(
              site: draft,
              isNew: isNew,
              onSurveyChoice: (value) => fillSurvey = value));
      if (updated == null) return false;
      final schema = _workspace?.schema;
      final requiredSurvey =
          StudyFeaturePolicy.requiresSurvey(updated.status, isNew: isNew);
      if (requiredSurvey && schema == null) {
        _showSnack(
            'New and updated features require a questionnaire. Select a survey form first.');
        return false;
      }
      if (schema != null && (requiredSurvey || fillSurvey)) {
        final answers = await editFormAttributes(context,
            form: schema,
            username: _fieldworker,
            answers: FormAttributeService.prefill(
                schema, {...updated.attributes, ...updated.formAnswers},
                geometry: updated.currentGeometry));
        if (answers == null) return false;
        updated.formAnswers = answers;
        updated.formSnapshot = schema.toJson();
        for (final entry in answers.entries) {
          updated.attributes[entry.key] =
              entry.value is Map || entry.value is List
                  ? jsonEncode(entry.value)
                  : entry.value?.toString() ?? '';
        }
      }

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
      await StudyAreaOutboxService(_database).enqueue(updated, _fieldworker);
      await _loadSites();
      if (!mounted) return true;
      setState(() => _selectedSite = updated);
      _showSnack('Feature saved');
      return true;
    }
    return false;
  }

  void _startDrawing(String type, {StudyAreaSite? site}) {
    if (widget.viewOnly) return;
    if (_workspace == null) {
      _showSnack("Select a project first");
      return;
    }
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
        projectId: previous?.projectId ?? _workspace?.project.id,
        projectExternalId:
            previous?.projectExternalId ?? _workspace?.project.externalId,
        layerId: previous?.layerId ?? _workspace!.layerId,
        formAnswers: previous?.formAnswers,
        formSnapshot: previous?.formSnapshot,
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

  Future<void> _addSurveyAtGps() async {
    final workspace = _workspace;
    final schema = workspace?.schema;
    if (workspace == null || schema == null) {
      _showSnack('Select a project and survey form first.');
      return;
    }
    final gps = _currentPos;
    if (gps == null ||
        DateTime.now().difference(gps.timestamp).inSeconds > 30) {
      _showSnack('Wait for a fresh GPS location before recording a site.');
      return;
    }
    final geometry = <String, dynamic>{
      'type': 'Point',
      'coordinates': [gps.longitude, gps.latitude]
    };
    final answers = await editFormAttributes(context,
        form: schema,
        username: _fieldworker,
        answers: FormAttributeService.prefill(schema, {}, geometry: geometry));
    if (answers == null || !mounted) return;
    final site = StudyAreaSite(
        id: 'new_${DateTime.now().microsecondsSinceEpoch}',
        latitude: gps.latitude,
        longitude: gps.longitude,
        geometry: geometry,
        status: StudyAreaStatus.newFeature,
        projectId: workspace.project.id,
        projectExternalId: workspace.project.externalId,
        layerId: workspace.layerId,
        formAnswers: answers,
        formSnapshot: schema.toJson(),
        attributes: {
          'name': 'New feature',
          'gps_accuracy_m': gps.accuracy.toString(),
          'gps_captured_at': gps.timestamp.toUtc().toIso8601String()
        });
    try {
      await _store.updateSite(site, author: _fieldworker);
      await StudyAreaOutboxService(_database).enqueue(site, _fieldworker);
      await _loadSites();
      if (mounted) setState(() => _selectedSite = site);
      _showSnack('Survey feature saved');
    } catch (e) {
      _showSnack('Could not save feature: $e');
    }
  }

  Future<void> _addSite(LatLng coordinates, {Position? gps}) async {
    if (_workspace == null) {
      _showSnack('Select a project first');
      return;
    }
    final site = StudyAreaSite(
        id: 'new_${DateTime.now().microsecondsSinceEpoch}',
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        status: StudyAreaStatus.newFeature,
        projectId: _workspace?.project.id,
        projectExternalId: _workspace?.project.externalId,
        layerId: _workspace!.layerId,
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
    });
    await _loadSites();
    _showSnack('Displayed sites cleared');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _buildStyleString(Basemap basemap) =>
      MapStyleChoice.online(basemap).style;

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
        title: Text(
            widget.viewOnly ? 'Study Area — View only' : 'Study Area Mode'),
        bottom: widget.viewOnly
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(112),
                child: ProjectWorkspaceBar(
                    database: _database,
                    workspace: _workspace,
                    onChanged: _changeWorkspace,
                    enabled: _drawType == null && !widget.viewOnly,
                    onAddPoint: widget.viewOnly ? null : _addSurveyAtGps)),
        actions: [
          IconButton(
            tooltip: 'Import sites',
            icon: const Icon(Icons.file_download_outlined,
                color: Color(0xFF1565C0)),
            onPressed: widget.viewOnly ? null : () => _importSites(),
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
          IconButton(
            tooltip: 'Project layers',
            icon: const Icon(Icons.layers_outlined),
            onPressed: _manageProjectLayers,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (widget.viewOnly && v != 'fit') return;
              if (v == 'claim') _claimLegacy();
              if (v == 'operator') _editOperator();
              if (v == 'layers') _manageProjectLayers();
              if (v == 'line') _startDrawing('LineString');
              if (v == 'polygon') _startDrawing('Polygon');
              if (v == 'clear') _clearAll();
              if (v == 'fit') _fitBounds();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'operator', child: Text('Fieldworker: $_fieldworker')),
              const PopupMenuItem(
                  value: 'claim',
                  child: Text('Assign previous unassigned sites')),
              if (!widget.viewOnly)
                const PopupMenuItem(
                    value: 'layers',
                    child: Text('Manage project files and road layers')),
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
              if (_movingSite != null) {
                setState(() => _movingCoordinates = coordinates);
                _refreshMapMarkers();
                return;
              }
              if (_drawType != null) {
                setState(() => _draft.add(coordinates));
                _refreshMapMarkers();
              }
            },
            onMapLongClick: (_, coordinates) {
              if (_drawType == null && !widget.viewOnly) _addSite(coordinates);
            },
            onStyleLoadedCallback: _onStyleLoaded,
            styleString: _offlineBasemap?.style ?? _buildStyleString(basemap),
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.normal,
            compassEnabled: true,
            annotationConsumeTapEvents: const [
              AnnotationType.circle,
              AnnotationType.symbol,
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
                        'Use the top Import button for GeoJSON, GeoPackage, zipped shapefiles, CSV, Excel or KML/KMZ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
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
          if (_movingSite != null)
            Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text(
                              'Tap the map to place this feature at its new location.'),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: _cancelMove,
                                    child: const Text('Cancel'))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: FilledButton(
                                    onPressed: _movingCoordinates == null
                                        ? null
                                        : _saveMove,
                                    child: const Text('Save location'))),
                          ])
                        ])))),
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
    );
  }

  Future<void> _chooseCategories() async {
    final style = StudyCategoryStyle.fromJson(_categoryStyle.toJson());
    final columns = _sites.expand((s) => s.attributes.keys).toSet().toList()
      ..sort();
    final applied = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              final categories = style.categories(_sites);
              return AlertDialog(
                  title: const Text('Categories & colors'),
                  content: SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        DropdownButtonFormField<String>(
                            value: style.column,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Color by column'),
                            hint: const Text('Single color'),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Single color')),
                              const DropdownMenuItem(
                                  value: '__verification_status__',
                                  child: Text('Verification status')),
                              for (final column in columns)
                                DropdownMenuItem(
                                    value: column, child: Text(column))
                            ],
                            onChanged: (value) => update(() {
                                  style.column = value;
                                  style.colors.clear();
                                  style.hidden.clear();
                                })),
                        Text('Point size: ${style.radius.round()}'),
                        Slider(
                            value: style.radius,
                            min: 4,
                            max: 12,
                            divisions: 8,
                            onChanged: (value) =>
                                update(() => style.radius = value)),
                        if (style.column != null) ...[
                          Row(children: [
                            TextButton(
                                onPressed: () =>
                                    update(() => style.hidden.clear()),
                                child: const Text('Show all')),
                            TextButton(
                                onPressed: () => update(
                                    () => style.hidden.addAll(categories)),
                                child: const Text('Hide all'))
                          ]),
                          for (final category in categories)
                            Row(children: [
                              Checkbox(
                                  value: !style.hidden.contains(category),
                                  onChanged: (value) => update(() {
                                        if (value == true) {
                                          style.hidden.remove(category);
                                        } else {
                                          style.hidden.add(category);
                                        }
                                      })),
                              Expanded(
                                  child: Text(
                                      '$category (${_sites.where((s) => style.category(s) == category).length})')),
                              PopupMenuButton<String>(
                                  tooltip: 'Category color',
                                  onSelected: (color) => update(
                                      () => style.colors[category] = color),
                                  icon: Icon(Icons.circle,
                                      color: Color(int.parse(
                                          style.colors[category]!
                                              .replaceFirst('#', 'FF'),
                                          radix: 16))),
                                  itemBuilder: (_) => [
                                        for (final color
                                            in StudyCategoryStyle.palette)
                                          PopupMenuItem(
                                              value: color,
                                              child: Row(children: [
                                                Icon(Icons.circle,
                                                    color: Color(int.parse(
                                                        color.replaceFirst(
                                                            '#', 'FF'),
                                                        radix: 16))),
                                                const SizedBox(width: 8),
                                                Text(color)
                                              ]))
                                      ])
                            ])
                        ]
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Apply'))
                  ]);
            }));
    if (applied != true || !mounted) return;
    setState(() => _categoryStyle = style);
    if (!widget.viewOnly && _categoryWorkspaceKey != null)
      await _database.setSetting(
          _categoryWorkspaceKey!, jsonEncode(style.toJson()));
    await _refreshMapMarkers();
  }

  Widget _buildHeaderCard() => Card(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Expanded(
                child: Text(
                    '${_sites.where((s) => (_filter == null || s.status.verificationStatus == _filter) && _categoryStyle.visible(s)).length} / ${_sites.length} features',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            IconButton(
                tooltip: 'Categories & colors',
                onPressed: _chooseCategories,
                icon: const Icon(Icons.palette_outlined)),
            DropdownButton<StudyAreaStatus>(
                value: _filter,
                underline: const SizedBox.shrink(),
                hint: const Text('All'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  for (final status in [
                    StudyAreaStatus.pending,
                    StudyAreaStatus.completed,
                    StudyAreaStatus.needsReview
                  ])
                    DropdownMenuItem(
                        value: status,
                        child: Text(
                            '${status.label}: ${_sites.where((s) => s.status.verificationStatus == status).length}')),
                ],
                onChanged: (value) {
                  setState(() => _filter = value);
                  _refreshMapMarkers();
                }),
          ])));

  String _siteField(StudyAreaSite site, List<String> keys,
      {String fallback = '—'}) {
    for (final key in keys) {
      for (final entry in site.attributes.entries) {
        if (entry.key.trim().toLowerCase() == key.toLowerCase() &&
            entry.value.trim().isNotEmpty) {
          return entry.value.trim();
        }
      }
    }
    return fallback;
  }

  Widget _buildSelectedPanel() {
    final site = _selectedSite!;
    final id =
        _siteField(site, ['id', 'feature_id', 'site_id'], fallback: site.id);
    final layer = _siteField(site, ['layer', 'layer_name'],
        fallback: _workspace?.layer.name ?? site.layerId);
    final name = _siteField(site, ['name', 'site_name', 'label'],
        fallback: site.displayName);
    final location =
        _siteField(site, ['location', 'locality', 'locality_name']);
    if (widget.viewOnly) {
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ID  $id'),
                    Text('Layer  $layer'),
                    Text('Name  $name'),
                    Text('Location  $location')
                  ])));
    }
    final pos = _currentPos;
    final routeVisible = _routeSiteId == site.id && _routeDistanceM != null;
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
                Expanded(
                  child: Text(
                    'ID  $id',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(site.status.label,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: switch (site.status.verificationStatus) {
                    StudyAreaStatus.completed => Colors.green.shade50,
                    StudyAreaStatus.needsReview => Colors.amber.shade50,
                    _ => Colors.red.shade50,
                  },
                  side: BorderSide(
                      color: Color(int.parse(
                          site.status.colorHex.replaceFirst('#', 'FF'),
                          radix: 16))),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _selectedSite = null;
                    _routeSiteId = null;
                    _routeCoordinates = null;
                    _routeDistanceM = null;
                    _refreshMapMarkers();
                  }),
                ),
              ],
            ),
            _detailRow('Layer', layer),
            _detailRow('Name', name),
            _detailRow('Location', location),
            if (site.currentGeometry['type'] == 'LineString' ||
                site.currentGeometry['type'] == 'Polygon')
              TextButton.icon(
                  onPressed: () => _startDrawing(
                      site.currentGeometry['type'] as String,
                      site: site),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Redraw geometry')),
            if (_workspace != null)
              TextButton.icon(
                  icon: const Icon(Icons.timeline),
                  label: const Text('Site timeline / add observation'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SiteTimelineScreen(
                          database: _database,
                          store: _store,
                          projectId: _workspace!.project.id,
                          site: site)))),
            TextButton.icon(
                onPressed: () => _showHistory(site),
                icon: const Icon(Icons.history),
                label: Text('Revision history (${site.history.length})')),
            if (routeVisible)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'Shortest road route  ${StudyAreaService.formatDistance(_routeDistanceM!)}',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            if (pos == null)
              const Text('Waiting for GPS fix', style: TextStyle(fontSize: 11)),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _markUnchanged(site),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Unchanged'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _beginMove(site),
                      icon: const Icon(Icons.location_on_outlined, size: 16),
                      label: const Text('Location changed'))),
            ]),
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
                    label: const Text('Location removed'),
                  ),
                ),
              ],
            ),
            if (pos != null)
              SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                      onPressed: () => _showRoadRoute(site),
                      icon: const Icon(Icons.directions_outlined, size: 17),
                      label: Text(routeVisible
                          ? 'Refresh road directions'
                          : 'Show road directions'))),
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

  Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 68,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),
      ]));
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _EditSiteDialog extends StatefulWidget {
  final StudyAreaSite site;

  final bool isNew;
  final ValueChanged<bool>? onSurveyChoice;
  const _EditSiteDialog(
      {required this.site, this.isNew = false, this.onSurveyChoice});

  @override
  State<_EditSiteDialog> createState() => _EditSiteDialogState();
}

class _EditSiteDialogState extends State<_EditSiteDialog> {
  bool _fillSurvey = false;
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
    _status = widget.site.status.verificationStatus;
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
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latCtrl,
                          enabled:
                              widget.site.currentGeometry['type'] == 'Point',
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
                          enabled:
                              widget.site.currentGeometry['type'] == 'Point',
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 12),
              DropdownButtonFormField<StudyAreaStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  StudyAreaStatus.pending,
                  StudyAreaStatus.completed,
                  StudyAreaStatus.needsReview
                ]
                    .map((status) => DropdownMenuItem(
                        value: status, child: Text(status.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 12),
              if (StudyFeaturePolicy.requiresSurvey(_status,
                  isNew: widget.isNew))
                const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                        'Questionnaire required for new or updated features.'))
              else
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fill questionnaire (optional)'),
                    value: _fillSurvey,
                    onChanged: (value) {
                      setState(() => _fillSurvey = value ?? false);
                      widget.onSurveyChoice?.call(_fillSurvey);
                    }),
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
              status: widget.isNew && _status == StudyAreaStatus.pending
                  ? StudyAreaStatus.newFeature
                  : _status == StudyAreaStatus.completed &&
                          widget.site.status.verificationStatus ==
                              StudyAreaStatus.completed
                      ? widget.site.status
                      : _status,
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
