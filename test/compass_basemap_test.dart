import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/compass_heading_filter.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/ui/common/basemap_picker.dart';

void main() {
  test('compass crosses north without a full turn or reversed jump', () {
    final filter = CompassHeadingFilter();
    expect(filter.update(359), 359);
    expect(filter.update(1, smoothing: 1), 361);
    expect(filter.update(358, smoothing: 1), 358);
  });
  test('compass rejects missing bearings and damps jitter', () {
    final filter = CompassHeadingFilter();
    expect(filter.update(-1), isNull);
    expect(filter.update(double.nan), isNull);
    filter.update(90);
    expect(filter.update(100), 94.5);
    expect(filter.update(double.infinity), 94.5);
  });
  test('shared basemaps omit CARTO and generate valid raster or empty styles',
      () {
    expect(
        Basemap.defaults.map((b) => b.id),
        containsAll([
          'osm',
          'satellite',
          'topographic',
          'humanitarian',
          'cycling',
          'none'
        ]));
    expect(Basemap.defaults.any((b) => b.url.contains('cartocdn')), isFalse);
    for (final basemap in Basemap.defaults) {
      final style = jsonDecode(MapStyleChoice.online(basemap).style);
      if (basemap.id == 'none') {
        expect(style['sources'], isEmpty);
        expect(style['layers'][0]['type'], 'background');
      } else {
        expect(style['sources']['basemap']['maxzoom'], basemap.maxNativeZoom);
        expect(style['sources']['basemap']['tiles'][0], basemap.url);
      }
    }
    expect(
        Basemap.defaults.firstWhere((b) => b.id == 'topographic').maxNativeZoom,
        17);
  });
}
