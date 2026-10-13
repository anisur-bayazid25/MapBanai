import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

class OfflineMapRequest {
  const OfflineMapRequest(
      {required this.name,
      required this.styleUrl,
      required this.attribution,
      required this.permissionAcknowledged,
      required this.south,
      required this.west,
      required this.north,
      required this.east,
      this.minZoom = 10,
      this.maxZoom = 16,
      this.maxBytes = 250 * 1024 * 1024});

  final String name, styleUrl, attribution;
  final bool permissionAcknowledged;
  final double south, west, north, east;
  final int minZoom, maxZoom, maxBytes;
  static const maxTiles = 6000;
  static const reserveBytes = 100 * 1024 * 1024;

  ml.LatLngBounds get bounds => ml.LatLngBounds(
      southwest: ml.LatLng(south, west), northeast: ml.LatLng(north, east));

  int get estimatedTiles {
    var total = 0;
    for (var z = minZoom; z <= maxZoom; z++) {
      final count = math.pow(2, z).toInt();
      int x(double lon) =>
          ((lon + 180) / 360 * count).floor().clamp(0, count - 1);
      int y(double lat) {
        final radians = lat * math.pi / 180;
        return ((1 -
                    math.log(math.tan(radians) + 1 / math.cos(radians)) /
                        math.pi) /
                2 *
                count)
            .floor()
            .clamp(0, count - 1);
      }

      total += (x(east) - x(west) + 1) * (y(south) - y(north) + 1);
    }
    return total;
  }

  void validate() {
    if (name.trim().isEmpty || attribution.trim().isEmpty) {
      throw const FormatException(
          'Enter a package name and source attribution.');
    }
    if (!permissionAcknowledged) {
      throw const FormatException(
          'Confirm your provider permits offline downloads.');
    }
    OfflineSourcePolicy.validateUrl(styleUrl);
    if (![south, west, north, east].every((v) => v.isFinite) ||
        south < -85.05112878 ||
        north > 85.05112878 ||
        west < -180 ||
        east > 180 ||
        south >= north ||
        west >= east) {
      throw const FormatException(
          'Enter valid south/west/north/east bounds. Dateline-crossing areas must be split.');
    }
    if (minZoom < 0 || maxZoom > 18 || minZoom > maxZoom) {
      throw const FormatException(
          'Zoom levels must be between 0 and 18, with minimum no greater than maximum.');
    }
    if (estimatedTiles > maxTiles) {
      throw FormatException(
          'This area needs about $estimatedTiles tiles per source. Reduce the bounds or maximum zoom (limit $maxTiles).');
    }
    if (maxBytes < 10 * 1024 * 1024 || maxBytes > 500 * 1024 * 1024) {
      throw const FormatException(
          'Choose a storage limit between 10 and 500 MB.');
    }
  }

  Map<String, dynamic> get metadata => {
        'app': 'mapbanai',
        'name': name.trim(),
        'attribution': attribution.trim(),
        'provider_permission_acknowledged': true,
        'max_bytes': maxBytes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
}

/// Public built-in basemaps are online-only. Check the style AND TileJSON so a
/// custom style cannot accidentally trigger bulk downloads from those servers.
class OfflineSourcePolicy {
  static bool isBlockedHost(String host) {
    host = host.toLowerCase();
    return [
      'openstreetmap.org',
      'openstreetmap.fr',
      'opentopomap.org',
      'cartocdn.com',
      'arcgisonline.com',
      'esri.com'
    ].any((domain) => host == domain || host.endsWith('.$domain'));
  }

  static Uri validateUrl(String value, {Uri? base}) {
    final uri = base == null ? Uri.tryParse(value.trim()) : base.resolve(value);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const FormatException(
          'Use an HTTPS MapLibre style URL from a provider that permits offline use.');
    }
    if (isBlockedHost(uri.host)) {
      throw const FormatException(
          'Built-in OSM, CARTO and Esri servers are online-only here. Use a permitted custom provider or your own server.');
    }
    if (uri.scheme == 'http' &&
        !['localhost', '127.0.0.1', '::1'].contains(uri.host)) {
      throw const FormatException(
          'Use HTTPS for your provider. HTTP is supported only for local development.');
    }
    return uri;
  }

  static Future<void> verifyStyle(String styleUrl,
      {http.Client? client}) async {
    final owned = client == null;
    client ??= http.Client();
    try {
      final styleUri = validateUrl(styleUrl);
      Future<Map<String, dynamic>> readJson(Uri uri) async {
        final response =
            await client!.get(uri).timeout(const Duration(seconds: 20));
        // Validate redirects too; provider permission must cover every resource.
        if (response.request?.url != null)
          validateUrl(response.request!.url.toString());
        if (response.statusCode != 200 ||
            response.bodyBytes.length > 2 * 1024 * 1024) {
          throw const FormatException(
              'The provider did not return a valid style or TileJSON (maximum 2 MB).');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>)
          throw const FormatException(
              'Expected a JSON object from map provider.');
        return decoded;
      }

      void checkTiles(dynamic tiles, Uri base) {
        if (tiles is! List || tiles.isEmpty)
          throw const FormatException('Map source contains no tile URLs.');
        for (final tile in tiles) {
          validateUrl(tile.toString(), base: base);
        }
      }

      final style = await readJson(styleUri);
      final sources = style['sources'];
      if (style['version'] != 8 ||
          sources is! Map ||
          sources.isEmpty ||
          style['layers'] is! List) {
        throw const FormatException(
            'Provider must supply a MapLibre version 8 style with layers and tile sources.');
      }
      for (final source in sources.values) {
        if (source is! Map ||
            !['raster', 'vector', 'raster-dem'].contains(source['type'])) {
          throw const FormatException(
              'Offline basemap styles support raster, vector and terrain tile sources only.');
        }
        if (source['url'] is String) {
          final tileJsonUri =
              validateUrl(source['url'] as String, base: styleUri);
          final tileJson = await readJson(tileJsonUri);
          checkTiles(tileJson['tiles'], tileJsonUri);
        } else {
          checkTiles(source['tiles'], styleUri);
        }
      }
      final glyphs = style['glyphs'];
      if (glyphs is String) validateUrl(glyphs, base: styleUri);
      final sprites = style['sprite'];
      if (sprites is String) validateUrl(sprites, base: styleUri);
      if (sprites is List) {
        for (final sprite in sprites) {
          if (sprite is Map && sprite['url'] is String)
            validateUrl(sprite['url'] as String, base: styleUri);
        }
      }
    } finally {
      if (owned) client.close();
    }
  }
}

class OfflinePackageStatus {
  const OfflinePackageStatus(
      {this.complete = false,
      this.completed = 0,
      this.required = 0,
      this.bytes = 0,
      this.tiles = 0,
      this.active = false});
  final bool complete, active;
  final int completed, required, bytes, tiles;
  double? get progress =>
      required == 0 ? null : (completed / required).clamp(0.0, 1.0);
  factory OfflinePackageStatus.fromMap(Map<dynamic, dynamic> map) =>
      OfflinePackageStatus(
          complete: map['complete'] == true,
          active: map['active'] == true,
          completed: (map['completed'] as num?)?.toInt() ?? 0,
          required: (map['required'] as num?)?.toInt() ?? 0,
          bytes: (map['bytes'] as num?)?.toInt() ?? 0,
          tiles: (map['tiles'] as num?)?.toInt() ?? 0);
}

class OfflineMapPackage {
  const OfflineMapPackage(this.region, this.status);
  final ml.OfflineRegion region;
  final OfflinePackageStatus status;
  int get id => region.id;
  String get name => region.metadata['name']?.toString() ?? 'Offline area $id';
  String get attribution => region.metadata['attribution']?.toString() ?? '';
}

abstract class OfflineMapBackend {
  Future<List<ml.OfflineRegion>> list();
  Future<ml.OfflineRegion> download(
      ml.OfflineRegionDefinition definition, Map<String, dynamic> metadata);
  Future<OfflinePackageStatus> status(int id);
  Future<void> setActive(int id, bool active);
  Future<void> delete(int id);
  Future<Map<dynamic, dynamic>> storage();
}

class NativeOfflineMapBackend implements OfflineMapBackend {
  static const channel = MethodChannel('plugins.flutter.io/maplibre_gl');
  @override
  Future<List<ml.OfflineRegion>> list() => ml.getListOfRegions();
  @override
  Future<ml.OfflineRegion> download(ml.OfflineRegionDefinition definition,
          Map<String, dynamic> metadata) =>
      ml.downloadOfflineRegion(definition, metadata: metadata);
  @override
  Future<OfflinePackageStatus> status(int id) async =>
      OfflinePackageStatus.fromMap(await channel
              .invokeMapMethod<dynamic, dynamic>(
                  'getOfflineRegionStatus', {'id': id}) ??
          {});
  @override
  Future<void> setActive(int id, bool active) async {
    await channel.invokeMethod(
        'setOfflineRegionDownloadState', {'id': id, 'active': active});
  }

  @override
  Future<void> delete(int id) async {
    await ml.deleteOfflineRegion(id);
  }

  @override
  Future<Map<dynamic, dynamic>> storage() async =>
      await channel
          .invokeMapMethod<dynamic, dynamic>('getOfflineStorageInfo') ??
      {};
}

class OfflineMapService extends ChangeNotifier {
  OfflineMapService(
      {OfflineMapBackend? backend,
      Future<void> Function(String)? verifySource,
      Duration pollInterval = const Duration(seconds: 1)})
      : _backend = backend ?? NativeOfflineMapBackend(),
        _verifySource = verifySource ?? OfflineSourcePolicy.verifyStyle,
        _pollInterval = pollInterval;
  static final instance = OfflineMapService();
  static bool get supported => !kIsWeb && Platform.isAndroid;
  final OfflineMapBackend _backend;
  final Future<void> Function(String) _verifySource;
  final Duration _pollInterval;
  List<OfflineMapPackage> packages = [];
  String? message;
  bool busy = false;
  bool _cancelRequested = false;
  int? activeId;
  int freeBytes = 0;
  int cacheBytes = 0;
  OfflinePackageStatus? downloadStatus;

  Future<void> refresh() async {
    final regions = await _backend.list();
    final items = <OfflineMapPackage>[];
    for (final region in regions) {
      if (region.metadata['app'] != 'mapbanai') continue;
      items.add(OfflineMapPackage(region, await _backend.status(region.id)));
    }
    final info = await _backend.storage();
    packages = items;
    freeBytes = (info['freeBytes'] as num?)?.toInt() ?? 0;
    cacheBytes = (info['cacheBytes'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  Future<void> download(OfflineMapRequest request) async {
    if (busy) throw StateError('Another offline map download is running.');
    request.validate();
    busy = true;
    activeId = null;
    downloadStatus = null;
    _cancelRequested = false;
    message = 'Checking provider and storage…';
    notifyListeners();
    try {
      await _verifySource(request.styleUrl);
      final storage = await _backend.storage();
      final available = (storage['freeBytes'] as num?)?.toInt() ?? 0;
      if (available < request.maxBytes + OfflineMapRequest.reserveBytes) {
        throw StateError(
            'Not enough free storage for the selected limit plus 100 MB reserve.');
      }
      if (_cancelRequested) return;
      final region = await _backend.download(
          ml.OfflineRegionDefinition(
              bounds: request.bounds,
              mapStyleUrl: request.styleUrl,
              minZoom: request.minZoom.toDouble(),
              maxZoom: request.maxZoom.toDouble()),
          request.metadata);
      activeId = region.id;
      var idlePolls = 0;
      var previousCompleted = -1;
      while (!_cancelRequested) {
        final status = await _backend.status(region.id);
        if (_cancelRequested) break;
        downloadStatus = status;
        message = 'Downloading ${request.name}…';
        notifyListeners();
        if (status.bytes > request.maxBytes ||
            status.tiles > OfflineMapRequest.maxTiles) {
          await _backend.setActive(region.id, false);
          throw StateError(
              'Download exceeded the storage or tile limit. Partial package was paused; delete it or download a smaller area.');
        }
        if (status.complete) {
          await _backend.setActive(region.id, false);
          message = '${request.name} is ready offline.';
          break;
        }
        if (!status.active) {
          throw StateError(
              'Download stopped before completion. Check the provider and internet connection; delete the incomplete package and retry.');
        }
        idlePolls = status.completed == previousCompleted ? idlePolls + 1 : 0;
        previousCompleted = status.completed;
        if (idlePolls * _pollInterval.inMilliseconds >= 120000) {
          await _backend.setActive(region.id, false);
          throw StateError(
              'No download progress for two minutes. Incomplete package paused. Check internet and retry.');
        }
        await Future<void>.delayed(_pollInterval);
      }
      if (_cancelRequested) {
        await _backend.setActive(region.id, false);
        await _backend.delete(region.id);
        message = 'Download cancelled. Partial package removed.';
      }
    } catch (e) {
      if (activeId != null) {
        try {
          await _backend.setActive(activeId!, false);
        } catch (_) {}
      }
      message = 'Offline map download failed: $e';
      rethrow;
    } finally {
      busy = false;
      activeId = null;
      if (_cancelRequested && downloadStatus == null)
        message = 'Download cancelled.';
      try {
        await refresh();
      } catch (error) {
        message = '${message ?? ''} Could not refresh package list: $error';
        notifyListeners();
      }
    }
  }

  Future<void> cancel() async {
    if (!busy) return;
    _cancelRequested = true;
    message = 'Cancelling download…';
    final id = activeId;
    if (id != null) await _backend.setActive(id, false);
    notifyListeners();
  }

  Future<void> delete(int id) async {
    if (activeId == id)
      throw StateError('Cancel this download before deleting it.');
    await _backend.setActive(id, false);
    await _backend.delete(id);
    await refresh();
  }

  static String formatBytes(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
