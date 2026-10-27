import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/site_priority_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/google_maps_links.dart';

void main() {
  StudyAreaSite site(String id, double lat, String name) => StudyAreaSite(
      id: id, latitude: lat, longitude: 90, attributes: {'Name': name});
  final sites = [
    site('far', 24, 'Alpha'),
    site('near', 23.001, 'Zeta'),
    site('done', 23, 'Done'),
    site('review', 23, 'Review')
  ];
  StudyAreaStatus status(StudyAreaSite site) => site.id == 'done'
      ? StudyAreaStatus.completed
      : site.id == 'review'
          ? StudyAreaStatus.needsReview
          : StudyAreaStatus.pending;
  test('nearest list excludes completed and review and sorts by GPS distance',
      () {
    final rows = SitePriorityService.unvisited(sites,
        status: status, latitude: 23, longitude: 90);
    expect(rows.map((row) => row.site.id), ['near', 'far']);
    expect(rows.first.distanceMeters, closeTo(111.2, 1));
    expect(sites.first.id, 'far');
  });
  test('missing or invalid GPS falls back to names; ties are stable', () {
    for (final latitude in [null, double.nan, 91.0]) {
      final rows = SitePriorityService.unvisited(sites,
          status: status, latitude: latitude, longitude: 90);
      expect(rows.map((row) => row.site.id), ['far', 'near']);
      expect(rows.every((row) => row.distanceMeters == null), true);
    }
    final ties = SitePriorityService.unvisited(
        [site('b', 23, 'Same'), site('a', 23, 'Same')],
        status: (_) => StudyAreaStatus.pending, latitude: 23, longitude: 90);
    expect(ties.map((row) => row.site.id), ['a', 'b']);
  });
  test('caller supplied round status determines pending membership', () {
    expect(
        SitePriorityService.unvisited(sites,
            status: (_) => StudyAreaStatus.completed),
        isEmpty);
    expect(
        SitePriorityService.unvisited(sites,
            status: (_) => StudyAreaStatus.pending),
        hasLength(4));
  });
  test('Google Maps URLs preserve valid WGS84 coordinates and encode query',
      () {
    final pin = GoogleMapsLinks.site(23.75, 90.4);
    expect(pin.host, 'www.google.com');
    expect(pin.path, '/maps/search/');
    expect(pin.queryParameters, {'api': '1', 'query': '23.75,90.4'});
    expect(
        GoogleMapsLinks.area(-23, -90, zoom: 40).queryParameters['zoom'], '21');
    for (final lat in [double.nan, double.infinity, 91.0]) {
      expect(() => GoogleMapsLinks.site(lat, 90), throwsArgumentError);
    }
    expect(() => GoogleMapsLinks.area(0, 181), throwsArgumentError);
  });
}
