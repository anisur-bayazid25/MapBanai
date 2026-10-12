import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapbanai/services/offline_map_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

OfflineMapRequest request({int maxZoom = 14, double west = 90.35}) =>
    OfflineMapRequest(
        name: 'Field area',
        styleUrl: 'https://maps.example.org/style.json',
        attribution: 'Field team',
        permissionAcknowledged: true,
        south: 23.75,
        west: west,
        north: 23.76,
        east: 90.36,
        minZoom: 10,
        maxZoom: maxZoom,
        maxBytes: 10 * 1024 * 1024);

class FakeOfflineBackend implements OfflineMapBackend {
  final regions = <ml.OfflineRegion>[];
  OfflinePackageStatus current = const OfflinePackageStatus(
      complete: true, completed: 10, required: 10, bytes: 5000, tiles: 10);
  int free = 1024 * 1024 * 1024;
  bool active = false;
  Completer<OfflinePackageStatus>? pendingStatus;
  final statusRequested = Completer<void>();
  @override
  Future<List<ml.OfflineRegion>> list() async => List.from(regions);
  @override
  Future<ml.OfflineRegion> download(ml.OfflineRegionDefinition definition,
      Map<String, dynamic> metadata) async {
    active = true;
    final region =
        ml.OfflineRegion(id: 1, definition: definition, metadata: metadata);
    regions.add(region);
    return region;
  }

  @override
  Future<OfflinePackageStatus> status(int id) async {
    if (!statusRequested.isCompleted) statusRequested.complete();
    return pendingStatus == null ? current : await pendingStatus!.future;
  }

  @override
  Future<void> setActive(int id, bool value) async {
    active = value;
  }

  @override
  Future<void> delete(int id) async {
    regions.removeWhere((r) => r.id == id);
  }

  @override
  Future<Map<dynamic, dynamic>> storage() async =>
      {'freeBytes': free, 'cacheBytes': 5000};
}

void main() {
  test(
      'invalid bounds, large areas and disallowed providers never start downloads',
      () {
    expect(() => request(west: double.nan).validate(), throwsFormatException);
    expect(() => request(maxZoom: 19).validate(), throwsFormatException);
    expect(
        () => const OfflineMapRequest(
                name: 'Country',
                styleUrl: 'https://maps.example.org/style.json',
                attribution: 'Team',
                permissionAcknowledged: true,
                south: 20,
                west: 88,
                north: 27,
                east: 93,
                minZoom: 10,
                maxZoom: 18)
            .validate(),
        throwsFormatException);
    expect(
        () => OfflineSourcePolicy.validateUrl(
            'https://tile.openstreetmap.org/style.json'),
        throwsFormatException);
    request().validate();
  });

  test('provider validation rejects blocked tiles hidden in custom TileJSON',
      () async {
    final client = MockClient((uri) async => http.Response(
        jsonEncode(uri.url.path == '/style.json'
            ? {
                'version': 8,
                'layers': [],
                'sources': {
                  'base': {
                    'type': 'raster',
                    'url': 'https://maps.example.org/tiles.json'
                  }
                }
              }
            : {
                'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png']
              }),
        200));
    await expectLater(
        OfflineSourcePolicy.verifyStyle('https://maps.example.org/style.json',
            client: client),
        throwsFormatException);
    client.close();
  });

  test('complete downloads become selectable packages and release active state',
      () async {
    final backend = FakeOfflineBackend();
    final service =
        OfflineMapService(backend: backend, verifySource: (_) async {});
    await service.download(request());
    expect(service.packages.single.status.complete, isTrue);
    expect(service.packages.single.region.definition.mapStyleUrl,
        request().styleUrl);
    expect(service.packages.single.attribution, 'Field team');
    expect(service.busy, isFalse);
    expect(backend.active, isFalse);
    await service.delete(1);
    expect(service.packages, isEmpty);
    service.dispose();
  });

  test('insufficient storage fails before creating native region', () async {
    final backend = FakeOfflineBackend()..free = 20;
    final service =
        OfflineMapService(backend: backend, verifySource: (_) async {});
    await expectLater(service.download(request()), throwsStateError);
    expect(backend.regions, isEmpty);
    expect(service.busy, isFalse);
    service.dispose();
  });

  test(
      'download budget failures deactivate the region and retain incomplete status',
      () async {
    final backend = FakeOfflineBackend()
      ..current = const OfflinePackageStatus(
          active: true, completed: 1, required: 100, bytes: 11 * 1024 * 1024);
    final service =
        OfflineMapService(backend: backend, verifySource: (_) async {});
    await expectLater(service.download(request()), throwsStateError);
    expect(backend.active, isFalse);
    expect(service.busy, isFalse);
    expect(service.packages.single.status.complete, isFalse);
    service.dispose();
  });

  test('cancellation during status polling stops and deletes partial download',
      () async {
    final backend = FakeOfflineBackend()
      ..pendingStatus = Completer<OfflinePackageStatus>();
    final service =
        OfflineMapService(backend: backend, verifySource: (_) async {});
    final downloading = service.download(request());
    await backend.statusRequested.future;
    await service.cancel();
    backend.pendingStatus!.complete(const OfflinePackageStatus(active: false));
    await downloading;
    expect(backend.active, isFalse);
    expect(backend.regions, isEmpty);
    expect(service.message, contains('cancelled'));
    expect(service.busy, isFalse);
    service.dispose();
  });
}
