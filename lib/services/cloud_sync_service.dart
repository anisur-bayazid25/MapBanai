import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:mapbanai/data/app_database.dart';

class CloudSyncException implements Exception {
  final String message;
  const CloudSyncException(this.message);
  @override
  String toString() => message;
}

class SyncResult {
  final int responsesSynced;
  final int featuresSynced;
  const SyncResult({required this.responsesSynced, required this.featuresSynced});
}

class CloudSyncService {
  final AppDatabase db;
  final http.Client? _client;

  CloudSyncService(this.db, {http.Client? client}) : _client = client;

  Future<List<SurveySession>> queryUnsyncedResponses(int projectId) async {
    final all = await (db.select(db.surveySessions)
          ..where((t) => t.projectId.equals(projectId))
          ..where((t) => t.syncedAt.isNull())
          ..where((t) => t.status.equals('draft').not()))
        .get();
    return all.where((s) => !_containsFeatureType(s.responses)).toList();
  }

  Future<List<SurveySession>> queryUnsyncedFeatures(int projectId) async {
    final all = await (db.select(db.surveySessions)
          ..where((t) => t.projectId.equals(projectId))
          ..where((t) => t.syncedAt.isNull())
          ..where((t) => t.status.equals('draft').not()))
        .get();
    return all.where((s) => _containsFeatureType(s.responses)).toList();
  }

  bool _containsFeatureType(String responses) {
    // Same distinction project already uses: %feature_type%
    return responses.contains('feature_type');
  }

  /// Syncs unsynced responses + features for [projectId].
  /// Throws [CloudSyncException] on failure; marks rows only on {ok:true}.
  Future<SyncResult> syncProject(int projectId) async {
    final config = await db.getSyncConfig(projectId);
    final rawUrl = config?.syncEndpointUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      throw const CloudSyncException('Sync URL not configured for this project');
    }
    Uri uri;
    try {
      uri = Uri.parse(rawUrl);
      if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        throw const FormatException('URL must start with http:// or https://');
      }
      if (uri.host.isEmpty) throw const FormatException('Invalid URL');
    } catch (e) {
      throw CloudSyncException('Invalid sync URL: $e');
    }
    final apiKey = config?.syncApiKey?.trim() ?? '';

    final project = await db.getProjectById(projectId);
    if (project == null) {
      throw const CloudSyncException('Project not found');
    }

    final unsyncedResponses = await queryUnsyncedResponses(projectId);
    final unsyncedFeatures = await queryUnsyncedFeatures(projectId);

    if (unsyncedResponses.isEmpty && unsyncedFeatures.isEmpty) {
      return const SyncResult(responsesSynced: 0, featuresSynced: 0);
    }

    final responsesPayload = _buildResponsesPayload(unsyncedResponses, project.name);
    final featuresPayload = _buildFeaturesPayload(unsyncedFeatures, project.name);

    final body = jsonEncode({
      'apiKey': apiKey,
      'action': 'sync_data',
      'responses': responsesPayload,
      'features': featuresPayload,
    });

    http.Response httpResponse;
    try {
      final client = _client ?? http.Client();
      final shouldClose = _client == null;
      try {
        httpResponse = await _postJsonWithRedirect(
          client: client,
          uri: uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 30));
      } finally {
        if (shouldClose) client.close();
      }
    } on TimeoutException {
      throw const CloudSyncException('Sync timed out after 30s');
    } on CloudSyncException {
      rethrow;
    } catch (e) {
      throw CloudSyncException('Network error: $e');
    }

    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
      // Try to extract server error field even on non-2xx
      try {
        final decoded = jsonDecode(httpResponse.body);
        if (decoded is Map<String, dynamic> && decoded['error'] is String) {
          throw CloudSyncException(decoded['error'] as String);
        }
      } catch (e) {
        if (e is CloudSyncException) rethrow;
        // ignore parse errors, fall through
      }
      // Provide a more actionable message for 405
      if (httpResponse.statusCode == 405) {
        throw CloudSyncException(
          'Sync failed: HTTP 405 Method Not Allowed — the endpoint rejected the request. '
          'Verify the Apps Script is deployed as a Web App (Execute as: Me, Who has access: Anyone), '
          'implements function doPost(e), and that you saved the /exec URL (not /dev).',
        );
      }
      throw CloudSyncException(
        'Sync failed: HTTP ${httpResponse.statusCode}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(httpResponse.body);
    } catch (_) {
      throw const CloudSyncException('Invalid server response: not JSON');
    }

    if (decoded is Map<String, dynamic> && decoded['ok'] == true) {
      final now = DateTime.now();
      final cfg = config!;
      await db.transaction(() async {
        for (final s in [...unsyncedResponses, ...unsyncedFeatures]) {
          await (db.update(db.surveySessions)..where((t) => t.id.equals(s.id)))
              .write(SurveySessionsCompanion(syncedAt: Value(now)));
        }
        // Update lastSyncAt preserving url/key
        await db.upsertSyncConfig(
          projectId: projectId,
          syncEndpointUrl: cfg.syncEndpointUrl,
          syncApiKey: cfg.syncApiKey,
          lastSyncAt: Value(now),
        );
      });
      return SyncResult(
        responsesSynced: unsyncedResponses.length,
        featuresSynced: unsyncedFeatures.length,
      );
    } else {
      final message = (decoded is Map<String, dynamic> &&
              decoded['error'] is String &&
              (decoded['error'] as String).trim().isNotEmpty)
          ? decoded['error'] as String
          : 'Sync failed';
      throw CloudSyncException(message);
    }
  }

  /// POSTs [body] as JSON, following redirects the way Apps Script requires.
  ///
  /// Apps Script Web App flow: the initial POST to script.google.com/.../exec
  /// EXECUTES doPost and caches the response, then answers 302 with a
  /// Location on script.googleusercontent.com that serves the cached body
  /// and ONLY accepts GET. Re-POSTing there returns "405 Method Not Allowed",
  /// so after the first hop we always switch to GET with no body.
  Future<http.Response> _postJsonWithRedirect({
    required http.Client client,
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    const maxHops = 5;
    Uri currentUri = uri;
    var method = 'POST';
    String? payload = body;
    for (var hop = 0; hop <= maxHops; hop++) {
      final request = http.Request(method, currentUri);
      request.headers.addAll(headers);
      if (payload != null) request.body = payload;
      request.followRedirects = false;
      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      final isRedirect = response.isRedirect ||
          (response.statusCode >= 301 && response.statusCode <= 308);
      if (!isRedirect) {
        return response;
      }
      if (hop == maxHops) {
        throw const CloudSyncException('Too many redirects');
      }
      final location = response.headers['location'];
      if (location == null || location.isEmpty) {
        throw const CloudSyncException('Redirect without Location header');
      }
      Uri nextUri = Uri.parse(location);
      if (!nextUri.hasScheme) {
        nextUri = currentUri.resolveUri(nextUri);
      }
      final host = nextUri.host.toLowerCase();
      // Allow loopback for unit tests; production only follows google hosts.
      final isLoopback = host == '127.0.0.1' ||
          host == 'localhost' ||
          host == '::1';
      if (!(host.endsWith('.google.com') ||
          host.endsWith('.googleusercontent.com') ||
          isLoopback)) {
        throw CloudSyncException(
            'Refusing to follow redirect to $host');
      }
      // The script already ran on the initial POST; the redirect target only
      // serves the cached response via GET.
      method = 'GET';
      payload = null;
      currentUri = nextUri;
    }
    throw const CloudSyncException('Too many redirects');
  }

  List<Map<String, dynamic>> _buildResponsesPayload(
    List<SurveySession> sessions,
    String projectName,
  ) {
    final list = <Map<String, dynamic>>[];
    for (final s in sessions) {
      Map<String, dynamic> resp;
      try {
        resp = jsonDecode(s.responses) as Map<String, dynamic>;
      } catch (_) {
        resp = {};
      }
      final formName = resp['form_name']?.toString() ??
          resp['form_id']?.toString() ??
          '';
      final answers = resp['answers'];
      final surveyor = resp['user_name']?.toString() ??
          resp['surveyor']?.toString() ??
          '';
      // Use stable UUID, fallback to local id only for very old unmigrated rows
      final stableId = (s.externalId != null && s.externalId!.isNotEmpty)
          ? s.externalId!
          : s.id.toString();
      list.add({
        'response_id': stableId,
        'project_name': projectName,
        'surveyor': surveyor,
        'submitted_at': s.createdAt.toIso8601String(),
        'form_name': formName,
        'answers': answers is Map ? answers : {},
      });
    }
    return list;
  }

  List<Map<String, dynamic>> _buildFeaturesPayload(
    List<SurveySession> sessions,
    String projectName,
  ) {
    final list = <Map<String, dynamic>>[];
    for (final s in sessions) {
      Map<String, dynamic> resp;
      try {
        resp = jsonDecode(s.responses) as Map<String, dynamic>;
      } catch (_) {
        resp = {};
      }
      final geometryType = resp['feature_type']?.toString() ?? 'unknown';
      double? lat;
      double? lon;
      dynamic geojson;
      String photoPath = '';

      // photo_path extraction
      final photo = resp['photo'];
      if (photo is Map<String, dynamic> && photo['path'] is String) {
        photoPath = photo['path'] as String;
      } else if (photo is String) {
        photoPath = photo;
      } else if (resp['photo_path'] is String) {
        photoPath = resp['photo_path'] as String;
      }

      if (geometryType == 'point') {
        lat = (resp['latitude'] as num?)?.toDouble();
        lon = (resp['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          geojson = {
            'type': 'Point',
            'coordinates': [lon, lat],
          };
        }
      } else if (geometryType == 'line' || geometryType == 'polygon') {
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
        if (coords.isNotEmpty) {
          lat = coords.first[1];
          lon = coords.first[0];
        }
        if (geometryType == 'line') {
          geojson = {
            'type': 'LineString',
            'coordinates': coords,
          };
        } else {
          // polygon: close ring if needed
          final closed = List<List<double>>.from(coords);
          if (closed.isNotEmpty &&
              (closed.first[0] != closed.last[0] ||
                  closed.first[1] != closed.last[1])) {
            closed.add(List<double>.from(closed.first));
          }
          geojson = {
            'type': 'Polygon',
            'coordinates': [closed],
          };
        }
      } else {
        // fallback: try to expose whatever geometry is present
        geojson = null;
      }

      // Use stable UUID for deduplication
      final stableId = (s.externalId != null && s.externalId!.isNotEmpty)
          ? s.externalId!
          : s.id.toString();
      list.add({
        'feature_id': stableId,
        'project_name': projectName,
        'surveyor': resp['user_name']?.toString() ?? '',
        'geometry_type': geometryType,
        'latitude': lat,
        'longitude': lon,
        'geojson': geojson,
        'photo_path': photoPath,
      });
    }
    return list;
  }
}
