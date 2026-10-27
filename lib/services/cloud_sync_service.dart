import 'package:mapbanai/services/project_workspace_service.dart';
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/guided_visit_service.dart';

class CloudSyncException implements Exception {
  final String message;
  const CloudSyncException(this.message);
  @override
  String toString() => message;
}

class SyncResult {
  final int responsesSynced;
  final int featuresSynced;
  const SyncResult(
      {required this.responsesSynced, required this.featuresSynced});
}

class CloudSyncService {
  final AppDatabase db;
  final http.Client? _client;
  final StudyAreaStore? studyAreaStore;

  CloudSyncService(this.db, {http.Client? client, this.studyAreaStore})
      : _client = client;

  /// Checks credentials and spreadsheet access without sending field records.
  Future<void> testConnection({
    required String endpoint,
    required String apiKey,
    required String projectId,
  }) async {
    final uri = Uri.tryParse(endpoint.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const CloudSyncException(
          'Paste the complete Apps Script Web app URL, starting with https:// and ending /exec.');
    }
    if (uri.host == 'script.google.com' &&
        (uri.scheme != 'https' ||
            !RegExp(r'^/macros/s/[^/]+/exec$').hasMatch(uri.path))) {
      throw const CloudSyncException(
          'Use Deploy → Manage deployments → Web app URL ending /exec. Editor and /dev URLs cannot be used.');
    }
    if (projectId.trim().isEmpty) {
      throw const CloudSyncException(
          'Project identity is missing. Reopen the project and try again.');
    }
    if (apiKey.trim().isEmpty) {
      throw const CloudSyncException(
          'Enter the API key shown by the manager setup.');
    }
    final client = _client ?? http.Client();
    try {
      final response = await _postJsonWithRedirect(
        client: client,
        uri: uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'test_connection',
          'projectId': projectId,
          'apiKey': apiKey.trim()
        }),
      ).timeout(const Duration(seconds: 25));
      final body = response.body.trim();
      final lower = body.toLowerCase();
      if (lower.contains('accounts.google.com') ||
          lower.contains('servicelogin')) {
        throw const CloudSyncException(
            'Google requires sign-in. Deploy the Web app with Execute as: Me and Who has access: Anyone, then copy its /exec URL.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CloudSyncException(
            'Google returned HTTP ${response.statusCode}. Check the deployment URL and Web app access in Deploy → Manage deployments.');
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        throw const CloudSyncException(
            'The URL returned a web page instead of the MapBanai API. Deploy the bundled Code.gs as a Web app (Execute as: Me; access: Anyone). For an existing deployment, select Edit → New version → Deploy.');
      }
      if (decoded is! Map || decoded['ok'] != true) {
        final error = decoded is Map ? decoded['error']?.toString() ?? '' : '';
        if (error.toLowerCase().contains('unknown action')) {
          throw const CloudSyncException(
              'This deployment uses an older script. Replace Code.gs with the bundled manager script, then Edit deployment → New version → Deploy. Keep the same URL and API key.');
        }
        if (error.toLowerCase().contains('api key') ||
            error.toLowerCase().contains('project id')) {
          throw const CloudSyncException(
              'Project ID or API key does not match the manager script. Copy this project’s ID into manager setup and use its API key.');
        }
        throw const CloudSyncException(
            'Manager setup could not be verified. Run setupMapBanai, authorize spreadsheet access, and deploy the latest script version.');
      }
      if (decoded['connectionVerified'] != true) {
        throw const CloudSyncException(
            'The server replied but did not verify credentials. Update Code.gs and deploy a new version to enable the connection check.');
      }
    } on TimeoutException {
      throw const CloudSyncException(
          'Connection timed out. Check internet access and try again.');
    } on http.ClientException {
      throw const CloudSyncException(
          'Could not reach the server. Check internet access and the Web app URL.');
    } finally {
      if (_client == null) client.close();
    }
  }

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
    try {
      final value = jsonDecode(responses);
      return value is Map &&
          ['point', 'line', 'polygon'].contains(value['feature_type']);
    } catch (_) {
      return false;
    }
  }

  /// Syncs unsynced responses + features for [projectId].
  /// Throws [CloudSyncException] on failure; marks rows only on {ok:true}.
  static final Set<(AppDatabase, int)> _activeSyncs = {};

  Future<SyncResult> syncProject(int projectId) async {
    final key = (db, projectId);
    if (!_activeSyncs.add(key)) {
      throw const CloudSyncException(
          'This project is already syncing. Wait for it to finish.');
    }
    try {
      return await _syncProject(projectId);
    } finally {
      _activeSyncs.remove(key);
    }
  }

  Future<SyncResult> _syncProject(int projectId) async {
    final config = await db.getSyncConfig(projectId);
    final rawUrl = config?.syncEndpointUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      throw const CloudSyncException(
          'Sync URL not configured for this project');
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

    final existingProject = await db.getProjectById(projectId);
    if (existingProject == null) {
      throw const CloudSyncException('Project not found');
    }

    final project = (await ProjectWorkspaceService(db).load(projectId)).project;

    if (studyAreaStore != null) {
      final operator = await db.getSetting('user_name') ?? 'Local fieldworker';
      for (final site in await studyAreaStore!.loadSites()) {
        if (!GuidedVisitService.belongsToProject(site, project)) continue;
        if (!site.hasChanges) continue;
        site.projectId = projectId;
        await StudyAreaOutboxService(db)
            .enqueue(site, site.history.lastOrNull?.author ?? operator);
      }
    }
    final unsyncedResponses = await queryUnsyncedResponses(projectId);
    final unsyncedFeatures = await queryUnsyncedFeatures(projectId);

    if (unsyncedResponses.isEmpty && unsyncedFeatures.isEmpty) {
      return const SyncResult(responsesSynced: 0, featuresSynced: 0);
    }

    var responsesSynced = 0, featuresSynced = 0;
    // Small sequential requests keep Apps Script execution and lock time bounded.
    final pending = [...unsyncedResponses, ...unsyncedFeatures];
    final responseIds = unsyncedResponses.map((s) => s.id).toSet();
    for (var offset = 0; offset < pending.length; offset += 20) {
      final chunk = pending.skip(offset).take(20).toList();
      final result = await _syncBatch(
          projectId,
          uri,
          apiKey,
          project.externalId!,
          project.name,
          chunk.where((s) => responseIds.contains(s.id)).toList(),
          chunk.where((s) => !responseIds.contains(s.id)).toList());
      responsesSynced += result.responsesSynced;
      featuresSynced += result.featuresSynced;
    }
    return SyncResult(
        responsesSynced: responsesSynced, featuresSynced: featuresSynced);
  }

  Future<SyncResult> _syncBatch(
      int projectId,
      Uri uri,
      String apiKey,
      String externalId,
      String projectName,
      List<SurveySession> unsyncedResponses,
      List<SurveySession> unsyncedFeatures) async {
    // A history cleanup may run between queued batches. Recheck storage so
    // deleted records are never sent from an old in-memory queue snapshot.
    final expected = {...unsyncedResponses, ...unsyncedFeatures};
    final ids = expected.map((session) => session.id).toSet();
    final current = await (db.select(db.surveySessions)
          ..where((row) => row.projectId.equals(projectId) & row.id.isIn(ids)))
        .get();
    final remaining = current
        .where((session) =>
            session.status != 'draft' &&
            session.syncedAt == null &&
            expected.any((old) =>
                old.id == session.id && old.responses == session.responses))
        .map((session) => session.id)
        .toSet();
    unsyncedResponses = unsyncedResponses
        .where((session) => remaining.contains(session.id))
        .toList();
    unsyncedFeatures = unsyncedFeatures
        .where((session) => remaining.contains(session.id))
        .toList();
    if (remaining.isEmpty)
      return const SyncResult(responsesSynced: 0, featuresSynced: 0);
    final responsesPayload =
        _buildResponsesPayload(unsyncedResponses, projectName);
    final featuresPayload =
        _buildFeaturesPayload(unsyncedFeatures, projectName);

    final body = jsonEncode({
      'apiKey': apiKey,
      'action': 'sync_data',
      'projectId': externalId,
      'responses': responsesPayload,
      'features': featuresPayload,
    });

    http.Response httpResponse;
    try {
      final client = _client ?? http.Client();
      final shouldClose = _client == null;
      try {
        for (var attempt = 0;; attempt++) {
          httpResponse = await _postJsonWithRedirect(
            client: client,
            uri: uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          ).timeout(const Duration(seconds: 90));
          dynamic reply;
          try {
            reply = jsonDecode(httpResponse.body);
          } catch (_) {}
          final busy = reply is Map &&
              reply['ok'] != true &&
              (reply['error']
                      ?.toString()
                      .toLowerCase()
                      .contains('server busy') ??
                  false);
          if (!busy || attempt >= 2) break;
          await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      } finally {
        if (shouldClose) client.close();
      }
    } on TimeoutException {
      throw const CloudSyncException(
          'The sync server took too long to respond. Saved batches stay synced; retry to send the remaining records.');
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
        throw const CloudSyncException(
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
      final sendsEdits = [...responsesPayload, ...featuresPayload]
          .any((r) => (r['response_revision'] as num) > 1);
      if (sendsEdits && decoded['revisionSupport'] != true) {
        throw const CloudSyncException(
            'Your manager must deploy the updated revision-aware Code.gs. Edited responses remain saved and waiting to sync.');
      }
      final now = DateTime.now();
      await db.transaction(() async {
        for (final s in [...unsyncedResponses, ...unsyncedFeatures]) {
          await (db.update(db.surveySessions)
                ..where(
                    (t) => t.id.equals(s.id) & t.responses.equals(s.responses)))
              .write(SurveySessionsCompanion(syncedAt: Value(now)));
        }
        // Update lastSyncAt preserving url/key
        await db.upsertSyncConfig(
          projectId: projectId,
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
      final isLoopback =
          host == '127.0.0.1' || host == 'localhost' || host == '::1';
      if (!(host.endsWith('.google.com') ||
          host.endsWith('.googleusercontent.com') ||
          isLoopback)) {
        throw CloudSyncException('Refusing to follow redirect to $host');
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
      final formName =
          resp['form_name']?.toString() ?? resp['form_id']?.toString() ?? '';
      final answers = resp['answers'];
      final surveyor =
          resp['user_name']?.toString() ?? resp['surveyor']?.toString() ?? '';
      // Use stable UUID, fallback to local id only for very old unmigrated rows
      final stableId = (s.externalId != null && s.externalId!.isNotEmpty)
          ? s.externalId!
          : s.id.toString();
      list.add({
        'response_id': stableId,
        'project_name': projectName,
        'layer_id': resp['layer_id'] ?? 'default',
        'surveyor': surveyor,
        'submitted_at': s.createdAt.toIso8601String(),
        'form_name': formName,
        'answers': answers is Map ? answers : {},
        'edited_at': resp['edited_at'],
        'edited_by': resp['edited_by'],
        'response_revision': resp['response_revision'] ?? 1,
        'form_version': resp['form_snapshot'] is Map
            ? resp['form_snapshot']['version'] ?? 1
            : resp['form_version'] ?? 1,
        'form_id': resp['form_id'],
        if (resp['visit'] is Map) 'feature_uuid': resp['visit']['feature_uuid'],
        if (resp['workflow'] == 'guided_visit_v1') ...{
          'workflow': resp['workflow'],
          'visit': resp['visit'],
          'photo': resp['photo'],
        },
        if (resp['workflow'] == 'study_collection_v1') ...{
          'workflow': resp['workflow'],
          'study_workflow': resp['study_workflow'],
          'record_kind': resp['record_kind'],
          'site_id': resp['site_id'],
          'feature_uuid': resp['feature_uuid'],
          'site_name': resp['site_name'],
          'round_id': resp['round_id'],
          'collection_round': resp['collection_round'],
          'outcome': resp['outcome'],
          'observed_at': resp['observed_at'],
          'geometry': resp['geometry'],
          'form_snapshot': resp['form_snapshot'],
          'note': resp['note'],
        },
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
        'geojson': resp['geometry'] is Map ? resp['geometry'] : geojson,
        'layer_id': resp['layer_id'] ?? 'default',
        'form_name': resp['form_name'],
        if (resp['site'] is Map) 'study_site': resp['site'],
        'photo_path': photoPath,
        'attributes': {
          if (resp['attributes'] is Map)
            ...Map<String, dynamic>.from(resp['attributes']),
          if (resp['fields'] is Map)
            ...Map<String, dynamic>.from(resp['fields']),
          if (resp['answers'] is Map)
            ...Map<String, dynamic>.from(resp['answers']),
        },
        'name': resp['name'] ?? '',
        'notes': resp['notes'] ?? '',
        'edited_at': resp['edited_at'],
        'edited_by': resp['edited_by'],
        'response_revision': resp['response_revision'] ?? 1,
        'form_version': resp['form_snapshot'] is Map
            ? resp['form_snapshot']['version'] ?? 1
            : resp['form_version'] ?? 1,
        'form_id': resp['form_id'],
      });
    }
    return list;
  }
}
