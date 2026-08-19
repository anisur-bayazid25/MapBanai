import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mapbanai/services/geotag_writer.dart';
import 'package:mapbanai/services/photo_store.dart';

/// Decodes GPS EXIF back to decimal degrees using the (independent) exif
/// package. Returns null when no GPS tag is present.
Future<({double lat, double lng})?> readGps(Uint8List jpeg) async {
  final tags = await readExifFromBytes(jpeg);
  final latTag = tags['GPS GPSLatitude'];
  final lngTag = tags['GPS GPSLongitude'];
  final latRef = tags['GPS GPSLatitudeRef']?.printable;
  final lngRef = tags['GPS GPSLongitudeRef']?.printable;
  if (latTag == null || lngTag == null) return null;
  final lat = latTag.values as IfdRatios;
  final lng = lngTag.values as IfdRatios;
  double toDecimal(List<Ratio> r) {
    final deg = r[0].numerator / r[0].denominator;
    final min = r[1].numerator / r[1].denominator;
    final sec = r[2].numerator / r[2].denominator;
    return deg + min / 60 + sec / 3600;
  }

  var latValue = toDecimal(lat.ratios);
  var lngValue = toDecimal(lng.ratios);
  if (latRef?.contains('S') ?? false) latValue = -latValue;
  if (lngRef?.contains('W') ?? false) lngValue = -lngValue;
  return (lat: latValue, lng: lngValue);
}

Uint8List makeJpeg() {
  final image = img.Image(width: 6, height: 4);
  img.fill(image, color: img.ColorRgb8(20, 120, 200));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  group('GeotagWriter', () {
    test('inserts EXIF GPS into a JPEG without EXIF', () async {
      final jpeg = makeJpeg();
      final result = GeotagWriter.embedGps(
        jpeg,
        latitude: 45.501701,
        longitude: -73.567253,
        altitude: 25.4,
        capturedAt: DateTime.utc(2026, 8, 17, 14, 30, 5),
      );

      expect(result.status, GeotagWriter.inserted);
      expect(result.bytes.length, greaterThan(jpeg.length));

      final gps = await readGps(result.bytes);
      expect(gps, isNotNull);
      expect(gps!.lat, closeTo(45.5017, 1e-4));
      expect(gps.lng, closeTo(-73.5673, 1e-4));

      // JPEG still decodable
      expect(img.decodeImage(result.bytes), isNotNull);
    });

    test('recognizes an already-geotagged JPEG (device GPS)', () async {
      final jpeg = makeJpeg();
      final geotagged = GeotagWriter.embedGps(
        jpeg,
        latitude: 10.0,
        longitude: 20.0,
      ).bytes;

      final second = GeotagWriter.embedGps(
        geotagged,
        latitude: 30.0,
        longitude: 40.0,
      );
      expect(second.status, GeotagWriter.deviceGeotag);
      expect(second.bytes, equals(geotagged));

      final gps = await readGps(second.bytes);
      expect(gps!.lat, closeTo(10.0, 1e-4));
      expect(gps.lng, closeTo(20.0, 1e-4));
    });

    test('patches existing EXIF without GPS, preserving other tags', () async {
      final base = makeJpeg();
      // Build a camera-like JPEG: APP0 (JFIF) + EXIF APP1 (with orientation)
      // + rest of image. We build the EXIF APP1 with our own builder, then
      // strip its GPS by building one without a timestamp… simpler: craft a
      // fake "camera EXIF" APP1 using a manual TIFF with an orientation tag.
      final exifSegment = _buildCameraStyleExif(); // APP1 w/o GPS
      final jpeg = _joinSegments(base, exifSegment);

      final result = GeotagWriter.embedGps(
        jpeg,
        latitude: -33.858611,
        longitude: 151.214722,
        altitude: 100.0,
      );

      expect(result.status, GeotagWriter.patched);

      final tags = await readExifFromBytes(result.bytes);
      // camera's orientation (0x0112) preserved through the patch
      final orientation = tags['Image Orientation'];
      expect(orientation, isNotNull);
      final gps = await readGps(result.bytes);
      expect(gps, isNotNull);
      expect(gps!.lat, closeTo(-33.8586, 1e-4));
      expect(gps.lng, closeTo(151.2147, 1e-4));
      expect(img.decodeImage(result.bytes), isNotNull);
    });

    test('leaves non-JPEG bytes untouched', () {
      final png = Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));
      final result = GeotagWriter.embedGps(png, latitude: 1, longitude: 2);
      expect(result.status, GeotagWriter.unchanged);
      expect(result.bytes, equals(png));
    });

    test('leaves JPEG untouched when coordinates are out of range', () {
      final jpeg = makeJpeg();
      final result = GeotagWriter.embedGps(jpeg, latitude: 95, longitude: 2);
      expect(result.status, GeotagWriter.unchanged);
      expect(result.bytes, equals(jpeg));
    });

    test('hasEmbeddedGps detects camera GPS and rejects plain JPEGs', () {
      final plain = makeJpeg();
      expect(GeotagWriter.hasEmbeddedGps(plain), isFalse);
      final tagged = GeotagWriter.embedGps(plain, latitude: 1, longitude: 2).bytes;
      expect(GeotagWriter.hasEmbeddedGps(tagged), isTrue);
      expect(GeotagWriter.hasEmbeddedGps(Uint8List(0)), isFalse);
    });
  });

  group('PhotoStore', () {
    late Directory tempDir;
    late Directory photoDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mapbanai_photos');
      photoDir = Directory('${tempDir.path}${Platform.pathSeparator}photos');
      await photoDir.create();
      await Directory(
        '${photoDir.path}${Platform.pathSeparator}thumbs',
      ).create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('saves photo with embedded GPS and thumbnail', () async {
      final jpeg = makeJpeg();
      final record = await PhotoStore.save(
        jpeg,
        latitude: 45.5017,
        longitude: -73.5673,
        capturedAt: DateTime(2026, 8, 17, 12, 0),
        dir: photoDir,
      );

      expect(record.isGeotagged, isTrue);
      expect(record.gpsStatus, GeotagWriter.inserted);
      expect(File(record.path).existsSync(), isTrue);
      expect(File(record.thumbPath).existsSync(), isTrue);

      final gps = await readGps(await File(record.path).readAsBytes());
      expect(gps, isNotNull);
      expect(gps!.lat, closeTo(45.5017, 1e-4));

      // thumbnail is decodable and bounded in dimension
      final thumbBytes = await File(record.thumbPath).readAsBytes();
      final thumb = img.decodeImage(thumbBytes);
      expect(thumb, isNotNull);
      expect(
        thumb!.width <= PhotoStore.maxThumbDimension,
        isTrue,
        reason: 'thumb width ${thumb.width}',
      );

      // JSON round-trip
      final restored = PhotoRecord.fromJson(record.toJson());
      expect(restored.path, record.path);
      expect(restored.latitude, 45.5017);
      expect(restored.gpsStatus, GeotagWriter.inserted);
    });

    test('records device geotag when camera already wrote GPS', () async {
      final tagged = GeotagWriter.embedGps(makeJpeg(), latitude: 10, longitude: 20).bytes;
      final record = await PhotoStore.save(tagged, dir: photoDir);
      expect(record.gpsStatus, GeotagWriter.deviceGeotag);
      expect(record.isGeotagged, isTrue);
    });

    test('stores without coordinates and reports none', () async {
      final record = await PhotoStore.save(makeJpeg(), dir: photoDir);
      expect(record.isGeotagged, isFalse);
      expect(record.gpsStatus, 'none');
      expect(record.latitude, isNull);
    });

    test('keeps non-JPEG and reports no geotag', () async {
      final png = Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));
      final record = await PhotoStore.save(
        png,
        latitude: 1.0,
        longitude: 2.0,
        dir: photoDir,
      );
      expect(record.gpsStatus, GeotagWriter.unchanged);
      expect(record.isGeotagged, isFalse);
      expect(File(record.path).existsSync(), isTrue);
    });

    test('lists photos newest first and deletes them', () async {
      await PhotoStore.save(
        makeJpeg(),
        latitude: 1,
        longitude: 2,
        capturedAt: DateTime(2026, 8, 1, 10, 0),
        dir: photoDir,
      );
      await PhotoStore.save(
        makeJpeg(),
        latitude: 3,
        longitude: 4,
        capturedAt: DateTime(2026, 8, 2, 10, 0),
        dir: photoDir,
      );

      final records = await PhotoStore.list(dir: photoDir);
      expect(records, hasLength(2));
      expect(records[0].latitude, 3.0); // newest first

      final first = records[0];
      await PhotoStore.delete(first);
      final remaining = await PhotoStore.list(dir: photoDir);
      expect(remaining, hasLength(1));
      expect(File(first.path).existsSync(), isFalse);
      expect(File('${first.path}.json').existsSync(), isFalse);
    });
  });
}

// ── helpers ──────────────────────────────────────────────────────

/// Builds a fake "camera" JPEG: APP0 JFIF + EXIF APP1 with only an
/// Orientation tag (no GPS), then the rest of the source image.
Uint8List _joinSegments(Uint8List source, Uint8List app1Segment) {
  final app0 = Uint8List.fromList([
    0xFF, 0xE0, 0x00, 0x10, // APP0, length 16
    0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
    0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
  ]);
  final out = Uint8List(2 + app0.length + app1Segment.length + source.length - 2);
  out[0] = 0xFF;
  out[1] = 0xD8;
  out.setAll(2, app0);
  out.setAll(2 + app0.length, app1Segment);
  out.setAll(2 + app0.length + app1Segment.length, source.sublist(2));
  return out;
}

/// EXIF APP1 (incl. marker+length) with an Orientation SHORT tag only.
Uint8List _buildCameraStyleExif() {
  // TIFF little endian:
  // header(8) + IFD0(2 + 2*12 + 4) — orientation inline + ExifVersion inline
  final tiff = Uint8List(8 + 2 + 2 * 12 + 4);
  tiff[0] = 0x49;
  tiff[1] = 0x49;
  tiff[2] = 0x2A;
  tiff[3] = 0x00;
  tiff[4] = 0x08;
  tiff[5] = 0x00;
  tiff[8] = 0x02; // 2 entries
  // entry 0: Orientation (0x0112) SHORT count 1 value 6
  tiff[10] = 0x12;
  tiff[11] = 0x01;
  tiff[12] = 0x03;
  tiff[13] = 0x00;
  tiff[14] = 0x01;
  tiff[15] = 0x00;
  tiff[16] = 0x00;
  tiff[17] = 0x00;
  tiff[18] = 0x06;
  tiff[19] = 0x00;
  tiff[20] = 0x00;
  tiff[21] = 0x00;
  // entry 1: ExifVersion (0x9000) ASCII 4 inline "0230"
  tiff[22] = 0x00;
  tiff[23] = 0x90;
  tiff[24] = 0x02;
  tiff[25] = 0x00;
  tiff[26] = 0x04;
  tiff[27] = 0x00;
  tiff[28] = 0x00;
  tiff[29] = 0x00;
  tiff[30] = 0x30;
  tiff[31] = 0x32;
  tiff[32] = 0x33;
  tiff[33] = 0x30;
  // next IFD pointer
  tiff[34] = 0x00;
  tiff[35] = 0x00;
  tiff[36] = 0x00;
  tiff[37] = 0x00;

  final segment = Uint8List(4 + 6 + tiff.length);
  segment[0] = 0xFF;
  segment[1] = 0xE1;
  final length = 2 + 6 + tiff.length; // length field excludes marker itself
  segment[2] = (length >> 8) & 0xFF;
  segment[3] = length & 0xFF;
  segment[4] = 0x45;
  segment[5] = 0x78;
  segment[6] = 0x69;
  segment[7] = 0x66;
  segment[8] = 0x00;
  segment[9] = 0x00;
  segment.setAll(10, tiff);
  return segment;
}
