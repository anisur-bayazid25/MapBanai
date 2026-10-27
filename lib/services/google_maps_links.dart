/// Public Google Maps URLs; no embedded SDK, API key or billing is involved.
class GoogleMapsLinks {
  static void _check(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid coordinates');
    }
  }

  static Uri site(double latitude, double longitude) {
    _check(latitude, longitude);
    return Uri.https('www.google.com', '/maps/search/',
        {'api': '1', 'query': '$latitude,$longitude'});
  }

  static Uri area(double latitude, double longitude, {double zoom = 16}) {
    _check(latitude, longitude);
    return Uri.https('www.google.com', '/maps/@', {
      'api': '1',
      'map_action': 'map',
      'center': '$latitude,$longitude',
      'zoom': '${zoom.clamp(0, 21).round()}',
    });
  }
}
