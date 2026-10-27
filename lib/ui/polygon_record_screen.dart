import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/accuracy_filter.dart';
import 'package:mapbanai/services/geometry_service.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/track_recorder.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';

class PolygonRecordScreen extends StatefulWidget {
  final String projectName;

  const PolygonRecordScreen({required this.projectName, super.key});

  @override
  State<PolygonRecordScreen> createState() => _PolygonRecordScreenState();
}

class _PolygonRecordScreenState extends State<PolygonRecordScreen> {
  final LocationService _locationService = LocationService();
  final AppDatabase _database = AppDatabase();
  final TrackRecorder _recorder = TrackRecorder(
    minDistanceM: 3,
    minIntervalS: 2,
    maxAccuracyM: 20,
  );

  StreamSubscription<Position>? _subscription;
  bool _permissionGranted = false;
  bool _streamError = false;
  bool _saving = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    final granted = await _locationService.ensurePermission();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
    });
    if (!granted) return;

    await _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (position) {
        if (!mounted) return;
        setState(() {
          if (_recorder.add(position)) _restartTicker();
        });
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() {
          _streamError = true;
        });
      },
      cancelOnError: false,
    );
  }

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker?.cancel();
    _database.close();
    super.dispose();
  }

  List<({double lat, double lon})> get _polygon => _recorder.vertices
      .map((p) => (lat: p.latitude, lon: p.longitude))
      .toList();

  Future<void> _save() async {
    final vertices = List<Position>.from(_recorder.vertices);
    if (vertices.length < 3 || _saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final projectId = await _database.getProjectIdByName(widget.projectName);
      if (projectId == null) {
        _showSnack(
            ui(context, 'Project not found: {v0}', [widget.projectName]));
        return;
      }

      final polygon = _polygon;
      final responses = jsonEncode({
        'feature_type': 'polygon',
        'user_name': await _database.getSetting('user_name'),
        'vertices': [
          for (final v in vertices)
            {
              'latitude': v.latitude,
              'longitude': v.longitude,
              'accuracy_m': v.accuracy,
            },
        ],
        'area_m2': GeometryService.polygonAreaM2(polygon),
        'perimeter_m': GeometryService.polygonPerimeterM(polygon),
        'vertex_count': vertices.length,
        'elapsed_s': _recorder.elapsed.inSeconds,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      await _database.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value(
            'Polygon • ${GeometryService.formatArea(GeometryService.polygonAreaM2(polygon))}'
            ' • ${vertices.length} pts',
          ),
          status: const drift.Value('saved'),
          responses: drift.Value(responses),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(ui(context, 'Polygon saved'));
    } catch (e) {
      _showSnack(ui(context, 'Failed to save polygon: {v0}', [e]));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmCancel() async {
    final cancel = await showConfirmDialog(
      context,
      title: ui(context, 'Cancel recording?'),
      message: ui(context, 'The collected vertices will be discarded.'),
      confirmText: 'Cancel',
      cancelText: 'Keep recording',
      destructive: true,
    );
    if (cancel && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ui(context, 'Record Polygon'))),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ui(context, 'Project: {v0}', [widget.projectName]),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildStatsPanel(),
            const SizedBox(height: 24),
            _buildControls(),
          ],
        ),
      )),
    );
  }

  Widget _buildStatusCard() {
    final Color color;
    final String text;

    if (!_permissionGranted) {
      color = Colors.red;
      text = 'Location permission required';
    } else if (_streamError) {
      color = Colors.orange;
      text = 'Waiting for GPS fix…';
    } else if (_recorder.latest != null) {
      color = Colors.green;
      text = 'GPS ready';
    } else {
      color = Colors.orange;
      text = 'Searching for GPS…';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            _permissionGranted && !_streamError
                ? Icons.gps_fixed
                : Icons.gps_off,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ),
          if (!_permissionGranted)
            TextButton(
              onPressed: _startListening,
              child: Text(ui(context, 'Allow')),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    final vertices = _recorder.vertices.length;
    final area = GeometryService.polygonAreaM2(_polygon);
    final perimeter = GeometryService.polygonPerimeterM(_polygon);
    final accuracy = _recorder.latest?.accuracy;
    final quality = AccuracyFilter.qualityLevel(accuracy, 20);
    final Color accuracyColor = switch (quality) {
      1 => Colors.green,
      2 => Colors.orange,
      _ => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ResponsiveGrid(
            minChildWidth: 130,
            children: [
              _StatItem(
                  label: ui(context, 'Area'),
                  value: GeometryService.formatArea(area)),
              _StatItem(
                label: ui(context, 'Perimeter'),
                value: GeometryService.formatDistance(perimeter),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ResponsiveGrid(
            minChildWidth: 110,
            children: [
              _StatItem(label: ui(context, 'Vertices'), value: '$vertices'),
              _StatItem(
                  label: ui(context, 'Elapsed'), value: _recorder.elapsedLabel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gps_fixed, size: 16, color: accuracyColor),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(
                ui(context, 'Accuracy: {v0} (max 20 m)',
                    [AccuracyFilter.format(accuracy)]),
                style: TextStyle(fontSize: 12, color: accuracyColor),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (!_recorder.running) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _permissionGranted
                ? () {
                    setState(() {
                      _recorder.start();
                      _restartTicker();
                    });
                  }
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(ui(context, 'Start recording')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ui(context, 'Cancel')),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          minChildWidth: 150,
          children: [
            _recorder.paused
                ? OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _recorder.resume();
                        _restartTicker();
                      });
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(ui(context, 'Resume')),
                  )
                : OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _recorder.pause();
                      });
                    },
                    icon: const Icon(Icons.pause),
                    label: Text(ui(context, 'Pause')),
                  ),
            OutlinedButton.icon(
              onPressed: _recorder.vertices.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _recorder.undo();
                      });
                    },
              icon: const Icon(Icons.undo),
              label: Text(ui(context, 'Undo')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _recorder.vertices.length >= 3 && !_saving ? _save : null,
          icon: _saving
              ? const AppLoadingIndicator(dense: true)
              : const Icon(Icons.check),
          label: Text(ui(context, 'Save polygon')),
        ),
        if (_recorder.vertices.isNotEmpty && _recorder.vertices.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              ui(context, 'At least 3 vertices required ({v0}/3)',
                  [_recorder.vertices.length]),
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _saving ? null : _confirmCancel,
          icon: const Icon(Icons.close),
          label: Text(ui(context, 'Cancel recording')),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
