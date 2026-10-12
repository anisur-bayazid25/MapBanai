import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/survey_logic.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

SurveyForm form(List<Question> questions) =>
    SurveyForm(id: 'test', name: 'Test', description: '', questions: questions);

Future<void> pump(WidgetTester tester, SurveyForm form,
        {FutureOr<void> Function(Map<String, dynamic>)? save,
        VoidCallback? complete}) =>
    tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SurveyFormRenderer(
                form: form, onSave: save, onComplete: complete))));

void main() {
  testWidgets('survey geoshape captures and persists a GeoJSON polygon',
      (tester) async {
    Map<String, dynamic>? saved;
    await pump(
        tester,
        form([
          Question(
              name: 'boundary',
              label: 'Boundary',
              type: QuestionType.geoshape,
              required: true)
        ]),
        save: (answers) => saved = answers);
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('Draw on map'));
    final polygon = <String, dynamic>{
      'type': 'Polygon',
      'coordinates': [
        [
          [90.0, 23.0],
          [90.1, 23.0],
          [90.1, 23.1],
          [90.0, 23.0]
        ]
      ]
    };
    // Return a valid geometry through the picker route; map drawing itself
    // is verified by GeometryCaptureScreen tests.
    tester.state<NavigatorState>(find.byType(Navigator)).pop(polygon);
    await tester.pumpAndSettle();
    expect(find.text('Polygon captured'), findsOneWidget);
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved!['boundary'], polygon);
  });

  testWidgets('legacy repeated form cannot save flattened records',
      (tester) async {
    var saved = false;
    final repeated =
        SurveyForm(id: 'legacy', name: 'Legacy', description: '', groups: [
      const GroupInfo(name: 'members', isRepeat: true)
    ], questions: [
      Question(
          name: 'member',
          label: 'Member',
          type: QuestionType.text,
          groupPath: ['members'])
    ]);
    await pump(tester, repeated, save: (_) => saved = true);
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    expect(find.textContaining('unsupported repeats'), findsOneWidget);
  });

  testWidgets('username defaults from operator setting and remains editable',
      (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SurveyFormRenderer(
                initialUsername: 'Operator',
                form: form([
                  Question(
                      name: 'operator',
                      label: 'Operator',
                      type: QuestionType.text,
                      metadataType: 'username')
                ]),
                onSave: (answers) => saved = answers))));
    expect(find.text('Operator'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Corrected operator');
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved!['operator'], 'Corrected operator');
  });

  test('cross-field constraint uses the other answers', () {
    expect(
        SurveyLogic.evaluateConstraint(r'. <= ${maximum}', 10, 'Too high',
            answers: {'maximum': 20}),
        isNull);
    expect(
        SurveyLogic.evaluateConstraint(r'. <= ${maximum}', 30, 'Too high',
            answers: {'maximum': 20}),
        'Too high');
  });

  testWidgets('date default is editable and picker opens on existing date',
      (tester) async {
    Map<String, dynamic>? saved;
    await pump(
        tester,
        form([
          Question(
              name: 'date',
              label: 'Visit date',
              type: QuestionType.date,
              defaultValue: '1995-02-03')
        ]),
        save: (answers) => saved = answers);
    expect(find.text('1995-02-03'), findsOneWidget);
    await tester.tap(find.text('1995-02-03'));
    await tester.pumpAndSettle();
    final picker =
        tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.initialDate, DateTime(1995, 2, 3));
    await tester.tap(find.text('4').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('1995-02-04'), findsOneWidget);
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved!['date'], '1995-02-04');
  });

  testWidgets('time picker initializes from existing answer and saves ISO time',
      (tester) async {
    Map<String, dynamic>? saved;
    await pump(
        tester,
        form([
          Question(
              name: 'time',
              label: 'Time',
              type: QuestionType.time,
              defaultValue: '16:35:00')
        ]),
        save: (answers) => saved = answers);
    await tester.tap(find.text('16:35:00'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TimePickerDialog>(find.byType(TimePickerDialog))
            .initialTime,
        const TimeOfDay(hour: 16, minute: 35));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved!['time'], '16:35:00');
  });

  testWidgets(
      'date default today evaluates once; read-only date cannot open picker',
      (tester) async {
    await pump(
        tester,
        form([
          Question(
              name: 'date',
              label: 'Date',
              type: QuestionType.date,
              defaultValue: 'today()',
              readOnly: true)
        ]));
    final dateText = DateTime.now().toIso8601String().split('T').first;
    expect(find.text(dateText), findsOneWidget);
    await tester.tap(find.text(dateText), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets(
      'nontext defaults are saved and empty multiselect cannot satisfy required',
      (tester) async {
    Map<String, dynamic>? saved;
    await pump(
        tester,
        form([
          Question(
              name: 'hidden',
              label: 'Hidden',
              type: QuestionType.hidden,
              defaultValue: 'source'),
          Question(
              name: 'choice',
              label: 'Choices',
              type: QuestionType.select_multiple,
              required: true,
              choices: [Choice(name: 'a', label: 'A')]),
        ]),
        save: (answers) => saved = answers);
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(saved!['hidden'], 'source');
    expect(saved!['choice'], ['a']);
  });

  testWidgets('save waits for persistence and prevents double submit',
      (tester) async {
    final pending = Completer<void>();
    var saves = 0;
    var completed = 0;
    await pump(tester,
        form([Question(name: 'text', label: 'Text', type: QuestionType.text)]),
        save: (_) {
          saves++;
          return pending.future;
        },
        complete: () => completed++);
    await tester.tap(find.text('Save responses'));
    await tester.pump();
    await tester.tap(find.text('Save responses'));
    expect(saves, 1);
    expect(completed, 0);
    pending.complete();
    await tester.pumpAndSettle();
    expect(completed, 1);
  });

  testWidgets('failed persistence preserves answers and keeps form open',
      (tester) async {
    var completed = false;
    await pump(tester,
        form([Question(name: 'text', label: 'Text', type: QuestionType.text)]),
        save: (_) async => throw StateError('disk full'),
        complete: () => completed = true);
    await tester.enterText(find.byType(TextField), 'Keep this');
    await tester.tap(find.text('Save responses'));
    await tester.pumpAndSettle();
    expect(completed, isFalse);
    expect(find.text('Keep this'), findsOneWidget);
    expect(find.textContaining('Your answers are still here'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.byWidgetPredicate((widget) => widget is FilledButton))
            .onPressed,
        isNotNull);
  });
}
