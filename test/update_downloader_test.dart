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

  test('does not resume bytes belonging to an older release', () async {
    final part = File('${tempDir.path}/mapbanai-update.apk.part');
    await part.writeAsBytes(_makePayload(900));
    await File('${part.path}.url').writeAsString('https://old.example/app.apk');
    final payload = _makePayload(2400);
    final ranges = <String?>[];
    final server = await _serve(payload, dropAfter: null, log: ranges.add);
    try {
      final file = await UpdateDownloader.download(
          'http://127.0.0.1:${server.port}/new.apk',
          downloadDir: tempDir);
      expect(ranges, [null]);
      expect(await file.readAsBytes(), payload);
      expect(await File('${part.path}.url').exists(), isFalse);
    } finally {
      await server.close(force: true);
    }
  });

  test('discards invalid Content-Range and retries from zero', () async {
    final payload = _makePayload(2400);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final url = 'http://127.0.0.1:${server.port}/app.apk';
    final part = File('${tempDir.path}/mapbanai-update.apk.part');
    await part.writeAsBytes(payload.sublist(0, 100));
    await File('${part.path}.url').writeAsString(url);
    final ranges = <String?>[];
    server.listen((request) async {
      ranges.add(request.headers.value('range'));
      if (ranges.length == 1) {
        request.response.statusCode = 206;
        request.response.headers.set('Content-Range', 'bytes 200-2399/2400');
        request.response.add(payload.sublist(200));
      } else {
        request.response.add(payload);
      }
      await request.response.close();
    });
    try {
      final file = await UpdateDownloader.download(url, downloadDir: tempDir);
      expect(ranges, ['bytes=100-', null]);
      expect(await file.readAsBytes(), payload);
    } finally {
      await server.close(force: true);
    }
  });

  test('restarts when the server ignores a saved range', () async {
    final payload = _makePayload(2400);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final url = 'http://127.0.0.1:${server.port}/app.apk';
    final part = File('${tempDir.path}/mapbanai-update.apk.part');
    await part.writeAsBytes(payload.sublist(0, 100));
    await File('${part.path}.url').writeAsString(url);
    server.listen((request) {
      request.response.add(payload);
      request.response.close();
    });
    try {
      final file = await UpdateDownloader.download(url, downloadDir: tempDir);
      expect(await file.readAsBytes(), payload);
    } finally {
      await server.close(force: true);
    }
  });

  test('throttles progress notifications while streaming many chunks',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    const chunks = 200;
    final payload = _makePayload(1024);
    server.listen((request) async {
      request.response.contentLength = payload.length * chunks;
      for (var i = 0; i < chunks; i++) {
        request.response.add(payload);
        await request.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await request.response.close();
    });
    try {
      final progress = <double>[];
      final elapsed = Stopwatch()..start();
      final file = await UpdateDownloader.download(
          'http://127.0.0.1:${server.port}/app.apk',
          downloadDir: tempDir,
          onProgress: progress.add);
      expect(await file.length(), payload.length * chunks);
      expect(progress.last, 1);
      expect(progress.length,
          lessThanOrEqualTo(elapsed.elapsedMilliseconds ~/ 200 + 3));
    } finally {
      await server.close(force: true);
    }
  });

  test('follows an HTTP redirect and still completes byte-identical', () async {
    // GitHub release URLs (github.com/.../download/...) 302-redirect to a
    // signed objects.githubusercontent.com asset. The client must follow the
    // redirect and then verify the final byte count, not the redirect URL.
    final payload = _makePayload(3000);
    final requests = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      requests.add(req.uri.path);
      if (req.uri.path == '/release/app.apk') {
        req.response.statusCode = 302;
        req.response.headers.set('Location', '/objects/app.apk');
        req.response.close();
        return;
      }
      req.response.add(payload);
      req.response.close();
    });
    try {
      double? lastProgress;
      final file = await UpdateDownloader.download(
        'http://127.0.0.1:${server.port}/release/app.apk',
        downloadDir: tempDir,
        onProgress: (p) => lastProgress = p,
      );
      expect(requests.first, '/release/app.apk');
      expect(requests.last, '/objects/app.apk');
      expect(lastProgress, 1);
      expect(file.readAsBytesSync(), payload);
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
    if (start > 0) {
      req.response.headers.set('Content-Range',
          'bytes $start-${payload.length - 1}/${payload.length}');
    }
    req.response.add(payload.sublist(start));
    req.response.close();
  });
  return server;
}
