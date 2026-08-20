import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:zxing2/qrcode.dart';

/// Scans a MapBanai project QR code with the phone camera.
///
/// This intentionally avoids a native scanning plugin (the project builds
/// with AGP 8.1/Gradle 8.3, which modern ML-Kit scanners require bumping):
/// we capture a photo with the already-present [ImagePicker] and decode it
/// with the pure-Dart ZXing port in [zxing2].
class QrScanner {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the camera, takes a photo of a project QR code and returns the
  /// decoded payload.
  ///
  /// Throws [QrScanException] with a user-friendly [message] when the camera
  /// is unavailable, the photo cannot be read, or no QR code was found.
  static Future<String> scanFromCamera() async {
    final XFile? shot;
    try {
      shot = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );
    } catch (error) {
      throw QrScanException(
        'Could not open the camera. Please paste the project code instead.',
        error,
      );
    }
    if (shot == null) {
      throw const QrScanException('No photo was captured.');
    }
    return decodeFromFile(File(shot.path));
  }

  /// Decodes a QR payload from an image file. Pure Dart, unit-testable.
  static String decodeFromFile(File file) {
    final img.Image? image;
    try {
      image = img.decodeImage(file.readAsBytesSync());
    } catch (error) {
      throw QrScanException('Could not read the captured photo.', error);
    }
    if (image == null) {
      throw const QrScanException('Could not read the captured photo.');
    }

    final oriented = img.bakeOrientation(image);
    final pixels = oriented
        .convert(numChannels: 4)
        .getBytes(order: img.ChannelOrder.abgr)
        .buffer
        .asInt32List();
    final source = RGBLuminanceSource(
      oriented.width,
      oriented.height,
      pixels,
    );

    var text = _decode(source);
    text ??= _decode(InvertedLuminanceSource(source));
    if (text == null) {
      throw const QrScanException(
        'No QR code was found in the photo. Take another shot with the '
        'full code in frame and in focus.',
      );
    }
    return text.trim();
  }

  static String? _decode(LuminanceSource source) {
    final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
    try {
      return QRCodeReader().decode(bitmap).text;
    } catch (_) {
      return null;
    }
  }
}

/// A QR scan that could not complete, with a message safe to show the user.
class QrScanException implements Exception {
  const QrScanException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}