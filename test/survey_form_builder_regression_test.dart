import 'dart:async';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/ui/survey_form_builder_screen.dart';

class MemoryFilePicker extends FilePicker {
  final Uint8List bytes;
  MemoryFilePicker(this.bytes);
  @override
  Future<FilePickerResult?> pickFiles(
          {String? dialogTitle,
          String? initialDirectory,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          Function(FilePickerStatus)? onFileLoading,
          bool allowCompression = true,
          int compressionQuality = 30,
          bool allowMultiple = false,
          bool withData = false,
          bool withReadStream = false,
          bool lockParentWindow = false,
          bool readSequential = false}) async =>
      FilePickerResult(
          [PlatformFile(name: 'form.xlsx', size: bytes.length, bytes: bytes)]);
}

Future<void> openBuilder(WidgetTester tester,
    {SurveyForm? source, FutureOr<void> Function(SurveyForm)? save}) async {
  await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SurveyFormBuilderScreen(
                              existingForm: source, onSave: save))),
                  child: const Text('Open'))))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

SurveyForm sourceForm() => SurveyForm(
    id: 'source',
    name: 'Original',
    description: 'Description',
    version: 7,
    groups: [const GroupInfo(name: 'module', relevance: r'${flag} = 1')],
    languages: ['en', 'bn'],
    defaultLanguage: 'bn',
    importWarnings: ['Metadata not captured'],
    questions: [
      Question(
          name: 'date',
          label: 'Date',
          type: QuestionType.date,
          defaultValue: '2020-01-01',
          groupPath: ['module'],
          readOnly: true,
          labelTranslations: {'bn': 'তারিখ'})
    ]);

void main() {
  testWidgets(
      'builder preserves imported schema when saving and editing questions',
      (tester) async {
    SurveyForm? saved;
    await openBuilder(tester,
        source: sourceForm(), save: (form) => saved = form);
    await tester.tap(find.byType(PopupMenuButton<dynamic>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Question label'),
        'Updated date');
    await tester.ensureVisible(find.text('Save').last);
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved!.id, 'source');
    expect(saved!.version, 7);
    expect(saved!.defaultLanguage, 'bn');
    expect(saved!.languages, ['en', 'bn']);
    expect(saved!.groups.single.relevance, r'${flag} = 1');
    expect(saved!.importWarnings, ['Metadata not captured']);
    expect(saved!.questions.single.label, 'Updated date');
    expect(saved!.questions.single.readOnly, isTrue);
    expect(saved!.questions.single.labelTranslations, {'bn': 'তারিখ'});
    expect(saved!.questions.single.groupPath, ['module']);
  });

  testWidgets('XLSForm import preserves form metadata and reviews warnings',
      (tester) async {
    final excel = Excel.createExcel();
    for (final row in [
      ['type', 'name', 'label::English (en)', 'label::Bangla (bn)'],
      ['start', 'started', '', ''],
      ['begin group', 'module', 'Module', ''],
      ['date', 'visit', 'Visit date', 'তারিখ'],
      ['end group', '', '', ''],
    ]) {
      excel['survey']
          .appendRow(row.map((value) => TextCellValue(value)).toList());
    }
    excel['settings'].appendRow([
      TextCellValue('form_id'),
      TextCellValue('form_title'),
      TextCellValue('version'),
      TextCellValue('default_language')
    ]);
    excel['settings'].appendRow([
      TextCellValue('imported'),
      TextCellValue('Imported'),
      IntCellValue(12),
      TextCellValue('Bangla (bn)')
    ]);
    FilePicker.platform = MemoryFilePicker(Uint8List.fromList(excel.save()!));
    SurveyForm? saved;
    await openBuilder(tester, save: (form) => saved = form);
    await tester.tap(find.byTooltip('Import from XLSForm (.xlsx)'));
    await tester.pumpAndSettle();
    expect(find.text('XLSForm import limitations'), findsOneWidget);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved!.id, 'imported');
    expect(saved!.version, 12);
    expect(saved!.defaultLanguage, 'bn');
    expect(saved!.groups.single.name, 'module');
    expect(saved!.questions.single.groupPath, ['module']);
    expect(saved!.importWarnings.single, contains('not collected'));
  });

  testWidgets('builder remains open while saving and preserves form on failure',
      (tester) async {
    final pending = Completer<void>();
    var saves = 0;
    await openBuilder(tester, source: sourceForm(), save: (_) {
      saves++;
      return pending.future;
    });
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    expect(saves, 1);
    expect(find.byType(SurveyFormBuilderScreen), findsOneWidget);
    pending.completeError(StateError('disk full'));
    await tester.pumpAndSettle();
    expect(find.byType(SurveyFormBuilderScreen), findsOneWidget);
    expect(find.textContaining('Your form is still here'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
  });
}
