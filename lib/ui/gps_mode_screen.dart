import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/background_gps_recorder.dart';
import 'package:mapbanai/services/coordinate_utils.dart';
import 'package:mapbanai/services/gnss_service.dart';
import 'package:mapbanai/services/gps_log_store.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/gps_csv_service.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/gps_csv_viewer_screen.dart';
import 'package:mapbanai/ui/webmap_viewer_screen.dart';
import 'package:share_plus/share_plus.dart';

class GpsModeScreen extends StatefulWidget {
  const GpsModeScreen({super.key});

  @override
  State<GpsModeScreen> createState() => _GpsModeScreenState();
}

class _GpsModeScreenState extends State<GpsModeScreen> {
  static const String _userNameKey = 'user_name';

  final LocationService _locationService = LocationService();
  final AppDatabase _database = AppDatabase();
  final GpsLogStore _store = GpsLogStore();

  StreamSubscription<Position>? _subscription;
  Position? _latest;
  bool _permissionGranted = false;
  bool _streamError = false;
  bool _streamPaused = false;

  GnssSnapshot? _gnss;
  Timer? _gnssTimer;
  double? _groundRefAltitude;

  List<GpsLog> _logs = [];
  Map<int, int> _counts = {};
  Map<int, DateTime?> _lastReadings = {};
  int? _recordingLogId;
  String _surveyor = '';
  DateTime? _lastCountsRefresh;

  @override
  void initState() {
    super.initState();
    BackgroundGps.instance.addListener(_onBackgroundChange);
    _loadSettings();
    _loadLogs();
    _startListening();
    _startGnssPolling();
  }

  void _startGnssPolling() {
    _gnssTimer?.cancel();
    _gnssTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final snapshot = await GnssService.fetch();
      if (!mounted) return;
      setState(() {
        _gnss = snapshot;
      });
    });
  }

  Future<void> _loadSettings() async {
    final name = await _database.getSetting(_userNameKey);
    if (mounted) {
      setState(() {
        _surveyor = (name ?? '').trim();
      });
    }
  }

  Future<void> _loadLogs() async {
    final logs = await _database.getGpsLogs();
    final counts = <int, int>{};
    final last = <int, DateTime?>{};
    for (final log in logs) {
      counts[log.id] = await _store.readingCount(log.id);
      last[log.id] = await _store.lastReadingTime(log.id);
    }
    if (mounted) {
      setState(() {
        _logs = logs;
        _counts = counts;
        _lastReadings = last;
      });
    }
  }

  Future<void> _startListening() async {
    final bg = BackgroundGps.instance;

    // A background recording is active (e.g. started earlier and still
    // running, or the user just returned to this screen): mirror its state
    // instead of opening a second GPS stream.
    if (bg.isRecording) {
      await _subscription?.cancel();
      _subscription = null;
      if (!mounted) return;
      setState(() {
        _permissionGranted = true;
        _recordingLogId = bg.activeLogId;
        _latest = bg.latest;
        if (bg.latest != null) _groundRefAltitude ??= bg.latest!.altitude;
        _streamError = false;
      });
      return;
    }

    final granted = await _locationService.ensurePermission();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
    });
    if (!granted) return;
    if (_subscription != null) return;

    // Read-only preview stream: fixes drive the live readout but are never
    // appended. Recording is owned by BackgroundGps so it survives leaving
    // this screen.
    _subscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      ),
    ).listen(
      (position) {
        if (!mounted) return;
        if (BackgroundGps.instance.isRecording) return;
        setState(() {
          _latest = position;
          _groundRefAltitude ??= position.altitude;
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

  void _onBackgroundChange() {
    if (!mounted) return;
    final bg = BackgroundGps.instance;
    setState(() {
      if (bg.isRecording) {
        _recordingLogId = bg.activeLogId;
        _latest = bg.latest;
        if (bg.latest != null) _groundRefAltitude ??= bg.latest!.altitude;
        _streamError = false;
      }
    });
    _refreshCountsThrottled();
  }

  Future<void> _refreshCountsThrottled() async {
    final now = DateTime.now();
    final last = _lastCountsRefresh;
    if (last != null &&
        now.difference(last) < const Duration(seconds: 3)) {
      return;
    }
    _lastCountsRefresh = now;
    await _loadLogs();
  }

  @override
  void dispose() {
    BackgroundGps.instance.removeListener(_onBackgroundChange);
    _subscription?.cancel();
    _gnssTimer?.cancel();
    _database.close();
    super.dispose();
  }

  // ── actions ──────────────────────────────────────────────────

  void _togglePause() {
    final bg = BackgroundGps.instance;
    setState(() {
      _streamPaused = !_streamPaused;
    });
    if (bg.isRecording) {
      bg.setPaused(_streamPaused);
    }
  }

  Future<void> _copyCoordinates() async {
    final position = _latest;
    if (position == null) return;
    final decimal = '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}';
    final dms = formatCoordinate(position.latitude, position.longitude);
    await Clipboard.setData(ClipboardData(text: '$decimal\n$dms'));
    _showSnack('Coordinates copied to clipboard');
  }

  /// Captures the current fix once as a point with an optional note.
  ///
  /// Line/track logging stays automatic; this gives points an explicit
  /// save action with a text box for a note (datetime + coordinates are
  /// recorded automatically).
  Future<void> _saveWaypoint() async {
    final position = _latest;
    if (position == null) {
      _showSnack('Waiting for a GPS fix before saving a point');
      return;
    }

    final targetLogId = _recordingLogId ?? await _pickWaypointLog();
    if (targetLogId == null) return;

    final note = await showDialog<String>(
      context: context,
      builder: (context) => _WaypointDialog(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        capturedAt: position.timestamp.toLocal(),
      ),
    );
    if (note == null || !mounted) return;

    await _store.appendReading(
      logId: targetLogId,
      surveyor: _surveyor,
      position: position,
      notes: note,
    );
    await _loadLogs();
    _showSnack('Point saved');
  }

  Future<int?> _pickWaypointLog() async {
    final logs = await _database.getGpsLogs();
    if (logs.isEmpty) {
      return _createPointLog();
    }
    if (!mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Save point to…'),
        children: [
          SimpleDialogOption(
            onPressed: () => _createPointLog().then((id) {
              if (id != null && context.mounted) {
                Navigator.pop(context, id);
              }
            }),
            child: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.teal),
                SizedBox(width: 12),
                Text('New log (new CSV)…',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          for (final log in logs)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, log.id),
              child: Text(
                log.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  /// Creates a new GPS log (with its CSV file) that Save Point can write
  /// into. Returns the new log id, or null when the user cancels.
  Future<int?> _createPointLog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _LogNameDialog(title: 'New point log'),
    );
    if (name == null) return null;

    final defaultName = 'Point Log ${_logs.length + 1}';
    final logId = await _database.insertGpsLog(
      GpsLogsCompanion(
        name: drift.Value(name.trim().isEmpty ? defaultName : name.trim()),
        surveyor: drift.Value(_surveyor),
      ),
    );
    await _store.createLogFile(logId);
    await _loadLogs();
    _showSnack(
      '"${name.trim().isEmpty ? defaultName : name.trim()}" created',
    );
    return logId;
  }

  Future<void> _createLog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _LogNameDialog(title: 'Record track'),
    );
    if (name == null) return;

    final defaultName = 'GPS Log ${_logs.length + 1}';
    final logId = await _database.insertGpsLog(
      GpsLogsCompanion(
        name: drift.Value(name.trim().isEmpty ? defaultName : name.trim()),
        surveyor: drift.Value(_surveyor),
      ),
    );
    await _store.createLogFile(logId);
    await _loadLogs();
    final log = (await _database.getGpsLogs())
        .firstWhere((l) => l.id == logId, orElse: () => _logs.firstWhere((l) => l.id == logId));
    _showSnack(
      '"${name.trim().isEmpty ? defaultName : name.trim()}" created',
    );
    await _startRecording(log);
  }

  Future<void> _startRecording(GpsLog log) async {
    await _subscription?.cancel();
    _subscription = null;
    final ok = await BackgroundGps.instance.start(
      logId: log.id,
      logName: log.name,
      surveyor: _surveyor,
    );
    if (!ok) {
      _showSnack('Location permission not granted');
      await _loadLogs();
      _startListening();
      return;
    }
    if (!mounted) return;
    setState(() {
      _recordingLogId = log.id;
    });
    await _loadLogs();
    _showSnack('Recording to "${log.name}"');
  }

  Future<void> _toggleRecording(GpsLog log) async {
    final bg = BackgroundGps.instance;
    if (bg.isRecording && bg.activeLogId == log.id) {
      await bg.stop();
      if (!mounted) return;
      setState(() {
        _recordingLogId = null;
      });
      _showSnack('Recording stopped');
      await _loadLogs();
      _startListening();
      return;
    }
    await _startRecording(log);
  }

  Future<void> _renameLog(GpsLog log) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _LogNameDialog(title: 'Rename log', initialName: log.name),
    );
    if (name == null || name.trim().isEmpty) return;
    await _database.renameGpsLog(log.id, name.trim());
    await _loadLogs();
  }

  Future<void> _shareLog(GpsLog log) async {
    final path = await _store.filePath(log.id);
    try {
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      _showSnack('Could not share log: $e');
    }
  }

  Future<void> _deleteLog(GpsLog log) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete log',
      message: 'Delete "${log.name}" and its CSV file?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;

    if (BackgroundGps.instance.isRecording &&
        BackgroundGps.instance.activeLogId == log.id) {
      await BackgroundGps.instance.stop();
      if (!mounted) return;
      setState(() {
        _recordingLogId = null;
      });
      _startListening();
    }
    await _store.deleteFile(log.id);
    await _database.deleteGpsLog(log.id);
    await _loadLogs();
  }

  Future<void> _viewLog(GpsLog log) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GpsCsvDetailScreen(log: log)),
    );
    _loadLogs();
  }

  Future<void> _projectLogOnWebMap(GpsLog log) async {
    final path = await _store.filePath(log.id);
    final readings = await GpsCsvService.parseFile(path);
    if (readings.isEmpty) {
      _showSnack('No readings in "${log.name}" to project');
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await GpsCsvService.writeWebMapToFile(
        readings,
        logName: log.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => WebmapViewerScreen(htmlFile: file)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('WebMap failed: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Mode'),
        actions: [
          IconButton(
            tooltip: 'Refresh GPS',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _startListening();
              _startGnssPolling();
            },
          ),
          IconButton(
            tooltip: _streamPaused ? 'Resume GPS stream' : 'Pause GPS stream',
            icon: Icon(
              _streamPaused
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
            ),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(),
            if (_recordingLogId != null) ...[
              const SizedBox(height: 12),
              _buildRecordingBanner(),
            ],
            const SizedBox(height: 12),
            _buildReadoutCard(),
            const SizedBox(height: 12),
            _buildCompassCard(),
            const SizedBox(height: 16),
            _buildLogsHeader(),
            const SizedBox(height: 8),
            if (_logs.isEmpty)
              _buildEmptyLogs()
            else
              ..._buildLogTiles(),
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
    } else if (_streamPaused) {
      color = Colors.blueGrey;
      text = 'GPS stream paused';
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
            _permissionGranted && !_streamError && !_streamPaused
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

  Widget _buildRecordingBanner() {
    final log = _logs.firstWhere(
      (log) => log.id == _recordingLogId,
      orElse: () => _logs.first,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.fiber_manual_record, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recording to "${log.name}"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _toggleRecording(log),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassCard() {
    final heading = _latest?.heading;
    final hasHeading = heading != null && !heading.isNaN && _latest != null;
    final deg = hasHeading ? (heading % 360) : 0.0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Text('Compass', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasHeading ? Colors.teal.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: hasHeading ? Colors.teal.shade200 : Colors.grey.shade300),
                  ),
                  child: Text(
                    hasHeading ? '${deg.toStringAsFixed(0)}° ${ _cardinalFromDegrees(deg)}' : 'No heading',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: hasHeading ? Colors.teal.shade800 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _CompassPainter(headingDeg: hasHeading ? deg : null),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasHeading ? '${deg.toStringAsFixed(0)}°' : '—',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: hasHeading ? Colors.teal.shade900 : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        hasHeading ? 'from North' : 'Waiting for heading…',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasHeading
                  ? 'Heading ${deg.toStringAsFixed(1)}°  •  ${_cardinalFromDegrees(deg)}'
                  : 'Move with GPS to get a heading fix',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _cardinalFromDegrees(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((deg + 22.5) / 45).floor() % 8;
    return dirs[idx];
  }

  Widget _buildReadoutCard() {
    final position = _latest;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          _readoutRow(
            label: 'Latitude',
            value: position == null ? '—' : position.latitude.toStringAsFixed(7),
          ),
          const SizedBox(height: 12),
          _readoutRow(
            label: 'Longitude',
            value: position == null
                ? '—'
                : position.longitude.toStringAsFixed(7),
          ),
          if (position != null) ...[
            const SizedBox(height: 12),
            _readoutRow(
              label: 'UTC time (GPS)',
              value: _formatTimestamp(position.timestamp.toUtc()),
            ),
            const SizedBox(height: 12),
            _readoutRow(
              label: 'Dhaka time (GMT+6)',
              value: _formatTimestamp(
                position.timestamp.toUtc().add(const Duration(hours: 6)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              position == null
                  ? 'Waiting for position…'
                  : formatCoordinate(position.latitude, position.longitude),
              style: TextStyle(fontSize: 13, color: Colors.teal.shade800),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _readoutCell(
                  label: 'Accuracy',
                  value: position == null
                      ? '—'
                      : '${position.accuracy.toStringAsFixed(1)} m',
                  color: position == null
                      ? Colors.grey
                      : (position.accuracy <= 10
                          ? Colors.green
                          : position.accuracy <= 30
                              ? Colors.orange
                              : Colors.red),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _readoutCell(
                  label: 'Elevation',
                  value: position == null
                      ? '—'
                      : _formatRelativeElevation(position.altitude),
                  color: _elevationColor(position?.altitude),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _readoutCell(
                  label: 'Speed',
                  value: position == null
                      ? '—'
                      : position.speed <= 0
                          ? '0.0 km/h'
                          : '${(position.speed * 3.6).toStringAsFixed(1)} km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _readoutCell(
                  label: 'Satellites (in use / in view)',
                  value: _gnss == null ? '—' : '${_gnss!.inUse}/${_gnss!.inView}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            position == null || _groundRefAltitude == null
                ? 'Elevation is relative to the first fix of this session.'
                : 'Elevation relative to first fix '
                    '(${_groundRefAltitude!.toStringAsFixed(1)} m abs).',
            style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: position == null ? null : _copyCoordinates,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Copy coordinates'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: position == null ? null : _saveWaypoint,
                  icon: const Icon(Icons.gps_not_fixed_outlined),
                  label: const Text('Save Point'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Point saves the current fix once with a note; '
            'continuous recording below drives line/track logging.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _readoutRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.teal.shade700)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _formatRelativeElevation(double altitude) {
    final ref = _groundRefAltitude;
    if (ref == null) return '${altitude.toStringAsFixed(1)} m';
    final relative = altitude - ref;
    final sign = relative >= 0 ? '+' : '';
    return '$sign${relative.toStringAsFixed(1)} m';
  }

  Color? _elevationColor(double? altitude) {
    final ref = _groundRefAltitude;
    if (altitude == null || ref == null) return null;
    final relative = altitude - ref;
    if (relative > 0.5) return Colors.green;
    if (relative < -0.5) return Colors.blueGrey;
    return null;
  }

  Widget _readoutCell({
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'GPS Logs (${_logs.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const GpsCsvViewerScreen()),
                );
              },
              icon: const Icon(Icons.table_chart_outlined, size: 18),
              label: const Text('Viewer'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _createLog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Record Track'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyLogs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.assessment_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No logs yet. Create one to record coordinates, time, elevation '
            'and accuracy into a CSV file.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLogTiles() {
    return [
      for (final log in _logs)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Icon(
              _recordingLogId == log.id
                  ? Icons.fiber_manual_record
                  : Icons.description_outlined,
              color: _recordingLogId == log.id ? Colors.red : Colors.teal,
            ),
            title: Text(
              log.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_counts[log.id] ?? 0} readings'
              '${_lastReadings[log.id] == null ? '' : ' • last ${_formatTime(_lastReadings[log.id]!)}'}'
              '${log.surveyor.trim().isEmpty ? '' : ' • ${log.surveyor.trim()}'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _recordingLogId == log.id
                      ? 'Stop recording'
                      : 'Record to this log',
                  icon: Icon(
                    _recordingLogId == log.id
                        ? Icons.stop_circle_outlined
                        : Icons.radio_button_checked,
                    color: _recordingLogId == log.id ? Colors.red : Colors.teal,
                  ),
                  onPressed: () => _toggleRecording(log),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'view':
                        _viewLog(log);
                        break;
                      case 'webmap':
                        _projectLogOnWebMap(log);
                        break;
                      case 'rename':
                        _renameLog(log);
                        break;
                      case 'share':
                        _shareLog(log);
                        break;
                      case 'delete':
                        _deleteLog(log);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.table_view_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('View CSV'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'webmap',
                      child: Row(
                        children: [
                          Icon(Icons.public_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Project on WebMap'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.ios_share_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Export / share CSV'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 8),
    ];
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTimestamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}

class _CompassPainter extends CustomPainter {
  final double? headingDeg;
  _CompassPainter({this.headingDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final outerPaint = Paint()
      ..color = Colors.teal.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerPaint);
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 1, fillPaint);
    // Degree ticks every 30°, longer at N/E/S/W
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final cardinalPaint = Paint()
      ..color = Colors.teal.shade700
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int deg = 0; deg < 360; deg += 15) {
      final isCardinal = deg % 90 == 0;
      final isMajor = deg % 30 == 0;
      final rad = deg * math.pi / 180;
      final inner = isCardinal ? radius - 14 : isMajor ? radius - 10 : radius - 6;
      final outer = radius - 2;
      final p1 = Offset(center.dx + inner * math.sin(rad), center.dy - inner * math.cos(rad));
      final p2 = Offset(center.dx + outer * math.sin(rad), center.dy - outer * math.cos(rad));
      canvas.drawLine(p1, p2, isCardinal ? cardinalPaint : tickPaint);
    }
    // N/E/S/W labels
    const labels = ['N', 'E', 'S', 'W'];
    const labelDegs = [0, 90, 180, 270];
    for (int i = 0; i < labels.length; i++) {
      final deg = labelDegs[i];
      final rad = deg * math.pi / 180;
      final r = radius - 22;
      final pos = Offset(center.dx + r * math.sin(rad), center.dy - r * math.cos(rad));
      final isNorth = labels[i] == 'N';
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: isNorth ? Colors.red.shade700 : Colors.teal.shade800,
            fontWeight: isNorth ? FontWeight.w900 : FontWeight.w700,
            fontSize: isNorth ? 15 : 13,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
    // Intercardinal labels NE, SE, SW, NW smaller
    const inter = ['NE', 'SE', 'SW', 'NW'];
    const interDegs = [45, 135, 225, 315];
    for (int i = 0; i < inter.length; i++) {
      final rad = interDegs[i] * math.pi / 180;
      final r = radius - 20;
      final pos = Offset(center.dx + r * math.sin(rad), center.dy - r * math.cos(rad));
      final tp = TextPainter(
        text: TextSpan(
          text: inter[i],
          style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
    // Needle - heading from north clockwise
    if (headingDeg != null) {
      final h = headingDeg! % 360;
      final rad = h * math.pi / 180;
      // Needle triangle pointing to heading
      final tip = Offset(center.dx + (radius - 10) * math.sin(rad), center.dy - (radius - 10) * math.cos(rad));
      final baseLeftRad = rad + 2.6;
      final baseRightRad = rad - 2.6;
      final baseR = 14.0;
      final baseLeft = Offset(center.dx + baseR * math.sin(baseLeftRad), center.dy - baseR * math.cos(baseLeftRad));
      final baseRight = Offset(center.dx + baseR * math.sin(baseRightRad), center.dy - baseR * math.cos(baseRightRad));
      final needlePaint = Paint()
        ..color = Colors.red.shade600
        ..style = PaintingStyle.fill;
      final path = Path()..moveTo(tip.dx, tip.dy)..lineTo(baseLeft.dx, baseLeft.dy)..lineTo(baseRight.dx, baseRight.dy)..close();
      canvas.drawPath(path, needlePaint);
      // Center dot
      canvas.drawCircle(center, 4, Paint()..color = Colors.teal.shade800);
      canvas.drawCircle(center, 2.2, Paint()..color = Colors.white);
    } else {
      // No heading: faint center dot
      canvas.drawCircle(center, 4, Paint()..color = Colors.grey.shade400);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.headingDeg != headingDeg;
}

class _WaypointDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;

  const _WaypointDialog({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  @override
  State<_WaypointDialog> createState() => _WaypointDialogState();
}

class _WaypointDialogState extends State<_WaypointDialog> {
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captured = widget.capturedAt;
    final h = captured.hour.toString().padLeft(2, '0');
    final m = captured.minute.toString().padLeft(2, '0');
    final date =
        '${captured.year}-${captured.month.toString().padLeft(2, '0')}-'
        '${captured.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Save Point'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.latitude.toStringAsFixed(6)}, '
            '${widget.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$date $h:$m  •  ±${widget.accuracy.toStringAsFixed(1)} m',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Note (optional)',
              hintText: 'e.g., Standing water at footbridge',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _notes.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LogNameDialog extends StatefulWidget {
  final String title;
  final String? initialName;

  const _LogNameDialog({required this.title, this.initialName});

  @override
  State<_LogNameDialog> createState() => _LogNameDialogState();
}

class _LogNameDialogState extends State<_LogNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Track name (optional)',
          hintText: 'e.g., Site A boundary walk',
        ),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
