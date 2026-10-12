import 'dart:typed_data';

/// Embeds GPS coordinates into JPEG EXIF metadata.
///
/// Strategy (device-friendly):
///  1. If the JPEG already contains GPS EXIF (e.g. the device camera wrote it),
///     nothing is done — the device geotag wins.
///  2. Append a replacement root IFD and GPS block, preserving original
///     metadata offsets, orientation and thumbnails in either byte order.
///  3. If the JPEG has no EXIF at all, a minimal EXIF APP1 segment containing
///     GPS is inserted right after the SOI marker.
class GeotagWriter {
  static const int _exifMarker = 0xFFE1;
  static const int _sos = 0xFFDA;

  static const int _tagGpsInfo = 0x8825;
  static const int _tagExifIfd = 0x8769;

  /// Result of trying to geotag an image.
  static const String deviceGeotag = 'device'; // camera already wrote GPS
  static const String inserted = 'inserted'; // new EXIF segment written
  static const String patched = 'patched'; // existing EXIF updated
  static const String unchanged = 'unchanged'; // not a JPEG / unsafe to patch

  /// Returns the (possibly modified) JPEG bytes and how GPS was embedded.
  static ({Uint8List bytes, String status}) embedGps(
    Uint8List jpeg, {
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? capturedAt,
    bool preserveExistingGps = true,
  }) {
    if (!_isJpeg(jpeg)) return (bytes: jpeg, status: unchanged);
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return (bytes: jpeg, status: unchanged);
    }

    final exifSegment = _findExifSegment(jpeg);
    if (preserveExistingGps &&
        exifSegment != null &&
        _hasGps(exifSegment.data)) {
      return (bytes: jpeg, status: deviceGeotag);
    }

    if (exifSegment != null) {
      final patchedBytes = _patchExif(
        jpeg,
        exifSegment,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        capturedAt: capturedAt,
      );
      if (patchedBytes != null) {
        return (bytes: patchedBytes, status: patched);
      }
      return (bytes: jpeg, status: unchanged);
    }

    final newJpeg = _insertExifSegment(
      jpeg,
      _buildExifSegment(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        capturedAt: capturedAt,
      ),
    );
    return (bytes: newJpeg, status: inserted);
  }

  /// True when the JPEG already carries GPS EXIF (written by the device
  /// camera or otherwise). Never modifies the bytes.
  static bool hasEmbeddedGps(Uint8List jpeg) {
    return readGps(jpeg) != null;
  }

  /// Reads and validates actual GPS values; a GPS pointer alone is not a fix.
  static ({double latitude, double longitude, double? altitude})? readGps(
      Uint8List jpeg) {
    if (!_isJpeg(jpeg)) return null;
    final segment = _findExifSegment(jpeg);
    if (segment == null) return null;
    return _readGps(segment.data);
  }

  static ({double latitude, double longitude, double? altitude})? _readGps(
      Uint8List data) {
    try {
      final tiff = _tiffOf(data);
      final header = _parseTiffHeader(tiff);
      if (header == null) return null;
      final root = _readIfd(tiff, header.ifd0Offset);
      final pointer = root?.tags.indexOf(_tagGpsInfo) ?? -1;
      if (pointer < 0 ||
          root!.types[pointer] != 4 ||
          root.counts[pointer] != 1) {
        return null;
      }
      final gps = _readIfd(tiff, root.values[pointer]);
      if (gps == null) return null;
      String? reference(int tag) {
        final index = gps.tags.indexOf(tag);
        if (index < 0 || gps.types[index] != 2 || gps.counts[index] != 2) {
          return null;
        }
        final code = header.type == 0
            ? gps.values[index] & 255
            : gps.values[index] >> 24;
        return String.fromCharCode(code);
      }

      double? rational(int tag, int count) {
        final index = gps.tags.indexOf(tag);
        if (index < 0 || gps.types[index] != 5 || gps.counts[index] != count) {
          return null;
        }
        final offset = gps.values[index];
        if (offset < 0 || offset + count * 8 > tiff.length) return null;
        var result = 0.0;
        for (var i = 0; i < count; i++) {
          final denominator = _u32(tiff, offset + i * 8 + 4, header.type);
          if (denominator == 0) return null;
          final value = _u32(tiff, offset + i * 8, header.type) / denominator;
          if (count == 3 && i > 0 && value >= 60) return null;
          result += value / (i == 0 ? 1 : (i == 1 ? 60 : 3600));
        }
        return result;
      }

      var latitude = rational(2, 3);
      var longitude = rational(4, 3);
      final latRef = reference(1);
      final lonRef = reference(3);
      if (latitude == null ||
          longitude == null ||
          latitude > 90 ||
          longitude > 180 ||
          !['N', 'S'].contains(latRef) ||
          !['E', 'W'].contains(lonRef)) return null;
      if (latRef == 'S') latitude = -latitude;
      if (lonRef == 'W') longitude = -longitude;
      var altitude = rational(6, 1);
      final altRef = gps.tags.indexOf(5);
      if (altitude != null && altRef >= 0) {
        final ref = header.type == 0
            ? gps.values[altRef] & 255
            : gps.values[altRef] >> 24;
        if (ref == 1) altitude = -altitude;
      }
      return (latitude: latitude, longitude: longitude, altitude: altitude);
    } on RangeError {
      return null;
    }
  }

  // ── segment discovery ────────────────────────────────────────

  static bool _isJpeg(Uint8List bytes) =>
      bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

  static ({int offset, Uint8List data})? _findExifSegment(Uint8List jpeg) {
    var offset = 2; // skip SOI
    while (offset + 4 <= jpeg.length) {
      if (jpeg[offset] != 0xFF) break;
      final marker = jpeg[offset + 1];
      if (marker == 0xFF || marker == 0x00) break;
      if (marker == 0xD9 || marker == (_sos & 0xFF)) break; // EOI / SOS
      if (offset + 4 > jpeg.length) break;
      final length = (jpeg[offset + 2] << 8) | jpeg[offset + 3];
      if (length < 2 || offset + 2 + length > jpeg.length) break;
      if (marker == (_exifMarker & 0xFF) &&
          length >= 8 &&
          jpeg[offset + 4] == 0x45 && // 'E'
          jpeg[offset + 5] == 0x78 && // 'x'
          jpeg[offset + 6] == 0x69 && // 'i'
          jpeg[offset + 7] == 0x66 && // 'f'
          jpeg[offset + 8] == 0x00 &&
          jpeg[offset + 9] == 0x00) {
        return (
          offset: offset,
          data: Uint8List.fromList(
            jpeg.sublist(offset + 4, offset + 2 + length),
          ),
        );
      }
      offset += 2 + length;
    }
    return null;
  }

  static bool _hasGps(Uint8List segmentData) {
    return _readGps(segmentData) != null;
  }

  static Uint8List _tiffOf(Uint8List segmentData) {
    // segmentData = "Exif\0\0" + TIFF
    if (segmentData.length < 14) return Uint8List(0);
    return Uint8List.fromList(segmentData.sublist(6));
  }

  // ── TIFF parsing ─────────────────────────────────────────────

  static ({int ifd0Offset, int type})? _parseTiffHeader(Uint8List tiff) {
    if (tiff.length < 8) return null;
    final type = (tiff[0] == 0x49 && tiff[1] == 0x49)
        ? 0
        : ((tiff[0] == 0x4D && tiff[1] == 0x4D) ? 1 : -1);
    if (type < 0 || _u16(tiff, 2, type) != 42) return null;
    final ifd0 = _u32(tiff, 4, type);
    if (ifd0 < 8 || ifd0 >= tiff.length) return null;
    return (ifd0Offset: ifd0, type: type);
  }

  static int _u16(Uint8List b, int off, int type) =>
      type == 0 ? b[off] | (b[off + 1] << 8) : (b[off] << 8) | b[off + 1];

  static int _u32(Uint8List b, int off, int type) {
    if (type == 0) {
      return b[off] |
          (b[off + 1] << 8) |
          (b[off + 2] << 16) |
          (b[off + 3] << 24);
    }
    return (b[off] << 24) | (b[off + 1] << 16) | (b[off + 2] << 8) | b[off + 3];
  }

  static ({
    List<int> tags,
    List<int> types,
    List<int> counts,
    List<int> values
  })? _readIfd(Uint8List tiff, int offset) {
    if (offset < 0 || offset + 2 > tiff.length) return null;
    final header = _parseTiffHeader(tiff);
    if (header == null) return null;
    final type = header.type;
    final count = _u16(tiff, offset, type);
    final end = offset + 2 + count * 12;
    if (end > tiff.length) return null;

    final tags = <int>[];
    final types = <int>[];
    final counts = <int>[];
    final values = <int>[];
    for (int i = 0; i < count; i++) {
      final e = offset + 2 + i * 12;
      tags.add(_u16(tiff, e, type));
      types.add(_u16(tiff, e + 2, type));
      counts.add(_u32(tiff, e + 4, type));
      values.add(_u32(tiff, e + 8, type));
    }
    return (tags: tags, types: types, counts: counts, values: values);
  }

  static int _typeSize(int fieldType) {
    switch (fieldType) {
      case 1: // BYTE
      case 2: // ASCII
      case 7: // UNDEFINED
        return 1;
      case 3: // SHORT
        return 2;
      case 5: // RATIONAL
      case 10:
        return 8;
      default: // LONG and others
        return 4;
    }
  }

  // ── EXIF patching ────────────────────────────────────────────

  static Uint8List? _patchExif(
    Uint8List jpeg,
    ({int offset, Uint8List data}) segment, {
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? capturedAt,
  }) {
    final tiff = _tiffOf(segment.data);
    final header = _parseTiffHeader(tiff);
    if (header == null) return null;
    final ifd0 = _readIfd(tiff, header.ifd0Offset);
    if (ifd0 == null) return null;
    final oldEnd = header.ifd0Offset + 2 + ifd0.tags.length * 12;
    if (oldEnd + 4 > tiff.length) return null;

    // Append a replacement root IFD. Original payload offsets, EXIF sub-IFDs
    // and thumbnail links remain unchanged, including out-of-line camera tags.
    final kept = <int>[
      for (var i = 0; i < ifd0.tags.length; i++)
        if (ifd0.tags[i] != _tagGpsInfo) i,
    ]..sort((a, b) => ifd0.tags[a].compareTo(ifd0.tags[b]));
    final rootOffset = tiff.length;
    final gpsOffset = rootOffset + 2 + (kept.length + 1) * 12 + 4;
    final gpsBlock = _buildGpsBlock(
      gpsOffset,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      capturedAt: capturedAt,
      type: header.type,
    );
    final newTiff = Uint8List(gpsOffset + gpsBlock.length);
    newTiff.setAll(0, tiff);
    _writeU32(newTiff, 4, rootOffset, header.type);
    _writeU16(newTiff, rootOffset, kept.length + 1, header.type);
    var entryOffset = rootOffset + 2;
    var gpsWritten = false;
    void writeGpsEntry() {
      _writeU16(newTiff, entryOffset, _tagGpsInfo, header.type);
      _writeU16(newTiff, entryOffset + 2, 4, header.type);
      _writeU32(newTiff, entryOffset + 4, 1, header.type);
      _writeU32(newTiff, entryOffset + 8, gpsOffset, header.type);
      entryOffset += 12;
      gpsWritten = true;
    }

    for (final index in kept) {
      if (!gpsWritten && ifd0.tags[index] > _tagGpsInfo) writeGpsEntry();
      final oldEntry = header.ifd0Offset + 2 + index * 12;
      newTiff.setAll(entryOffset, tiff.sublist(oldEntry, oldEntry + 12));
      entryOffset += 12;
    }
    if (!gpsWritten) writeGpsEntry();
    _writeU32(
        newTiff, entryOffset, _u32(tiff, oldEnd, header.type), header.type);
    newTiff.setAll(gpsOffset, gpsBlock);
    if (newTiff.length + 8 > 65535) return null;
    final patchedSegment = _buildExifSegmentFromTiff(newTiff);
    final oldSegmentLength = segment.data.length + 4;
    final out =
        Uint8List(jpeg.length - oldSegmentLength + patchedSegment.length);
    out.setAll(0, jpeg.sublist(0, segment.offset));
    out.setAll(segment.offset, patchedSegment);
    out.setAll(segment.offset + patchedSegment.length,
        jpeg.sublist(segment.offset + oldSegmentLength));
    return out;
  }

  // ── fresh EXIF segment ───────────────────────────────────────

  static Uint8List _insertExifSegment(Uint8List jpeg, Uint8List segment) {
    final out = Uint8List(jpeg.length + segment.length);
    out[0] = 0xFF;
    out[1] = 0xD8;
    out.setAll(2, segment);
    out.setAll(2 + segment.length, jpeg.sublist(2));
    return out;
  }

  /// Wraps a TIFF blob into a complete APP1 EXIF segment, marker included.
  static Uint8List _buildExifSegmentFromTiff(Uint8List tiff) {
    final segment = Uint8List(4 + 6 + tiff.length);
    segment[0] = 0xFF;
    segment[1] = 0xE1;
    final length = 2 + 6 + tiff.length; // bytes following the length field
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

  /// Builds a complete minimal APP1 EXIF segment (marker included).
  static Uint8List _buildExifSegment({
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? capturedAt,
  }) {
    const type = 0; // little endian
    final gpsEntries = _gpsEntries(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      capturedAt: capturedAt,
    );
    const ifd0Offset = 8;
    // IFD0: Exif pointer + GPS pointer (+ next ptr) = 2 entries
    const exifIfdOffset = ifd0Offset + 2 + 2 * 12 + 4;
    const gpsIfdOffset = exifIfdOffset + 2 + 1 * 12 + 4;
    final dataStart = gpsIfdOffset + 2 + gpsEntries.length * 12 + 4;
    final dataSize = _gpsDataSize(gpsEntries);

    final tiff = Uint8List(dataStart + dataSize);

    // header
    tiff[0] = 0x49;
    tiff[1] = 0x49;
    tiff[2] = 0x2A;
    tiff[3] = 0x00;
    _writeU32(tiff, 4, ifd0Offset, type);

    final ifd0Entries = <List<int>>[
      [_tagExifIfd, 4, 1, exifIfdOffset],
      [_tagGpsInfo, 4, 1, gpsIfdOffset],
    ];
    final exifEntries = <List<int>>[
      [0x9000, 2, 4, 0x30333230], // ExifVersion "0230" (ASCII, inline)
    ];
    _writeIfd(tiff, ifd0Offset, ifd0Entries, type);
    _writeIfd(tiff, exifIfdOffset, exifEntries, type);
    final gpsBlock = _buildGpsBlock(
      gpsIfdOffset,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      capturedAt: capturedAt,
    );
    tiff.setAll(gpsIfdOffset, gpsBlock);

    return _buildExifSegmentFromTiff(tiff);
  }

  /// Builds a GPS IFD (entries + next-ptr + rational data) located at the
  /// absolute TIFF offset [gpsIfdOffset].
  static Uint8List _buildGpsBlock(
    int gpsIfdOffset, {
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? capturedAt,
    int type = 0,
  }) {
    final entries = _gpsEntries(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      capturedAt: capturedAt,
    );
    final ifdSize = 2 + entries.length * 12 + 4;
    final dataStart = gpsIfdOffset + ifdSize;
    final block = Uint8List(ifdSize + _gpsDataSize(entries));
    _writeIfd(block, 0, entries, type, dataStart);
    _writeGpsData(
      block,
      ifdSize,
      entries,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      capturedAt: capturedAt,
      type: type,
    );
    return block;
  }

  static List<List<int>> _gpsEntries({
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? capturedAt,
  }) {
    final entries = <List<int>>[
      [0x0000, 1, 4, 0x00000302], // GPSVersionID 2.3.0.0 (bytes 02 03 00 00)
      [0x0001, 2, 2, latitude < 0 ? 0x53 : 0x4E], // 'S\0' / 'N\0' (inline)
      [0x0002, 5, 3, 0], // GPSLatitude → data
      [0x0003, 2, 2, longitude < 0 ? 0x57 : 0x45], // 'W\0' / 'E\0' (inline)
      [0x0004, 5, 3, 0], // GPSLongitude → data
      [0x0005, 1, 1, (altitude ?? 0) >= 0 ? 0 : 1], // GPSAltitudeRef (inline)
      [0x0006, 5, 1, 0], // GPSAltitude → data
      [0x0007, 5, 3, 0], // GPSTimeStamp → data
    ];
    if (capturedAt == null) entries.removeLast();
    return entries;
  }

  static int _gpsDataSize(List<List<int>> entries) {
    var size = 0;
    for (final entry in entries) {
      final byteCount = _typeSize(entry[1]) * entry[2];
      if (byteCount > 4) size += byteCount;
    }
    return size;
  }

  /// Writes an IFD ([entries]) at [offset] inside [b]. Values that do not fit
  /// inline are placed at successive absolute offsets starting at [dataStart].
  /// Returns the offset just past the last written data block.
  static int _writeIfd(
    Uint8List b,
    int offset,
    List<List<int>> entries,
    int type, [
    int? dataStart,
  ]) {
    var dataOffset = dataStart ?? (offset + 2 + entries.length * 12 + 4);
    _writeU16(b, offset, entries.length, type);
    for (int i = 0; i < entries.length; i++) {
      final e = offset + 2 + i * 12;
      final entry = entries[i];
      final byteCount = _typeSize(entry[1]) * entry[2];
      _writeU16(b, e, entry[0], type);
      _writeU16(b, e + 2, entry[1], type);
      _writeU32(b, e + 4, entry[2], type);
      if (byteCount <= 4) {
        if (type == 1 && (entry[1] == 1 || entry[1] == 2)) {
          for (var j = 0; j < 4; j++) {
            b[e + 8 + j] = (entry[3] >> (8 * j)) & 255;
          }
        } else {
          _writeU32(b, e + 8, entry[3], type);
        }
      } else {
        _writeU32(b, e + 8, dataOffset, type);
        dataOffset += byteCount;
      }
    }
    _writeU32(b, offset + 2 + entries.length * 12, 0, type);
    return dataOffset;
  }

  static void _writeGpsData(
    Uint8List block,
    int dataOffset,
    List<List<int>> entries, {
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? capturedAt,
    int type = 0,
  }) {
    // Round total seconds first so rounding cannot create an invalid 60-second
    // component at a minute/degree boundary.
    final latUnits = (latitude.abs() * 3600 * 10000).round();
    final latDeg = latUnits ~/ 36000000;
    final latMin = (latUnits % 36000000) ~/ 600000;
    final latSec = (latUnits % 600000) / 10000;
    final lngUnits = (longitude.abs() * 3600 * 10000).round();
    final lngDeg = lngUnits ~/ 36000000;
    final lngMin = (lngUnits % 36000000) ~/ 600000;
    final lngSec = (lngUnits % 600000) / 10000;

    var offset = dataOffset;
    for (final entry in entries) {
      final byteCount = _typeSize(entry[1]) * entry[2];
      if (byteCount <= 4) continue;
      if (entry[0] == 0x0002) {
        // GPSLatitude
        _writeRational(block, offset, latDeg, 1, type);
        offset += 8;
        _writeRational(block, offset, latMin, 1, type);
        offset += 8;
        final sec = _roundSec(latSec);
        _writeRational(block, offset, sec.num, sec.den, type);
        offset += 8;
      } else if (entry[0] == 0x0004) {
        // GPSLongitude
        _writeRational(block, offset, lngDeg, 1, type);
        offset += 8;
        _writeRational(block, offset, lngMin, 1, type);
        offset += 8;
        final sec = _roundSec(lngSec);
        _writeRational(block, offset, sec.num, sec.den, type);
        offset += 8;
      } else if (entry[0] == 0x0006) {
        // GPSAltitude
        _writeRational(
            block, offset, ((altitude ?? 0).abs() * 100).round(), 100, type);
        offset += 8;
      } else if (entry[0] == 0x0007) {
        // GPSTimeStamp
        final utc = capturedAt?.toUtc() ?? DateTime.now().toUtc();
        _writeRational(block, offset, utc.hour, 1, type);
        offset += 8;
        _writeRational(block, offset, utc.minute, 1, type);
        offset += 8;
        final sec = _roundSec(utc.second.toDouble());
        _writeRational(block, offset, sec.num, sec.den, type);
        offset += 8;
      }
    }
  }

  static ({int num, int den}) _roundSec(double seconds) {
    final rounded = (seconds * 10000).round();
    return (num: rounded, den: 10000);
  }

  static void _writeRational(
      Uint8List b, int offset, int numerator, int denominator, int type) {
    _writeU32(b, offset, numerator, type);
    _writeU32(b, offset + 4, denominator, type);
  }

  static void _writeU16(Uint8List b, int off, int value, int type) {
    if (type == 0) {
      b[off] = value & 0xFF;
      b[off + 1] = (value >> 8) & 0xFF;
    } else {
      b[off] = (value >> 8) & 0xFF;
      b[off + 1] = value & 0xFF;
    }
  }

  static void _writeU32(Uint8List b, int off, int value, int type) {
    if (type == 0) {
      b[off] = value & 0xFF;
      b[off + 1] = (value >> 8) & 0xFF;
      b[off + 2] = (value >> 16) & 0xFF;
      b[off + 3] = (value >> 24) & 0xFF;
    } else {
      b[off] = (value >> 24) & 0xFF;
      b[off + 1] = (value >> 16) & 0xFF;
      b[off + 2] = (value >> 8) & 0xFF;
      b[off + 3] = value & 0xFF;
    }
  }
}
