import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thrown when the device blocks installing apps from unknown sources
/// (Android 8+, `REQUEST_INSTALL_PACKAGES` not granted for MapBanai).
class InstallPermissionException implements Exception {
  const InstallPermissionException();

  @override
  String toString() =>
      'Your device is blocking installation from this app. Allow '
      '"Install unknown apps" for MapBanai, then try again.';
}

/// Downloads the APK from a GitHub release and hands it to the Android
/// package installer.
class UpdateDownloader {
  static const String _fileName = 'mapbanai-update.apk';
  static const int _maxAttempts = 3;

  /// Downloads [url] to app storage and returns the finished .apk file.
  /// [onProgress] receives 0..1 values. Throws on HTTP errors, incomplete
  /// downloads and I/O failures.
  ///
  /// The body is written to a `.part` file so a dropped connection (which
  /// previously showed "Download failed" near 99% on large APKs) resumes
  /// from the last byte instead of restarting. The final file is only
  /// produced after the byte count matches the server Content-Length and
  /// the partial file is renamed atomically.
  static Future<File> download(
    String url, {
    Directory? downloadDir,
    void Function(double progress)? onProgress,
  }) async {
    final directory = downloadDir ?? await _downloadDirectory();
    final partFile = File(p.join(directory.path, '$_fileName.part'));
    final finalFile = File(p.join(directory.path, _fileName));

    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _attempt(url, partFile, finalFile, onProgress);
      } on Exception catch (e) {
        // Covers dart:io HttpException/SocketException/FileSystemException,
        // package:http ClientException and TimeoutException. The partial
        // .part file is kept so the next attempt resumes.
        lastError = e;
      }
    }
    throw HttpException(
      'Download failed: $lastError. Please check your connection and try '
      'again (the download resumes where it stopped).',
    );
  }

  static Future<File> _attempt(
    String url,
    File partFile,
    File finalFile,
    void Function(double)? onProgress,
  ) async {
    var offset = 0;
    if (await partFile.exists()) {
      offset = await partFile.length();
    }

    final request = http.Request('GET', Uri.parse(url));
    if (offset > 0) {
      request.headers['Range'] = 'bytes=$offset-';
    }
    final streamed =
        await request.send().timeout(const Duration(seconds: 30));
    if (streamed.statusCode != 200 && streamed.statusCode != 206) {
      throw HttpException('Download failed: HTTP ${streamed.statusCode}');
    }

    if (streamed.statusCode == 200) {
      // Server ignored the Range header (or this is a fresh download):
      // start over from byte zero.
      offset = 0;
    }

    final remaining = streamed.contentLength ?? 0;
    final expected = remaining <= 0 ? 0 : offset + remaining;
    var received = offset;

    final sink = partFile.openWrite(
      mode: offset > 0 ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in streamed.stream
          .timeout(const Duration(seconds: 45))) {
        sink.add(chunk);
        received += chunk.length;
        if (expected > 0) onProgress?.call(received / expected);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (expected > 0 && received != expected) {
      throw const HttpException(
        'Connection closed before the download finished.',
      );
    }

    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await partFile.rename(finalFile.path);
    onProgress?.call(1);
    return finalFile;
  }

  /// Hands the downloaded package to the system installer over the
  /// `mapbanai/update` platform channel. Throws
  /// [InstallPermissionException] when "Install unknown apps" is not
  /// allowed for MapBanai yet.
  static Future<void> openInstaller(File file) async {
    try {
      await const MethodChannel('mapbanai/update').invokeMethod<void>(
        'openInstaller',
        {'path': file.path},
      );
    } on PlatformException catch (e) {
      if (e.code == 'install_permission') {
        throw const InstallPermissionException();
      }
      throw Exception(
        'Could not open the installer: ${e.message ?? e.code}.',
      );
    } on MissingPluginException {
      throw const InstallPermissionException();
    }
  }

  /// Opens the Android "Install unknown apps" settings screen for MapBanai.
  /// Returns true when the settings screen was launched.
  static Future<bool> requestInstallPermission() async {
    try {
      final allowed = await const MethodChannel('mapbanai/update')
          .invokeMethod<bool>('openInstallUnknownAppSources');
      return allowed ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Directory> _downloadDirectory() async {
    try {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    } catch (_) {
      // Fall through to the temporary directory.
    }
    return getTemporaryDirectory();
  }
}
