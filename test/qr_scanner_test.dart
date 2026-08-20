import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mapbanai/services/qr_scanner.dart';
import 'package:zxing2/qrcode.dart';

void main() {
  group('QrScanner', () {
    test('decodes a rendered QR payload (round trip)', () {
      // A realistic MapBanai inline payload: base64url of a zlib envelope.
      const payload =
          'MBN1#eJzrDPBz5+WS4mJgYGBgZGBgYGBrzMvLL83NzMnUSwQyeCAAA5YFEg==:::::MBN';
      final code = Encoder.encode(payload, ErrorCorrectionLevel.m);
      final matrix = code.matrix!;

      const scale = 8;
      const quietModules = 4;
      const quiet = quietModules * scale;
      final size = matrix.width * scale + 2 * quiet;
      final image = img.Image(width: size, height: size);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      for (var y = 0; y < matrix.height; y++) {
        for (var x = 0; x < matrix.width; x++) {
          if (matrix.get(x, y) == 1) {
            img.fillRect(
              image,
              x1: quiet + x * scale,
              y1: quiet + y * scale,
              x2: quiet + x * scale + scale,
              y2: quiet + y * scale + scale,
              color: img.ColorRgb8(0, 0, 0),
            );
          }
        }
      }

      final tmp = Directory.systemTemp.createTempSync('qrscan-test-');
      final file = File('${tmp.path}${Platform.pathSeparator}code.png');
      file.writeAsBytesSync(img.encodePng(image));
      try {
        expect(QrScanner.decodeFromFile(file), payload);
      } finally {
        tmp.deleteSync(recursive: true);
      }
    });

    test('throws QrScanException when no QR code is present', () {
      final tmp = Directory.systemTemp.createTempSync('qrscan-test-');
      final file = File('${tmp.path}${Platform.pathSeparator}blank.png');
      file.writeAsBytesSync(
        img.encodePng(img.Image(width: 128, height: 128)),
      );
      try {
        expect(
          () => QrScanner.decodeFromFile(file),
          throwsA(isA<QrScanException>()),
        );
      } finally {
        tmp.deleteSync(recursive: true);
      }
    });

    test('trims whitespace around the decoded payload', () {
      final code = Encoder.encode('  hello  ', ErrorCorrectionLevel.l);
      final matrix = code.matrix!;
      const scale = 4;
      const quiet = 6 * scale;
      final size = matrix.width * scale + 2 * quiet;
      final image = img.Image(width: size, height: size);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      for (var y = 0; y < matrix.height; y++) {
        for (var x = 0; x < matrix.width; x++) {
          if (matrix.get(x, y) == 1) {
            img.fillRect(
              image,
              x1: quiet + x * scale,
              y1: quiet + y * scale,
              x2: quiet + x * scale + scale,
              y2: quiet + y * scale + scale,
              color: img.ColorRgb8(0, 0, 0),
            );
          }
        }
      }
      final tmp = Directory.systemTemp.createTempSync('qrscan-test-');
      final file = File('${tmp.path}${Platform.pathSeparator}code.png');
      file.writeAsBytesSync(img.encodePng(image));
      try {
        expect(QrScanner.decodeFromFile(file), 'hello');
      } finally {
        tmp.deleteSync(recursive: true);
      }
    });
  });
}