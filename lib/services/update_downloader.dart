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
    final sourceFile = File('${partFile.path}.url');
    await directory.create(recursive: true);
    // Never append bytes from a different release to the new APK.
    if (!await sourceFile.exists() || await sourceFile.readAsString() != url) {
      if (await partFile.exists()) await partFile.delete();
      await sourceFile.writeAsString(url, flush: true);
    }

    // Network chunks can arrive hundreds of times a second. Rebuilding the
    // dialog for each one creates unnecessary work on the phone's UI isolate.
    final progressClock = Stopwatch()..start();
    var lastProgressAt = -200;
    void reportProgress(double value) {
      final now = progressClock.elapsedMilliseconds;
      if (value == 1 || now - lastProgressAt >= 200) {
        lastProgressAt = now;
        onProgress?.call(value);
      }
    }

    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final file = await _attempt(url, partFile, finalFile, reportProgress);
        await sourceFile.delete();
        return file;
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

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['Accept-Encoding'] = 'identity';
      if (offset > 0) {
        request.headers['Range'] = 'bytes=$offset-';
      }
      final streamed =
          await client.send(request).timeout(const Duration(seconds: 30));
      if (streamed.statusCode == 416) {
        // A saved partial file may already contain the complete response, or
        // the server's asset may have changed. Restart safely on the next try.
        if (await partFile.exists()) await partFile.delete();
        throw const HttpException(
            'Saved download range is no longer available.');
      }
      if (streamed.statusCode != 200 && streamed.statusCode != 206) {
        throw HttpException('Download failed: HTTP ${streamed.statusCode}');
      }

      if (streamed.statusCode == 200) {
        // Server ignored the Range header (or this is a fresh download):
        // start over from byte zero.
        offset = 0;
      }

      if (streamed.statusCode == 206) {
        final range = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$')
            .firstMatch(streamed.headers['content-range'] ?? '');
        if (range == null ||
            int.parse(range[1]!) != offset ||
            int.parse(range[2]!) < offset ||
            int.parse(range[2]!) + 1 != int.parse(range[3]!) ||
            (streamed.contentLength != null &&
                streamed.contentLength != int.parse(range[3]!) - offset)) {
          if (await partFile.exists()) await partFile.delete();
          throw const HttpException(
              'Server returned an invalid download range.');
        }
      }

      final remaining = streamed.contentLength ?? 0;
      final expected = remaining <= 0 ? 0 : offset + remaining;
      var received = offset;

      final sink = partFile.openWrite(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
      try {
        // addStream applies disk backpressure instead of queuing the whole APK
        // in memory when network delivery is faster than device storage.
        await sink.addStream(
            streamed.stream.timeout(const Duration(seconds: 45)).map((chunk) {
          received += chunk.length;
          if (expected > 0 && received < expected) {
            onProgress?.call(received / expected);
          }
          return chunk;
        }));
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
    } finally {
      client.close();
    }
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
