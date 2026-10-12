import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mapbanai/services/geotag_writer.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/location_service.dart';

import 'helpers/test_utils.dart';

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
    test('rounding near degree boundary retains a valid GPS fix', () async {
      final result = GeotagWriter.embedGps(makeJpeg(),
          latitude: 23.999999999, longitude: 90.999999999);
      expect(GeotagWriter.hasEmbeddedGps(result.bytes), isTrue);
      final gps = await readGps(result.bytes);
      expect(gps!.lat, closeTo(24, 1e-6));
      expect(gps.lng, closeTo(91, 1e-6));
    });
    for (final endian in [Endian.little, Endian.big]) {
      test('preserves out-of-line camera metadata with $endian EXIF', () async {
        final tiff = Uint8List(44);
        final data = ByteData.sublistView(tiff);
        tiff[0] = endian == Endian.little ? 73 : 77;
        tiff[1] = tiff[0];
        data.setUint16(2, 42, endian);
        data.setUint32(4, 8, endian);
        data.setUint16(8, 2, endian);
        data.setUint16(10, 0x010f, endian); // Camera make, out-of-line ASCII
        data.setUint16(12, 2, endian);
        data.setUint32(14, 6, endian);
        data.setUint32(18, 38, endian);
        data.setUint16(22, 0x0112, endian); // Orientation
        data.setUint16(24, 3, endian);
        data.setUint32(26, 1, endian);
        data.setUint16(30, 6, endian);
        tiff.setAll(38, [67, 65, 77, 69, 82, 0]);
        final app1 = Uint8List(10 + tiff.length);
        app1.setAll(0, [255, 225, 0, tiff.length + 8, 69, 120, 105, 102, 0, 0]);
        app1.setAll(10, tiff);
        final jpeg = _joinSegments(makeJpeg(), app1);
        final result = GeotagWriter.embedGps(jpeg,
            latitude: -23.5, longitude: -90.5, altitude: -12.3);
        expect(result.status, GeotagWriter.patched);
        final tags = await readExifFromBytes(result.bytes);
        expect(tags['Image Make']!.printable, 'CAMER');
        expect(tags['Image Orientation'], isNotNull);
        final gps = await readGps(result.bytes);
        expect(gps!.lat, closeTo(-23.5, 1e-6));
        expect(gps.lng, closeTo(-90.5, 1e-6));
        expect(
            GeotagWriter.readGps(result.bytes)!.altitude, closeTo(-12.3, 1e-6));
        expect(img.decodeImage(result.bytes), isNotNull);
      });
    }
    test('replaces an existing camera fix when fresh GPS is mandatory',
        () async {
      final original =
          GeotagWriter.embedGps(makeJpeg(), latitude: 1, longitude: 2).bytes;
      final result = GeotagWriter.embedGps(original,
          latitude: -23.5, longitude: 90.5, preserveExistingGps: false);
      final gps = await readGps(result.bytes);
      expect(gps!.lat, closeTo(-23.5, 1e-6));
      expect(gps.lng, closeTo(90.5, 1e-6));
      expect(img.decodeImage(result.bytes), isNotNull);
    });

    test('rejects NaN and infinite coordinates', () {
      expect(
          GeotagWriter.embedGps(makeJpeg(), latitude: double.nan, longitude: 2)
              .status,
          GeotagWriter.unchanged);
      expect(
          GeotagWriter.embedGps(makeJpeg(),
                  latitude: 2, longitude: double.infinity)
              .status,
          GeotagWriter.unchanged);
    });

    test('GPS pointer without valid coordinates does not count as a geotag',
        () {
      final tagged =
          GeotagWriter.embedGps(makeJpeg(), latitude: 1, longitude: 2).bytes;
      final invalid = Uint8List.fromList(tagged);
      invalid.fillRange(40, 44, 255);
      expect(GeotagWriter.hasEmbeddedGps(invalid), isFalse);
      final repaired =
          GeotagWriter.embedGps(invalid, latitude: 3, longitude: 4);
      expect(GeotagWriter.readGps(repaired.bytes)!.latitude, closeTo(3, 1e-6));
    });

    test('photo fix accepts any accuracy but rejects stale/invalid coordinates',
        () {
      final fix = testPosition();
      expect(LocationService.isUsablePhotoFix(fix, fix.timestamp), isTrue);
      expect(
          LocationService.isUsablePhotoFix(
              fix, fix.timestamp.add(const Duration(seconds: 31))),
          isFalse);
      expect(
          LocationService.isUsablePhotoFix(
              testPosition(accuracy: 26), fix.timestamp),
          isTrue);
      expect(
          LocationService.isUsablePhotoFix(
              testPosition(accuracy: 0), fix.timestamp),
          isTrue);
      expect(
          LocationService.isUsablePhotoFix(
              testPosition(accuracy: double.nan), fix.timestamp),
          isTrue);
      expect(
          LocationService.isUsablePhotoFix(
              testPosition(accuracy: 26), fix.timestamp,
              maximumAccuracy: 25),
          isFalse);
      expect(
          LocationService.isUsablePhotoFix(
              testPosition(lat: double.nan), fix.timestamp),
          isFalse);
    });
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
      final png =
          Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));
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
      final tagged =
          GeotagWriter.embedGps(plain, latitude: 1, longitude: 2).bytes;
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

    test('mandatory capture rejects missing GPS without writing a file',
        () async {
      await expectLater(PhotoStore.saveGeotagged(makeJpeg(), dir: photoDir),
          throwsFormatException);
      expect(await PhotoStore.list(dir: photoDir), isEmpty);
    });

    test('poor photo accuracy is retained as metadata without blocking save',
        () async {
      final fixedAt = DateTime.utc(2026, 10, 12);
      final record = await PhotoStore.saveGeotagged(makeJpeg(),
          latitude: 23.5,
          longitude: 90.5,
          accuracy: 180,
          gpsFixedAt: fixedAt,
          dir: photoDir);
      expect(record.isGeotagged, isTrue);
      final restored = (await PhotoStore.list(dir: photoDir)).single;
      expect(restored.accuracy, 180);
      expect(restored.gpsFixedAt, fixedAt);
      final unknown = await PhotoStore.saveGeotagged(makeJpeg(),
          latitude: 23.6, longitude: 90.6, accuracy: double.nan, dir: photoDir);
      expect(unknown.isGeotagged, isTrue);
      expect(unknown.accuracy, isNull);
    });

    test('mandatory capture converts PNG and verifies GPS in the saved JPEG',
        () async {
      final png =
          Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));
      final record = await PhotoStore.saveGeotagged(png,
          latitude: 23.5, longitude: 90.5, dir: photoDir);
      final bytes = await File(record.path).readAsBytes();
      expect(bytes.take(2), [255, 216]);
      expect(record.isGeotagged, isTrue);
      expect((await readGps(bytes))!.lat, closeTo(23.5, 1e-6));
    });

    test('gallery sidecar agrees with preserved EXIF rather than fallback fix',
        () async {
      final tagged =
          GeotagWriter.embedGps(makeJpeg(), latitude: 10, longitude: 20).bytes;
      final record = await PhotoStore.saveGeotagged(tagged,
          latitude: 30, longitude: 40, dir: photoDir);
      expect(record.latitude, 10);
      expect(record.longitude, 20);
      expect(record.gpsStatus, GeotagWriter.deviceGeotag);
    });

    test('mandatory capture rejects unsupported or corrupt image bytes',
        () async {
      await expectLater(
          PhotoStore.saveGeotagged(Uint8List.fromList([255, 216, 1]),
              latitude: 1, longitude: 2, dir: photoDir),
          throwsFormatException);
      expect(await PhotoStore.list(dir: photoDir), isEmpty);
    });

    test('records device geotag when camera already wrote GPS', () async {
      final tagged =
          GeotagWriter.embedGps(makeJpeg(), latitude: 10, longitude: 20).bytes;
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
      final png =
          Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));
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
  final out =
      Uint8List(2 + app0.length + app1Segment.length + source.length - 2);
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
