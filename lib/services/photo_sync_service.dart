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
    return all.where((s) => _extractPhotoPath(s.responses).isNotEmpty).toList();
  }

  String _extractPhotoPath(String responsesJson) {
    try {
      final decoded = jsonDecode(responsesJson) as Map<String, dynamic>;
      final photo = decoded['photo'];
      if (photo is Map<String, dynamic> && photo['path'] is String) {
        return photo['path'] as String;
      }
      if (photo is String && photo.isNotEmpty) return photo;
      if (decoded['photo_path'] is String) {
        return decoded['photo_path'] as String;
      }
      // Some GIS features may store photo under different keys?
      // Fallback: check nested fields
      return '';
    } catch (_) {
      return '';
    }
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

    int synced = 0;
    int failed = 0;
    int skipped = 0;

    for (var idx = 0; idx < photos.length; idx++) {
      final session = photos[idx];
      final photoPath = _extractPhotoPath(session.responses);
      if (photoPath.isEmpty) {
        await (db.update(db.surveySessions)
              ..where((t) => t.id.equals(session.id)))
            .write(SurveySessionsCompanion(photoSyncedAt: Value(DateTime.now())));
        synced++;
        if (onProgress != null) onProgress(synced + failed + skipped, photos.length);
        continue;
      }

      final file = File(photoPath);
      if (!file.existsSync()) {
        failed++;
        if (onProgress != null) onProgress(synced + failed + skipped, photos.length);
        continue;
      }

      final size = file.lengthSync();
      if (size > maxPhotoBytes) {
        skipped++;
        if (onProgress != null) onProgress(synced + failed + skipped, photos.length);
        continue;
      }

      String base64;
      try {
        final bytes = await file.readAsBytes();
        base64 = base64Encode(bytes);
      } catch (e) {
        failed++;
        if (onProgress != null) onProgress(synced + failed + skipped, photos.length);
        continue;
      }

      final filename = p.basename(photoPath);
      final mimeType = _mimeTypeFor(filename);

      bool succeeded = false;
      // Retry up to 3 attempts
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
            // try to extract error, but treat as failure for retry
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
        await (db.update(db.surveySessions)
              ..where((t) => t.id.equals(session.id)))
            .write(SurveySessionsCompanion(photoSyncedAt: Value(DateTime.now())));
        synced++;
      } else {
        failed++;
      }
      if (onProgress != null) {
        try {
          onProgress(synced + failed + skipped, photos.length);
        } catch (_) {}
      }
    }

    final total = photos.length;
    return PhotoSyncResult(
      total: total,
      synced: synced,
      failed: failed,
      skippedOversized: skipped,
    );
  }

  Future<http.Response> _postJsonWithRedirect({
    required http.Client client,
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    const maxHops = 5;
    Uri currentUri = uri;
    for (var hop = 0; hop <= maxHops; hop++) {
      final request = http.Request('POST', currentUri);
      request.headers.addAll(headers);
      request.body = body;
      request.followRedirects = false;
      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      final isRedirect = response.isRedirect ||
          (response.statusCode >= 301 && response.statusCode <= 308);
      if (isRedirect) {
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
        currentUri = nextUri;
        continue;
      }
      return response;
    }
    throw const HttpException('Too many redirects');
  }
}
