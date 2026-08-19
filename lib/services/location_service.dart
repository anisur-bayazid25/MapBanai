import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
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
