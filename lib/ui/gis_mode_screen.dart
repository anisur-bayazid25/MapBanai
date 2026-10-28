import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/ui/response_layer_screen.dart';
import 'package:mapbanai/ui/project_vector_layers_screen.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/ui/common/map_chrome.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'package:mapbanai/services/record_geometry.dart';
import 'package:mapbanai/ui/study_area_mode_screen.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/ui/common/project_workspace_bar.dart';
import 'package:mapbanai/ui/common/form_attribute_editor.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:provider/provider.dart';
import 'package:mapbanai/ui/common/basemap_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' show Point;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/geometry_service.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/measure_units.dart';
import 'package:mapbanai/services/track_recorder.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/feature_detail_sheet.dart';
import 'package:mapbanai/ui/survey_session_detail_screen.dart';

enum _DraftType { none, point, line, polygon }

enum _MeasureTool { none, distance, area }

class _InfoFeature {
  final int sessionId;
  final String title;
  final String featureType;
  final bool studySite;

  const _InfoFeature({
    required this.sessionId,
    required this.title,
    required this.featureType,
    this.studySite = false,
  });
}

class GisModeScreen extends StatefulWidget {
  final String projectName;
  final int? projectId;

  /// When set, the screen restores an in-progress (draft) feature for this
  /// session id instead of starting fresh. The draft keeps saving to that
  /// same session until the user finishes (which promotes it to saved).
  final int? resumeDraftId;

  const GisModeScreen({
    required this.projectName,
    this.projectId,
    this.resumeDraftId,
    super.key,
  });

  @override
  State<GisModeScreen> createState() => _GisModeScreenState();
}

class _GisModeScreenState extends State<GisModeScreen> {
  final LocationService _locationService = LocationService();
  final AppDatabase _database = AppDatabase();
  final TrackRecorder _recorder = TrackRecorder(
    minDistanceM: 3,
    minIntervalS: 2,
    maxAccuracyM: 20,
  );

  MapLibreMapController? _controller;
  StreamSubscription<Position>? _subscription;
  Timer? _ticker;

  LatLng? _currentLocation;
  DateTime? _currentFixAt;
  bool _centeredOnInitialLocation = false;
  double? _currentAccuracy;
  String _locationStatus = 'Checking permission...';
  bool _styleReady = false;
  String _selectedBasemapId = 'osm';
  MapStyleChoice? _offlineBasemap;

  ProjectWorkspace? _workspace;
  List<Project> _projects = [];
  int? _selectedProjectId;

  int? _resumeDraftSessionId;

  _DraftType _draftType = _DraftType.none;
  bool _manualMode = false;
  final List<LatLng> _manualVertices = [];
  final List<Circle> _manualMarkers = [];
  Future<void> _manualRenderQueue = Future.value();
  int _manualRevision = 0;
  double _layerOpacity = 1;
  String _geometryFilter = 'all';
  List<({double lat, double lon})> get _draftVertices => _manualMode
      ? [for (final p in _manualVertices) (lat: p.latitude, lon: p.longitude)]
      : [
          for (final p in _recorder.vertices)
            (lat: p.latitude, lon: p.longitude)
        ];
  Circle? _draftPoint;
  Circle? _draftPlaceholder;
  Line? _draftLine;
  Fill? _draftFill;
  ({double lat, double lon, double accuracy})? _draftPointFix;
  ({double lat, double lon})? _draftStartFix;
  _InfoFeature? _infoFeature;
  bool _showInfoPanel = false;

  _MeasureTool _measureTool = _MeasureTool.none;
  List<({double lat, double lon})> _measurePoints = [];
  List<Circle> _measureMarkers = [];
  Line? _measureLine;
  Fill? _measureFill;
  DistanceUnit _measureDistanceUnit = DistanceUnit.auto;
  AreaUnit _measureAreaUnit = AreaUnit.auto;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadLocationStatus();
    _startLocationStream();
  }

  Future<void> _loadProjects() async {
    final projects = await _database.getProjects();
    if (!mounted) return;
    setState(() {
      _projects = projects;
    });

    final current = projects.where(
      (p) => widget.projectId != null
          ? p.id == widget.projectId
          : p.name == widget.projectName,
    );
    if (current.isNotEmpty) {
      await _selectProject(current.first.id, current.first.name);
    } else if (projects.isNotEmpty &&
        widget.projectId == null &&
        widget.resumeDraftId == null) {
      await _selectProject(projects.first.id, projects.first.name);
    } else {
      setState(() {
        _selectedProjectId = null;
      });
    }
    await _loadResumeDraft();
  }

  /// Restores an in-progress feature (line/polygon recorder state or point
  /// fix) so the user can continue recording and finish it later.
  Future<void> _loadResumeDraft() async {
    final id = widget.resumeDraftId;
    if (id == null) return;
    final row = await _database.getSurveySession(id);
    if (row == null || !mounted || row.status != 'draft') return;
    final project = await _database.getProjectById(row.projectId);
    if (project == null || project.archived || !mounted) {
      _showSnack(ui(context,
          'The draft project is unavailable. Restore the project before resuming.'));
      return;
    }
    if (_selectedProjectId != project.id) {
      await _selectProject(project.id, project.name);
    }

    Map<String, dynamic> responses;
    try {
      responses = jsonDecode(row.responses) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final layerId = responses['layer_id']?.toString() ?? 'default';
    if (_workspace!.layers.any((layer) => layer.id == layerId))
      _workspace = await ProjectWorkspaceService(_database)
          .select(project.id, layerId: layerId);
    final featureType = responses['feature_type'];
    if (featureType == null) return;

    _resumeDraftSessionId = row.id;

    setState(() {
      _manualMode = responses['capture_method'] == 'manual';
      if (_manualMode) {
        for (final p in responses['manual_vertices'] as List? ?? []) {
          _manualVertices
              .add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
        }
      }
      if (featureType == 'point') {
        _draftType = _DraftType.point;
        final lat = responses['latitude'];
        final lon = responses['longitude'];
        if (lat is num && lon is num) {
          _draftPointFix = (
            lat: lat.toDouble(),
            lon: lon.toDouble(),
            accuracy: (responses['accuracy_m'] as num?)?.toDouble() ?? 0,
          );
        }
      } else if (featureType == 'line' || featureType == 'polygon') {
        _draftType =
            featureType == 'line' ? _DraftType.line : _DraftType.polygon;
        final raw = responses['recorder'];
        if (raw is Map<String, dynamic>) {
          _recorder.restore(raw);
        }
      }
    });

    _showSnack(
        ui(context, 'Draft restored — continue, finish, or save it again'));
    _refreshDraftGeometry();

    if (_draftType == _DraftType.point) {
      await _restorePointDraftMarker();
    }
    if (_recorder.running) {
      _restartTicker();
      _startLocationStream(foreground: true);
    }
  }

  /// Renders the circular draggable marker for a restored point draft.
  Future<void> _restorePointDraftMarker() async {
    final controller = _controller;
    final fix = _draftPointFix;
    if (!_styleReady || controller == null || fix == null) return;
    if (_draftPoint != null) {
      await controller.removeCircle(_draftPoint!);
    }
    final circle = await controller.addCircle(
      CircleOptions(
        geometry: LatLng(fix.lat, fix.lon),
        circleRadius: 10,
        circleColor: '#E53935',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
        draggable: true,
      ),
    );
    if (!mounted) return;
    setState(() {
      _draftPoint = circle;
    });
  }

  Future<void> _selectProject(int id, String name) async {
    final workspace = await ProjectWorkspaceService(_database).load(id);
    _cancelDraft();
    await _endMeasure();
    setState(() {
      _workspace = workspace;
      _selectedProjectId = id;
      _infoFeature = null;
      _showInfoPanel = false;
    });
    try {
      context.read<ProjectState>().setSelectedProject(name, projectId: id);
    } catch (_) {}
    await _clearSurveyAnnotations();
    await _addSurveyAnnotations();
  }

  Future<void> _loadLocationStatus() async {
    final status = await _locationService.getStatusLabel();
    if (!mounted) return;
    setState(() {
      _locationStatus = status;
    });
  }

  Future<void> _startLocationStream({bool? foreground}) async {
    final granted = await _locationService.ensurePermission();
    if (!mounted) return;
    setState(() {
      _locationStatus =
          granted ? 'Waiting for GPS fix…' : 'Location permission not granted';
    });
    if (!granted) return;

    await _subscription?.cancel();

    final recording = foreground ??
        ((_draftType == _DraftType.line || _draftType == _DraftType.polygon) &&
            _recorder.running);

    // While recording a line/polygon the stream runs with a foreground
    // notification + wake lock so fixes keep arriving with the screen off.
    final LocationSettings settings;
    if (recording && defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'MapBanai — GIS recording',
          notificationText: 'Feature recording continues with the screen off',
          notificationChannelName: 'MapBanai GIS recording',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    _subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        if (!mounted) return;
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
          _currentFixAt = position.timestamp;
          _locationStatus = 'GPS ready';
          _currentAccuracy = position.accuracy;
        });
        _centerOnInitialLocation();
        if (!_manualMode &&
            _draftType == _DraftType.point &&
            _draftPoint == null &&
            _draftPointFix == null) {
          _placePointAtCurrentFix();
        }
        if (!_manualMode &&
            (_draftType == _DraftType.line ||
                _draftType == _DraftType.polygon)) {
          if (!_recorder.running && _currentLocation != null) {
            if (_draftPlaceholder == null) {
              _placeDraftPlaceholder();
            } else {
              _moveDraftPlaceholder();
            }
          }
        }
        final recorded =
            _draftType == _DraftType.line || _draftType == _DraftType.polygon;
        if (recorded && _recorder.add(position)) {
          _refreshDraftGeometry();
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _locationStatus = 'Waiting for GPS fix…';
        });
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker?.cancel();
    _database.close();
    super.dispose();
  }

  // ── map setup ────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onFeatureTapped.add(_onFeatureTapped);
    controller.onFeatureDrag.add(_onFeatureDragged);
    _centerOnInitialLocation();
  }

  void _centerOnInitialLocation() {
    final location = _currentLocation,
        controller = _controller,
        fixedAt = _currentFixAt;
    if (_centeredOnInitialLocation ||
        !_styleReady ||
        controller == null ||
        location == null ||
        fixedAt == null) return;
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        location.latitude.abs() > 90 ||
        location.longitude.abs() > 180 ||
        DateTime.now().difference(fixedAt).abs() > const Duration(minutes: 2))
      return;
    _centeredOnInitialLocation = true;
    unawaited(controller
        .animateCamera(CameraUpdate.newLatLngZoom(location, 16))
        .catchError((Object error) {
      _centeredOnInitialLocation = false;
      return false;
    }));
  }

  void _onStyleLoaded() {
    _styleReady = true;
    _centerOnInitialLocation();
    _addSurveyAnnotations();
    if (_draftActive) {
      _refreshDraftGeometry();
      if (_draftType == _DraftType.point) {
        _restorePointDraftMarker();
      }
    }
  }

  Map? _annotationData(Annotation? annotation) {
    if (annotation is Circle) return annotation.data;
    if (annotation is Line) return annotation.data;
    if (annotation is Fill) return annotation.data;
    if (annotation is Symbol) return annotation.data;
    return null;
  }

  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    if (_measureTool != _MeasureTool.none || _draftActive) return;
    final data = _annotationData(annotation);
    final sessionId = data?['session_id'];
    final title = data?['title'] as String?;
    final featureType = data?['feature_type'] as String?;
    if (sessionId == null || !mounted) return;
    setState(() {
      _infoFeature = _InfoFeature(
        sessionId:
            sessionId is int ? sessionId : int.tryParse('$sessionId') ?? 0,
        title: title ?? ui(context, 'Feature {v0}', [sessionId]),
        featureType: featureType ?? 'feature',
        studySite: data?['study_site'] == true,
      );
      _showInfoPanel = true;
    });
  }

  // ── feature editing (move & delete) ─────────────────────────

  /// Persists a drag-move when a survey point annotation is released.
  Future<void> _onFeatureDragged(
    Point<double> point,
    LatLng origin,
    LatLng current,
    LatLng delta,
    String id,
    Annotation? annotation,
    DragEventType eventType,
  ) async {
    if (eventType != DragEventType.end) return;

    // Draft markers: remember the dragged position so the drop happens
    // exactly where the user released the marker.
    if (mounted && annotation is Circle) {
      if (identical(annotation, _draftPoint)) {
        setState(() {
          _draftPointFix = (
            lat: current.latitude,
            lon: current.longitude,
            accuracy: _currentAccuracy ?? 0,
          );
        });
        return;
      }
      if (identical(annotation, _draftPlaceholder)) {
        setState(() {
          _draftStartFix = (
            lat: current.latitude,
            lon: current.longitude,
          );
        });
        return;
      }
    }

    final data = _annotationData(annotation);
    final sessionId = data?['session_id'];
    if (sessionId == null || !mounted) return;
    final parsedId = sessionId is int ? sessionId : int.tryParse('$sessionId');
    if (parsedId == null) return;

    final session = await _database.getSurveySession(parsedId);
    if (session == null) return;
    Map<String, dynamic> responses;
    try {
      responses = jsonDecode(session.responses) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (responses['feature_type'] != 'point') return;

    final oldLat = responses['latitude'];
    final oldLon = responses['longitude'];
    final answers = responses['answers'];
    final snapshot = responses['form_snapshot'];
    final questions = snapshot is Map ? snapshot['questions'] : null;
    if (answers is Map && questions is List) {
      for (final question in questions) {
        if (question is! Map || question['type'] != 'geopoint') continue;
        final value = answers[question['name']];
        if (value is! String) continue;
        final parts =
            value.split(RegExp(r'[,\s]+')).map(double.tryParse).toList();
        if (parts.length >= 2 && parts[0] == oldLat && parts[1] == oldLon) {
          answers[question['name']] =
              '${current.latitude},${current.longitude},0.0';
        }
      }
    }
    responses['latitude'] = current.latitude;
    responses['longitude'] = current.longitude;
    await _database.updateSurveySession(
      parsedId,
      title: session.title,
      responses: jsonEncode(responses),
    );
    if (!mounted) return;
    _showSnack(ui(context, 'Point moved'));
  }

  Future<void> _deleteSelectedFeature() async {
    final info = _infoFeature;
    if (info == null) return;
    if (info.studySite) {
      _showSnack(ui(context, 'Edit or remove this site in Study Area mode'));
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: ui(context, 'Delete feature'),
      message:
          ui(context, 'Delete "{v0}"? This cannot be undone.', [info.title]),
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await StudyAreaOutboxService(_database)
        .deleteFeatureSession(info.sessionId);
    final controller = _controller;
    if (controller != null) {
      for (final circle in controller.circles.toList()) {
        if (circle.data?['session_id'] == info.sessionId) {
          await controller.removeCircle(circle);
        }
      }
      for (final line in controller.lines.toList()) {
        if (line.data?['session_id'] == info.sessionId) {
          await controller.removeLine(line);
        }
      }
      for (final fill in controller.fills.toList()) {
        if (fill.data?['session_id'] == info.sessionId) {
          await controller.removeFill(fill);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _infoFeature = null;
      _showInfoPanel = false;
    });
    _showSnack(ui(context, 'Feature deleted'));
  }

  // ── survey feature annotations ───────────────────────────────

  Future<void> _addSurveyAnnotations() async {
    final controller = _controller;
    final projectId = _selectedProjectId;
    if (!_styleReady || controller == null || projectId == null) return;
    for (final layer
        in await ProjectVectorLayerService(_database).load(projectId)) {
      if (layer['visible'] == false ||
          (ProjectVectorLayerService.studyLayerId(layer) !=
                  _workspace?.layerId &&
              layer['role'] != 'reference')) continue;
      for (final raw in layer['features'] as List? ?? []) {
        if (raw is! Map || raw['geometry'] is! Map) continue;
        await _addGeometry(
            controller, Map<String, dynamic>.from(raw['geometry']), {
          'read_only_geometry': true,
          'reference': layer['role'] == 'reference',
          'color': layer['color'],
          'opacity': layer['opacity'],
        });
      }
    }

    final sessions = (await _database.getSurveySessions())
        .where((s) => s.projectId == projectId)
        .toList();

    final deletedSites = <String>{};
    for (final session in sessions) {
      try {
        final raw = jsonDecode(session.responses);
        if (raw is! Map) continue;
        if (raw['deleted'] == true && raw['site_id'] != null)
          deletedSites.add(raw['site_id'].toString());
      } catch (_) {/* A malformed legacy record has no deletion identity. */}
    }
    for (final session in sessions) {
      if (session.status == 'draft') continue;
      final data = <String, dynamic>{
        'session_id': session.id,
        'title': session.title,
      };
      try {
        final responses = jsonDecode(session.responses) as Map<String, dynamic>;
        final siteId = responses['site_id'] ??
            (responses['visit'] is Map ? responses['visit']['site_id'] : null);
        if (responses['deleted'] == true || deletedSites.contains(siteId))
          continue;
        if ((responses['layer_id'] ?? 'default') !=
            (_workspace?.layerId ?? 'default')) continue;
        data['feature_type'] = responses['feature_type'] ?? 'survey';
        data['study_site'] = responses['workflow'] == 'study_area_feature_v1';
        final geometries = RecordGeometry.fromResponses(responses);
        for (final geometry in geometries) {
          await _addGeometry(controller, geometry, {
            ...data,
            'read_only_geometry': data['study_site'] == true ||
                responses['feature_type'] != 'point' ||
                geometry['type'] != 'Point' ||
                jsonEncode(geometry['coordinates']) !=
                    jsonEncode([responses['longitude'], responses['latitude']])
          });
        }
      } catch (_) {
        // Skip sessions whose responses are not GeoJSON-like.
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _addGeometry(MapLibreMapController controller,
      Map<String, dynamic> geometry, Map<String, dynamic> data) async {
    final type = geometry['type'];
    final coordinates = geometry['coordinates'];
    if (coordinates is! List) return;
    if (type == 'Point' && coordinates.length >= 2) {
      await _addSurveyFeature(
          controller,
          {
            'feature_type': 'point',
            'longitude': coordinates[0],
            'latitude': coordinates[1]
          },
          data);
    } else if (type == 'LineString' || type == 'Polygon') {
      final points = type == 'Polygon' ? coordinates.first : coordinates;
      if (points is! List) return;
      await _addSurveyFeature(
          controller,
          {
            'feature_type': type == 'Polygon' ? 'polygon' : 'line',
            if (type == 'Polygon')
              'polygon_rings': <List<LatLng>>[
                for (final ring in coordinates)
                  [
                    for (final point in ring)
                      LatLng((point[1] as num).toDouble(),
                          (point[0] as num).toDouble())
                  ]
              ],
            'vertices': [
              for (final point in points)
                if (point is List && point.length >= 2)
                  {'longitude': point[0], 'latitude': point[1]}
            ]
          },
          data);
    } else if (type == 'MultiPoint' ||
        type == 'MultiLineString' ||
        type == 'MultiPolygon') {
      for (final part in coordinates) {
        await _addGeometry(controller,
            {'type': type.toString().substring(5), 'coordinates': part}, data);
      }
    }
  }

  Future<void> _addSurveyFeature(
    MapLibreMapController controller,
    Map<String, dynamic> responses,
    Map<String, dynamic> data,
  ) async {
    final type = responses['feature_type'];
    if (data['reference'] != true &&
        _geometryFilter != 'all' &&
        _geometryFilter != type) return;
    final opacity =
        ((data['opacity'] as num?)?.toDouble() ?? 1) * _layerOpacity;
    if (type == 'point') {
      final lat = responses['latitude'];
      final lon = responses['longitude'];
      if (lat is num && lon is num) {
        await controller.addCircle(
          CircleOptions(
            geometry: LatLng(lat.toDouble(), lon.toDouble()),
            circleRadius: 7,
            circleColor: data['color'] as String? ?? '#E53935',
            circleOpacity: opacity,
            circleStrokeWidth: 2,
            circleStrokeColor: '#FFFFFF',
            circleStrokeOpacity: opacity,
            draggable: data['read_only_geometry'] != true,
          ),
          data,
        );
      }
    } else if (type == 'line' || type == 'polygon') {
      final rawVertices = responses['vertices'];
      if (rawVertices is List) {
        final vertices = [
          for (final v in rawVertices)
            if (v is Map && v['latitude'] is num && v['longitude'] is num)
              LatLng(
                (v['latitude'] as num).toDouble(),
                (v['longitude'] as num).toDouble(),
              ),
        ];
        if (vertices.length >= 2 && type == 'line') {
          await controller.addLine(
            LineOptions(
              geometry: vertices,
              lineColor: data['color'] as String? ?? '#1565C0',
              lineWidth: 4.0,
              lineOpacity: 0.9 * opacity,
            ),
            data,
          );
        } else if (vertices.length >= 3) {
          await controller.addFill(
            FillOptions(
              geometry: responses['polygon_rings'] as List<List<LatLng>>? ??
                  [vertices],
              fillColor: data['color'] as String? ?? '#2E7D32',
              fillOpacity: 0.35 * opacity,
              fillOutlineColor: data['color'] as String? ?? '#1B5E20',
            ),
            data,
          );
        }
      }
    }
  }

  Future<void> _clearSurveyAnnotations() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.symbolManager != null) {
      await controller.clearSymbols();
    }
    if (controller.lineManager != null) {
      await controller.clearLines();
    }
    if (controller.fillManager != null) {
      await controller.clearFills();
    }
    if (controller.circleManager != null) {
      await controller.clearCircles();
    }
  }

  // ── drawing ──────────────────────────────────────────────────

  void _startPointDraft() {
    if (_currentLocation == null) {
      _showSnack(ui(context, 'Waiting for a GPS fix to place the point'));
      return;
    }
    setState(() {
      _draftType = _DraftType.point;
    });
    _placePointAtCurrentFix();
  }

  Future<void> _placePointAtCurrentFix() async {
    if (_manualMode) return;
    final controller = _controller;
    final location = _currentLocation;
    if (!_styleReady || controller == null || location == null) return;
    if (_draftPoint != null) {
      await controller.removeCircle(_draftPoint!);
    }
    final circle = await controller.addCircle(
      CircleOptions(
        geometry: location,
        circleRadius: 10,
        circleColor: '#E53935',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
        draggable: true,
      ),
    );
    if (!mounted) return;
    setState(() {
      _draftPoint = circle;
      _draftPointFix = (
        lat: location.latitude,
        lon: location.longitude,
        accuracy: _currentAccuracy ?? 0,
      );
    });
  }

  void _startLineDraft() {
    if (_selectedProjectId == null) {
      _showSnack(ui(context, 'Select a project before drawing'));
      return;
    }
    setState(() {
      _draftType = _DraftType.line;
    });
    if (!_manualMode) _placeDraftPlaceholder();
  }

  void _startPolygonDraft() {
    if (_selectedProjectId == null) {
      _showSnack(ui(context, 'Select a project before drawing'));
      return;
    }
    setState(() {
      _draftType = _DraftType.polygon;
    });
    if (!_manualMode) _placeDraftPlaceholder();
  }

  /// Shows a placeholder marker at the current GPS fix while a line/polygon
  /// draft is active but no vertices have been recorded yet, so the user can
  /// see where the sketch will start.
  Future<void> _placeDraftPlaceholder() async {
    if (_manualMode) return;
    final controller = _controller;
    final location = _currentLocation;
    if (!_styleReady || controller == null || location == null) return;
    if (_draftPlaceholder != null) {
      await controller.removeCircle(_draftPlaceholder!);
    }
    final circle = await controller.addCircle(
      CircleOptions(
        geometry: location,
        circleRadius: 9,
        circleColor: '#1E88E5',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
        draggable: true,
      ),
    );
    if (!mounted) return;
    setState(() {
      _draftPlaceholder = circle;
      _draftStartFix = null;
    });
  }

  Future<void> _moveDraftPlaceholder() async {
    final controller = _controller;
    final placeholder = _draftPlaceholder;
    final location = _currentLocation;
    if (!_styleReady || controller == null || placeholder == null) return;
    if (location == null) return;
    // Once the user drags the marker to a custom spot, stop re-centering it
    // on every GPS fix so the chosen drop point is preserved.
    if (_draftStartFix != null) return;
    await controller.updateCircle(
      placeholder,
      CircleOptions(geometry: location),
    );
  }

  void _beginRecording() {
    _removeDraftPlaceholder();
    setState(() {
      _recorder.start();
    });
    final startFix = _draftStartFix;
    if (startFix != null) {
      _recorder.add(
        Position(
          latitude: startFix.lat,
          longitude: startFix.lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      _refreshDraftGeometry();
    }
    _restartTicker();
    _startLocationStream(foreground: true);
  }

  void _refreshDraftGeometry() {
    if (!mounted || _controller == null || !_styleReady) return;
    if (_manualMode) {
      _manualRenderQueue = _manualRenderQueue
          .then((_) => _renderManual())
          .catchError((Object error) {
        if (mounted)
          _showSnack(
              ui(context, 'Could not update drawing. Tap Undo and try again.'));
      });
    } else {
      _updateDraftAnnotations();
    }
  }

  Future<void> _renderManual() async {
    final controller = _controller;
    if (!mounted || controller == null || !_styleReady || !_manualMode) return;
    final revision = _manualRevision;
    final oldMarkers = List<Circle>.from(_manualMarkers);
    _manualMarkers.clear();
    for (final marker in oldMarkers) {
      await controller.removeCircle(marker);
    }
    _manualMarkers.clear();
    if (_draftLine != null) {
      await controller.removeLine(_draftLine!);
      _draftLine = null;
    }
    if (_draftFill != null) {
      await controller.removeFill(_draftFill!);
      _draftFill = null;
    }
    if (!_draftActive || _draftType == _DraftType.point) return;
    final points = List<LatLng>.from(_manualVertices);
    for (final p in points) {
      final marker = await controller.addCircle(CircleOptions(
          geometry: p,
          circleRadius: 5,
          circleColor: '#f4511e',
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 2));
      if (revision != _manualRevision || !mounted || !_draftActive) {
        await controller.removeCircle(marker);
        return;
      }
      _manualMarkers.add(marker);
    }
    if (points.length >= 2) {
      _draftLine = await controller.addLine(LineOptions(geometry: [
        ...points,
        if (_draftType == _DraftType.polygon && points.length >= 3) points.first
      ], lineColor: '#f4511e', lineWidth: 3));
      if (revision != _manualRevision || !mounted || !_draftActive) {
        if (_draftLine != null) await controller.removeLine(_draftLine!);
        _draftLine = null;
        return;
      }
    }
    if (_draftType == _DraftType.polygon && points.length >= 3) {
      _draftFill = await controller.addFill(FillOptions(
          geometry: [points], fillColor: '#f4511e', fillOpacity: 0.25));
      if (revision != _manualRevision || !mounted || !_draftActive) {
        if (_draftFill != null) await controller.removeFill(_draftFill!);
        _draftFill = null;
      }
    }
  }

  void _toggleManualMode() {
    if (_draftActive || _measureActive) {
      _showSnack(ui(context,
          'Finish or cancel the current drawing before changing capture mode.'));
      return;
    }
    setState(() => _manualMode = !_manualMode);
  }

  void _startCapture(_DraftType type) {
    if (!_manualMode) {
      switch (type) {
        case _DraftType.point:
          _startPointDraft();
          break;
        case _DraftType.line:
          _startLineDraft();
          break;
        case _DraftType.polygon:
          _startPolygonDraft();
          break;
        case _DraftType.none:
          break;
      }
      return;
    }
    if (_selectedProjectId == null) {
      _showSnack(ui(context, 'Select a project before drawing'));
      return;
    }
    setState(() {
      _centeredOnInitialLocation = true;
      _draftType = type;
      _manualVertices.clear();
    });
  }

  Future<void> _updateDraftAnnotations() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;

    final vertices = [
      for (final p in _recorder.vertices) LatLng(p.latitude, p.longitude),
    ];
    if (vertices.isEmpty) return;

    if (_draftType == _DraftType.line) {
      if (_draftLine == null) {
        final line = await controller.addLine(
          LineOptions(
            geometry: vertices,
            lineColor: '#F4511E',
            lineWidth: 4.0,
            lineOpacity: 1.0,
          ),
        );
        if (mounted) setState(() => _draftLine = line);
      } else {
        await controller.updateLine(
          _draftLine!,
          LineOptions(geometry: vertices),
        );
      }
    } else if (_draftType == _DraftType.polygon && vertices.length >= 3) {
      if (_draftFill == null) {
        final fill = await controller.addFill(
          FillOptions(
            geometry: [vertices],
            fillColor: '#F4511E',
            fillOpacity: 0.4,
            fillOutlineColor: '#BF360C',
          ),
        );
        if (mounted) setState(() => _draftFill = fill);
      } else {
        await controller.updateFill(
          _draftFill!,
          FillOptions(geometry: [vertices]),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _finishDraft() async {
    final fields = _workspace?.form != null || _selectedProjectId == null
        ? const <String>[]
        : (await _database.getProjectFields(_selectedProjectId!))
            .map((f) => f.name)
            .toList();
    if (!mounted) return;
    final fix = _draftPointFix;
    if (_draftType == _DraftType.point && fix != null) {
      final result = await showFeatureDetailSheet(
        context,
        featureType: 'point',
        latitude: fix.lat,
        longitude: fix.lon,
        accuracyM: _manualMode ? null : fix.accuracy,
        fields: fields,
      );
      if (result != null) {
        final saved = await _saveFeature(
          featureType: 'point',
          result: result,
          latitude: fix.lat,
          longitude: fix.lon,
          accuracyM: _manualMode ? null : fix.accuracy,
        );
        if (saved && mounted) _cancelDraft();
      }
      return;
    }

    if (_draftType == _DraftType.line || _draftType == _DraftType.polygon) {
      final vertices = _draftVertices;
      final minVertices = _draftType == _DraftType.line ? 2 : 3;
      if (vertices.length < minVertices) {
        _showSnack(
          ui(context, 'Need at least {v0} vertices to finish ({v1} collected)',
              [minVertices, vertices.length]),
        );
        return;
      }
      if (vertices.toSet().length < minVertices) {
        _showSnack(
            ui(context, 'Add at least {v0} distinct vertices.', [minVertices]));
        return;
      }
      if (_draftType == _DraftType.polygon &&
          GeometryService.polygonAreaM2(vertices) < 0.001) {
        _showSnack(ui(context, 'Polygon vertices must enclose an area.'));
        return;
      }
      final result = await showFeatureDetailSheet(
        context,
        featureType: _draftType == _DraftType.line ? 'line' : 'polygon',
        vertices: vertices,
        fields: fields,
      );
      if (result != null) {
        final saved = await _saveFeature(
          featureType: _draftType == _DraftType.line ? 'line' : 'polygon',
          result: result,
          vertices: vertices,
        );
        if (saved && mounted) _cancelDraft();
      }
    }
  }

  Future<bool> _saveFeature({
    required String featureType,
    required FeatureDetailResult result,
    double? latitude,
    double? longitude,
    double? accuracyM,
    List<({double lat, double lon})>? vertices,
  }) async {
    final projectId = _selectedProjectId;
    if (projectId == null) {
      _showSnack(ui(context, 'No project selected'));
      return false;
    }

    final schema = _workspace?.schema;
    Map<String, dynamic> answers = {};
    if (schema != null) {
      final geometry = featureType == 'point'
          ? {
              'type': 'Point',
              'coordinates': [longitude, latitude]
            }
          : {
              'type': featureType == 'line' ? 'LineString' : 'Polygon',
              'coordinates': featureType == 'line'
                  ? [
                      for (final p
                          in vertices ?? <({double lat, double lon})>[])
                        [p.lon, p.lat]
                    ]
                  : [
                      [
                        for (final p
                            in vertices ?? <({double lat, double lon})>[])
                          [p.lon, p.lat],
                        if (vertices?.isNotEmpty == true)
                          [vertices!.first.lon, vertices.first.lat]
                      ]
                    ]
            };
      for (final question in schema.questions) {
        if (question.type == QuestionType.geopoint && featureType == 'point') {
          answers[question.name] = '$latitude,$longitude,${accuracyM ?? 0}';
        } else if (question.type == QuestionType.geotrace &&
                featureType == 'line' ||
            question.type == QuestionType.geoshape &&
                featureType == 'polygon') {
          answers[question.name] = jsonEncode(geometry);
        }
        if (question.type == QuestionType.image && result.photo != null)
          answers[question.name] = result.photo!.toJson();
      }
      final edited = await editFormAttributes(context,
          form: schema,
          answers: answers,
          username: await _database.getSetting('user_name'));
      if (edited == null) return false;
      answers = edited;
    }
    final responses = <String, dynamic>{
      'layer_id': _workspace?.layerId ?? 'default',
      'capture_method': _manualMode ? 'manual' : 'gps',
      if (schema != null) 'form_id': schema.id,
      if (schema != null) 'form_name': schema.name,
      if (schema != null) 'form_snapshot': schema.toJson(),
      if (schema != null) 'answers': answers,
      'feature_type': featureType,
      'user_name': await _database.getSetting('user_name'),
      'recorded_at': DateTime.now().toIso8601String(),
      'id': result.id,
      'name': result.name,
      'notes': result.notes,
      if (result.photo != null) 'photo': result.photo!.toJson(),
      if (result.fieldValues.isNotEmpty) 'fields': result.fieldValues,
    };

    String title;
    if (featureType == 'point') {
      responses['latitude'] = latitude;
      responses['longitude'] = longitude;
      responses['accuracy_m'] = accuracyM;
      title = 'Point ${result.id.isEmpty ? '' : result.id}';
    } else {
      final v = vertices ?? const [];
      responses['vertices'] = [
        for (final p in v) {'latitude': p.lat, 'longitude': p.lon},
      ];
      final length = GeometryService.polylineLengthM(v);
      if (featureType == 'line') {
        responses['length_m'] = length;
        responses['vertex_count'] = v.length;
        responses['elapsed_s'] = _recorder.elapsed.inSeconds;
        title = 'Line ${result.id.isEmpty ? '' : result.id} • '
            '${GeometryService.formatDistance(length)}';
      } else {
        final area = GeometryService.polygonAreaM2(v);
        responses['area_m2'] = area;
        responses['perimeter_m'] = GeometryService.polygonPerimeterM(v);
        responses['vertex_count'] = v.length;
        responses['elapsed_s'] = _recorder.elapsed.inSeconds;
        title = 'Polygon ${result.id.isEmpty ? '' : result.id} • '
            '${GeometryService.formatArea(area)}';
      }
    }
    if (result.name.isNotEmpty) title = '$title — ${result.name}';

    final resumeDraftId = _resumeDraftSessionId;
    final int sessionId;
    if (resumeDraftId != null) {
      final draft = await _database.getSurveySession(resumeDraftId);
      if (draft == null ||
          draft.projectId != projectId ||
          draft.status != 'draft') {
        throw StateError('The resumed draft no longer belongs to this project');
      }
      await _database.updateSurveySession(
        resumeDraftId,
        title: title,
        status: 'saved',
        responses: jsonEncode(responses),
      );
      sessionId = resumeDraftId;
      _resumeDraftSessionId = null;
    } else {
      sessionId = await _database.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value(title),
          status: const drift.Value('saved'),
          responses: drift.Value(jsonEncode(responses)),
        ),
      );
    }
    if (!mounted) return true;
    _showSnack(ui(context, '{v0} saved', [featureType]));
    final controller = _controller;
    if (controller == null || !_styleReady) return true;
    try {
      await _addSurveyFeature(
        controller,
        responses,
        {
          'session_id': sessionId,
          'title': title,
          'feature_type': featureType,
        },
      );
    } catch (_) {
      // The feature is already in the database; it renders on the next
      // map load.
    }
    return true;
  }

  void _cancelDraft() {
    final wasRecording =
        (_draftType == _DraftType.line || _draftType == _DraftType.polygon) &&
            _recorder.running;
    _resumeDraftSessionId = null;
    _recorder.reset();
    _manualRevision++;
    _manualVertices.clear();
    for (final marker in _manualMarkers) {
      _controller?.removeCircle(marker);
    }
    _manualMarkers.clear();
    _ticker?.cancel();
    _removeDraftAnnotations();
    if (mounted) {
      setState(() {
        _draftType = _DraftType.none;
        _draftPoint = null;
        _draftLine = null;
        _draftFill = null;
        _draftPointFix = null;
        _draftStartFix = null;
        _draftPlaceholder = null;
      });
    }
    if (wasRecording) {
      _startLocationStream();
    }
  }

  String get _draftTypeName {
    switch (_draftType) {
      case _DraftType.point:
        return 'point';
      case _DraftType.line:
        return 'line';
      case _DraftType.polygon:
        return 'polygon';
      case _DraftType.none:
        return '';
    }
  }

  bool get _canSaveDraft {
    if (!_draftActive) return false;
    if (_draftType == _DraftType.point) return _draftPointFix != null;
    return _draftVertices.isNotEmpty;
  }

  /// Stores the in-progress feature as a draft session so it can be resumed
  /// later from the History screen (for the selected project).
  Future<void> _saveDraft() async {
    final projectId = _selectedProjectId;
    if (projectId == null) {
      _showSnack(ui(context, 'No project selected'));
      return;
    }
    if (!_canSaveDraft) return;

    final responses = <String, dynamic>{
      'draft': true,
      'capture_method': _manualMode ? 'manual' : 'gps',
      if (_manualMode)
        'manual_vertices': [
          for (final p in _manualVertices) [p.longitude, p.latitude]
        ],
      'layer_id': _workspace?.layerId ?? 'default',
      'feature_type': _draftTypeName,
      'user_name': await _database.getSetting('user_name'),
      'saved_at': DateTime.now().toIso8601String(),
    };

    String title;
    if (_draftType == _DraftType.point) {
      final fix = _draftPointFix;
      if (fix == null) {
        _showSnack(
            ui(context, 'Waiting for a GPS fix before saving the draft'));
        return;
      }
      responses['latitude'] = fix.lat;
      responses['longitude'] = fix.lon;
      responses['accuracy_m'] = fix.accuracy;
      title = 'Draft point';
    } else {
      responses['recorder'] = _recorder.serialize();
      final pts = _draftVertices;
      title = _draftType == _DraftType.line ? 'Draft line' : 'Draft polygon';
      if (pts.length >= 1) {
        title = '$title • ${pts.length} pts';
      }
    }

    final targetId = _resumeDraftSessionId;
    if (targetId != null) {
      final draft = await _database.getSurveySession(targetId);
      if (draft == null ||
          draft.projectId != projectId ||
          draft.status != 'draft') {
        throw StateError('The resumed draft no longer belongs to this project');
      }
      await _database.updateSurveySession(
        targetId,
        title: title,
        status: 'draft',
        responses: jsonEncode(responses),
      );
    } else {
      await _database.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value(title),
          status: const drift.Value('draft'),
          responses: drift.Value(jsonEncode(responses)),
        ),
      );
    }
    if (!mounted) return;
    _showSnack(ui(context, 'Draft saved — resume it from History later'));
  }

  // ── measurement tools ────────────────────────────────────────

  bool get _measureActive => _measureTool != _MeasureTool.none;
  bool get _editingActive => _draftActive || _measureActive;

  Future<void> _toggleMeasureTool(_MeasureTool tool) async {
    if (_editingActive && !_measureActive) return;
    if (_measureTool == tool) {
      await _endMeasure();
      return;
    }
    _measureDistanceUnit = DistanceUnit.fromSetting(
      await _database.getSetting('distance_unit'),
    );
    _measureAreaUnit = AreaUnit.fromSetting(
      await _database.getSetting('area_unit'),
    );
    if (!mounted) return;
    setState(() {
      _measureTool = tool;
      _measurePoints = [];
    });
  }

  void _onMapMeasureTap(Point<double> point, LatLng coordinates) {
    if (_manualMode && _draftActive) {
      if (_draftType == _DraftType.point) {
        setState(() => _draftPointFix = (
              lat: coordinates.latitude,
              lon: coordinates.longitude,
              accuracy: 0
            ));
        _restorePointDraftMarker();
      } else {
        setState(() => _manualVertices.add(coordinates));
        _refreshDraftGeometry();
      }
      return;
    }
    if (_measureTool == _MeasureTool.none) return;
    _addMeasurePoint(coordinates);
  }

  Future<void> _addMeasurePoint(LatLng coordinates) async {
    final controller = _controller;
    if (!_styleReady || controller == null) return;
    _measurePoints = [
      ..._measurePoints,
      (lat: coordinates.latitude, lon: coordinates.longitude),
    ];
    final circle = await controller.addCircle(
      CircleOptions(
        geometry: coordinates,
        circleRadius: 6,
        circleColor: '#00ACC1',
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ),
    );
    if (!mounted) return;
    setState(() {
      _measureMarkers = [..._measureMarkers, circle];
    });
    _updateMeasureOverlay();
  }

  Future<void> _updateMeasureOverlay() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    final geometry = [
      for (final p in _measurePoints) LatLng(p.lat, p.lon),
    ];

    if (_measureTool == _MeasureTool.distance && geometry.length >= 2) {
      final line = _measureLine;
      if (line == null) {
        final added = await controller.addLine(
          LineOptions(
            geometry: geometry,
            lineColor: '#00ACC1',
            lineWidth: 3.0,
            lineOpacity: 0.9,
          ),
        );
        if (mounted) setState(() => _measureLine = added);
      } else {
        await controller.updateLine(line, LineOptions(geometry: geometry));
      }
    } else if (_measureTool == _MeasureTool.area) {
      final closed = [
        ...geometry,
        if (geometry.length >= 3) geometry.first,
      ];
      if (closed.length >= 2) {
        final line = _measureLine;
        if (line == null) {
          final added = await controller.addLine(
            LineOptions(
              geometry: closed,
              lineColor: '#26A69A',
              lineWidth: 3.0,
              lineOpacity: 0.9,
            ),
          );
          if (mounted) setState(() => _measureLine = added);
        } else {
          await controller.updateLine(
            line,
            LineOptions(geometry: closed),
          );
        }
      }
      if (geometry.length >= 3) {
        final fill = _measureFill;
        if (fill == null) {
          final added = await controller.addFill(
            FillOptions(
              geometry: [geometry],
              fillColor: '#26A69A',
              fillOpacity: 0.25,
              fillOutlineColor: '#00695C',
            ),
          );
          if (mounted) setState(() => _measureFill = added);
        } else {
          await controller.updateFill(fill, FillOptions(geometry: [geometry]));
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _undoMeasurePoint() async {
    final controller = _controller;
    if (_measureMarkers.isNotEmpty && controller != null) {
      await controller.removeCircle(_measureMarkers.last);
    }
    if (!mounted) return;
    setState(() {
      if (_measurePoints.isNotEmpty) {
        _measurePoints = _measurePoints.sublist(0, _measurePoints.length - 1);
      }
      if (_measureMarkers.isNotEmpty) {
        _measureMarkers =
            _measureMarkers.sublist(0, _measureMarkers.length - 1);
      }
    });
    _updateMeasureOverlay();
  }

  Future<void> _endMeasure() async {
    final controller = _controller;
    if (controller != null && mounted) {
      for (final marker in _measureMarkers) {
        await controller.removeCircle(marker);
      }
      if (_measureLine != null) {
        await controller.removeLine(_measureLine!);
      }
      if (_measureFill != null) {
        await controller.removeFill(_measureFill!);
      }
    }
    if (!mounted) return;
    setState(() {
      _measureTool = _MeasureTool.none;
      _measurePoints = [];
      _measureMarkers = [];
      _measureLine = null;
      _measureFill = null;
    });
  }

  Future<void> _removeDraftAnnotations() async {
    final controller = _controller;
    if (controller == null) return;
    final point = _draftPoint;
    final placeholder = _draftPlaceholder;
    final line = _draftLine;
    final fill = _draftFill;
    if (point != null) {
      await controller.removeCircle(point);
    }
    if (placeholder != null) {
      await controller.removeCircle(placeholder);
    }
    if (line != null) {
      await controller.removeLine(line);
    }
    if (fill != null) {
      await controller.removeFill(fill);
    }
  }

  Future<void> _removeDraftPlaceholder() async {
    final controller = _controller;
    final placeholder = _draftPlaceholder;
    if (controller == null || placeholder == null) return;
    await controller.removeCircle(placeholder);
    if (mounted) setState(() => _draftPlaceholder = null);
  }

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  bool get _draftActive => _draftType != _DraftType.none;

  // ── ui actions ───────────────────────────────────────────────

  Future<void> _centerOnLocation() async {
    final location = _currentLocation;
    if (location == null) {
      _showSnack(ui(context, 'Waiting for a GPS fix'));
      return;
    }
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16),
    );
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

  Future<void> _showProjectPicker() async {
    final projects = _projects;
    if (projects.isEmpty) {
      _showSnack(ui(context,
          'No projects yet — open Project Settings on Home to create one, or use Import Project to import a .mbproj file'));
      return;
    }
    final selected = await showDialog<Project>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(ui(context, 'Select project')),
        children: [
          for (final project in projects)
            RadioListTile<Project>(
              title: Text(project.name),
              subtitle: Text(
                project.description.trim().isEmpty
                    ? ui(context, 'No description')
                    : project.description.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: project,
              groupValue: projects.firstWhere(
                (p) => p.id == _selectedProjectId,
                orElse: () => projects.first,
              ),
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
            ),
          if (projects.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(ui(context, 'No projects yet')),
            ),
        ],
      ),
    );
    if (selected != null && selected.id != _selectedProjectId) {
      await _selectProject(selected.id, selected.name);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── build ────────────────────────────────────────────────────

  Future<void> _workspaceSheet() async {
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .8),
                child: SingleChildScrollView(child: _buildProjectBar()))));
    if (mounted) setState(() {});
  }

  Future<void> _saveProjectLayer() async {
    if (_selectedProjectId == null || _editingActive) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ResponseLayerScreen(
                database: _database,
                projectId: _selectedProjectId!,
                initialLayerId: _workspace?.layerId)));
  }

  Future<void> _projectLayers() async {
    if (_selectedProjectId == null || _editingActive) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProjectVectorLayersScreen(
                database: _database, projectId: _selectedProjectId!)));
    if (!mounted) return;
    _workspace =
        await ProjectWorkspaceService(_database).load(_selectedProjectId!);
    await _clearSurveyAnnotations();
    await _addSurveyAnnotations();
    if (mounted) setState(() {});
  }

  Future<void> _filtersSheet() async {
    if (_editingActive) return;
    await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .75),
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(ui(context, 'Map filters'),
                              style: Theme.of(context).textTheme.titleLarge),
                          Wrap(spacing: 8, runSpacing: 4, children: [
                            for (final entry in {
                              'all': 'All',
                              'point': 'Points',
                              'line': 'Lines',
                              'polygon': 'Polygons'
                            }.entries)
                              ChoiceChip(
                                  label: Text(ui(context, entry.value)),
                                  selected: _geometryFilter == entry.key,
                                  onSelected: (_) {
                                    update(() => _geometryFilter = entry.key);
                                    setState(() {});
                                  }),
                          ]),
                          Text(ui(context, 'Layer opacity')),
                          Slider(
                              value: _layerOpacity,
                              label: '${(_layerOpacity * 100).round()}%',
                              onChanged: (value) {
                                update(() => _layerOpacity = value);
                                setState(() {});
                              }),
                          FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(ui(context, 'Apply'))),
                        ]))))));
    if (!mounted) return;
    await _clearSurveyAnnotations();
    await _addSurveyAnnotations();
  }

  @override
  Widget build(BuildContext context) {
    final basemap = Basemap.defaults.firstWhere(
      (b) => b.id == _selectedBasemapId,
      orElse: () => Basemap.defaults.first,
    );

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(ui(context, 'GIS Mode'),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              tooltip: ui(context,
                  _manualMode ? 'Hand drawing on' : 'Hand drawing off'),
              isSelected: _manualMode,
              icon: const Icon(Icons.draw_outlined),
              selectedIcon: const Icon(Icons.draw),
              onPressed: _toggleManualMode),
          Tooltip(
            message: _locationStatus,
            child: IconButton(
              onPressed: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildGpsCard()))),
              icon: Icon(
                _locationStatus.contains('ready')
                    ? Icons.location_on
                    : Icons.location_off,
                color: _locationStatus.contains('ready')
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ),
          IconButton(
            tooltip: ui(context, 'Basemap'),
            icon: const Icon(Icons.map_outlined),
            onPressed: _showBasemapDialog,
          ),
        ],
      ),
      body: LayoutBuilder(
          builder: (context, bounds) => Stack(
                children: [
                  MapLibreMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ?? const LatLng(0, 0),
                      zoom: _currentLocation == null ? 2 : 16,
                    ),
                    onMapCreated: _onMapCreated,
                    onStyleLoadedCallback: _onStyleLoaded,
                    onMapClick: _onMapMeasureTap,
                    styleString:
                        _offlineBasemap?.style ?? _buildStyleString(basemap),
                    myLocationEnabled: true,
                    myLocationRenderMode: MyLocationRenderMode.normal,
                    compassViewPosition: CompassViewPosition.bottomRight,
                    compassViewMargins: const Point(16, 56),
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
                  Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: MapControlSurface(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(children: [
                            Expanded(
                                child: TextButton.icon(
                                    onPressed:
                                        _editingActive ? null : _workspaceSheet,
                                    icon: const Icon(Icons.layers_outlined),
                                    label: Text(
                                        _workspace == null
                                            ? ui(context, 'Select project')
                                            : '${_workspace!.project.name} · ${_workspace!.layer.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis))),
                            IconButton(
                                tooltip: ui(context, 'Map filters'),
                                onPressed:
                                    _editingActive ? null : _filtersSheet,
                                icon: const Icon(Icons.tune)),
                            PopupMenuButton<String>(
                                enabled: !_editingActive,
                                tooltip: ui(context, 'Layer options'),
                                onSelected: (value) {
                                  if (value == 'save')
                                    _saveProjectLayer();
                                  else
                                    _projectLayers();
                                },
                                itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'save',
                                          child: Text(ui(context,
                                              'Save as project layer'))),
                                      PopupMenuItem(
                                          value: 'layers',
                                          child: Text(
                                              ui(context, 'Project layers'))),
                                    ]),
                          ]))),
                  if (_draftActive)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 64,
                      child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxHeight: bounds.maxHeight * .48),
                          child: SingleChildScrollView(
                              child: ScreenLayout.mapPanel(
                                  context, _buildDraftBanner()))),
                    ),
                  if (_measureActive)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 60,
                      child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxHeight: bounds.maxHeight * .48),
                          child: SingleChildScrollView(
                              child: ScreenLayout.mapPanel(
                                  context, _buildMeasureBanner()))),
                    ),
                  if (_showInfoPanel)
                    Positioned(
                      left: 16,
                      right: 72,
                      bottom: 96,
                      child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxHeight: bounds.maxHeight * .48),
                          child: SingleChildScrollView(
                              child: ScreenLayout.mapPanel(
                                  context, _buildInfoPanel()))),
                    ),
                ],
              )),
      bottomNavigationBar: SafeArea(top: false, child: _buildBottomToolbar()),
    );
  }

  String _buildStyleString(Basemap basemap) =>
      MapStyleChoice.online(basemap).style;

  Widget _buildProjectBar() => ProjectWorkspaceBar(
      database: _database,
      workspace: _workspace,
      enabled: !_draftActive,
      onChanged: (workspace) async {
        await _selectProject(workspace.project.id, workspace.project.name);
        if (mounted) Navigator.pop(context);
      });

  Widget _buildGpsCard() {
    final location = _currentLocation;
    final accuracy = _currentAccuracy;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gps_fixed,
              color: location != null ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
                child: Text(
              location != null
                  ? '${location.latitude.toStringAsFixed(5)}, '
                      '${location.longitude.toStringAsFixed(5)}'
                      '${accuracy != null ? '  ±${accuracy.toStringAsFixed(1)} m' : ''}'
                  : ui(context, 'GPS: Searching...'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _editSelectedAttributes() async {
    final info = _infoFeature;
    if (info == null) return;
    if (info.studySite) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StudyAreaModeScreen(
              projectId: _selectedProjectId, database: _database)));
      await _clearSurveyAnnotations();
      await _addSurveyAnnotations();
      return;
    }
    final row = await _database.getSurveySession(info.sessionId);
    if (row == null || !mounted) return;
    final project = await _database.getProjectById(row.projectId);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SurveySessionDetailScreen(
            session: row, projectName: project?.name ?? '')));
    await _clearSurveyAnnotations();
    await _addSurveyAnnotations();
  }

  Widget _buildInfoPanel() {
    final info = _infoFeature;
    return Card(
      elevation: 4,
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
                    ui(context, 'Feature Info'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: ui(context, 'Close'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _showInfoPanel = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (info == null)
              Text(
                ui(context, 'Tap a feature on the map to see its details'),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else ...[
              TextButton.icon(
                  onPressed: _editSelectedAttributes,
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(ui(context, 'View / edit information'))),
              Text(
                info.title,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                ui(context, '{v0}  •  session #{v1}',
                    [info.featureType, info.sessionId]),
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (info.featureType == 'point') ...[
                const SizedBox(height: 6),
                Text(
                  ui(context, 'Drag the point on the map to move it.'),
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onPressed: _deleteSelectedFeature,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(ui(context, 'Delete')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDraftBanner() {
    final recording = _recorder.running;
    final points = _draftVertices;
    final vertices = points.length;

    return Card(
      elevation: 6,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _draftType == _DraftType.point
                      ? Icons.add_location_alt
                      : _draftType == _DraftType.line
                          ? Icons.polyline
                          : Icons.pentagon,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildDraftTitle(vertices),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildDraftMetrics(points),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _canSaveDraft ? _saveDraft : null,
                icon: const Icon(Icons.edit_note, size: 18),
                label: Text(ui(context, 'Save draft')),
              ),
            ),
            const SizedBox(height: 4),
            _buildDraftActions(recording),
          ],
        ),
      ),
    );
  }

  String _buildDraftTitle(int vertices) {
    if (_manualMode)
      return ui(context, 'Hand drawing • {v0} vertices', [
        _draftType == _DraftType.point
            ? (_draftPointFix == null ? 0 : 1)
            : vertices
      ]);
    switch (_draftType) {
      case _DraftType.point:
        return 'Drag the marker to set the point, then Finish';
      case _DraftType.line:
        return _recorder.running
            ? 'Recording line • $vertices vertices'
            : 'Line draft — drag the marker to set the start point';
      case _DraftType.polygon:
        return _recorder.running
            ? 'Recording polygon • $vertices vertices'
            : 'Polygon draft — drag the marker to set the start point';
      case _DraftType.none:
        return '';
    }
  }

  Widget _buildDraftMetrics(
    List<({double lat, double lon})> points,
  ) {
    if (_manualMode)
      return Text(
          ui(context,
              'Tap the map to place vertices. Undo removes the last vertex.'),
          style: const TextStyle(fontSize: 12));
    if (_draftType == _DraftType.point) {
      final fix = _draftPointFix;
      return Text(
        fix == null
            ? ui(context, 'Positioning…')
            : '${fix.lat.toStringAsFixed(6)}, ${fix.lon.toStringAsFixed(6)}'
                '${fix.accuracy > 0 ? '  ±${fix.accuracy.toStringAsFixed(1)} m' : ''}',
        style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    if (points.length < 2) {
      return Text(
        ui(context, 'Walk along the boundary while recording'),
        style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    final metrics = <String>[
      '${points.length} pts',
      GeometryService.formatDistance(GeometryService.polylineLengthM(points)),
      _recorder.elapsedLabel,
    ];
    if (_draftType == _DraftType.polygon && points.length >= 3) {
      metrics.add(GeometryService.formatArea(
        GeometryService.polygonAreaM2(points),
      ));
    }
    return Text(
      metrics.join('  •  '),
      style: TextStyle(
          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildDraftActions(bool recording) {
    if (_manualMode) {
      final enough = _draftType == _DraftType.point
          ? _draftPointFix != null
          : _manualVertices.length >= (_draftType == _DraftType.line ? 2 : 3);
      return Wrap(spacing: 8, children: [
        TextButton(onPressed: _cancelDraft, child: Text(ui(context, 'Cancel'))),
        if (_draftType != _DraftType.point)
          TextButton.icon(
              onPressed: _manualVertices.isEmpty
                  ? null
                  : () {
                      setState(() => _manualVertices.removeLast());
                      _refreshDraftGeometry();
                    },
              icon: const Icon(Icons.undo),
              label: Text(ui(context, 'Undo'))),
        FilledButton.icon(
            onPressed: enough ? _finishDraft : null,
            icon: const Icon(Icons.check),
            label: Text(ui(context, 'Finish'))),
      ]);
    }
    final List<Widget> actions = [];

    if (_draftType == _DraftType.point) {
      actions.addAll([
        OutlinedButton(
          onPressed: _cancelDraft,
          child: Text(ui(context, 'Cancel')),
        ),
        FilledButton.icon(
          onPressed: _finishDraft,
          icon: const Icon(Icons.check, size: 18),
          label: Text(ui(context, 'Finish')),
        ),
      ]);
      return ResponsiveGrid(minChildWidth: 125, children: actions);
    }

    if (!recording) {
      actions.addAll([
        OutlinedButton(
          onPressed: _cancelDraft,
          child: Text(ui(context, 'Cancel')),
        ),
        FilledButton.icon(
          onPressed: _beginRecording,
          icon: const Icon(Icons.play_arrow, size: 18),
          label: Text(ui(context, 'Start')),
        ),
      ]);
      return ResponsiveGrid(minChildWidth: 125, children: actions);
    }

    actions.addAll([
      OutlinedButton.icon(
        onPressed: () {
          setState(() {
            if (_recorder.paused) {
              _recorder.resume();
            } else {
              _recorder.pause();
            }
          });
        },
        icon: Icon(
          _recorder.paused ? Icons.play_arrow : Icons.pause,
          size: 18,
        ),
        label: Text(
            _recorder.paused ? ui(context, 'Resume') : ui(context, 'Pause')),
      ),
      OutlinedButton.icon(
        onPressed: _recorder.vertices.isEmpty
            ? null
            : () {
                _recorder.undo();
                _refreshDraftGeometry();
              },
        icon: const Icon(Icons.undo, size: 18),
        label: Text(ui(context, 'Undo')),
      ),
      FilledButton.icon(
        onPressed: _finishDraft,
        icon: const Icon(Icons.check, size: 18),
        label: Text(ui(context, 'Finish')),
      ),
    ]);
    return ResponsiveGrid(minChildWidth: 125, children: actions);
  }

  Widget _buildMeasureBanner() {
    final points = _measurePoints;
    final distanceUnit = _measureDistanceUnit;
    final areaUnit = _measureAreaUnit;
    final isArea = _measureTool == _MeasureTool.area;

    final length = GeometryService.polylineLengthM(points);
    final metrics = <String>[
      '${points.length} pts',
      MeasureUnits.formatDistance(length, distanceUnit),
    ];
    if (isArea && points.length >= 3) {
      metrics.insertAll(1, [
        MeasureUnits.formatArea(
            GeometryService.polygonAreaM2(points), areaUnit),
        'P ${MeasureUnits.formatDistance(GeometryService.polygonPerimeterM(points), distanceUnit)}',
      ]);
    }

    return Card(
      elevation: 6,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isArea ? Icons.square_foot : Icons.straighten,
                  color: const Color(0xFF00838F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArea
                        ? ui(context, 'Measure area — tap points on the map')
                        : ui(context,
                            'Measure distance — tap points on the map'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              points.isEmpty
                  ? ui(context, 'Tap the map to add the first point')
                  : metrics.join('  •  '),
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            ResponsiveGrid(
              minChildWidth: 125,
              children: [
                OutlinedButton.icon(
                  onPressed: points.isEmpty ? null : _undoMeasurePoint,
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text(ui(context, 'Undo')),
                ),
                OutlinedButton.icon(
                  onPressed: points.isEmpty ? null : () => _endMeasure(),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(ui(context, 'Clear')),
                ),
                FilledButton.icon(
                  onPressed: _endMeasure,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(ui(context, 'Done')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: MapControlSurface(
          padding: const EdgeInsets.all(4),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.sizeOf(context).width - 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Tooltip(
                        message: ui(context, 'Add Point'),
                        child: IconButton(
                          icon: CircleAvatar(
                            radius: 14,
                            backgroundColor: _draftType == _DraftType.point
                                ? Colors.red.shade50
                                : Colors.transparent,
                            child: Icon(
                              Icons.add_location_alt_outlined,
                              size: 22,
                              color: _editingActive
                                  ? Colors.grey
                                  : Colors.red.shade700,
                            ),
                          ),
                          onPressed: _editingActive
                              ? null
                              : () => _startCapture(_DraftType.point),
                        ),
                      ),
                      Tooltip(
                        message: ui(context, 'Draw Line'),
                        child: IconButton(
                          icon: Icon(
                            Icons.polyline_outlined,
                            size: 24,
                            color: _editingActive
                                ? Colors.grey
                                : Colors.blue.shade700,
                          ),
                          onPressed: _editingActive
                              ? null
                              : () => _startCapture(_DraftType.line),
                        ),
                      ),
                      Tooltip(
                        message: ui(context, 'Draw Polygon'),
                        child: IconButton(
                          icon: Icon(
                            Icons.pentagon_outlined,
                            size: 24,
                            color: _editingActive
                                ? Colors.grey
                                : Colors.blue.shade700,
                          ),
                          onPressed: _editingActive
                              ? null
                              : () => _startCapture(_DraftType.polygon),
                        ),
                      ),
                      Tooltip(
                        message: ui(context, 'Measure Distance'),
                        child: IconButton(
                          icon: Icon(
                            Icons.straighten,
                            size: 24,
                            color: _measureTool == _MeasureTool.distance
                                ? const Color(0xFF00838F)
                                : _draftActive
                                    ? Colors.grey
                                    : Colors.teal.shade700,
                          ),
                          onPressed: _draftActive
                              ? null
                              : () => _toggleMeasureTool(_MeasureTool.distance),
                        ),
                      ),
                      Tooltip(
                        message: ui(context, 'Measure Area'),
                        child: IconButton(
                          icon: Icon(
                            Icons.square_foot,
                            size: 24,
                            color: _measureTool == _MeasureTool.area
                                ? const Color(0xFF00838F)
                                : _draftActive
                                    ? Colors.grey
                                    : Colors.teal.shade700,
                          ),
                          onPressed: _draftActive
                              ? null
                              : () => _toggleMeasureTool(_MeasureTool.area),
                        ),
                      ),
                      Tooltip(
                        message: ui(context, 'Center on GPS'),
                        child: IconButton(
                          icon: const Icon(Icons.gps_fixed),
                          onPressed: _centerOnLocation,
                        ),
                      ),
                    ],
                  )))),
    );
  }
}
