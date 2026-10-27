import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/ui/common/user_name_dialog.dart';

void main() {
  for (final welcome in [true, false]) {
    testWidgets(
        'name dialog saves while keyboard and closing route are active: welcome=$welcome',
        (tester) async {
      String? saved;
      await tester.pumpWidget(MaterialApp(
          home: StatefulBuilder(
              builder: (context, update) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        final name = await showDialog<String>(
                            context: context,
                            builder: (_) => UserNameDialog(
                                welcome: welcome, initialName: 'Previous'));
                        update(() => saved = name);
                      },
                      child: Text(saved ?? 'Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '  Fieldworker  ');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(saved, 'Fieldworker');
      expect(find.byType(UserNameDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
