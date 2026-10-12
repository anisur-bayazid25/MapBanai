import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const Duration photoFixMaxAge = Duration(seconds: 30);

  static bool isUsablePhotoFix(Position position, DateTime now,
      {double? maximumAccuracy}) {
    final age = now.difference(position.timestamp);
    return position.latitude.isFinite &&
        position.longitude.isFinite &&
        position.latitude >= -90 &&
        position.latitude <= 90 &&
        position.longitude >= -180 &&
        position.longitude <= 180 &&
        (maximumAccuracy == null ||
            (position.accuracy.isFinite &&
                position.accuracy > 0 &&
                position.accuracy <= maximumAccuracy)) &&
        age >= const Duration(seconds: -5) &&
        age <= photoFixMaxAge &&
        !position.isMocked;
  }

  Future<Position> getPhotoFix() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on device location, then retry GPS.');
    }
    if (!await ensurePermission()) {
      throw StateError('Allow location in app settings, then retry GPS.');
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
    if (!isUsablePhotoFix(position, DateTime.now())) {
      throw StateError(
          'GPS coordinates are invalid or stale. Stay at the photo location and retry GPS.');
    }
    return position;
  }

  Future<PermissionStatus> checkPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status;
  }

  /// Requests permission when needed and returns whether precision
  /// location is available.
  Future<bool> ensurePermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status == PermissionStatus.denied) {
      status = await Permission.locationWhenInUse.request();
    }
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  Future<String> getStatusLabel() async {
    final status = await checkPermission();

    switch (status) {
      case PermissionStatus.granted:
        return 'GPS ready';
      case PermissionStatus.denied:
        return 'Location permission denied';
      case PermissionStatus.restricted:
        return 'Location permission restricted';
      case PermissionStatus.limited:
        return 'Approximate location only';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied';
      case PermissionStatus.provisional:
        return 'Provisional permission';
      default:
        return 'Permission unknown';
    }
  }

  Future<Stream<Position>> getPositionStream() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }
}
