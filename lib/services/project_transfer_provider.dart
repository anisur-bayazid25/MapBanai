import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Abstraction over project-transfer channels.
///
/// Only the native Android share sheet is implemented today
/// ([NativeShareProvider]); it already reaches Quick Share/Bluetooth,
/// WhatsApp, email and every other ACTION_SEND target on the device and
/// works fully offline. Future transports (local Wi-Fi/LAN, Bluetooth,
/// Nearby) plug in behind the same interface without touching the package
/// format, exporter or importer.
abstract class ProjectTransferProvider {
  String get id;

  String get displayName;

  /// Whether the transport is usable on this device/state.
  Future<bool> isAvailable();

  /// Sends the .mbproj file. Returns true when the transfer was accepted
  /// by the transport (or target picker was shown).
  Future<bool> shareProjectFile(File file, {String? title});
}

/// Native ACTION_SEND implementation (share sheet → any installed app).
class NativeShareProvider implements ProjectTransferProvider {
  @override
  String get id => 'native_share';

  @override
  String get displayName => 'Share with Android (WhatsApp, email, ...)';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> shareProjectFile(File file, {String? title}) async {
    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.mapbanai.project')],
      text: title == null ? 'MapBanai project' : 'MapBanai project: $title',
      subject: title ?? 'MapBanai project',
    );
    return result.status != ShareResultStatus.dismissed;
  }
}

/// Registry listing every implemented provider. The first available
/// provider is used by the UI; sharing through the native sheet already
/// reaches all local/offline targets.
class ProjectTransferProviders {
  static List<ProjectTransferProvider> available() {
    final providers = <ProjectTransferProvider>[NativeShareProvider()];
    return providers;
  }
}