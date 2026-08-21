import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';
import 'package:mapbanai/ui/project_setup_screen.dart';
import 'package:provider/provider.dart';

Future<void> _pumpSetup(
  WidgetTester tester,
  AppDatabase db,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ProjectState(),
      child: MaterialApp(
        home: ProjectSetupScreen(database: db),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('create project shows in list, then settings update name',
      (tester) async {
    await _pumpSetup(tester, db);
    expect(find.text('No projects yet. Create one to start collecting data.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Riverbank Survey');
    await tester.tap(find.text('Create project'));
    await tester.pumpAndSettle();

    expect(find.text('Project created: Riverbank Survey'), findsOneWidget);
    expect(await db.getProjectByName('Riverbank Survey'), isNotNull);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('Riverbank Survey'), findsWidgets);

    await tester.tap(find.text('Edit project name'));
    await tester.pumpAndSettle();
    expect(find.text('Project name'), findsNWidgets(2));

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller != null,
      ).last,
      'Riverbank North',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Riverbank North'), findsWidgets);
    expect(await db.getProjectByName('Riverbank North'), isNotNull);
  });

  testWidgets('duplicate project name shows error snackbar', (tester) async {
    await db.createProject('Riverbank Survey');
    await _pumpSetup(tester, db);

    await tester.enterText(find.byType(TextField), 'Riverbank Survey');
    await tester.tap(find.text('Create project'));
    await tester.pumpAndSettle();

    expect(
      find.text('A project named "Riverbank Survey" already exists'),
      findsOneWidget,
    );
    expect(await db.getProjects(), hasLength(1));
  });

  testWidgets('archive and restore from detail screen', (tester) async {
    await db.createProject('Riverbank Survey');
    final project = await db.getProjectByName('Riverbank Survey');

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ProjectState(),
        child: MaterialApp(
          home: ProjectDetailScreen(
            projectId: project!.id,
            database: db,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Archive project'),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axis == Axis.vertical,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive project'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('It will be hidden from project setup'),
      findsOneWidget,
    );
    expect(find.text('Archive'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Project archived'), findsOneWidget);
    expect((await db.getProjectByName('Riverbank Survey'))!.archived, isTrue);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();
    expect((await db.getProjectByName('Riverbank Survey'))!.archived, isFalse);
  });
}