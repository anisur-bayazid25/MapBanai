import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mapbanai/services/atlas_image_export.dart';

void main() {
  for (final png in [true, false]) {
    test('native export retains ${png ? 'PNG' : 'JPEG'} bytes and MIME', () {
      final image = img.Image(width: 3, height: 2);
      final bytes = png ? img.encodePng(image) : img.encodeJpg(image);
      final mime = png ? 'image/png' : 'image/jpeg';
      final result = AtlasImageExport.fromMessage({
        'name': png ? 'mapbanai-map.png' : 'mapbanai-map.jpg',
        'type': mime,
        'content': 'data:$mime;base64,${base64Encode(bytes)}'
      });
      expect(result.bytes, bytes);
      expect(result.mimeType, mime);
      expect(img.decodeImage(result.bytes)!.width, 3);
    });
  }
  test('native export rejects filenames, formats and invalid image payloads',
      () {
    for (final data in [
      {'name': '../map.png', 'type': 'image/png', 'content': ''},
      {'name': 'mapbanai-map.jpg', 'type': 'image/png', 'content': ''},
      {
        'name': 'mapbanai-map.png',
        'type': 'image/png',
        'content': 'data:image/png;base64,aGVsbG8='
      },
      {
        'name': 'mapbanai-map.png',
        'type': 'image/png',
        'content': 'https://example.org/image.png'
      }
    ]) {
      expect(() => AtlasImageExport.fromMessage(data), throwsFormatException);
    }
  });
}
