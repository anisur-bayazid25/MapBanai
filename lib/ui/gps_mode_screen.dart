import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'dart:async';
import 'package:mapbanai/services/compass_heading_filter.dart';
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

  /// Unwrapped heading (no 359→0 jumps) used to animate the compass dial
  /// smoothly across consecutive fixes.
  final CompassHeadingFilter _headingFilter = CompassHeadingFilter();
  double? get _continuousHeading => _headingFilter.value;
  final ValueNotifier<double?> _compass = ValueNotifier(null);
  StreamSubscription<dynamic>? _compassSubscription;
  bool _sensorCompass = false;
  int _compassAccuracy = 0;
  void _startCompass() {
    _compassSubscription = const EventChannel('mapbanai/compass')
        .receiveBroadcastStream()
        .listen((event) {
      if (!mounted || event is! Map) return;
      _sensorCompass = event['available'] == true;
      _compassAccuracy = (event['accuracy'] as num?)?.toInt() ?? 0;
      if (_sensorCompass && event['heading'] is num)
        _noteHeading((event['heading'] as num).toDouble(), sensor: true);
    }, onError: (_) {
      _sensorCompass = false;
    });
  }

  /// Feeds [heading] into the continuous/unwrapped accumulator so the
  /// compass dial can rotate through the shortest path instead of spinning
  /// backwards when crossing north.
  void _noteHeading(double? heading, {bool sensor = false}) {
    if ((_sensorCompass && !sensor) ||
        heading == null ||
        !heading.isFinite ||
        heading < 0) return;
    _compass.value =
        _headingFilter.update(heading, smoothing: sensor ? .45 : 1);
  }

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
    _startCompass();
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
      _noteHeading(bg.latest?.heading);
      setState(() {
        _permissionGranted = true;
        _recordingLogId = bg.activeLogId;
        _latest = bg.latest;
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
        _noteHeading(position.heading);
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

  void _onBackgroundChange() {
    if (!mounted) return;
    final bg = BackgroundGps.instance;
    setState(() {
      if (bg.isRecording) {
        _recordingLogId = bg.activeLogId;
        _latest = bg.latest;
        _streamError = false;
      }
    });
    if (bg.isRecording) _noteHeading(bg.latest?.heading);
    _refreshCountsThrottled();
  }

  Future<void> _refreshCountsThrottled() async {
    final now = DateTime.now();
    final last = _lastCountsRefresh;
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
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
    _compassSubscription?.cancel();
    _compass.dispose();
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
    _showSnack(ui(context, 'Coordinates copied to clipboard'));
  }

  /// Captures the current fix once as a point with an optional note.
  ///
  /// Line/track logging stays automatic; this gives points an explicit
  /// save action with a text box for a note (datetime + coordinates are
  /// recorded automatically).
  Future<void> _saveWaypoint() async {
    final position = _latest;
    if (position == null) {
      _showSnack(ui(context, 'Waiting for a GPS fix before saving a point'));
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
    _showSnack(ui(context, 'Point saved'));
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
        title: Text(ui(context, 'Save point to…')),
        children: [
          SimpleDialogOption(
            onPressed: () => _createPointLog().then((id) {
              if (id != null && context.mounted) {
                Navigator.pop(context, id);
              }
            }),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.teal),
                SizedBox(width: 12),
                Text(ui(context, 'New log (new CSV)…'),
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
      builder: (context) => _LogNameDialog(title: ui(context, 'New point log')),
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
      ui(context, '"{v0}" created',
          [name.trim().isEmpty ? defaultName : name.trim()]),
    );
    return logId;
  }

  Future<void> _createLog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _LogNameDialog(title: ui(context, 'Record track')),
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
    final log = (await _database.getGpsLogs()).firstWhere((l) => l.id == logId,
        orElse: () => _logs.firstWhere((l) => l.id == logId));
    _showSnack(
      ui(context, '"{v0}" created',
          [name.trim().isEmpty ? defaultName : name.trim()]),
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
      _showSnack(ui(context, 'Location permission not granted'));
      await _loadLogs();
      _startListening();
      return;
    }
    if (!mounted) return;
    setState(() {
      _recordingLogId = log.id;
    });
    await _loadLogs();
    _showSnack(ui(context, 'Recording to "{v0}"', [log.name]));
  }

  Future<void> _toggleRecording(GpsLog log) async {
    final bg = BackgroundGps.instance;
    if (bg.isRecording && bg.activeLogId == log.id) {
      await bg.stop();
      if (!mounted) return;
      setState(() {
        _recordingLogId = null;
      });
      _showSnack(ui(context, 'Recording stopped'));
      await _loadLogs();
      _startListening();
      return;
    }
    await _startRecording(log);
  }

  Future<void> _renameLog(GpsLog log) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _LogNameDialog(
          title: ui(context, 'Rename log'), initialName: log.name),
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
      _showSnack(ui(context, 'Could not share log: {v0}', [e]));
    }
  }

  Future<void> _deleteLog(GpsLog log) async {
    final confirmed = await showConfirmDialog(
      context,
      title: ui(context, 'Delete log'),
      message: ui(context, 'Delete "{v0}" and its CSV file?', [log.name]),
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
      _showSnack(ui(context, 'No readings in "{v0}" to project', [log.name]));
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
        MaterialPageRoute(builder: (_) => WebmapViewerScreen(htmlFile: file)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(ui(context, 'WebMap failed: {v0}', [e]));
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
        title: Text(ui(context, 'GPS Mode')),
        actions: [
          IconButton(
            tooltip: ui(context, 'Refresh GPS'),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _startListening();
              _startGnssPolling();
            },
          ),
          IconButton(
            tooltip: _streamPaused
                ? ui(context, 'Resume GPS stream')
                : ui(context, 'Pause GPS stream'),
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
            if (_logs.isEmpty) _buildEmptyLogs() else ..._buildLogTiles(),
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
              child: Text(ui(context, 'Allow')),
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
              ui(context, 'Recording to "{v0}"', [log.name]),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _toggleRecording(log),
            child: Text(ui(context, 'Stop')),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassCard() => ValueListenableBuilder<double?>(
        valueListenable: _compass,
        builder: (context, heading, _) => _compassCard(heading),
      );

  Widget _compassCard(double? heading) {
    final hasHeading = heading != null && !heading.isNaN;
    final deg = hasHeading ? ((heading % 360) + 360) % 360 : 0.0;
    // The dial rotates to -heading (shortest path via unwrapped value);
    // the red needle stays fixed pointing up — where the phone faces.
    final dialTurns = hasHeading ? -((_continuousHeading ?? deg) / 360) : 0.0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.explore_outlined, color: Colors.teal.shade700),
        title: Text(ui(context, 'Compass'),
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          hasHeading
              ? '${deg.toStringAsFixed(0)}° ${_cardinalFromDegrees(deg)} ${_sensorCompass ? '(magnetic north)' : '(GPS travel bearing)'}'
              : ui(context, 'No heading yet'),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Rotating dial: degree ring + direction labels.
                      AnimatedRotation(
                        turns: dialTurns,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        child:
                            const CustomPaint(painter: _CompassDialPainter()),
                      ),
                      // Fixed needle: always points up = phone facing.
                      const CustomPaint(painter: _CompassNeedlePainter()),
                      // Degrees-from-north readout below the hub.
                      Align(
                        alignment: const Alignment(0, 0.55),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasHeading ? '${deg.toStringAsFixed(0)}°' : '—',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: hasHeading
                                    ? Colors.teal.shade900
                                    : Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              hasHeading
                                  ? (_sensorCompass
                                      ? ui(context, 'magnetic north')
                                      : ui(context, 'travel direction'))
                                  : ui(context, 'Waiting…'),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasHeading
                      ? (_sensorCompass
                          ? (_compassAccuracy <= 1
                              ? ui(context,
                                  'Compass needs calibration: move the phone in a figure-eight, away from metal.')
                              : ui(context,
                                  'Phone direction · magnetic north. Keep the phone reasonably flat.'))
                          : ui(context,
                              'GPS direction of travel; this does not show where a stationary phone faces.'))
                      : ui(context, 'Move with GPS to get a heading fix'),
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
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
            label: ui(context, 'Latitude'),
            value:
                position == null ? '—' : position.latitude.toStringAsFixed(7),
          ),
          const SizedBox(height: 12),
          _readoutRow(
            label: ui(context, 'Longitude'),
            value:
                position == null ? '—' : position.longitude.toStringAsFixed(7),
          ),
          if (position != null) ...[
            const SizedBox(height: 12),
            _readoutRow(
              label: ui(context, 'UTC time (GPS)'),
              value: _formatTimestamp(position.timestamp.toUtc()),
            ),
            const SizedBox(height: 12),
            _readoutRow(
              label: ui(context, 'Dhaka time (GMT+6)'),
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
                  ? ui(context, 'Waiting for position…')
                  : formatCoordinate(position.latitude, position.longitude),
              style: TextStyle(fontSize: 13, color: Colors.teal.shade800),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            minChildWidth: 110,
            children: [
              _readoutCell(
                label: ui(context, 'Accuracy'),
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
              _readoutCell(
                label: ui(context, 'GNSS altitude'),
                value: position == null
                    ? '—'
                    : position.altitude.isFinite &&
                            position.altitudeAccuracy > 0
                        ? '${position.altitude.toStringAsFixed(1)} m'
                        : 'Unavailable',
              ),
              _readoutCell(
                label: ui(context, 'Speed'),
                value: position == null
                    ? '—'
                    : position.speed <= 0
                        ? '0.0 km/h'
                        : '${(position.speed * 3.6).toStringAsFixed(1)} km/h',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _readoutCell(
                  label: ui(context, 'Satellites (in use / in view)'),
                  value:
                      _gnss == null ? '—' : '${_gnss!.inUse}/${_gnss!.inView}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              position == null || position.altitudeAccuracy <= 0
                  ? ui(context,
                      'Vertical accuracy unavailable. GNSS altitude is not a reliable floor-height measurement indoors.')
                  : ui(
                      context,
                      'Vertical uncertainty ±{v0} m · WGS84 ellipsoid, not sea level or height above ground.',
                      [position.altitudeAccuracy.toStringAsFixed(1)]),
              style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
              textAlign: TextAlign.center),
          Text(
              ui(context,
                  'Indoor readings, including negative values, may be unreliable. Test outdoors before setting a ground reference.'),
              style: TextStyle(fontSize: 11)),
          if (_groundRefAltitude != null && position != null)
            Text(ui(context, 'Height change from your reference: {v0}',
                [_formatRelativeElevation(position.altitude)])),
          TextButton.icon(
              onPressed: position == null || position.altitudeAccuracy <= 0
                  ? null
                  : () {
                      setState(() => _groundRefAltitude = position.altitude);
                    },
              icon: const Icon(Icons.height),
              label: Text(ui(context, 'Set relative height reference here'))),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minChildWidth: 180,
            children: [
              OutlinedButton.icon(
                onPressed: position == null ? null : _copyCoordinates,
                icon: const Icon(Icons.copy_all_outlined),
                label: Text(ui(context, 'Copy coordinates')),
              ),
              FilledButton.icon(
                onPressed: position == null ? null : _saveWaypoint,
                icon: const Icon(Icons.gps_not_fixed_outlined),
                label: Text(ui(context, 'Save Point')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ui(context,
                'Point saves the current fix once with a note; continuous recording below drives line/track logging.'),
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _readoutRow({required String label, required String value}) {
    return ResponsiveGrid(
      minChildWidth: 180,
      maxColumns: 2,
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

  Widget _readoutCell({
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ui(context, 'GPS Logs ({v0})', [_logs.length]),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        ResponsiveGrid(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GpsCsvViewerScreen()),
                );
              },
              icon: const Icon(Icons.table_chart_outlined, size: 18),
              label: Text(ui(context, 'Viewer')),
            ),
            FilledButton.icon(
              onPressed: _createLog,
              icon: const Icon(Icons.add, size: 18),
              label: Text(ui(context, 'Record Track')),
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.assessment_outlined,
              size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            ui(context,
                'No logs yet. Create one to record coordinates, time, elevation and accuracy into a CSV file.'),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            side:
                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
              ui(context, '{v0} readings{v1}{v2}', [
                _counts[log.id] ?? 0,
                _lastReadings[log.id] == null
                    ? ''
                    : ' • last ${_formatTime(_lastReadings[log.id]!)}',
                log.surveyor.trim().isEmpty ? '' : ' • ${log.surveyor.trim()}'
              ]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _recordingLogId == log.id
                      ? ui(context, 'Stop recording')
                      : ui(context, 'Record to this log'),
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
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.table_view_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(ui(context, 'View CSV')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'webmap',
                      child: Row(
                        children: [
                          Icon(Icons.public_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(ui(context, 'Project on WebMap')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(ui(context, 'Rename')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.ios_share_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(ui(context, 'Export / share CSV')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(ui(context, 'Delete'),
                              style: TextStyle(color: Colors.red)),
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

/// Static dial of the compass: ring, degree ticks and N/E/S/W +
/// NE/SE/SW/NW labels. Never repaints — rotation is done by AnimatedRotation,
/// which keeps the compass smooth even at 1 Hz GPS updates.
class _CompassDialPainter extends CustomPainter {
  const _CompassDialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    canvas.drawCircle(
        center,
        radius - 1,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.teal.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Degree ticks every 15°.
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
      final inner = isCardinal
          ? radius - 14
          : isMajor
              ? radius - 10
              : radius - 6;
      final outer = radius - 2;
      final p1 = Offset(
          center.dx + inner * math.sin(rad), center.dy - inner * math.cos(rad));
      final p2 = Offset(
          center.dx + outer * math.sin(rad), center.dy - outer * math.cos(rad));
      canvas.drawLine(p1, p2, isCardinal ? cardinalPaint : tickPaint);
    }
    // Degree numbers every 90° (N/E/S/W positions carry letters instead).
    for (final deg in [30, 60, 120, 150, 210, 240, 300, 330]) {
      final rad = deg * math.pi / 180;
      final r = radius - 24;
      final pos =
          Offset(center.dx + r * math.sin(rad), center.dy - r * math.cos(rad));
      final tp = TextPainter(
        text: TextSpan(
          text: '$deg',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
    // Cardinal labels.
    const labels = ['N', 'E', 'S', 'W'];
    const labelDegs = [0, 90, 180, 270];
    for (int i = 0; i < labels.length; i++) {
      final rad = labelDegs[i] * math.pi / 180;
      final r = radius - 22;
      final pos =
          Offset(center.dx + r * math.sin(rad), center.dy - r * math.cos(rad));
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
    // Intercardinal labels.
    const inter = ['NE', 'SE', 'SW', 'NW'];
    const interDegs = [45, 135, 225, 315];
    for (int i = 0; i < inter.length; i++) {
      final rad = interDegs[i] * math.pi / 180;
      final r = radius - 20;
      final pos =
          Offset(center.dx + r * math.sin(rad), center.dy - r * math.cos(rad));
      final tp = TextPainter(
        text: TextSpan(
          text: inter[i],
          style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 9,
              fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) => false;
}

/// Fixed needle overlay: the red arrow always points UP — the direction the
/// phone is facing — while the dial rotates underneath it.
class _CompassNeedlePainter extends CustomPainter {
  const _CompassNeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    // Red triangle pointing up.
    final tip = Offset(center.dx, center.dy - (radius - 12));
    final baseLeft = Offset(center.dx - 7, center.dy + 4);
    final baseRight = Offset(center.dx + 7, center.dy + 4);
    final notch = Offset(center.dx, center.dy + 1);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.red.shade600);
    // Hub dot on top.
    canvas.drawCircle(center, 5, Paint()..color = Colors.teal.shade800);
    canvas.drawCircle(center, 2.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) => false;
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
      title: Text(ui(context, 'Save Point')),
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
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: ui(context, 'Note (optional)'),
              hintText: ui(context, 'e.g., Standing water at footbridge'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ui(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _notes.text),
          child: Text(ui(context, 'Save')),
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
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: ui(context, 'Track name (optional)'),
          hintText: ui(context, 'e.g., Site A boundary walk'),
        ),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ui(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(ui(context, 'Create')),
        ),
      ],
    );
  }
}
