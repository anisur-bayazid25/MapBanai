import 'package:flutter/services.dart';

/// Receives the incoming VIEW intent payload from Android's native side
/// (MainActivity.kt "mapbanai/intents" channel):
///
///  * a .mbproj file opened from another app → native side already copied
///    the content into the cache and reports a plain file path;
///  * a `mapbanai://project/...` deep link or an https://...mbproj URL →
///    the raw string.
class IntentHandler {
  IntentHandler._();

  static const MethodChannel _channel = MethodChannel('mapbanai/intents');

  static Future<String?> getInitialOpen() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getInitialOpen',
      );
      if (result == null) return null;
      final uri = result['uri'];
      return uri is String && uri.isNotEmpty ? uri : null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }
}