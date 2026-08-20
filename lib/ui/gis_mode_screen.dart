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

enum _DraftType { none, point, line, polygon }

enum _MeasureTool { none, distance, area }

class _InfoFeature {
  final int sessionId;
  final String title;
  final String featureType;

  const _InfoFeature({
    required this.sessionId,
    required this.title,
    required this.featureType,
  });
}

class GisModeScreen extends StatefulWidget {
  final String projectName;

  /// When set, the screen restores an in-progress (draft) feature for this
  /// session id instead of starting fresh. The draft keeps saving to that
  /// same session until the user finishes (which promotes it to saved).
  final int? resumeDraftId;

  const GisModeScreen({
    required this.projectName,
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
  double? _currentAccuracy;
  String _locationStatus = 'Checking permission...';
  bool _styleReady = false;
  String _selectedBasemapId = 'osm';

  List<Project> _projects = [];
  int? _selectedProjectId;
  String? _selectedProjectName;

  int? _resumeDraftSessionId;

  _DraftType _draftType = _DraftType.none;
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
      (p) => p.name == widget.projectName,
    );
    if (current.isNotEmpty) {
      await _selectProject(current.first.id, current.first.name);
    } else if (projects.isNotEmpty) {
      await _selectProject(projects.first.id, projects.first.name);
    } else {
      setState(() {
        _selectedProjectId = null;
        _selectedProjectName = null;
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
    if (row == null || !mounted) return;

    Map<String, dynamic> responses;
    try {
      responses = jsonDecode(row.responses) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final featureType = responses['feature_type'];
    if (featureType == null) return;

    _resumeDraftSessionId = row.id;

    setState(() {
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
        _draftType = featureType == 'line'
            ? _DraftType.line
            : _DraftType.polygon;
        final raw = responses['recorder'];
        if (raw is Map<String, dynamic>) {
          _recorder.restore(raw);
        }
      }
    });

    _showSnack('Draft restored — continue, finish, or save it again');
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
    _cancelDraft();
    await _endMeasure();
    setState(() {
      _selectedProjectId = id;
      _selectedProjectName = name;
      _infoFeature = null;
      _showInfoPanel = false;
    });
    _clearSurveyAnnotations();
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
      _locationStatus = granted
          ? 'GPS ready'
          : 'Location permission not granted';
    });
    if (!granted) return;

    await _subscription?.cancel();

    final recording =
        foreground ??
        ((_draftType == _DraftType.line ||
                _draftType == _DraftType.polygon) &&
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
          _currentAccuracy = position.accuracy;
        });
        if (_draftType == _DraftType.point &&
            _draftPoint == null &&
            _draftPointFix == null) {
          _placePointAtCurrentFix();
        }
        if (_draftType == _DraftType.line ||
            _draftType == _DraftType.polygon) {
          if (!_recorder.running && _currentLocation != null) {
            if (_draftPlaceholder == null) {
              _placeDraftPlaceholder();
            } else {
              _moveDraftPlaceholder();
            }
          }
        }
        final recorded = _draftType == _DraftType.line ||
            _draftType == _DraftType.polygon;
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
    if (_currentLocation != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 16),
      );
    }
  }

  void _onStyleLoaded() {
    _styleReady = true;
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
    if (_measureTool != _MeasureTool.none) return;
    final data = _annotationData(annotation);
    final sessionId = data?['session_id'];
    final title = data?['title'] as String?;
    final featureType = data?['feature_type'] as String?;
    if (sessionId == null || !mounted) return;
    setState(() {
      _infoFeature = _InfoFeature(
        sessionId: sessionId is int ? sessionId : int.tryParse('$sessionId') ?? 0,
        title: title ?? 'Feature $sessionId',
        featureType: featureType ?? 'feature',
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

    responses['latitude'] = current.latitude;
    responses['longitude'] = current.longitude;
    await _database.updateSurveySession(
      parsedId,
      title: session.title,
      responses: jsonEncode(responses),
    );
    if (!mounted) return;
    _showSnack('Point moved');
  }

  Future<void> _deleteSelectedFeature() async {
    final info = _infoFeature;
    if (info == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete feature',
      message: 'Delete "${info.title}"? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteSurveySession(info.sessionId);
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
    _showSnack('Feature deleted');
  }

  // ── survey feature annotations ───────────────────────────────

  Future<void> _addSurveyAnnotations() async {
    final controller = _controller;
    final projectId = _selectedProjectId;
    if (!_styleReady || controller == null || projectId == null) return;

    final sessions = (await _database.getSurveySessions())
        .where((s) => s.projectId == projectId)
        .toList();

    for (final session in sessions) {
      if (session.status == 'draft') continue;
      final data = <String, dynamic>{
        'session_id': session.id,
        'title': session.title,
      };
      try {
        final responses =
            jsonDecode(session.responses) as Map<String, dynamic>;
        data['feature_type'] = responses['feature_type'] ?? 'unknown';
        await _addSurveyFeature(controller, responses, data);
      } catch (_) {
        // Skip sessions whose responses are not GeoJSON-like.
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _addSurveyFeature(
    MapLibreMapController controller,
    Map<String, dynamic> responses,
    Map<String, dynamic> data,
  ) async {
    final type = responses['feature_type'];
    if (type == 'point') {
      final lat = responses['latitude'];
      final lon = responses['longitude'];
      if (lat is num && lon is num) {
        await controller.addCircle(
          CircleOptions(
            geometry: LatLng(lat.toDouble(), lon.toDouble()),
            circleRadius: 7,
            circleColor: '#E53935',
            circleStrokeWidth: 2,
            circleStrokeColor: '#FFFFFF',
            draggable: true,
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
              lineColor: '#1565C0',
              lineWidth: 4.0,
              lineOpacity: 0.9,
            ),
            data,
          );
        } else if (vertices.length >= 3) {
          await controller.addFill(
            FillOptions(
              geometry: [vertices],
              fillColor: '#2E7D32',
              fillOpacity: 0.35,
              fillOutlineColor: '#1B5E20',
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
      _showSnack('Waiting for a GPS fix to place the point');
      return;
    }
    setState(() {
      _draftType = _DraftType.point;
    });
    _placePointAtCurrentFix();
  }

  Future<void> _placePointAtCurrentFix() async {
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
      _showSnack('Select a project before drawing');
      return;
    }
    setState(() {
      _draftType = _DraftType.line;
    });
    _placeDraftPlaceholder();
  }

  void _startPolygonDraft() {
    if (_selectedProjectId == null) {
      _showSnack('Select a project before drawing');
      return;
    }
    setState(() {
      _draftType = _DraftType.polygon;
    });
    _placeDraftPlaceholder();
  }

  /// Shows a placeholder marker at the current GPS fix while a line/polygon
  /// draft is active but no vertices have been recorded yet, so the user can
  /// see where the sketch will start.
  Future<void> _placeDraftPlaceholder() async {
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
    _updateDraftAnnotations();
  }

  Future<void> _updateDraftAnnotations() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;

    final vertices = [
      for (final p in _recorder.vertices)
        LatLng(p.latitude, p.longitude),
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
    final fields = _selectedProjectId == null
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
        accuracyM: fix.accuracy,
        fields: fields,
      );
      if (result != null) {
        await _removeDraftAnnotations();
        await _saveFeature(
          featureType: 'point',
          result: result,
          latitude: fix.lat,
          longitude: fix.lon,
          accuracyM: fix.accuracy,
        );
      }
      if (mounted) _cancelDraft();
      return;
    }

    if (_draftType == _DraftType.line || _draftType == _DraftType.polygon) {
      final vertices = [
        for (final p in _recorder.vertices)
          (lat: p.latitude, lon: p.longitude),
      ];
      final minVertices = _draftType == _DraftType.line ? 2 : 3;
      if (vertices.length < minVertices) {
        _showSnack(
          'Need at least $minVertices vertices to finish '
          '(${vertices.length} collected)',
        );
        return;
      }
      final result = await showFeatureDetailSheet(
        context,
        featureType:
            _draftType == _DraftType.line ? 'line' : 'polygon',
        vertices: vertices,
        fields: fields,
      );
      if (result != null) {
        await _removeDraftAnnotations();
        await _saveFeature(
          featureType:
              _draftType == _DraftType.line ? 'line' : 'polygon',
          result: result,
          vertices: vertices,
        );
      }
      if (mounted) _cancelDraft();
    }
  }

  Future<void> _saveFeature({
    required String featureType,
    required FeatureDetailResult result,
    double? latitude,
    double? longitude,
    double? accuracyM,
    List<({double lat, double lon})>? vertices,
  }) async {
    final projectId = _selectedProjectId;
    if (projectId == null) {
      _showSnack('No project selected');
      return;
    }

    final responses = <String, dynamic>{
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
        for (final p in v)
          {'latitude': p.lat, 'longitude': p.lon},
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
    if (!mounted) return;
    _showSnack('$featureType saved');
    final controller = _controller;
    if (controller == null || !_styleReady) return;
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
  }

  void _cancelDraft() {
    final wasRecording =
        (_draftType == _DraftType.line || _draftType == _DraftType.polygon) &&
            _recorder.running;
    _recorder.reset();
    _ticker?.cancel();
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
    _removeDraftAnnotations();
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
    return _recorder.vertices.isNotEmpty;
  }

  /// Stores the in-progress feature as a draft session so it can be resumed
  /// later from the History screen (for the selected project).
  Future<void> _saveDraft() async {
    final projectId = _selectedProjectId;
    if (projectId == null) {
      _showSnack('No project selected');
      return;
    }
    if (!_canSaveDraft) return;

    final responses = <String, dynamic>{
      'draft': true,
      'feature_type': _draftTypeName,
      'user_name': await _database.getSetting('user_name'),
      'saved_at': DateTime.now().toIso8601String(),
    };

    String title;
    if (_draftType == _DraftType.point) {
      final fix = _draftPointFix;
      if (fix == null) {
        _showSnack('Waiting for a GPS fix before saving the draft');
        return;
      }
      responses['latitude'] = fix.lat;
      responses['longitude'] = fix.lon;
      responses['accuracy_m'] = fix.accuracy;
      title = 'Draft point';
    } else {
      responses['recorder'] = _recorder.serialize();
      final pts = [
        for (final p in _recorder.vertices)
          (lat: p.latitude, lon: p.longitude),
      ];
      title = _draftType == _DraftType.line
          ? 'Draft line'
          : 'Draft polygon';
      if (pts.length >= 1) {
        title = '$title • ${pts.length} pts';
      }
    }

    final targetId = _resumeDraftSessionId;
    if (targetId != null) {
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
    _showSnack('Draft saved — resume it from History later');
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
    if (_draftPoint != null) {
      await controller.removeCircle(_draftPoint!);
    }
    if (_draftPlaceholder != null) {
      await controller.removeCircle(_draftPlaceholder!);
    }
    if (_draftLine != null) {
      await controller.removeLine(_draftLine!);
    }
    if (_draftFill != null) {
      await controller.removeFill(_draftFill!);
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
      _showSnack('Waiting for a GPS fix');
      return;
    }
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16),
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
                setState(() {
                  _selectedBasemapId = value;
                });
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showProjectPicker() async {
    final projects = _projects;
    if (projects.isEmpty) {
      _showSnack('Create a project first (Home → Open → New project)');
      return;
    }
    final selected = await showDialog<Project>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select project'),
        children: [
          for (final project in projects)
            RadioListTile<Project>(
              title: Text(project.name),
              subtitle: Text(
                project.description.trim().isEmpty
                    ? 'No description'
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No projects yet'),
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

  @override
  Widget build(BuildContext context) {
    final basemap = Basemap.defaults.firstWhere(
      (b) => b.id == _selectedBasemapId,
      orElse: () => Basemap.defaults.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Mode'),
        actions: [
          Tooltip(
            message: _locationStatus,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Icon(
                  _locationStatus.contains('ready')
                      ? Icons.location_on
                      : Icons.location_off,
                  color: _locationStatus.contains('ready')
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Basemap',
            icon: const Icon(Icons.map_outlined),
            onPressed: _showBasemapDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(23.8103, 90.4125),
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapMeasureTap,
            styleString: _buildStyleString(basemap),
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
            top: 12,
            left: 12,
            right: 12,
            child: _buildProjectBar(),
          ),
          if (_currentLocation != null)
            Positioned(
              top: 64,
              right: 16,
              child: _buildGpsCard(),
            ),
          if (_draftActive)
            Positioned(
              left: 16,
              right: 16,
              top: 108,
              child: _buildDraftBanner(),
            ),
          if (_measureActive)
            Positioned(
              left: 16,
              right: 16,
              top: 108,
              child: _buildMeasureBanner(),
            ),
          if (_showInfoPanel)
            Positioned(
              left: 16,
              right: 72,
              bottom: 96,
              child: _buildInfoPanel(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomToolbar(),
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

  Widget _buildProjectBar() {
    final name = _selectedProjectName ?? 'Select a project';
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _showProjectPicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                size: 18,
                color: _selectedProjectId == null
                    ? Colors.orange
                    : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Project: $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

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
            Text(
              location != null
                  ? '${location.latitude.toStringAsFixed(5)}, '
                      '${location.longitude.toStringAsFixed(5)}'
                      '${accuracy != null ? '  ±${accuracy.toStringAsFixed(1)} m' : ''}'
                  : 'GPS: Searching...',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
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
                    'Feature Info',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
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
              const Text(
                'Tap a feature on the map to see its details',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else ...[
              Text(
                info.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${info.featureType}  •  session #${info.sessionId}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (info.featureType == 'point') ...[
                const SizedBox(height: 6),
                Text(
                  'Drag the point on the map to move it.',
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
                      label: const Text('Delete'),
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
    final vertices = _recorder.vertices.length;
    final points = [
      for (final p in _recorder.vertices)
        (lat: p.latitude, lon: p.longitude),
    ];

    return Card(
      elevation: 6,
      color: Colors.white,
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
                label: const Text('Save draft'),
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
    if (_draftType == _DraftType.point) {
      final fix = _draftPointFix;
      return Text(
        fix == null
            ? 'Positioning…'
            : '${fix.lat.toStringAsFixed(6)}, ${fix.lon.toStringAsFixed(6)}'
                '${fix.accuracy > 0 ? '  ±${fix.accuracy.toStringAsFixed(1)} m' : ''}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      );
    }
    if (points.length < 2) {
      return Text(
        'Walk along the boundary while recording',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
    );
  }

  Widget _buildDraftActions(bool recording) {
    final List<Widget> actions = [];

    if (_draftType == _DraftType.point) {
      actions.addAll([
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelDraft,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: _finishDraft,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Finish'),
          ),
        ),
      ]);
      return Row(children: actions);
    }

    if (!recording) {
      actions.addAll([
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelDraft,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: _beginRecording,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start'),
          ),
        ),
      ]);
      return Row(children: actions);
    }

    actions.addAll([
      Expanded(
        child: OutlinedButton.icon(
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
          label: Text(_recorder.paused ? 'Resume' : 'Pause'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _recorder.vertices.isEmpty
              ? null
              : () {
                  _recorder.undo();
                  _refreshDraftGeometry();
                },
          icon: const Icon(Icons.undo, size: 18),
          label: const Text('Undo'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton.icon(
          onPressed: _finishDraft,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Finish'),
        ),
      ),
    ]);
    return Row(children: actions);
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
        MeasureUnits.formatArea(GeometryService.polygonAreaM2(points), areaUnit),
        'P ${MeasureUnits.formatDistance(GeometryService.polygonPerimeterM(points), distanceUnit)}',
      ]);
    }

    return Card(
      elevation: 6,
      color: Colors.white,
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
                    isArea ? 'Measure area — tap points on the map' : 'Measure distance — tap points on the map',
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
              points.isEmpty ? 'Tap the map to add the first point' : metrics.join('  •  '),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: points.isEmpty ? null : _undoMeasurePoint,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: points.isEmpty ? null : () => _endMeasure(),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _endMeasure,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Tooltip(
            message: 'Add Point',
            child: IconButton(
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: _draftType == _DraftType.point
                    ? Colors.red.shade50
                    : Colors.transparent,
                child: Icon(
                  Icons.add_location_alt_outlined,
                  size: 22,
                  color: _editingActive ? Colors.grey : Colors.red.shade700,
                ),
              ),
              onPressed: _editingActive ? null : _startPointDraft,
            ),
          ),
          Tooltip(
            message: 'Draw Line',
            child: IconButton(
              icon: Icon(
                Icons.polyline_outlined,
                size: 24,
                color: _editingActive ? Colors.grey : Colors.blue.shade700,
              ),
              onPressed: _editingActive ? null : _startLineDraft,
            ),
          ),
          Tooltip(
            message: 'Draw Polygon',
            child: IconButton(
              icon: Icon(
                Icons.pentagon_outlined,
                size: 24,
                color: _editingActive ? Colors.grey : Colors.blue.shade700,
              ),
              onPressed: _editingActive ? null : _startPolygonDraft,
            ),
          ),
          Tooltip(
            message: 'Measure Distance',
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
              onPressed: _draftActive ? null : () => _toggleMeasureTool(_MeasureTool.distance),
            ),
          ),
          Tooltip(
            message: 'Measure Area',
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
              onPressed: _draftActive ? null : () => _toggleMeasureTool(_MeasureTool.area),
            ),
          ),
          Tooltip(
            message: 'Center on GPS',
            child: IconButton(
              icon: const Icon(Icons.gps_fixed),
              onPressed: _centerOnLocation,
            ),
          ),
        ],
      ),
    );
  }
}