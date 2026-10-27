import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/ui/common/confirm_field_data_removal.dart';

void main() {
  for (final pending in [0, 3]) {
    testWidgets(
        'removal requires project name and acknowledgement of $pending unsynced records',
        (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        result = await confirmFieldDataRemoval(context,
                            title: 'Clear study layer',
                            projectName: 'Dhaka',
                            details: '2 map points',
                            pendingCount: pending);
                      },
                      child: const Text('Review'))))));
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      FilledButton button() => tester
          .widget(find.byKey(const ValueKey('confirm-field-data-removal')));
      expect(button().onPressed, isNull);
      await tester.enterText(
          find.byKey(const ValueKey('removal-project-name')), 'Wrong project');
      expect(button().onPressed, isNull);
      await tester.enterText(
          find.byKey(const ValueKey('removal-project-name')), 'Dhaka');
      await tester.pump();
      if (pending > 0) {
        expect(button().onPressed, isNull);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
      }
      expect(button().onPressed, isNotNull);
      await tester
          .tap(find.byKey(const ValueKey('confirm-field-data-removal')));
      await tester.pumpAndSettle();
      expect(result, true);
      expect(tester.takeException(), isNull);
    });
  }
}
