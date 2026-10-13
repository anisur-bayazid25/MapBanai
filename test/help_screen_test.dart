import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/ui/help_screen.dart';

void main() {
  testWidgets(
      'offline help copies complete backend with the selected project ID',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const MaterialApp(
        home: HelpScreen(projectId: 'project-for-this-team')));
    expect(find.text('This project ID: project-for-this-team'), findsOneWidget);
    final codeSection = find.text('Code.gs — copy complete code');
    await tester.scrollUntilVisible(codeSection, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(codeSection);
    await tester.pumpAndSettle();
    final copy = find.text('Copy Code.gs');
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, contains("projectId: 'project-for-this-team'"));
    expect(copied, contains('function doPost(e)'));
    expect(copied, contains('function setupMapBanai()'));
    expect(
        copied, contains(RegExp(r"body\.action\s*===\s*'get_questionnaire'")));
    expect(copied, contains(RegExp(r"'sync_data',\s*'upload_photo'")));
    expect(copied, isNot(contains('PASTE_PROJECT_ID_FROM_MAPBANAI')));
    expect(tester.takeException(), isNull);
  });
}
