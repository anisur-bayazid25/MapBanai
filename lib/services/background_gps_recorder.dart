import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/services/gps_log_store.dart';
import 'package:mapbanai/services/location_service.dart';

/// App-wide GPS track recorder that keeps logging independently of the UI.
///
/// The GPS mode screen hands the active log to [start]; from that point the
/// recorder owns the live geolocator stream (with an Android foreground
/// notification + wake lock) so logging continues when the user presses the
/// back button, leaves the app, or turns the screen off. The Home screen
/// shows a banner while a recording is active so the user can return and
/// stop it. Only [stop] releases the stream and the foreground notification.
class BackgroundGps extends ChangeNotifier {
  BackgroundGps._();

  static final BackgroundGps instance = BackgroundGps._();

  final LocationService _locationService = LocationService();
  final GpsLogStore _store = GpsLogStore();

  StreamSubscription<Position>? _subscription;
  int? _logId;
  String _logName = '';
  String _surveyor = '';
  Position? _latest;
  bool _paused = false;
  DateTime? _lastAppend;

  bool get isRecording => _logId != null && _subscription != null;

  int? get activeLogId => _logId;

  String get activeLogName => _logName;

  Position? get latest => _latest;

  bool get isPaused => _paused;

  /// Starts recording fixes to [logId]. Replaces any active recording.
  Future<bool> start({
    required int logId,
    required String logName,
    required String surveyor,
  }) async {
    await stop();

    final granted = await _locationService.ensurePermission();
    if (!granted) return false;

    _logId = logId;
    _logName = logName;
    _surveyor = surveyor.trim();
    _paused = false;
    _lastAppend = null;

    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'MapBanai — GPS recording',
          notificationText: 'Track logging continues with the screen off',
          notificationChannelName: 'MapBanai GPS recording',
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
      _onFix,
      onError: (_) {
        // A transient fix error must not kill an ongoing recording; the
        // stream keeps delivering once a fix is available again.
      },
      cancelOnError: false,
    );
    notifyListeners();
    return true;
  }

  /// Stops recording and releases the GPS stream + foreground notification.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _logId = null;
    _logName = '';
    _latest = null;
    _paused = false;
    notifyListeners();
  }

  /// While [isRecording], paused appends are skipped but the stream (and the
  /// foreground service) stay alive so the last fix is still available.
  void setPaused(bool paused) {
    if (_paused == paused) return;
    _paused = paused;
    notifyListeners();
  }

  Future<void> _onFix(Position position) async {
    _latest = position;
    final logId = _logId;
    if (_paused || logId == null) {
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final last = _lastAppend;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      notifyListeners();
      return;
    }
    _lastAppend = now;

    try {
      await _store.appendReading(
        logId: logId,
        surveyor: _surveyor,
        position: position,
        timestamp: now,
      );
    } catch (_) {
      // A single failed write (e.g. storage hiccup) must not stop logging.
    }
    notifyListeners();
  }
}