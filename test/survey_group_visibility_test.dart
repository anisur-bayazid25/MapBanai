import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

/// Regression tests for the UGGP-form bug report (v2.4.3):
/// answering "no" on the interview-outcome question must hide the gated
/// module, and `<span style="color:…">` labels must render styled instead
/// of showing raw HTML.
SurveyForm _gatedForm() => SurveyForm(
      id: 'gated',
      name: 'Gated form',
      description: '',
      groups: [
        const GroupInfo(
          name: 'module_b',
          label: 'Module B',
          relevance: "\${a12} = '1'",
        ),
      ],
      questions: [
        Question(
          name: 'a12',
          label: 'Outcome of the Interview',
          type: QuestionType.select_one,
          choices: [
            Choice(name: '1', label: 'Completed'),
            Choice(name: '2', label: 'Not completed'),
          ],
        ),
        Question(
          name: 'b01',
          label: 'Name of the respondent',
          type: QuestionType.text,
          groupPath: ['module_b'],
        ),
        Question(
          name: 'end_note',
          label:
              '<span style="color:red; font-weight:bold">Interview not completed.</span>',
          type: QuestionType.note,
          relevance: "\${a12} != '1'",
        ),
      ],
    );

Future<void> _pumpForm(
  WidgetTester tester,
  Map<String, dynamic>? initialAnswers,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SurveyFormRenderer(
          form: _gatedForm(),
          initialAnswers: initialAnswers,
        ),
      ),
    ),
  );
}

/// True when any rendered RichText contains [text] inside a span whose
/// color matches [color].
bool _hasColoredSpan(WidgetTester tester, String text, Color color) {
  for (final element in find.byType(RichText).evaluate()) {
    final widget = element.widget as RichText;
    bool scan(InlineSpan span) {
      if (span is TextSpan) {
        if ((span.text ?? '').contains(text) && span.style?.color == color) {
          return true;
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          if (scan(child)) return true;
        }
      }
      return false;
    }

    if (scan(widget.text)) return true;
  }
  return false;
}

void main() {
  group('Survey group visibility (a12 gating)', () {
    testWidgets('answering "no" hides the gated module', (tester) async {
      await _pumpForm(tester, {'a12': '2'});
      await tester.pumpAndSettle();

      expect(find.text('Name of the respondent', findRichText: true), findsNothing);
      expect(find.text('Interview not completed.', findRichText: true), findsOneWidget);
      // No raw HTML anywhere on screen.
      expect(find.textContaining('<span', findRichText: true), findsNothing);
      expect(find.textContaining('font-weight', findRichText: true), findsNothing);
    });

    testWidgets('answering "yes" shows the gated module', (tester) async {
      await _pumpForm(tester, {'a12': '1'});
      await tester.pumpAndSettle();

      expect(find.text('Name of the respondent', findRichText: true), findsOneWidget);
      expect(find.text('Interview not completed.', findRichText: true), findsNothing);
    });

    testWidgets('changing the answer toggles the module live', (tester) async {
      await _pumpForm(tester, null);
      await tester.pumpAndSettle();
      expect(find.text('Name of the respondent', findRichText: true), findsNothing);

      // Open the outcome dropdown and pick "Completed".
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();

      expect(find.text('Name of the respondent', findRichText: true), findsOneWidget);
      expect(find.text('Interview not completed.', findRichText: true), findsNothing);
    });

    testWidgets('span colors render instead of raw markup', (tester) async {
      await _pumpForm(tester, {'a12': '2'});
      await tester.pumpAndSettle();

      expect(find.textContaining('<span', findRichText: true), findsNothing);
      // CSS `red` is pure 0xFFFF0000 (distinct from Material Colors.red).
      expect(
        _hasColoredSpan(
            tester, 'Interview not completed.', const Color(0xFFFF0000)),
        isTrue,
      );
    });

    testWidgets('module header appears for visible groups', (tester) async {
      await _pumpForm(tester, {'a12': '1'});
      await tester.pumpAndSettle();

      expect(find.text('Module B', findRichText: true), findsOneWidget);
    });
  });
}
