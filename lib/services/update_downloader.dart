import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads the APK from a GitHub release and hands it to the Android
/// package installer via OpenFile.
class UpdateDownloader {
  static const String _fileName = 'mapbanai-update.apk';

  /// Downloads [url] to app storage. [onProgress] receives 0..1 values.
  /// Throws on HTTP errors.
  static Future<File> download(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final directory = await _downloadDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$_fileName',
    );

    final request = http.Request('GET', Uri.parse(url));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    if (streamed.statusCode != 200) {
      throw HttpException('Download failed: HTTP ${streamed.statusCode}');
    }

    final total = streamed.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call(received / total);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    onProgress?.call(1);
    return file;
  }

  /// Opens the downloaded file with the system installer.
  static Future<void> openInstaller(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open installer: ${result.message}');
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
