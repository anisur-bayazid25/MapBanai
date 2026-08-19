import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mapbanai/services/geotag_writer.dart';
import 'package:path_provider/path_provider.dart';

/// A photo stored on disk with optional GPS coordinates.
class PhotoRecord {
  final String path;
  final String thumbPath;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final String gpsStatus; // GeotagWriter.deviceGeotag | inserted | patched | unchanged
  final DateTime capturedAt;

  const PhotoRecord({
    required this.path,
    required this.thumbPath,
    this.latitude,
    this.longitude,
    this.altitude,
    required this.gpsStatus,
    required this.capturedAt,
  });

  bool get isGeotagged =>
      gpsStatus == GeotagWriter.deviceGeotag ||
      gpsStatus == GeotagWriter.inserted ||
      gpsStatus == GeotagWriter.patched;

  String get gpsLabel => switch (gpsStatus) {
        GeotagWriter.deviceGeotag => 'Device GPS EXIF',
        GeotagWriter.inserted => 'Geotagged (EXIF added)',
        GeotagWriter.patched => 'Geotagged (EXIF patched)',
        'none' => 'No coordinates',
        _ => 'Geotag not embedded',
      };

  String get fileName => path.split(Platform.pathSeparator).last;

  Map<String, dynamic> toJson() => {
    'path': path,
    'thumb': thumbPath,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'gps': gpsStatus,
    'captured_at': capturedAt.toIso8601String(),
  };

  factory PhotoRecord.fromJson(Map<String, dynamic> json) => PhotoRecord(
    path: json['path'] as String,
    thumbPath: (json['thumb'] as String?) ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    altitude: (json['altitude'] as num?)?.toDouble(),
    gpsStatus: (json['gps'] as String?) ?? GeotagWriter.unchanged,
    capturedAt: DateTime.tryParse(json['captured_at'] as String? ?? '') ??
        DateTime.now(),
  );
}

/// Stores captured photos in the app documents directory.
///
/// Geotagging rules:
///  - the device camera's own GPS EXIF is kept untouched when present;
///  - otherwise GPS is embedded into the JPEG via [GeotagWriter];
///  - non-JPEG images (HEIC etc.) are stored with coordinates recorded in the
///    [PhotoRecord] (sidecar), since EXIF cannot be written.
class PhotoStore {
  static const int maxThumbDimension = 512;
  static const int _thumbQuality = 70;

  final Directory baseDir;

  PhotoStore({Directory? baseDir}) : baseDir = baseDir ?? _defaultBase();

  static Directory _defaultBase() {
    return Directory('.'); // replaced by _documentsDir() when used on device
  }

  static Future<Directory> _documentsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}photos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final thumbs = Directory(
      '${docs.path}${Platform.pathSeparator}photos${Platform.pathSeparator}thumbs',
    );
    if (!await thumbs.exists()) {
      await thumbs.create(recursive: true);
    }
    return dir;
  }

  /// Saves [bytes] as a photo, embedding GPS EXIF when possible.
  ///
  /// Returns the stored [PhotoRecord]. Coordinates are optional — a photo can
  /// be captured without a GPS fix.
  static Future<PhotoRecord> save(
    Uint8List bytes, {
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? capturedAt,
    Directory? dir,
  }) async {
    final photoDir = dir ?? await _documentsDir();
    final timestamp = DateTime.now();
    final stamp = '${timestamp.year}${_pad(timestamp.month)}${_pad(timestamp.day)}'
        '_${_pad(timestamp.hour)}${_pad(timestamp.minute)}${_pad(timestamp.second)}'
        '_${timestamp.millisecond}';
    final name = 'photo_$stamp.jpg';

    var fileBytes = bytes;
    var gpsStatus = 'none';
    if (latitude != null && longitude != null) {
      final result = GeotagWriter.embedGps(
        bytes,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        capturedAt: capturedAt ?? timestamp,
      );
      fileBytes = result.bytes;
      gpsStatus = result.status;
    } else if (GeotagWriter.hasEmbeddedGps(bytes)) {
      // Device camera already geotagged the photo.
      gpsStatus = GeotagWriter.deviceGeotag;
    }

    final file = File('${photoDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(fileBytes, flush: true);

    final thumbBytes = _buildThumb(fileBytes);
    final thumbFile = File(
      '${photoDir.path}${Platform.pathSeparator}thumbs${Platform.pathSeparator}$name',
    );
    await thumbFile.writeAsBytes(thumbBytes, flush: true);

    final record = PhotoRecord(
      path: file.path,
      thumbPath: thumbFile.path,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      gpsStatus: gpsStatus,
      capturedAt: capturedAt ?? timestamp,
    );

    // Sidecar JSON so [list] can restore coordinates/gps status later.
    final sidecar = File('${file.path}.json');
    await sidecar.writeAsString(jsonEncode(record.toJson()), flush: true);

    return record;
  }

  /// Lists all saved photos, newest first.
  static Future<List<PhotoRecord>> list({Directory? dir}) async {
    final photoDir = dir ?? await _documentsDir();
    if (!await photoDir.exists()) return [];
    final thumbsDir = Directory(
      '${photoDir.path}${Platform.pathSeparator}thumbs',
    );
    final files = (await photoDir.list().toList())
        .whereType<File>()
        .where((file) =>
            file.path.endsWith('.jpg') &&
            !file.path.contains(
              '${Platform.pathSeparator}thumbs${Platform.pathSeparator}',
            ))
        .toList();
    final records = [
      for (final file in files) _recordFromFile(file, thumbsDir),
    ];
    records.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return records;
  }

  static PhotoRecord _recordFromFile(File file, Directory thumbsDir) {
    final sidecar = File('${file.path}.json');
    try {
      if (sidecar.existsSync()) {
        final decoded = jsonDecode(sidecar.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          return PhotoRecord.fromJson(decoded);
        }
      }
    } catch (_) {
      // fall through to a minimal record
    }
    return PhotoRecord(
      path: file.path,
      thumbPath:
          '${thumbsDir.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
      gpsStatus: GeotagWriter.unchanged,
      capturedAt: file.statSync().modified,
    );
  }

  /// Deletes the photo, its thumbnail and sidecar from disk.
  static Future<void> delete(PhotoRecord record) async {
    final file = File(record.path);
    if (await file.exists()) await file.delete();
    final sidecar = File('${record.path}.json');
    if (await sidecar.exists()) await sidecar.delete();
    if (record.thumbPath.isNotEmpty) {
      final thumb = File(record.thumbPath);
      if (await thumb.exists()) await thumb.delete();
    }
  }

  static Uint8List _buildThumb(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return Uint8List.fromList(bytes.length <= 64 * 1024 ? bytes : bytes.sublist(0, 64 * 1024));
      }
      final thumb = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? maxThumbDimension : null,
        height: decoded.height >= decoded.width ? maxThumbDimension : null,
        interpolation: img.Interpolation.linear,
      );
      return Uint8List.fromList(
        img.encodeJpg(thumb, quality: _thumbQuality),
      );
    } catch (_) {
      return Uint8List.fromList(bytes.length <= 64 * 1024 ? bytes : bytes.sublist(0, 64 * 1024));
    }
  }

  static bool _isJpeg(Uint8List bytes) =>
      bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
