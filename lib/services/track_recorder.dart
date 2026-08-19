import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/services/geometry_service.dart';

/// Collects GPS vertices for line/polygon recording, applying the
/// configured filters (minimum distance, minimum interval, maximum
/// accuracy) as required by the product spec.
class TrackRecorder {
  final double minDistanceM;
  final double minIntervalS;
  final double maxAccuracyM;

  final List<Position> vertices = [];
  Position? latest;
  bool running = false;
  bool paused = false;

  DateTime? _startedAt;
  DateTime? _lastResumeAt;
  Duration _pausedTotal = Duration.zero;

  TrackRecorder({
    this.minDistanceM = 3,
    this.minIntervalS = 2,
    this.maxAccuracyM = 20,
  });

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    final now = paused ? (_lastResumeAt ?? _startedAt!) : DateTime.now();
    return now.difference(_startedAt!) - _pausedTotal;
  }

  double get totalDistanceM {
    return GeometryService.polylineLengthM(
      vertices.map((p) => (lat: p.latitude, lon: p.longitude)).toList(),
    );
  }

  void start() {
    running = true;
    paused = false;
    _startedAt ??= DateTime.now();
    _lastResumeAt = DateTime.now();
  }

  void pause() {
    if (!running || paused) return;
    paused = true;
    _pausedTotal += DateTime.now().difference(_lastResumeAt ?? _startedAt!);
  }

  void resume() {
    if (!running || !paused) return;
    paused = false;
    _lastResumeAt = DateTime.now();
  }

  /// Feeds a fresh GPS fix. Returns true when the fix passed the filters
  /// and a new vertex was added.
  bool add(Position position) {
    latest = position;
    if (!running || paused) return false;

    if (position.accuracy > maxAccuracyM) return false;

    final now = DateTime.now();
    final last = vertices.isEmpty ? null : vertices.last;
    final lastAddedAt = _lastVertexTime;

    if (last != null && lastAddedAt != null) {
      final interval = now.difference(lastAddedAt).inMilliseconds / 1000;
      if (interval < minIntervalS) return false;

      final distance = GeometryService.distanceMeters(
        last.latitude,
        last.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance < minDistanceM) return false;
    }

    vertices.add(position);
    _lastVertexTime = now;
    return true;
  }

  void undo() {
    if (vertices.isEmpty) return;
    vertices.removeLast();
  }

  void reset() {
    vertices.clear();
    latest = null;
    running = false;
    paused = false;
    _startedAt = null;
    _lastResumeAt = null;
    _lastVertexTime = null;
    _pausedTotal = Duration.zero;
  }

  String get elapsedLabel {
    final e = elapsed;
    final minutes = e.inMinutes.toString().padLeft(2, '0');
    final seconds = (e.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  DateTime? _lastVertexTime;
}