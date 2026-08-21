import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:path/path.dart' as p;

/// Builds a single GeoJSON FeatureCollection from all local survey_sessions.
///
/// Reuses the same geometry/attribute extraction logic already built for
/// `cloud_sync_service.dart` — both GIS features (feature_type) and survey
/// responses with a geopoint/location_point answer are converted to GeoJSON
/// Features. Photo handling reuses PhotoStore's thumbnail generation.
class WebMapDataService {
  final AppDatabase db;

  WebMapDataService(this.db);

  /// Returns a GeoJSON FeatureCollection map (ready for jsonEncode).
  Future<Map<String, dynamic>> buildFeatureCollection() async {
    final sessions = await (db.select(db.surveySessions)
          ..where((t) => t.status.isNotValue('draft')))
        .get();

    final features = <Map<String, dynamic>>[];
    for (final s in sessions) {
      final feature = await _sessionToFeature(s);
      if (feature != null) features.add(feature);
    }

    return {
      'type': 'FeatureCollection',
      'features': features,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>?> _sessionToFeature(SurveySession s) async {
    Map<String, dynamic> resp;
    try {
      resp = jsonDecode(s.responses) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    // Try GIS feature first (feature_type)
    final featureType = resp['feature_type']?.toString();
    if (featureType == 'point' || featureType == 'line' || featureType == 'polygon') {
      return _gisFeatureToGeoJson(s, resp, featureType!);
    }

    // Try survey response with geopoint answer
    final geopoint = _extractGeopointFromAnswers(resp);
    if (geopoint != null) {
      return _surveyGeopointToFeature(s, resp, geopoint);
    }

    return null;
  }

  /// Reuses cloud_sync's GIS geometry extraction.
  Future<Map<String, dynamic>?> _gisFeatureToGeoJson(
      SurveySession s, Map<String, dynamic> resp, String featureType) async {
    double? lat;
    double? lon;
    dynamic geometry;
    String photoPath = '';

    final photo = resp['photo'];
    if (photo is Map<String, dynamic> && photo['path'] is String) {
      photoPath = photo['path'] as String;
    } else if (photo is String) {
      photoPath = photo;
    } else if (resp['photo_path'] is String) {
      photoPath = resp['photo_path'] as String;
    }

    if (featureType == 'point') {
      lat = (resp['latitude'] as num?)?.toDouble();
      lon = (resp['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      geometry = {
        'type': 'Point',
        'coordinates': [lon, lat],
      };
    } else if (featureType == 'line' || featureType == 'polygon') {
      final raw = resp['vertices'];
      final coords = <List<double>>[];
      if (raw is List) {
        for (final v in raw) {
          if (v is Map && v['latitude'] is num && v['longitude'] is num) {
            coords.add([
              (v['longitude'] as num).toDouble(),
              (v['latitude'] as num).toDouble(),
            ]);
          }
        }
      }
      if (coords.isEmpty) return null;
      if (featureType == 'line') {
        if (coords.length < 2) return null;
        geometry = {
          'type': 'LineString',
          'coordinates': coords,
        };
        lat = coords.first[1];
        lon = coords.first[0];
      } else {
        if (coords.length < 3) return null;
        final closed = List<List<double>>.from(coords);
        if (closed.first[0] != closed.last[0] || closed.first[1] != closed.last[1]) {
          closed.add(List<double>.from(closed.first));
        }
        geometry = {
          'type': 'Polygon',
          'coordinates': [closed],
        };
        lat = coords.first[1];
        lon = coords.first[0];
      }
    } else {
      return null;
    }

    final properties = await _buildProperties(s, resp, featureType, photoPath);
    return {
      'type': 'Feature',
      'geometry': geometry,
      'properties': properties,
    };
  }

  Future<Map<String, dynamic>?> _surveyGeopointToFeature(
      SurveySession s, Map<String, dynamic> resp, _Geopoint geopoint) async {
    final geometry = {
      'type': 'Point',
      'coordinates': [geopoint.longitude, geopoint.latitude],
    };

    // Extract photo if any (survey photo questions)
    String photoPath = '';
    final answers = resp['answers'];
    if (answers is Map) {
      for (final value in answers.values) {
        String? candidate;
        if (value is String) {
          try {
            final inner = jsonDecode(value);
            if (inner is Map<String, dynamic> && inner['path'] is String) {
              candidate = inner['path'] as String;
            }
          } catch (_) {}
        } else if (value is Map<String, dynamic> && value['path'] is String) {
          candidate = value['path'] as String;
        }
        if (candidate != null && candidate.isNotEmpty) {
          // Prefer the one that looks like a photo file
          if (candidate.contains('photos') || candidate.endsWith('.jpg') || candidate.endsWith('.jpeg') || candidate.endsWith('.png')) {
            photoPath = candidate;
            break;
          }
        }
      }
    }
    // Also check top-level photo
    if (photoPath.isEmpty) {
      final photo = resp['photo'];
      if (photo is Map<String, dynamic> && photo['path'] is String) {
        photoPath = photo['path'] as String;
      } else if (resp['photo_path'] is String) {
        photoPath = resp['photo_path'] as String;
      }
    }

    final properties = await _buildProperties(s, resp, 'geopoint', photoPath);
    // For survey geopoint, form_name is more relevant than geometry_type
    // Keep both for consistency
    properties['geometry_type'] = 'geopoint';
    return {
      'type': 'Feature',
      'geometry': geometry,
      'properties': properties,
    };
  }

  /// Shared attribute extraction: surveyor, submitted_at, flattened answers, photo thumbnail.
  Future<Map<String, dynamic>> _buildProperties(
      SurveySession s, Map<String, dynamic> resp, String geometryType, String photoPath) async {
    final answers = resp['answers'];
    final flattened = <String, dynamic>{};
    if (answers is Map) {
      for (final entry in answers.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        // Skip embedding full photo files - just note path (handled separately)
        // If value is a JSON string containing photo path, keep the path string, not the full file
        if (value is String) {
          try {
            final inner = jsonDecode(value);
            if (inner is Map<String, dynamic> && inner.containsKey('path')) {
              flattened[key] = inner['path'];
              continue;
            }
          } catch (_) {}
        }
        flattened[key] = value;
      }
    }

    String? thumbnailBase64;
    if (photoPath.isNotEmpty) {
      thumbnailBase64 = await _thumbnailBase64(photoPath);
    }

    final project = await db.getProjectById(s.projectId);
    final projectName = project?.name ?? '';

    return {
      'id': s.externalId ?? s.id.toString(),
      'project_name': projectName,
      'surveyor': resp['user_name']?.toString() ?? resp['surveyor']?.toString() ?? '',
      'submitted_at': s.createdAt.toIso8601String(),
      'form_name': resp['form_name']?.toString() ?? '',
      'geometry_type': geometryType,
      'answers': flattened,
      if (photoPath.isNotEmpty) 'photo_path': p.basename(photoPath),
      if (photoPath.isNotEmpty) 'photo_relative_path': photoPath,
      if (thumbnailBase64 != null) 'thumbnail_base64': thumbnailBase64,
      'status': s.status,
    };
  }

  /// Extracts a geopoint from survey answers. Handles multiple storage formats:
  /// - String "lat lon alt accuracy" (ODK style)
  /// - Map {latitude, longitude}
  /// - Direct lat/lon fields in answers
  _Geopoint? _extractGeopointFromAnswers(Map<String, dynamic> resp) {
    final answers = resp['answers'];
    if (answers is! Map) return null;
    for (final value in answers.values) {
      final parsed = _parseGeopointValue(value);
      if (parsed != null) return parsed;
    }
    // Also check direct fields in resp (some forms store geopoint at top level)
    for (final key in ['geopoint', 'location_point', 'location', 'gps']) {
      if (resp.containsKey(key)) {
        final parsed = _parseGeopointValue(resp[key]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  _Geopoint? _parseGeopointValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      // Try JSON object first
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          if (decoded['latitude'] is num && decoded['longitude'] is num) {
            return _Geopoint(
              latitude: (decoded['latitude'] as num).toDouble(),
              longitude: (decoded['longitude'] as num).toDouble(),
            );
          }
          if (decoded['lat'] is num && decoded['lon'] is num) {
            return _Geopoint(
              latitude: (decoded['lat'] as num).toDouble(),
              longitude: (decoded['lon'] as num).toDouble(),
            );
          }
        }
      } catch (_) {}
      // ODK style: "lat lon alt accuracy" space-separated
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        if (lat != null && lon != null) {
          return _Geopoint(latitude: lat, longitude: lon);
        }
      }
    } else if (value is Map<String, dynamic>) {
      if (value['latitude'] is num && value['longitude'] is num) {
        return _Geopoint(
          latitude: (value['latitude'] as num).toDouble(),
          longitude: (value['longitude'] as num).toDouble(),
        );
      }
      if (value['lat'] is num && value['lon'] is num) {
        return _Geopoint(
          latitude: (value['lat'] as num).toDouble(),
          longitude: (value['lon'] as num).toDouble(),
        );
      }
      // Nested photo-like but with coordinates?
      if (value['path'] is String) return null; // photo, not geopoint
    } else if (value is Map) {
      final lat = value['latitude'] ?? value['lat'];
      final lon = value['longitude'] ?? value['lon'];
      if (lat is num && lon is num) {
        return _Geopoint(latitude: lat.toDouble(), longitude: lon.toDouble());
      }
    }
    return null;
  }

  /// Generates a 512px quality 70 thumbnail (reusing PhotoStore logic) and base64-encodes it.
  Future<String?> _thumbnailBase64(String photoPath) async {
    try {
      final file = File(photoPath);
      if (!file.existsSync()) return null;
      // Cap: don't embed if original is huge? Thumbnail will still be small.
      // We cap thumbnail base64 to avoid ballooning GeoJSON.
      final bytes = await file.readAsBytes();
      final thumb = _buildThumb(bytes);
      if (thumb == null || thumb.isEmpty) return null;
      // Cap thumbnail size to ~100KB base64 (~75KB binary) - already small via 512px
      if (thumb.length > 100 * 1024) return null;
      return base64Encode(thumb);
    } catch (_) {
      return null;
    }
  }

  /// Reuses PhotoStore's thumbnail generation: 512px max dimension, quality 70.
  Uint8List? _buildThumb(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final thumb = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? PhotoStore.maxThumbDimension : null,
        height: decoded.height >= decoded.width ? PhotoStore.maxThumbDimension : null,
        interpolation: img.Interpolation.linear,
      );
      return Uint8List.fromList(img.encodeJpg(thumb, quality: 70));
    } catch (_) {
      return null;
    }
  }
}

class _Geopoint {
  final double latitude;
  final double longitude;
  _Geopoint({required this.latitude, required this.longitude});
}
