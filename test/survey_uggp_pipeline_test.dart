import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/xlsform_parser.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

/// End-to-end regression test for the UGGP-form bug report (v2.4.4):
/// real xlsx bytes (English + Bengali labels, styled spans, once/coalesce
/// calculations, nested group + repeat, a12-gated modules) go through
/// XlsFormParser straight into a pumped SurveyFormRenderer, proving the
/// reported skip logic works on the actual pipeline — not just on
/// hand-built models.
Uint8List _uggpLikeWorkbook() {
  final excel = Excel.createExcel();
  final survey = excel['survey'];
  for (final row in <List<CellValue?>>[
    [
      TextCellValue('type'),
      TextCellValue('name'),
      TextCellValue('label::english'),
      TextCellValue('label::bengali'),
      TextCellValue('relevant'),
      TextCellValue('constraint'),
      TextCellValue('calculation'),
      TextCellValue('repeat_count'),
      TextCellValue('required'),
    ],
    [
      TextCellValue('calculate'),
      TextCellValue('date'),
      TextCellValue('Interviewer Date'),
      TextCellValue('আজকের তারিখ'),
      null, null,
      TextCellValue('once(today())'),
    ],
    [
      TextCellValue('calculate'),
      TextCellValue('start_time'),
      null, null, null, null,
      TextCellValue("once(format-date-time(now(), '%H:%M'))"),
    ],
    [
      TextCellValue('note'),
      TextCellValue('date_note'),
      TextCellValue('Interview date: \${date} | Start time: \${start_time}'),
      TextCellValue('তারিখ: \${date}'),
    ],
    [
      TextCellValue('begin_group'),
      TextCellValue('module_a'),
      TextCellValue(
          '<span style="color:maroon; font-weight:bold">Module A: Household Identification</span>'),
      TextCellValue('মডিউল এ'),
    ],
    [
      TextCellValue('select_one a12'),
      TextCellValue('a12'),
      TextCellValue('Outcome of the Interview'),
      TextCellValue('সাক্ষাৎকারের ফলাফল'),
    ],
    [TextCellValue('end_group')],
    [
      TextCellValue('note'),
      TextCellValue('a12_end_note'),
      TextCellValue(
          '<span style="color:red; font-weight:bold">Interview not completed. Save and finalise the form.</span>'),
      null,
      TextCellValue("\${a12} != '1'"),
    ],
    [
      TextCellValue('begin_group'),
      TextCellValue('module_b'),
      TextCellValue(
          '<span style="color:maroon; font-weight:bold">Module B: Household Information</span>'),
      null,
      TextCellValue("\${a12} = '1'"),
    ],
    [
      TextCellValue('text'),
      TextCellValue('b01'),
      TextCellValue('Name of the respondent'),
      TextCellValue('উত্তরদাতার নাম'),
    ],
    [
      TextCellValue('integer'),
      TextCellValue('b02'),
      TextCellValue('Respondent Age'),
      null, null,
      TextCellValue('. >= 0 and . <= 110'),
    ],
    [
      TextCellValue('begin_repeat'),
      TextCellValue('hh_member_repeat'),
      TextCellValue('Household Member line number'),
      null, null, null, null,
      TextCellValue('\${num_hh_members}'),
    ],
    [
      TextCellValue('text'),
      TextCellValue('b08'),
      TextCellValue('Member name'),
    ],
    [
      TextCellValue('select_one b09'),
      TextCellValue('b09'),
      TextCellValue('Relationship of \${b08} with household head'),
    ],
    [TextCellValue('end_repeat')],
    [TextCellValue('end_group')],
    [
      TextCellValue('calculate'),
      TextCellValue('b06_total'),
      null, null, null, null,
      TextCellValue('coalesce(\${c1}, 0) + coalesce(\${c2}, 0)'),
    ],
    [
      TextCellValue('note'),
      TextCellValue('b06_total_note'),
      TextCellValue('Total persons in vulnerable groups: \${b06_total}'),
    ],
  ]) {
    survey.appendRow(row);
  }
  final choices = excel['choices'];
  for (final row in <List<CellValue?>>[
    [TextCellValue('list_name'), TextCellValue('name'), TextCellValue('label')],
    [TextCellValue('a12'), TextCellValue('1'), TextCellValue('Consent given')],
    [TextCellValue('a12'), TextCellValue('2'), TextCellValue('Absent')],
    [TextCellValue('a12'), TextCellValue('3'), TextCellValue('Unwilling')],
    [TextCellValue('a12'), TextCellValue('4'), TextCellValue('Dwelling vacant')],
    [TextCellValue('b09'), TextCellValue('1'), TextCellValue('Head')],
    [TextCellValue('b09'), TextCellValue('2'), TextCellValue('Spouse')],
  ]) {
    choices.appendRow(row);
  }
  return Uint8List.fromList(excel.save()!);
}

void main() {
  group('UGGP-like pipeline (parse xlsx -> render -> gate)', () {
    test('parser keeps groups, paths, i18n and calculations', () {
      final form = XlsFormParser.parse(_uggpLikeWorkbook());

      final moduleB = form.groups.firstWhere((g) => g.name == 'module_b');
      expect(moduleB.relevance, "\${a12} = '1'");
      // Styled group label survives parsing (rendering strips/styles it).
      expect(moduleB.label, contains('Module B: Household Information'));

      final b01 = form.questions.firstWhere((q) => q.name == 'b01');
      expect(b01.groupPath, ['module_b']);
      // Bengali column maps to bn.
      expect(b01.labelTranslations['bn'], 'উত্তরদাতার নাম');

      // Repeat nested inside the gated group.
      final b08 = form.questions.firstWhere((q) => q.name == 'b08');
      expect(b08.groupPath, ['module_b', 'hh_member_repeat']);
      final repeat = form.groups.firstWhere((g) => g.name == 'hh_member_repeat');
      expect(repeat.isRepeat, isTrue);
      expect(repeat.repeatCount, '\${num_hh_members}');

      // once()/coalesce() calculations preserved verbatim.
      expect(
        form.questions.firstWhere((q) => q.name == 'date').calculation,
        'once(today())',
      );
      expect(
        form.questions.firstWhere((q) => q.name == 'b06_total').calculation,
        'coalesce(\${c1}, 0) + coalesce(\${c2}, 0)',
      );
    });

    testWidgets('only choice 1 opens the gated module', (tester) async {
      final form = XlsFormParser.parse(_uggpLikeWorkbook());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SurveyFormRenderer(form: form)),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing answered yet: gated module hidden, end note visible
      // (empty != '1', matching ODK), no raw markup anywhere.
      expect(
          find.text('Name of the respondent', findRichText: true), findsNothing);
      expect(find.text('Module B: Household Information', findRichText: true),
          findsNothing);
      expect(find.textContaining('<span', findRichText: true), findsNothing);
      expect(find.textContaining('\${date}', findRichText: true), findsNothing);
      // Unhidden module header renders (styled maroon, tags gone).
      expect(
          find.text('Module A: Household Identification', findRichText: true),
          findsOneWidget);

      // Answer a12 = 2 (Absent): still hidden.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Absent').last);
      await tester.pumpAndSettle();
      expect(
          find.text('Name of the respondent', findRichText: true), findsNothing);
      expect(
          find.text('Interview not completed. Save and finalise the form.',
              findRichText: true),
          findsOneWidget);

      // Answer a12 = 1 (Consent): module opens, end note hides.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consent given').last);
      await tester.pumpAndSettle();
      expect(find.text('Name of the respondent', findRichText: true),
          findsOneWidget);
      expect(find.text('Module B: Household Information', findRichText: true),
          findsOneWidget);
      expect(
          find.text('Interview not completed. Save and finalise the form.',
              findRichText: true),
          findsNothing);
    });

    testWidgets('other non-consent options keep the module closed', (tester) async {
      final form = XlsFormParser.parse(_uggpLikeWorkbook());
      for (final label in ['Unwilling', 'Dwelling vacant']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SurveyFormRenderer(form: form)),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(find.text('Name of the respondent', findRichText: true),
            findsNothing,
            reason: 'a12=$label must not open module_b');
        expect(
            find.text('Interview not completed. Save and finalise the form.',
                findRichText: true),
            findsOneWidget);
      }
    });
  });
}
