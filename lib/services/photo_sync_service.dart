import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:mapbanai/data/app_database.dart';

class PhotoSyncResult {
  final int total;
  final int synced;
  final int failed;
  final int skippedOversized;

  const PhotoSyncResult({
    required this.total,
    required this.synced,
    required this.failed,
    required this.skippedOversized,
  });

  String get summary => '$synced/$total photos synced'
      '${skippedOversized > 0 ? ', $skippedOversized skipped (too large)' : ''}'
      '${failed > 0 ? ', $failed failed' : ''}';

  bool get allSucceeded => failed == 0 && skippedOversized == 0 && total == synced;
}

class PhotoSyncService {
  final AppDatabase db;
  final http.Client? _client;
  final Future<void> Function(Duration)? _delayFn;
  final int maxPhotoBytes;

  static const int defaultMaxBytes = 15 * 1024 * 1024;
  static const List<Duration> _backoffs = [
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  PhotoSyncService(
    this.db, {
    http.Client? client,
    Future<void> Function(Duration)? delay,
    this.maxPhotoBytes = defaultMaxBytes,
  })  : _client = client,
        _delayFn = delay;

  Future<void> _delay(Duration d) {
    final fn = _delayFn;
    if (fn != null) return fn(d);
    return Future.delayed(d);
  }

  /// Sessions with a photo that hasn't been marked photo_synced.
  Future<List<SurveySession>> queryUnsyncedPhotos(int projectId) async {
    final all = await (db.select(db.surveySessions)
          ..where((t) => t.projectId.equals(projectId))
          ..where((t) => t.photoSyncedAt.isNull())
          ..where((t) => t.status.equals('draft').not()))
        .get();
    return all.where((s) => _extractAllPhotoPaths(s.responses).isNotEmpty).toList();
  }

  String _extractPhotoPath(String responsesJson) {
    final paths = _extractAllPhotoPaths(responsesJson);
    return paths.isEmpty ? '' : paths.first;
  }

  /// Extracts all photo paths from a responses JSON, including top-level
  /// feature photos and embedded PhotoQuestion answers inside survey responses.
  /// PhotoQuestion answers are stored as JSON strings under arbitrary field
  /// names, with a nested "path" key pointing under the app's photos directory.
  List<String> _extractAllPhotoPaths(String responsesJson) {
    final paths = <String>[];
    try {
      final decoded = jsonDecode(responsesJson) as Map<String, dynamic>;
      // Top-level feature photo (GIS)
      final photo = decoded['photo'];
      if (photo is Map<String, dynamic> && photo['path'] is String) {
        final p = photo['path'] as String;
        if (p.isNotEmpty) paths.add(p);
      } else if (photo is String && photo.isNotEmpty) {
        paths.add(photo);
      }
      if (decoded['photo_path'] is String) {
        final p = decoded['photo_path'] as String;
        if (p.isNotEmpty && !paths.contains(p)) paths.add(p);
      }
      // Embedded survey photo questions: answers map may contain JSON strings
      // with a "path" key. Don't hardcode field name — check every value.
      final answers = decoded['answers'];
      if (answers is Map) {
        for (final value in answers.values) {
          String? candidate;
          if (value is String) {
            // PhotoQuestion stores JSON string like '{"path":"...","thumb":...}'
            try {
              final inner = jsonDecode(value);
              if (inner is Map<String, dynamic> && inner['path'] is String) {
                candidate = inner['path'] as String;
              }
            } catch (_) {
              // Not a JSON string with path — ignore
            }
            // Also handle direct path string without JSON wrapper (just path)
            if (candidate == null && value.contains('photos') && value.contains('.jpg')) {
              // Heuristic: if value looks like a photo path, treat as candidate
              // but only if it points under photos directory
              if (value.contains('/') && (value.endsWith('.jpg') || value.endsWith('.jpeg') || value.endsWith('.png'))) {
                candidate = value;
              }
            }
          } else if (value is Map<String, dynamic> && value['path'] is String) {
            candidate = value['path'] as String;
          }
          if (candidate != null && candidate.isNotEmpty && !paths.contains(candidate)) {
            // Only queue if it points under app's photos directory (or at least looks like a photo file)
            if (candidate.contains('photos') || candidate.endsWith('.jpg') || candidate.endsWith('.jpeg') || candidate.endsWith('.png')) {
              paths.add(candidate);
            }
          }
        }
      }
    } catch (_) {
      // ignore malformed JSON
    }
    return paths;
  }

  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Uploads each unsynced photo individually with retry.
  /// Returns counts for reporting: "x/y photos synced".
  /// Optional [onProgress] is called after each photo with current index (1-based) and total.
  Future<PhotoSyncResult> syncPhotos(
    int projectId, {
    void Function(int current, int total)? onProgress,
  }) async {
    final config = await db.getSyncConfig(projectId);
    final rawUrl = config?.syncEndpointUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      return const PhotoSyncResult(
          total: 0, synced: 0, failed: 0, skippedOversized: 0);
    }
    Uri uri;
    try {
      uri = Uri.parse(rawUrl);
      if (!uri.hasScheme ||
          !(uri.scheme == 'http' || uri.scheme == 'https') ||
          uri.host.isEmpty) {
        throw const FormatException('Invalid URL');
      }
    } catch (e) {
      throw Exception('Invalid sync URL: $e');
    }
    final apiKey = config?.syncApiKey?.trim() ?? '';

    final photos = await queryUnsyncedPhotos(projectId);
    if (photos.isEmpty) {
      return const PhotoSyncResult(
          total: 0, synced: 0, failed: 0, skippedOversized: 0);
    }

    // Expand to per-photo granularity: a single survey session may contain
    // multiple embedded PhotoQuestion answers, each with its own file.
    final allPhotoPaths = <String>[];
    final sessionForPath = <String, SurveySession>{};
    for (final s in photos) {
      final paths = _extractAllPhotoPaths(s.responses);
      for (final pth in paths) {
        // Use path as key; if same path appears in multiple sessions (unlikely),
        // last session wins — acceptable for counting.
        if (!allPhotoPaths.contains(pth)) {
          allPhotoPaths.add(pth);
          sessionForPath[pth] = s;
        }
      }
      // Fallback: if _extractAllPhotoPaths returned empty but _extractPhotoPath had a value
      // (should not happen after the new extractor, but keep for safety)
      if (paths.isEmpty) {
        final single = _extractPhotoPath(s.responses);
        if (single.isNotEmpty && !allPhotoPaths.contains(single)) {
          allPhotoPaths.add(single);
          sessionForPath[single] = s;
        }
      }
    }

    final total = allPhotoPaths.length;
    if (total == 0) {
      return const PhotoSyncResult(total: 0, synced: 0, failed: 0, skippedOversized: 0);
    }

    int synced = 0;
    int failed = 0;
    int skipped = 0;
    // Track per-session photo success to decide when to mark photo_synced_at
    final sessionPhotoSuccess = <int, int>{}; // sessionId -> success count
    final sessionPhotoTotal = <int, int>{};
    for (final s in photos) {
      sessionPhotoTotal[s.id] = _extractAllPhotoPaths(s.responses).length;
      if (sessionPhotoTotal[s.id] == 0) {
        sessionPhotoTotal[s.id] = 1; // fallback single
      }
    }

    for (final photoPath in allPhotoPaths) {
      final session = sessionForPath[photoPath];
      if (session == null) {
        failed++;
        if (onProgress != null) onProgress(synced + failed + skipped, total);
        continue;
      }

      final file = File(photoPath);
      if (!file.existsSync()) {
        failed++;
        if (onProgress != null) onProgress(synced + failed + skipped, total);
        continue;
      }

      final size = file.lengthSync();
      if (size > maxPhotoBytes) {
        skipped++;
        if (onProgress != null) onProgress(synced + failed + skipped, total);
        continue;
      }

      String base64;
      try {
        final bytes = await file.readAsBytes();
        base64 = base64Encode(bytes);
      } catch (e) {
        failed++;
        if (onProgress != null) onProgress(synced + failed + skipped, total);
        continue;
      }

      final filename = p.basename(photoPath);
      final mimeType = _mimeTypeFor(filename);

      bool succeeded = false;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          final payload = jsonEncode({
            'apiKey': apiKey,
            'action': 'upload_photo',
            'filename': filename,
            'mimeType': mimeType,
            'base64': base64,
          });

          final client = _client ?? http.Client();
          final shouldClose = _client == null;
          http.Response resp;
          try {
            resp = await _postJsonWithRedirect(
              client: client,
              uri: uri,
              headers: {'Content-Type': 'application/json'},
              body: payload,
            ).timeout(const Duration(seconds: 30));
          } finally {
            if (shouldClose) client.close();
          }

          if (resp.statusCode < 200 || resp.statusCode >= 300) {
            if (resp.statusCode == 405) {
              throw HttpException(
                  'HTTP 405 Method Not Allowed — endpoint rejected the request; '
                  'verify the Web App deployment (/exec, Anyone access) and doPost(e)');
            }
            throw HttpException('HTTP ${resp.statusCode}');
          }

          dynamic decoded;
          try {
            decoded = jsonDecode(resp.body);
          } catch (_) {
            throw const FormatException('Invalid JSON');
          }

          if (decoded is Map<String, dynamic> && decoded['ok'] == true) {
            succeeded = true;
            break;
          } else {
            final msg = decoded is Map<String, dynamic> &&
                    decoded['error'] is String
                ? decoded['error'] as String
                : 'Server returned ok:false';
            throw Exception(msg);
          }
        } catch (_) {
          if (attempt < 3) {
            final backoff = attempt <= _backoffs.length
                ? _backoffs[attempt - 1]
                : _backoffs.last;
            await _delay(backoff);
          }
        }
      }

      if (succeeded) {
        synced++;
        sessionPhotoSuccess[session.id] =
            (sessionPhotoSuccess[session.id] ?? 0) + 1;
        if (sessionPhotoSuccess[session.id] == sessionPhotoTotal[session.id]) {
          await (db.update(db.surveySessions)
                ..where((t) => t.id.equals(session.id)))
              .write(SurveySessionsCompanion(photoSyncedAt: Value(DateTime.now())));
        }
      } else {
        failed++;
      }
      if (onProgress != null) {
        try {
          onProgress(synced + failed + skipped, total);
        } catch (_) {}
      }
    }

    return PhotoSyncResult(
      total: total,
      synced: synced,
      failed: failed,
      skippedOversized: skipped,
    );
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
        throw const HttpException('Too many redirects');
      }
      final location = response.headers['location'];
      if (location == null || location.isEmpty) {
        throw const HttpException('Redirect without Location');
      }
      Uri nextUri = Uri.parse(location);
      if (!nextUri.hasScheme) {
        nextUri = currentUri.resolveUri(nextUri);
      }
      final host = nextUri.host.toLowerCase();
      final isLoopback = host == '127.0.0.1' ||
          host == 'localhost' ||
          host == '::1';
      if (!(host.endsWith('.google.com') ||
          host.endsWith('.googleusercontent.com') ||
          isLoopback)) {
        throw HttpException('Refusing redirect to $host');
      }
      // The script already ran on the initial POST; the redirect target only
      // serves the cached response via GET.
      method = 'GET';
      payload = null;
      currentUri = nextUri;
    }
    throw const HttpException('Too many redirects');
  }
}
