import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/xlsx_reader.dart';
import 'package:mapbanai/services/xlsform_parser.dart';

Uint8List _buildXlsx({
  required List<String> sheets,
  required Map<String, String> sheetXml,
  List<String> sharedStrings = const [],
  bool includeSharedStringsFile = true,
}) {
  final archive = Archive();

  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add(
    '[Content_Types].xml',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
</Types>''',
  );
  add('_rels/.rels', '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"></Relationships>');
  final sheetRels = StringBuffer();
  final sheetEntries = StringBuffer();
  for (int i = 0; i < sheets.length; i++) {
    final name = sheets[i];
    final rid = 'rId${i + 1}';
    sheetRels.write(
      '<Relationship Id="$rid" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>',
    );
    sheetEntries.write(
      '<sheet name="$name" sheetId="${i + 1}" r:id="$rid"/>',
    );
    add('xl/worksheets/sheet${i + 1}.xml', sheetXml[name]!);
  }
  if (sharedStrings.isNotEmpty || includeSharedStringsFile) {
    sheetRels.write(
      '<Relationship Id="rId9" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>',
    );
    final sst = StringBuffer('<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    for (final s in sharedStrings) {
      sst.write('<si><t xml:space="preserve">${s.replaceAll('&', '&amp;').replaceAll('<', '&lt;')}</t></si>');
    }
    sst.write('</sst>');
    add('xl/sharedStrings.xml', sst.toString());
  }
  add(
    'xl/workbook.xml',
    '<?xml version="1.0"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets>$sheetEntries</sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '$sheetRels</Relationships>',
  );

  final bytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(bytes!);
}

String _surveySheet(String body) =>
    '''<?xml version="1.0"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>$body</sheetData></worksheet>''';

void main() {
  group('XlsxWorkbookReader', () {
    test('reads shared-strings workbook with correct column placement', () {
      final bytes = _buildXlsx(
        sheets: ['survey', 'choices'],
        sharedStrings: ['type', 'name', 'text', 'site_name', 'River site'],
        sheetXml: {
          'survey': _surveySheet(
            '''<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>
<row r="2"><c r="A2" t="s"><v>2</v></c><c r="B2" t="s"><v>3</v></c><c r="C2" t="s"><v>4</v></c></row>''',
          ),
          'choices': _surveySheet(''),
        },
      );

      final workbook = XlsxWorkbookReader.read(bytes);
      expect(workbook.sheetNames, ['survey', 'choices']);

      final survey = workbook.sheet('SURVEY'); // case-insensitive
      expect(survey, isNotNull);
      final rows = survey!.rows;
      expect(rows.length, 2);
      expect(rows[0], ['type', 'name', null]);
      expect(rows[1], ['text', 'site_name', 'River site']);
    });

    test('reads inline strings with empty cells without crashing', () {
      final bytes = _buildXlsx(
        sheets: ['survey'],
        includeSharedStringsFile: false,
        sheetXml: {
          'survey': _surveySheet(
            '''<row r="1"><c r="A1" t="inlineStr"><is><t>type</t></is></c><c r="C1" t="inlineStr"><is><t>label</t></is></c></row>
<row r="2"><c r="A2" t="inlineStr"><is><t>integer</t></is></c><c r="B2" t="inlineStr"/><c r="C2" t="inlineStr"><is><t>Width</t></is></c></row>''',
          ),
        },
      );

      final rows = XlsxWorkbookReader.read(bytes).sheet('survey')!.rows;
      expect(rows[0], ['type', null, 'label']);
      expect(rows[1], ['integer', null, 'Width']);
    });

    test('out-of-range shared string index is read as null, no crash', () {
      final bytes = _buildXlsx(
        sheets: ['survey'],
        sharedStrings: ['type'],
        sheetXml: {
          'survey': _surveySheet(
            '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>999</v></c></row>',
          ),
        },
      );

      final rows = XlsxWorkbookReader.read(bytes).sheet('survey')!.rows;
      expect(rows[0], ['type', null]);
    });

    test('rejects non-zip bytes with a helpful message', () {
      expect(
        () => XlsxWorkbookReader.read(
          Uint8List.fromList([0xD0, 0xCF, 0x11, 0xE0, 1, 2, 3]), // .xls magic
        ),
        throwsA(
          isA<XlsxReadException>().having(
            (e) => e.message,
            'message',
            contains('.xlsx'),
          ),
        ),
      );
    });

    test('reports missing xl/workbook.xml', () {
      final archive = Archive();
      final data = [1, 2, 3];
      archive.addFile(ArchiveFile('random.bin', data.length, data));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

      expect(
        () => XlsxWorkbookReader.read(bytes),
        throwsA(isA<XlsxReadException>()),
      );
    });
  });

  group('XlsFormParser with real-world files', () {
    final fixture = File('test/fixtures/riverbank_form.xlsx');

    test('parses an openpyxl-generated XLSForm (inline strings)', () {
      final bytes = fixture.readAsBytesSync();

      // Regression: this file crashed the old excel-based parser with
      // "Null check operator used on a null value".
      final form = XlsFormParser.parse(bytes, fileName: 'riverbank_form.xlsx');

      expect(form.name, 'Riverbank Survey');
      expect(form.id, 'riverbank_v1');
      expect(
        [for (final q in form.questions) q.type],
        [
          QuestionType.note,
          QuestionType.select_one,
          QuestionType.dropdown,
          QuestionType.integer,
          QuestionType.decimal,
          QuestionType.geopoint,
          QuestionType.image,
          QuestionType.text,
        ],
      );
      expect(
        [for (final c in form.questions[1].choices!) '${c.name}:${c.label}'],
        ['nile:Nile', 'amazon:Amazon'],
      );
      expect(form.questions[3].constraint, '. > 0 and . < 150');
      expect(form.questions[3].constraintMessage, 'Width must be 0-150 m');
      expect(form.questions[3].required, isTrue);
      expect(form.questions[3].label, 'Width (m)');
      expect(form.questions[4].label, 'Depth (m)');
    });

    test('missing survey sheet lists available sheets', () {
      final bytes = _buildXlsx(
        sheets: ['data'],
        includeSharedStringsFile: false,
        sheetXml: {'data': _surveySheet('<row r="1"><c r="A1" t="inlineStr"><is><t>x</t></is></c></row>')},
      );

      expect(
        () => XlsFormParser.parse(bytes),
        throwsA(
          isA<XlsFormParseException>().having(
            (e) => e.message,
            'message',
            allOf(contains('survey'), contains('data')),
          ),
        ),
      );
    });
  });
}