import 'dart:typed_data';

/// Embeds GPS coordinates into JPEG EXIF metadata.
///
/// Strategy (device-friendly):
///  1. If the JPEG already contains GPS EXIF (e.g. the device camera wrote it),
///     nothing is done — the device geotag wins.
///  2. If the JPEG has EXIF without GPS, the GPSInfo pointer + IFD is appended
///     into the existing EXIF structure (preserving all other tags such as
///     orientation), when the structure allows a safe patch.
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
  }) {
    if (!_isJpeg(jpeg)) return (bytes: jpeg, status: unchanged);
    if (latitude < -90 || latitude > 90 ||
        longitude < -180 || longitude > 180) {
      return (bytes: jpeg, status: unchanged);
    }

    final exifSegment = _findExifSegment(jpeg);
    if (exifSegment != null && _hasGps(exifSegment.data)) {
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
    if (!_isJpeg(jpeg)) return false;
    final exifSegment = _findExifSegment(jpeg);
    return exifSegment != null && _hasGps(exifSegment.data);
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
    final tiff = _tiffOf(segmentData);
    final header = _parseTiffHeader(tiff);
    if (header == null) return false;
    final ifd0 = _readIfd(tiff, header.ifd0Offset);
    return ifd0?.tags.contains(_tagGpsInfo) ?? false;
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
    if (type < 0 || tiff[2] != 0x2A || tiff[3] != 0x00) return null;
    final ifd0 = type == 0
        ? tiff[4] | (tiff[5] << 8)
        : (tiff[4] << 8) | tiff[5];
    if (ifd0 < 8 || ifd0 >= tiff.length) return null;
    return (ifd0Offset: ifd0, type: type);
  }

  static int _u16(Uint8List b, int off, int type) =>
      type == 0 ? b[off] | (b[off + 1] << 8) : (b[off] << 8) | b[off + 1];

  static int _u32(Uint8List b, int off, int type) {
    if (type == 0) {
      return b[off] | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);
    }
    return (b[off] << 24) | (b[off + 1] << 16) | (b[off + 2] << 8) | b[off + 3];
  }

  static ({List<int> tags, List<int> types, List<int> counts, List<int> values})?
      _readIfd(Uint8List tiff, int offset) {
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

  /// True when IFD0 and every IFD reachable through it (Exif, Interop) store
  /// all values inline (≤4 bytes). Only such structures can be patched safely
  /// by shifting the IFD chain by one entry without re-pointing data offsets.
  static bool _isPatchable(Uint8List tiff) {
    final header = _parseTiffHeader(tiff);
    if (header == null) return false;
    final visited = <int>{};
    final queue = <int>[header.ifd0Offset];
    while (queue.isNotEmpty) {
      final offset = queue.removeLast();
      if (!visited.add(offset)) continue;
      final ifd = _readIfd(tiff, offset);
      if (ifd == null) return false;
      for (int i = 0; i < ifd.tags.length; i++) {
        if (_typeSize(ifd.types[i]) * ifd.counts[i] > 4) return false;
        if (ifd.tags[i] == _tagExifIfd || ifd.tags[i] == 0xA005) {
          queue.add(ifd.values[i]);
        }
      }
    }
    return true;
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
    if (ifd0 == null || !_isPatchable(tiff)) return null;
    if (ifd0.tags.contains(_tagGpsInfo)) return null;

    final type = header.type;
    final entrySize = 12;
    final n = ifd0.tags.length;

    final ifd0End = header.ifd0Offset + 2 + n * entrySize + 4;
    final tailStart = ifd0End;
    final tail = Uint8List.fromList(tiff.sublist(tailStart, tiff.length));

    final gpsIfdOffset = tailStart + tail.length + entrySize;
    final gpsBlock = _buildGpsBlock(
      gpsIfdOffset,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      capturedAt: capturedAt,
    );

    final newTiff = Uint8List(tiff.length + entrySize + gpsBlock.length);

    // Header + IFD0 area (count now n+1) — copy, then fix offsets in-place.
    newTiff.setAll(0, tiff.sublist(0, tailStart));
    final ifd0Offset = header.ifd0Offset;
    _writeU16(newTiff, ifd0Offset, n + 1, type);
    for (int i = 0; i < n; i++) {
      final e = ifd0Offset + 2 + i * entrySize;
      _writeU16(newTiff, e, ifd0.tags[i], type);
      _writeU16(newTiff, e + 2, ifd0.types[i], type);
      _writeU32(newTiff, e + 4, ifd0.counts[i], type);
      final value = ifd0.tags[i] == _tagExifIfd
          ? ifd0.values[i] + entrySize
          : ifd0.values[i];
      _writeU32(newTiff, e + 8, value, type);
    }
    // New GPSInfo entry
    final gpsEntryOffset = ifd0Offset + 2 + n * entrySize;
    _writeU16(newTiff, gpsEntryOffset, _tagGpsInfo, type);
    _writeU16(newTiff, gpsEntryOffset + 2, 4, type); // LONG
    _writeU32(newTiff, gpsEntryOffset + 4, 1, type);
    _writeU32(newTiff, gpsEntryOffset + 8, gpsIfdOffset, type);
    // Next-IFD pointer (0)
    _writeU32(newTiff, gpsEntryOffset + entrySize, 0, type);

    // Tail (Exif IFD + its data) moved by one entry
    newTiff.setAll(tailStart + entrySize, tail);

    // GPS IFD + data at the very end
    newTiff.setAll(gpsIfdOffset, gpsBlock);

    // Rebuild the full JPEG: SOI + APP1 (patched) + original after segment
    final patchedSegment = _buildExifSegmentFromTiff(newTiff);

    final out = Uint8List(jpeg.length - segment.data.length + patchedSegment.length);
    out.setAll(0, jpeg.sublist(0, segment.offset));
    out.setAll(segment.offset, patchedSegment);
    out.setAll(
      segment.offset + patchedSegment.length,
      jpeg.sublist(segment.offset + segment.data.length),
    );
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
    final ifd0Offset = 8;
    // IFD0: Exif pointer + GPS pointer (+ next ptr) = 2 entries
    final exifIfdOffset = ifd0Offset + 2 + 2 * 12 + 4;
    final gpsIfdOffset = exifIfdOffset + 2 + 1 * 12 + 4;
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
  }) {
    const type = 0; // little endian
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
      [0x0000, 1, 4, 0x02030000], // GPSVersionID 2.3.0.0 (bytes 02 03 00 00)
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
        _writeU32(b, e + 8, entry[3], type);
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
  }) {
    final decimalLat = latitude.abs();
    final latDeg = decimalLat.floor();
    final latMinFull = (decimalLat - latDeg) * 60;
    final latMin = latMinFull.floor();
    final latSec = (latMinFull - latMin) * 60;

    final decimalLng = longitude.abs();
    final lngDeg = decimalLng.floor();
    final lngMinFull = (decimalLng - lngDeg) * 60;
    final lngMin = lngMinFull.floor();
    final lngSec = (lngMinFull - lngMin) * 60;

    var offset = dataOffset;
    for (final entry in entries) {
      final byteCount = _typeSize(entry[1]) * entry[2];
      if (byteCount <= 4) continue;
      if (entry[0] == 0x0002) { // GPSLatitude
        _writeRational(block, offset, latDeg, 1);
        offset += 8;
        _writeRational(block, offset, latMin, 1);
        offset += 8;
        final sec = _roundSec(latSec);
        _writeRational(block, offset, sec.num, sec.den);
        offset += 8;
      } else if (entry[0] == 0x0004) { // GPSLongitude
        _writeRational(block, offset, lngDeg, 1);
        offset += 8;
        _writeRational(block, offset, lngMin, 1);
        offset += 8;
        final sec = _roundSec(lngSec);
        _writeRational(block, offset, sec.num, sec.den);
        offset += 8;
      } else if (entry[0] == 0x0006) { // GPSAltitude
        _writeRational(block, offset, ((altitude ?? 0).abs() * 100).round(), 100);
        offset += 8;
      } else if (entry[0] == 0x0007) { // GPSTimeStamp
        final utc = capturedAt?.toUtc() ?? DateTime.now().toUtc();
        _writeRational(block, offset, utc.hour, 1);
        offset += 8;
        _writeRational(block, offset, utc.minute, 1);
        offset += 8;
        final sec = _roundSec(utc.second.toDouble());
        _writeRational(block, offset, sec.num, sec.den);
        offset += 8;
      }
    }
  }

  static ({int num, int den}) _roundSec(double seconds) {
    final rounded = (seconds * 10000).round();
    return (num: rounded, den: 10000);
  }

  static void _writeRational(Uint8List b, int offset, int numerator, int denominator) {
    _writeU32(b, offset, numerator, 0);
    _writeU32(b, offset + 4, denominator, 0);
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
