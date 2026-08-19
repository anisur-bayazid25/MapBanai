import 'dart:convert';
import 'dart:math' show Point;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FakeMaplibrePlatform implements MapLibrePlatform {
  final Map<String, Map<String, dynamic>> sources = {};
  final List<String> log = [];
  int viewId = 1;

  @override
  final onInfoWindowTappedPlatform = ArgumentCallbacks<String>();
  @override
  final onFeatureTappedPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onFeatureHoverPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onFeatureDraggedPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onCameraMoveStartedPlatform = ArgumentCallbacks<void>();
  @override
  final onCameraMovePlatform = ArgumentCallbacks<CameraPosition>();
  @override
  final onCameraIdlePlatform = ArgumentCallbacks<CameraPosition?>();
  @override
  final onMapStyleLoadedPlatform = ArgumentCallbacks<void>();
  @override
  final onMapClickPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onMapLongClickPlatform = ArgumentCallbacks<Map<String, dynamic>>();
  @override
  final onCameraTrackingChangedPlatform =
      ArgumentCallbacks<MyLocationTrackingMode>();
  @override
  final onCameraTrackingDismissedPlatform = ArgumentCallbacks<void>();
  @override
  final onMapIdlePlatform = ArgumentCallbacks<void>();
  @override
  final onUserLocationUpdatedPlatform = ArgumentCallbacks<UserLocation>();

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    onPlatformViewCreated(viewId++);
    return const SizedBox.shrink();
  }

  @override
  Future<void> addGeoJsonSource(String sourceId, Map<String, dynamic> geojson,
      {String? promoteId}) async {
    sources[sourceId] = geojson;
    log.add('addGeoJsonSource:$sourceId');
  }

  @override
  Future<void> setGeoJsonSource(
      String sourceId, Map<String, dynamic> geojson) async {
    sources[sourceId] = geojson;
    final features = geojson['features'] as List;
    log.add('setGeoJsonSource:$sourceId(${features.length} feat)');
  }

  @override
  Future<void> addCircleLayer(String sourceId, String layerId,
      Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    log.add('addCircleLayer:$layerId');
  }

  @override
  Future<void> addLineLayer(String sourceId, String layerId,
      Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    log.add('addLineLayer:$layerId');
  }

  @override
  Future<void> addFillLayer(String sourceId, String layerId,
      Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    log.add('addFillLayer:$layerId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Map<String, dynamic> featureAt(
  FakeMaplibrePlatform fake,
  String sourceId, {
  int index = 0,
}) {
  final features = fake.sources[sourceId]!['features'] as List;
  return features[index] as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMaplibrePlatform fake;
  late MapLibreMapController controller;

  Future<void> setUpController() async {
    fake = FakeMaplibrePlatform();
    controller = MapLibreMapController(
      maplibrePlatform: fake,
      initialCameraPosition:
          const CameraPosition(target: LatLng(23.8103, 90.4125), zoom: 14),
      annotationOrder: const [
        AnnotationType.circle,
        AnnotationType.line,
        AnnotationType.fill,
      ],
      annotationConsumeTapEvents: const [
        AnnotationType.circle,
        AnnotationType.line,
        AnnotationType.fill,
      ],
    );
    // Managers initialize when the platform reports the style loaded.
    fake.onMapStyleLoadedPlatform.call(null);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() {
    controller.dispose();
  });

  test('draft circle is replaced by saved point after finish flow', () async {
    await setUpController();

    // Draft point added (Add Point button).
    final draft = await controller.addCircle(
      CircleOptions(
        geometry: const LatLng(23.8103, 90.4125),
        circleRadius: 10,
        circleColor: '#E53935',
        draggable: true,
      ),
    );
    final layerId = controller.circleManager!.id;
    final sourceId = '${controller.circleManager!.id}_0';
    expect(fake.sources[sourceId]!['features'], hasLength(1));

    // User drags the draft point and releases.
    fake.onFeatureDraggedPlatform.call(<String, dynamic>{
      'id': draft.id,
      'point': const Point(90.4129, 23.8106),
      'origin': const LatLng(23.8103, 90.4125),
      'current': const LatLng(23.8106, 90.4129),
      'delta': const LatLng(0.0003, 0.0004),
      'eventType': 'end',
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      controller.circleManager!.byId(draft.id)!.options.geometry!.latitude,
      closeTo(23.8106, 1e-9),
    );
    expect(draft.options.geometry!.longitude, closeTo(90.4129, 1e-9));

    // Finish: the screen removes the draft circle, clears and re-adds the
    // saved point (what _saveFeature / _cancelDraft do today).
    await controller.removeCircle(draft);
    await controller.clearCircles();
    await controller.addCircle(
      CircleOptions(
        geometry: const LatLng(23.8106, 90.4129),
        circleRadius: 7,
        circleColor: '#E53935',
        draggable: true,
      ),
      const {'session_id': 1, 'title': 'Point P1'},
    );

    final features = fake.sources[sourceId]!['features'] as List;
    expect(features, hasLength(1));
    final saved = controller.circles.single;
    expect(saved.data?['session_id'], 1);
    expect(saved.options.geometry!.latitude, closeTo(23.8106, 1e-9));
    final savedCoords = (features.single as Map<String, dynamic>)['geometry']
        ['coordinates'] as List;
    expect(savedCoords[0], closeTo(90.4129, 1e-6));
    expect(savedCoords[1], closeTo(23.8106, 1e-6));

    // Deleting the feature removes it from the map.
    await controller.removeCircle(saved);
    expect(fake.sources[sourceId]!['features'], hasLength(0));
  });

  test('dragged saved point stays on the map after drag end', () async {
    await setUpController();

    final saved = await controller.addCircle(
      CircleOptions(
        geometry: const LatLng(23.8103, 90.4125),
        circleRadius: 7,
        draggable: true,
      ),
      const {'session_id': 7},
    );

    fake.onFeatureDraggedPlatform.call(<String, dynamic>{
      'id': saved.id,
      'point': const Point(90.4130, 23.8108),
      'origin': const LatLng(23.8103, 90.4125),
      'current': const LatLng(23.8108, 90.4130),
      'delta': const LatLng(0.0005, 0.0005),
      'eventType': 'end',
    });
    await Future<void>.delayed(Duration.zero);

    // The manager translated the annotation; the source reflects the new spot.
    final layerId = '${controller.circleManager!.id}_0';
    final features = fake.sources[layerId]!['features'] as List;
    expect(features, hasLength(1));
    expect(controller.circles.single.options.geometry!.longitude,
        closeTo(90.4130, 1e-9));
    final coords =
        (features.single as Map<String, dynamic>)['geometry']['coordinates']
            as List;
    expect(coords[0], closeTo(90.4130, 1e-6));
    expect(coords[1], closeTo(23.8108, 1e-6));
  });

  test('fresh style load without cleared circles renders all points', () async {
    await setUpController();
    final a = await controller.addCircle(
      CircleOptions(geometry: const LatLng(23.81, 90.41)),
      const {'session_id': 1},
    );
    final b = await controller.addCircle(
      CircleOptions(geometry: const LatLng(23.82, 90.42)),
      const {'session_id': 2},
    );
    final layerId = '${controller.circleManager!.id}_0';
    expect(fake.sources[layerId]!['features'], hasLength(2));
  });

  test('circle source json stays well-formed after clear + add with zeros',
      () async {
    await setUpController();

    // Simulate a zero-coordinate draft to make sure JSON encoding never
    // produces NaN/Infinity which would poison the native source.
    await controller.addCircle(
      CircleOptions(
        geometry: const LatLng(0, 0),
        circleRadius: 10,
        draggable: true,
      ),
    );
    await controller.clearCircles();
    await controller.addCircle(
      CircleOptions(geometry: const LatLng(0, 0)),
      const {'session_id': 1},
    );
    final layerId = '${controller.circleManager!.id}_0';
    final encoded = jsonEncode(fake.sources[layerId]);
    expect(encoded, isNot(contains('NaN')));
    expect(encoded, isNot(contains('Infinity')));
    expect(encoded, isNotEmpty);
  });
}