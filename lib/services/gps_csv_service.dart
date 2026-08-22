import 'dart:io';
import 'dart:math' as math;

import 'package:mapbanai/services/gps_log_store.dart';
import 'package:mapbanai/services/webmap_generator.dart';

/// Service for viewing GPS CSV log files and projecting them onto WebMap.
/// Uses GpsLogStore CSV format: id,surveyor,timestamp,latitude,longitude,altitude_m,accuracy_m,notes
class GpsCsvService {
  /// Parses a CSV file at [path] into readings.
  static Future<List<GpsLogReading>> parseFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return [];
    final content = await file.readAsString();
    return parseCsvContent(content);
  }

  /// Parses raw CSV string content (with header) into readings.
  static List<GpsLogReading> parseCsvContent(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return [];
    // Find header line.
    int headerIdx = 0;
    while (headerIdx < lines.length &&
        lines[headerIdx].trim().isEmpty) {
      headerIdx++;
    }
    if (headerIdx >= lines.length) return [];
    final header = _splitCsvLine(lines[headerIdx]);
    final lower = header.map((e) => e.trim().toLowerCase()).toList();

    int latIdx = lower.indexOf('latitude');
    if (latIdx == -1) latIdx = lower.indexOf('lat');
    int lonIdx = lower.indexOf('longitude');
    if (lonIdx == -1) lonIdx = lower.indexOf('lon');
    if (lonIdx == -1) lonIdx = lower.indexOf('lng');
    int altIdx = lower.indexOf('altitude_m');
    if (altIdx == -1) altIdx = lower.indexOf('altitude');
    if (altIdx == -1) altIdx = lower.indexOf('alt');
    int accIdx = lower.indexOf('accuracy_m');
    if (accIdx == -1) accIdx = lower.indexOf('accuracy');
    int timeIdx = lower.indexOf('timestamp');
    if (timeIdx == -1) timeIdx = lower.indexOf('time');
    int idIdx = lower.indexOf('id');
    int surveyorIdx = lower.indexOf('surveyor');
    int notesIdx = lower.indexOf('notes');

    if (latIdx == -1 || lonIdx == -1) return [];

    final readings = <GpsLogReading>[];
    for (int i = headerIdx + 1; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      final cols = _splitCsvLine(lines[i]);
      // Pad
      while (cols.length <=
          [latIdx, lonIdx, altIdx, accIdx, timeIdx, idIdx, surveyorIdx, notesIdx]
              .where((e) => e >= 0)
              .fold<int>(0, (a, b) => a > b ? a : b)) {
        cols.add('');
      }
      final latStr = latIdx < cols.length ? cols[latIdx].trim() : '';
      final lonStr = lonIdx < cols.length ? cols[lonIdx].trim() : '';
      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat == null || lon == null) continue;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

      final id = idIdx >= 0 && idIdx < cols.length
          ? int.tryParse(cols[idIdx].trim()) ?? readings.length + 1
          : readings.length + 1;
      final surveyor = surveyorIdx >= 0 && surveyorIdx < cols.length
          ? cols[surveyorIdx].trim()
          : '';
      final tsStr = timeIdx >= 0 && timeIdx < cols.length
          ? cols[timeIdx].trim()
          : '';
      final ts = DateTime.tryParse(tsStr) ?? DateTime.now();
      final alt = altIdx >= 0 && altIdx < cols.length
          ? double.tryParse(cols[altIdx].trim()) ?? 0
          : 0;
      final acc = accIdx >= 0 && accIdx < cols.length
          ? double.tryParse(cols[accIdx].trim()) ?? 0
          : 0;
      final notes = notesIdx >= 0 && notesIdx < cols.length
          ? _stripQuotes(cols[notesIdx])
          : '';

      readings.add(GpsLogReading(
        id: id,
        surveyor: _stripQuotes(surveyor),
        timestamp: ts,
        latitude: lat,
        longitude: lon,
        altitude: alt.toDouble(),
        accuracy: acc.toDouble(),
        notes: notes,
      ));
    }
    return readings;
  }

  static String _stripQuotes(String s) {
    var v = s.trim();
    if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
      v = v.substring(1, v.length - 1).replaceAll('""', '"');
    }
    return v;
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }

  /// Builds a GeoJSON FeatureCollection from GPS readings.
  /// Includes point features for each reading and a LineString track if >=2 points.
  static Map<String, dynamic> toFeatureCollection(
    List<GpsLogReading> readings, {
    String logName = 'GPS Log',
  }) {
    final features = <Map<String, dynamic>>[];

    if (readings.length >= 2) {
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            for (final r in readings) [r.longitude, r.latitude],
          ],
        },
        'properties': {
          'name': logName,
          'type': 'gps_track',
          'geometry_type': 'line',
          'reading_count': readings.length,
          'surveyor': readings.first.surveyor,
        },
      });
    }

    for (final r in readings) {
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [r.longitude, r.latitude],
        },
        'properties': {
          'id': r.id.toString(),
          'geometry_type': 'point',
          'surveyor': r.surveyor,
          'timestamp': r.timestamp.toIso8601String(),
          'altitude_m': r.altitude,
          'accuracy_m': r.accuracy,
          'notes': r.notes,
          'log_name': logName,
        },
      });
    }

    return {
      'type': 'FeatureCollection',
      'features': features,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'log_name': logName,
    };
  }

  /// Generates a self-contained WebMap HTML overlay for the given readings.
  /// This is separate from project-based webmap and does not add to projects.
  static Future<String> generateWebMapHtml(
    List<GpsLogReading> readings, {
    String logName = 'GPS Log',
  }) async {
    final fc = toFeatureCollection(readings, logName: logName);
    final generator = WebMapGenerator();
    return await generator.generateHtml(featureCollection: fc);
  }

  static Future<File> writeWebMapToFile(
    List<GpsLogReading> readings, {
    String logName = 'GPS Log',
    Directory? directory,
  }) async {
    final html = await generateWebMapHtml(readings, logName: logName);
    final generator = WebMapGenerator();
    return await generator.writeToFile(html, directory: directory);
  }

  /// Reads all GPS logs from [GpsLogStore] and returns map of logId -> readings.
  static Future<Map<int, List<GpsLogReading>>> loadAllLogs(
      GpsLogStore store, List<int> logIds) async {
    final result = <int, List<GpsLogReading>>{};
    for (final id in logIds) {
      final path = await store.filePath(id);
      final readings = await parseFile(path);
      result[id] = readings;
    }
    return result;
  }

  /// Quick stats for a list of readings.
  static Map<String, dynamic> stats(List<GpsLogReading> readings) {
    if (readings.isEmpty) {
      return {'count': 0, 'distance_m': 0.0, 'duration_s': 0};
    }
    double dist = 0;
    for (int i = 1; i < readings.length; i++) {
      dist += _haversine(
        readings[i - 1].latitude,
        readings[i - 1].longitude,
        readings[i].latitude,
        readings[i].longitude,
      );
    }
    final duration = readings.last.timestamp
        .difference(readings.first.timestamp)
        .inSeconds;
    return {
      'count': readings.length,
      'distance_m': dist,
      'duration_s': duration,
      'start': readings.first.timestamp,
      'end': readings.last.timestamp,
    };
  }

  static double _haversine(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(a)));
  }

}
