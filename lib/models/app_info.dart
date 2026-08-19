/// Static app metadata for the About section.
///
/// [version] is kept in sync with the `version:` field in pubspec.yaml by
/// tool/bump_version.dart.
class AppInfo {
  AppInfo._();

  static const String name = 'MapBanai';
  static const String version = '2.1.0+1';
  static const String tagline = 'Offline-first field data collection GIS';
  static const String creator = 'Anisur Rahman Bayazid';
  static const String description =
      'Collect survey responses, GPS points, lines and polygons in the field '
      'without a connection, then export and share the data.';
  static const String updatesNote =
      'Updates will be available on GitHub.';
  static const String githubUrl =
      'https://github.com/anisur-bayazid25/MapBanai';
  static const String email = 'anisur.rahman.bayazid@gmail.com';
}