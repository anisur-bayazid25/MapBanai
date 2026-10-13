import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());
  Future<void> check(http.Client client,
          {String endpoint = 'https://script.google.com/macros/s/test/exec'}) =>
      CloudSyncService(db, client: client).testConnection(
          endpoint: endpoint, apiKey: 'key', projectId: 'project');
  test(
      'connection POST verifies credentials and follows content redirect by GET',
      () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      if (requests == 1) {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'action': 'test_connection',
          'projectId': 'project',
          'apiKey': 'key'
        });
        return http.Response('', 302, headers: {
          'location': 'https://script.googleusercontent.com/result'
        });
      }
      expect(request.method, 'GET');
      expect(request.body, isEmpty);
      return http.Response('{"ok":true,"connectionVerified":true}', 200);
    });
    await check(client);
    expect(requests, 2);
    client.close();
  });
  test('rejects developer URL before any credential request', () async {
    final client = MockClient((_) async => throw StateError('must not send'));
    await expectLater(
        check(client, endpoint: 'https://script.google.com/macros/s/test/dev'),
        throwsA(isA<CloudSyncException>()
            .having((e) => e.message, 'message', contains('/exec'))));
    client.close();
  });
  for (final example in [
    ('<html>accounts.google.com/ServiceLogin</html>', 'sign-in'),
    ('<html>Google error</html>', 'web page'),
    ('{"ok":false,"error":"Unknown action."}', 'older script'),
    (
      '{"ok":false,"error":"Project ID or API key does not match."}',
      'does not match'
    ),
    ('{"ok":true}', 'did not verify'),
  ]) {
    test('explains connection failure: ${example.$2}', () async {
      final client = MockClient((_) async => http.Response(example.$1, 200));
      await expectLater(
          check(client),
          throwsA(isA<CloudSyncException>()
              .having((e) => e.message, 'message', contains(example.$2))));
      client.close();
    });
  }
}
