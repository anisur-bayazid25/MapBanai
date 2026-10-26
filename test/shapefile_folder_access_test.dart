import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/ui/common/shapefile_companions.dart';

void main() {
  const channel = MethodChannel('mapbanai/shapefile_folders');
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
      'a previously granted Android folder supplies companions for a cached SHP',
      (tester) async {
    final files = <String, Uint8List>{
      'sites.shp': Uint8List.fromList([0])
    };
    bool? result;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'readGranted');
      expect(call.arguments['identifiers'],
          ['content://example/document/primary:maps/sites.shp']);
      return {
        'SITES.DBF': Uint8List.fromList([1, 2, 3]),
        'sites.cpg': Uint8List.fromList([85, 84, 70])
      };
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await resolveShapefileCompanions(
                          context, files, [], identifiers: [
                        'content://example/document/primary:maps/sites.shp'
                      ]);
                    },
                    child: const Text('Import'))))));
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(files['SITES.DBF'], [1, 2, 3]);
    expect(find.byType(AlertDialog), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'choosing an Android folder reads companions through the document channel',
      (tester) async {
    final files = <String, Uint8List>{
      'sites.shp': Uint8List.fromList([0])
    };
    bool? result;
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'readGranted'
          ? {}
          : {
              'sites.dbf': Uint8List.fromList([4, 5])
            };
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result =
                          await resolveShapefileCompanions(context, files, []);
                    },
                    child: const Text('Import'))))));
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose folder'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(files['sites.dbf'], [4, 5]);
    expect(calls, ['readGranted', 'chooseFolder']);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('cancelling the native folder selection cancels the import',
      (tester) async {
    final files = <String, Uint8List>{
      'sites.shp': Uint8List.fromList([0])
    };
    bool? result;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel, (call) async => call.method == 'readGranted' ? {} : null);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result =
                          await resolveShapefileCompanions(context, files, []);
                    },
                    child: const Text('Import'))))));
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose folder'));
    await tester.pumpAndSettle();
    expect(result, false);
    expect(files.length, 1);
    debugDefaultTargetPlatformOverride = null;
  });
}
