import 'dart:convert';
import 'dart:typed_data';

/// Accepts only the two image formats emitted by the local atlas studio.
class AtlasImageExport {
  final String name;
  final String mimeType;
  final Uint8List bytes;
  const AtlasImageExport._(this.name, this.mimeType, this.bytes);
  static AtlasImageExport fromMessage(Map<String, dynamic> data) {
    final name = data['name'];
    final mime = data['type'];
    if (!((name == 'mapbanai-map.png' && mime == 'image/png') ||
        (name == 'mapbanai-map.jpg' && mime == 'image/jpeg'))) {
      throw const FormatException('Unsupported image format');
    }
    final content = data['content'];
    final prefix = 'data:$mime;base64,';
    if (content is! String ||
        !content.startsWith(prefix) ||
        content.length > 32 * 1024 * 1024) {
      throw const FormatException('Invalid or oversized image');
    }
    final bytes = base64Decode(content.substring(prefix.length));
    final png = bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10;
    final jpeg = bytes.length >= 4 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[bytes.length - 2] == 255 &&
        bytes.last == 217;
    if ((mime == 'image/png' && !png) || (mime == 'image/jpeg' && !jpeg)) {
      throw const FormatException('Image bytes do not match the format');
    }
    return AtlasImageExport._(name as String, mime as String, bytes);
  }
}
