import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/study_category_style.dart';
import 'package:mapbanai/services/study_area_service.dart';

void main() {
  test(
      'default is the same color irrespective of category or verification status',
      () {
    final style = StudyCategoryStyle();
    final first = StudyAreaSite(
        id: 'a', latitude: 23, longitude: 90, attributes: {'layer': 'Toilet'});
    final second = StudyAreaSite(
        id: 'b',
        latitude: 23,
        longitude: 90,
        status: StudyAreaStatus.verified,
        attributes: {'layer': 'School'});
    expect(style.column, isNull);
    expect(style.color(first), style.color(second));
  });
  test('explicit status coloring uses verification status colors', () {
    final site = StudyAreaSite(
        id: 'a', latitude: 23, longitude: 90, status: StudyAreaStatus.verified);
    final style = StudyCategoryStyle(column: '__verification_status__');
    style.categories([site]);
    expect(style.category(site), site.status.label);
    expect(style.color(site), site.status.mapColor);
  });
  test('column colors are stable and filters do not change status', () {
    final sites = [
      StudyAreaSite(
          id: '1',
          latitude: 23,
          longitude: 90,
          attributes: {'layer': 'Toilet'}),
      StudyAreaSite(
          id: '2', latitude: 23, longitude: 90, attributes: {'layer': 'School'})
    ];
    final style = StudyCategoryStyle(column: 'layer');
    expect(style.categories(sites), ['School', 'Toilet']);
    expect(style.color(sites[0]), isNot(style.color(sites[1])));
    style.hidden.add('Toilet');
    expect(style.visible(sites[0]), false);
    expect(style.visible(sites[1]), true);
    expect(sites[0].status, StudyAreaStatus.pending);
    final restored = StudyCategoryStyle.fromJson(style.toJson());
    expect(restored.color(sites[0]), style.color(sites[0]));
    expect(restored.visible(sites[0]), false);
  });
  test('missing category gets a visible label and point size is bounded', () {
    final site = StudyAreaSite(id: '1', latitude: 23, longitude: 90);
    final style =
        StudyCategoryStyle.fromJson({'column': 'layer', 'radius': 100});
    expect(style.category(site), '(No value)');
    expect(style.radius, 12);
  });
}
