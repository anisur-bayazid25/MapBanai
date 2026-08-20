import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/update_downloader.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('update-test-');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('downloads complete payload to the final .apk', () async {
    final payload = _makePayload(5000);
    final server = await _serve(
      payload,
      dropAfter: null,
      log: (_) {},
    );
    try {
      double? lastProgress;
      final file = await UpdateDownloader.download(
        'http://127.0.0.1:${server.port}/app.apk',
        downloadDir: tempDir,
        onProgress: (p) => lastProgress = p,
      );
      expect(lastProgress, 1);
      expect(file.path, endsWith('mapbanai-update.apk'));
      expect(file.readAsBytesSync(), payload);
      expect(
        File('${tempDir.path}${Platform.pathSeparator}mapbanai-update.apk.part')
            .existsSync(),
        isFalse,
      );
    } finally {
      await server.close(force: true);
    }
  });

  test('resumes from a dropped connection and still completes', () async {
    // 1 MB payload; the server drops the connection after the first 512
    // bytes on the first request, then serves the remainder when asked
    // with a Range header. This is the "99% then network error" scenario.
    final payload = _makePayload(1024 * 1024 + 137);
    final requests = <String>[];
    final server = await _serve(
      payload,
      dropAfter: 512,
      log: (range) => requests.add(range ?? ''),
    );
    try {
      final file = await UpdateDownloader.download(
        'http://127.0.0.1:${server.port}/app.apk',
        downloadDir: tempDir,
      );
      final bytes = file.readAsBytesSync();
      expect(bytes.length, payload.length);
      expect(bytes, payload);
      expect(requests.length, greaterThanOrEqualTo(2));
      expect(requests.last, 'bytes=512-');
    } finally {
      await server.close(force: true);
    }
  });

  test('rejects a non-200 response', () async {
    final requests = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      requests.add(req.uri.path);
      req.response.statusCode = 404;
      req.response.write('nope');
      req.response.close();
    });
    try {
      await expectLater(
        UpdateDownloader.download(
          'http://127.0.0.1:${server.port}/missing.apk',
          downloadDir: tempDir,
        ),
        throwsA(isA<HttpException>()),
      );
    } finally {
      await server.close(force: true);
    }
  });
}

Uint8List _makePayload(int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = (i * 31 + 7) & 0xff;
  }
  return bytes;
}

Future<HttpServer> _serve(
  Uint8List payload, {
  required int? dropAfter,
  required void Function(String? range) log,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    var start = 0;
    final range = req.headers.value('range');
    log(range);
    if (range != null) {
      final match = RegExp(r'bytes=(\d+)-').firstMatch(range);
      if (match != null) {
        start = int.parse(match.group(1)!);
      }
    }
    if (start == 0 && dropAfter != null && dropAfter < payload.length) {
      // Announce the full length, write only a slice, then drop the raw
      // socket — exactly what happens when a slow network dies mid-body.
      req.response.contentLength = payload.length;
      final socket = await req.response.detachSocket();
      socket.add(payload.sublist(0, dropAfter));
      await socket.flush();
      socket.destroy();
      return;
    }
    req.response.statusCode = start == 0 ? 200 : 206;
    req.response.add(payload.sublist(start));
    req.response.close();
  });
  return server;
}