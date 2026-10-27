import 'package:mapbanai/services/study_area_service.dart';

class NearbyStudySite {
  final StudyAreaSite site;
  final double? distanceMeters;
  const NearbyStudySite(this.site, this.distanceMeters);
}

class SitePriorityService {
  /// Review/completed sites are excluded. The caller supplies round-specific
  /// status; no visit is marked complete just by opening or navigating to it.
  static List<NearbyStudySite> unvisited(Iterable<StudyAreaSite> sites,
      {required StudyAreaStatus Function(StudyAreaSite) status,
      double? latitude,
      double? longitude}) {
    final located = latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude.abs() <= 90 &&
        longitude.abs() <= 180;
    final rows = [
      for (final site
          in sites.where((site) => status(site) == StudyAreaStatus.pending))
        NearbyStudySite(
            site,
            located
                ? StudyAreaService.distanceMeters(
                    latitude, longitude, site.latitude, site.longitude)
                : null)
    ];
    rows.sort((a, b) {
      final distance =
          located ? a.distanceMeters!.compareTo(b.distanceMeters!) : 0;
      if (distance != 0) return distance;
      final name = a.site.displayName
          .toLowerCase()
          .compareTo(b.site.displayName.toLowerCase());
      return name == 0 ? a.site.id.compareTo(b.site.id) : name;
    });
    return rows;
  }
}
