import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/accuracy_filter.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/photo_capture_screen.dart';

class PointRecordScreen extends StatefulWidget {
  final String projectName;

  const PointRecordScreen({
    required this.projectName,
    super.key,
  });

  @override
  State<PointRecordScreen> createState() => _PointRecordScreenState();
}

class _PointRecordScreenState extends State<PointRecordScreen> {
  final LocationService _locationService = LocationService();
  final AppDatabase _database = AppDatabase();

  StreamSubscription<Position>? _subscription;
  Position? _latest;
  bool _permissionGranted = false;
  bool _streamError = false;
  bool _saving = false;
  double _threshold = 10; // meters
  PhotoRecord? _photo;

  static const List<double> _thresholds = [5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    _loadProjectThreshold();
    _startListening();
  }

  Future<void> _loadProjectThreshold() async {
    final project = await _database.getProjectByName(widget.projectName);
    if (mounted && project != null) {
      setState(() {
        _threshold = project.gpsThresholdM;
      });
    }
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
          _latest = position;
          _streamError = false;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _streamError = true;
        });
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _database.close();
    super.dispose();
  }

  Future<void> _save({required bool force}) async {
    final position = _latest;
    if (position == null || _saving) return;

    if (force && !AccuracyFilter.isAcceptable(position.accuracy, _threshold)) {
      final accepted = await _confirmForceSave(position.accuracy);
      if (accepted != true) return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final projectId = await _database.getProjectIdByName(widget.projectName);
      if (projectId == null) {
        _showSnack('Project not found: ${widget.projectName}');
        return;
      }

      final responses = jsonEncode({
        'feature_type': 'point',
        'user_name': await _database.getSetting('user_name'),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy_m': position.accuracy,
        'threshold_m': _threshold,
        'recorded_at': DateTime.now().toIso8601String(),
        if (_photo != null) 'photo': _photo!.toJson(),
      });

      await _database.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value(
            'Point at ${DateTime.now().hour.toString().padLeft(2, '0')}:'
            '${DateTime.now().minute.toString().padLeft(2, '0')} '
            '(±${AccuracyFilter.format(position.accuracy)})',
          ),
          status: const drift.Value('saved'),
          responses: drift.Value(responses),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('Point saved');
    } catch (e) {
      _showSnack('Failed to save point: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<bool> _confirmForceSave(double accuracy) {
    return showConfirmDialog(
      context,
      title: 'Accuracy check',
      message: 'Current accuracy (${AccuracyFilter.format(accuracy)}) is worse '
          'than the configured threshold (${AccuracyFilter.format(_threshold)}). '
          'Save anyway?',
      confirmText: 'Save anyway',
      cancelText: 'Wait',
    );
  }

  Future<void> _capturePhoto() async {
    final record = await Navigator.of(context).push<PhotoRecord>(
      MaterialPageRoute(builder: (_) => const PhotoCaptureScreen()),
    );
    if (record != null && mounted) {
      setState(() {
        _photo = record;
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Point'),
        actions: [
          IconButton(
            tooltip: _photo != null ? 'Replace photo' : 'Attach photo (geotagged)',
            icon: Icon(
              _photo != null
                  ? (_photo!.isGeotagged
                      ? Icons.photo_camera
                      : Icons.photo_camera_back)
                  : Icons.photo_camera_outlined,
              color: _photo != null
                  ? (_photo!.isGeotagged ? Colors.green : Colors.orange)
                  : null,
            ),
            onPressed: _capturePhoto,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Project: ${widget.projectName}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildAccuracyDisplay(),
            const SizedBox(height: 16),
            _buildThresholdSelector(),
            const Spacer(),
            _buildSaveButtons(),
          ],
        ),
      ),
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
    } else if (_latest != null) {
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
              child: const Text('Allow'),
            ),
        ],
      ),
    );
  }

  Widget _buildAccuracyDisplay() {
    final accuracy = _latest?.accuracy;
    final quality = AccuracyFilter.qualityLevel(accuracy, _threshold);
    final Color color = switch (quality) {
      0 => Colors.grey,
      1 => Colors.green,
      2 => Colors.orange,
      _ => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Current accuracy',
            style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            AccuracyFilter.format(accuracy),
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          if (_latest != null)
            Text(
              '${_latest!.latitude.toStringAsFixed(6)}, '
              '${_latest!.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildThresholdSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max acceptable accuracy',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<double>(
          segments: [
            for (final t in _thresholds)
              ButtonSegment(value: t, label: Text('${t.round()}m')),
          ],
          selected: {_threshold},
          onSelectionChanged: (selection) {
            setState(() {
              _threshold = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSaveButtons() {
    final acceptable =
        AccuracyFilter.isAcceptable(_latest?.accuracy, _threshold);
    final enabled = _permissionGranted && _latest != null && !_saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: enabled ? () => _save(force: false) : null,
          icon: _saving
              ? const AppLoadingIndicator(dense: true)
              : const Icon(Icons.add_location_alt_outlined),
          label: const Text('Save point'),
        ),
        if (!acceptable && enabled) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving ? null : () => _save(force: true),
            child: const Text('Save anyway…'),
          ),
        ],
      ],
    );
  }
}