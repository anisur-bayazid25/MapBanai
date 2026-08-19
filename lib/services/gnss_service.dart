import 'package:flutter/services.dart';

class GnssSnapshot {
  const GnssSnapshot({required this.inView, required this.inUse});

  final int inView;
  final int inUse;
}

class GnssService {
  GnssService._();

  static const MethodChannel _channel = MethodChannel('mapbanai/gnss');

  static Future<GnssSnapshot?> fetch() async {
    try {
      final data =
          await _channel.invokeMapMethod<String, dynamic>('getSatellites');
      if (data == null) return null;
      return GnssSnapshot(
        inView: (data['inView'] as num?)?.toInt() ?? 0,
        inUse: (data['inUse'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
