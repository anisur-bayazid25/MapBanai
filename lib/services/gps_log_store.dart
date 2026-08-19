import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A single logged GPS reading (one CSV row).
class GpsLogReading {
  final int id;
  final String surveyor;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final String notes;

  const GpsLogReading({
    required this.id,
    required this.surveyor,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    this.notes = '',
  });
}

/// Stores GPS log files (CSV) under app documents / gps_logs/.
///
/// Each log has its own file named `log_<id>.csv`; every reading appended
/// during recording gets an auto-incremented row id. [GpsLogReading.notes]
/// holds an optional free-text note attached to a manually captured waypoint.
class GpsLogStore {
  static const String header =
      'id,surveyor,timestamp,latitude,longitude,altitude_m,accuracy_m,notes';

  final Directory? _baseDir;

  GpsLogStore({Directory? baseDir}) : _baseDir = baseDir;

  static Future<Directory> defaultLogsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'gps_logs'));
  }

  Future<Directory> _logsDir() async {
    final dir = _baseDir ?? await defaultLogsDir();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<String> filePath(int logId) async {
    final dir = await _logsDir();
    return p.join(dir.path, 'log_$logId.csv');
  }

  /// Creates the CSV file (header only) for a new log.
  Future<void> createLogFile(int logId) async {
    final path = await filePath(logId);
    final file = File(path);
    if (file.existsSync()) return;
    await file.writeAsString('$header\n', flush: true);
  }

  /// Appends one reading; the row id is the current line count (header is
  /// line 1), so ids are 1, 2, 3… and survive app restarts.
  Future<GpsLogReading> appendReading({
    required int logId,
    required String surveyor,
    required Position position,
    DateTime? timestamp,
    String notes = '',
  }) async {
    final file = File(await filePath(logId));
    if (!file.existsSync()) {
      await createLogFile(logId);
    }

    final now = timestamp ?? DateTime.now();
    final lines = file.existsSync() ? await file.readAsLines() : <String>[];
    final id = lines.length;
    final line = [
      '$id',
      _escape(surveyor),
      now.toIso8601String(),
      position.latitude.toStringAsFixed(7),
      position.longitude.toStringAsFixed(7),
      position.altitude.toStringAsFixed(2),
      position.accuracy.toStringAsFixed(2),
      _escape(notes.trim()),
    ].join(',');

    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);

    return GpsLogReading(
      id: id,
      surveyor: surveyor,
      timestamp: now,
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      notes: notes.trim(),
    );
  }

  /// Number of readings (rows after the header).
  Future<int> readingCount(int logId) async {
    final file = File(await filePath(logId));
    if (!file.existsSync()) return 0;
    final lines = await file.readAsLines();
    return lines.length > 1 ? lines.length - 1 : 0;
  }

  /// Timestamp of the last reading, if any.
  Future<DateTime?> lastReadingTime(int logId) async {
    final file = File(await filePath(logId));
    if (!file.existsSync()) return null;
    final lines = await file.readAsLines();
    if (lines.length < 2) return null;
    final columns = lines.last.split(',');
    if (columns.length < 3) return null;
    return DateTime.tryParse(columns[2]);
  }

  Future<void> deleteFile(int logId) async {
    final file = File(await filePath(logId));
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Loads live log info (id, name, surveyor, counts) for a list of logs.
  static Future<List<Map<String, dynamic>>> loadLogInfo(
    List<GpsLog> logs,
    GpsLogStore store,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final log in logs) {
      result.add({
        'log': log,
        'count': await store.readingCount(log.id),
        'last': await store.lastReadingTime(log.id),
      });
    }
    return result;
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
