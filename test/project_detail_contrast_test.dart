import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';
import 'package:mapbanai/ui/common/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('editable project cards have readable contrast in $brightness',
        (tester) async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      await db.createProject('Contrast project');
      final project = (await db.getProjects()).single;
      await tester.pumpWidget(ChangeNotifierProvider(
          create: (_) => ProjectState(),
          child: MaterialApp(
              theme: MapBanaiTheme.create(brightness),
              home: ProjectDetailScreen(projectId: project.id, database: db))));
      await tester.pumpAndSettle();
      for (final text in ['No description', '0 surveys · 0 map records']) {
        final finder = find.text(text);
        expect(finder, findsOneWidget);
        final widget = tester.widget<Text>(finder);
        final container = tester.widget<Container>(
            find.ancestor(of: finder, matching: find.byType(Container)).first);
        final background = (container.decoration as BoxDecoration).color!;
        final foreground = widget.style!.color!;
        final a = foreground.computeLuminance(),
            b = background.computeLuminance();
        expect((math.max(a, b) + .05) / (math.min(a, b) + .05),
            greaterThanOrEqualTo(4.5));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
