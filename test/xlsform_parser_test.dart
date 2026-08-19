import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/xlsform_parser.dart';

Uint8List _buildWorkbook({
  required List<List<CellValue?>> survey,
  List<List<CellValue?>>? choices,
  List<List<CellValue?>>? settings,
}) {
  final excel = Excel.createExcel();
  final surveySheet = excel['survey'];
  for (final row in survey) {
    surveySheet.appendRow(row);
  }
  if (choices != null) {
    final choicesSheet = excel['choices'];
    for (final row in choices) {
      choicesSheet.appendRow(row);
    }
  }
  if (settings != null) {
    final settingsSheet = excel['settings'];
    for (final row in settings) {
      settingsSheet.appendRow(row);
    }
  }
  return Uint8List.fromList(excel.save()!);
}

void main() {
  group('XlsFormParser', () {
    test('parses a full XLSForm with choices and settings', () {
      final bytes = _buildWorkbook(
        settings: [
          [TextCellValue('form_title'), TextCellValue('form_id'), TextCellValue('form_description'), TextCellValue('version')],
          [TextCellValue('Road Survey'), TextCellValue('road_v1'), TextCellValue('Road condition check'), IntCellValue(2)],
        ],
        survey: [
          [TextCellValue('type'), TextCellValue('name'), TextCellValue('label'), TextCellValue('required'), TextCellValue('relevance'), TextCellValue('constraint'), TextCellValue('constraint_message'), TextCellValue('hint'), TextCellValue('default'), TextCellValue('calculation'), TextCellValue('read_only')],
          [TextCellValue('text'), TextCellValue('surveyor'), TextCellValue('Surveyor name'), TextCellValue('yes')],
          [TextCellValue('select_one road_type'), TextCellValue('road_type'), TextCellValue('Road type')],
          [TextCellValue('select_multiple defects @or'), TextCellValue('defects'), TextCellValue('Defects seen'), TextCellValue('no'), TextCellValue("\${road_type} = 'asphalt'")],
          [TextCellValue('select_one road_type'), TextCellValue('condition'), TextCellValue('Condition'), TextCellValue('yes'), null, null, null, null, TextCellValue('good'), null, null],
          [TextCellValue('decimal'), TextCellValue('width'), TextCellValue('Width (m)'), TextCellValue(''), null, TextCellValue('. > 0 and . < 20'), TextCellValue('Width out of range')],
          [TextCellValue('integer'), TextCellValue('length_m'), TextCellValue('Length (m)')],
          [TextCellValue('calculate'), TextCellValue('area_m2'), TextCellValue('Area'), null, null, null, null, null, null, TextCellValue("\${width} * \${length_m}"), null],
          [TextCellValue('date'), TextCellValue('insp_date'), TextCellValue('Inspection date')],
          [TextCellValue('geopoint'), TextCellValue('location'), TextCellValue('Location')],
          [TextCellValue('image'), TextCellValue('photo'), TextCellValue('Photo')],
          [TextCellValue('yesno'), TextCellValue('has_guardrail'), TextCellValue('Guardrail?')],
          [TextCellValue('note'), TextCellValue('end_note'), TextCellValue('Thank you')],
          [TextCellValue('hidden'), TextCellValue('source'), TextCellValue('Source'), null, null, null, null, null, TextCellValue('xlsform'), null, null],
          [TextCellValue(''), TextCellValue(''), TextCellValue('')],
        ],
        choices: [
          [TextCellValue('list_name'), TextCellValue('name'), TextCellValue('label')],
          [TextCellValue('road_type'), TextCellValue('asphalt'), TextCellValue('Asphalt')],
          [TextCellValue('road_type'), TextCellValue('gravel'), TextCellValue('Gravel')],
          [TextCellValue('road_type'), TextCellValue('dirt'), TextCellValue('Dirt')],
          [TextCellValue('defects'), TextCellValue('pothole'), TextCellValue('Pothole')],
          [TextCellValue('defects'), TextCellValue('crack'), TextCellValue('Crack')],
        ],
      );

      final form = XlsFormParser.parse(bytes, fileName: 'road.xlsx');

      expect(form.name, 'Road Survey');
      expect(form.id, 'road_v1');
      expect(form.description, 'Road condition check');
      expect(form.version, 2);
      expect(form.questions, hasLength(13));

      final roadType = form.questions[1];
      expect(roadType.type, QuestionType.select_one);
      expect(roadType.choices, hasLength(3));
      expect(roadType.choices!.first.name, 'asphalt');
      expect(roadType.choices!.first.label, 'Asphalt');

      final defects = form.questions[2];
      expect(defects.type, QuestionType.select_multiple);
      expect(defects.choices, hasLength(2));
      expect(defects.relevance, "\${road_type} = 'asphalt'");

      final condition = form.questions[3];
      expect(condition.required, isTrue);
      expect(condition.defaultValue, 'good');

      final width = form.questions[4];
      expect(width.type, QuestionType.decimal);
      expect(width.required, isFalse);
      expect(width.constraint, '. > 0 and . < 20');
      expect(width.constraintMessage, 'Width out of range');

      final area = form.questions[6];
      expect(area.type, QuestionType.calculated);
      expect(area.calculation, '\${width} * \${length_m}');

      expect(form.questions[7].type, QuestionType.date);
      expect(form.questions[8].type, QuestionType.geopoint);
      expect(form.questions[9].type, QuestionType.image);
      expect(form.questions[10].type, QuestionType.yes_no);
      expect(form.questions[11].type, QuestionType.note);
      expect(form.questions[0].type, QuestionType.text);

      final hidden = form.questions.firstWhere((q) => q.name == 'source');
      expect(hidden.type, QuestionType.hidden);
      expect(hidden.defaultValue, 'xlsform');
    });

    test('maps multiline text appearance to long_text and dropdown to dropdown', () {
      final bytes = _buildWorkbook(
        survey: [
          [TextCellValue('type'), TextCellValue('name'), TextCellValue('label'), TextCellValue('appearance')],
          [TextCellValue('text'), TextCellValue('notes'), TextCellValue('Notes'), TextCellValue('multiline')],
          [TextCellValue('select_one status @or'), TextCellValue('status'), TextCellValue('Status')],
          [TextCellValue('select_one priority'), TextCellValue('priority'), TextCellValue('Priority'), TextCellValue('dropdown')],
        ],
        choices: [
          [TextCellValue('list_name'), TextCellValue('name'), TextCellValue('label')],
          [TextCellValue('status'), TextCellValue('open'), TextCellValue('Open')],
          [TextCellValue('status'), TextCellValue('closed'), TextCellValue('Closed')],
          [TextCellValue('priority'), TextCellValue('high'), TextCellValue('High')],
          [TextCellValue('priority'), TextCellValue('low'), TextCellValue('Low')],
        ],
      );

      final form = XlsFormParser.parse(bytes);
      expect(form.questions[0].type, QuestionType.long_text);
      expect(form.questions[1].type, QuestionType.select_one);
      expect(form.questions[1].choices, hasLength(2));
      expect(form.questions[2].type, QuestionType.dropdown);
      expect(form.questions[2].choices, hasLength(2));
    });

    test('falls back to file name and localized labels', () {
      final bytes = _buildWorkbook(
        survey: [
          [TextCellValue('type'), TextCellValue('name'), TextCellValue('label::English (en)')],
          [TextCellValue('text'), TextCellValue('q1'), TextCellValue('Question one')],
        ],
      );

      final form = XlsFormParser.parse(bytes, fileName: 'my_form.xlsx');
      expect(form.name, 'my_form');
      expect(form.questions.first.label, 'Question one');
    });

    test('throws on missing survey sheet', () {
      final excel = Excel.createExcel();
      excel['other'].appendRow([TextCellValue('type')]);
      expect(
        () => XlsFormParser.parse(Uint8List.fromList(excel.save()!)),
        throwsA(isA<XlsFormParseException>().having(
          (e) => e.message,
          'message',
          contains(XlsFormParser.sheetSurveyMissing),
        )),
      );
    });

    test('throws on missing choices list', () {
      final bytes = _buildWorkbook(
        survey: [
          [TextCellValue('type'), TextCellValue('name'), TextCellValue('label')],
          [TextCellValue('select_one missing_list'), TextCellValue('q1'), TextCellValue('Question')],
        ],
      );
      expect(
        () => XlsFormParser.parse(bytes),
        throwsA(
          isA<XlsFormParseException>().having(
            (e) => e.message,
            'message',
            contains('missing_list'),
          ),
        ),
      );
    });

    test('accepts a full ODK form with metadata, groups and translations', () {
      final bytes = _buildWorkbook(
        settings: [
          [TextCellValue('form_title'), TextCellValue('form_id')],
          [TextCellValue('Riverbank Survey'), TextCellValue('riverbank_v1')],
        ],
        survey: [
          [
            TextCellValue('type'),
            TextCellValue('name'),
            TextCellValue('label::English (en)'),
            TextCellValue('label::Bangla (bn)'),
            TextCellValue('hint::English (en)'),
            TextCellValue('hint::Bangla (bn)'),
            TextCellValue('required'),
            TextCellValue('relevant'),
            TextCellValue('constraint'),
            TextCellValue('constraint_message::English (en)'),
            TextCellValue('appearance'),
          ],
          [TextCellValue('start'), TextCellValue('start_time'), TextCellValue('Start time'), TextCellValue('শুরুর সময়')],
          [TextCellValue('end'), TextCellValue('end_time'), TextCellValue('End time'), TextCellValue('শেষ সময়')],
          [TextCellValue('today'), TextCellValue('survey_date'), TextCellValue('Survey date'), TextCellValue('তথ্য সংগ্রহের তারিখ'), null, null, TextCellValue('yes')],
          [TextCellValue('deviceid'), TextCellValue('device_id'), TextCellValue('Device ID'), TextCellValue('ডিভাইস আইডি')],
          [TextCellValue('username'), TextCellValue('enumerator_id'), TextCellValue('Enumerator ID'), TextCellValue('তথ্য সংগ্রহকারী আইডি'), null, null, TextCellValue('yes')],
          [TextCellValue('select_one study_site'), TextCellValue('study_site'), TextCellValue('Study site'), TextCellValue('গবেষণা এলাকা'), TextCellValue('Select the study site.'), TextCellValue('গবেষণা এলাকা নির্বাচন করুন।'), TextCellValue('yes')],
          [TextCellValue('begin_group'), TextCellValue('location_group'), TextCellValue('Location'), TextCellValue('অবস্থান'), null, null, null, null, null, null, TextCellValue('field-list')],
          [TextCellValue('geopoint'), TextCellValue('location_point'), TextCellValue('GPS location'), TextCellValue('GPS অবস্থান'), TextCellValue('Stand at the observation point.'), TextCellValue('পর্যবেক্ষণ স্থানে দাঁড়ান।'), TextCellValue('yes')],
          [TextCellValue('decimal'), TextCellValue('gps_accuracy_m'), TextCellValue('GPS accuracy (m)'), TextCellValue('GPS নির্ভুলতা (মিটার)'), TextCellValue('Record the accuracy.'), TextCellValue('নির্ভুলতা লিখুন।'), null, null, TextCellValue('. >= 0'), TextCellValue('Accuracy cannot be negative.'), TextCellValue('নির্ভুলতা ঋণাত্মক হতে পারবে না।')],
          [TextCellValue('text'), TextCellValue('locality_name'), TextCellValue('Locality / landmark name'), TextCellValue('এলাকা / পরিচিত স্থানের নাম')],
          [TextCellValue('select_one record_type'), TextCellValue('record_type'), TextCellValue('What are you mapping?'), TextCellValue('আপনি কী ম্যাপ করছেন?'), null, null, TextCellValue('yes')],
          [TextCellValue('end_group'), TextCellValue('location_group_end')],
          [TextCellValue('integer'), TextCellValue('duration_days'), TextCellValue('Duration (days)'), TextCellValue('স্থায়িত্ব (দিন)'), null, null, null, TextCellValue("\${record_type} = 'waterlogging'"), TextCellValue('. >= 0'), TextCellValue('Duration cannot be negative.')],
        ],
        choices: [
          [
            TextCellValue('list_name'),
            TextCellValue('name'),
            TextCellValue('label::English (en)'),
            TextCellValue('label::Bangla (bn)'),
          ],
          [TextCellValue('study_site'), TextCellValue('site_a'), TextCellValue('Site A'), TextCellValue('স্থান ক')],
          [TextCellValue('study_site'), TextCellValue('site_b'), TextCellValue('Site B'), TextCellValue('স্থান খ')],
          [TextCellValue('record_type'), TextCellValue('salinity'), TextCellValue('Salinity'), TextCellValue('লবণাক্ততা')],
          [TextCellValue('record_type'), TextCellValue('waterlogging'), TextCellValue('Waterlogging'), TextCellValue('জলাবদ্ধতা')],
        ],
      );

      final form = XlsFormParser.parse(bytes, fileName: 'riverbank.xlsx');

      expect(form.name, 'Riverbank Survey');
      // Metadata (start/end/today/deviceid/username) and group containers are
      // not turned into questions.
      final names = form.questions.map((q) => q.name).toList();
      expect(names, isNot(contains('start_time')));
      expect(names, isNot(contains('end_time')));
      expect(names, isNot(contains('device_id')));
      expect(names, isNot(contains('location_group')));
      expect(names, isNot(contains('location_group_end')));
      expect(form.questions, hasLength(6));

      final studySite = form.questions.firstWhere(
        (q) => q.name == 'study_site',
      );
      expect(studySite.type, QuestionType.select_one);
      expect(studySite.required, isTrue);
      expect(studySite.choices, hasLength(2));
      // English localized labels are preferred.
      expect(studySite.choices!.first.label, 'Site A');
      expect(studySite.label, 'Study site');
      expect(studySite.hint, 'Select the study site.');

      final accuracy = form.questions.firstWhere(
        (q) => q.name == 'gps_accuracy_m',
      );
      expect(accuracy.type, QuestionType.decimal);
      expect(accuracy.constraint, '. >= 0');
      expect(accuracy.constraintMessage, 'Accuracy cannot be negative.');

      final duration = form.questions.firstWhere(
        (q) => q.name == 'duration_days',
      );
      expect(duration.type, QuestionType.integer);
      expect(duration.relevance, "\${record_type} = 'waterlogging'");

      expect(form.questions.firstWhere((q) => q.name == 'record_type').type,
          QuestionType.select_one);
      expect(form.questions.firstWhere((q) => q.name == 'location_point').type,
          QuestionType.geopoint);
      expect(form.questions.firstWhere((q) => q.name == 'locality_name').type,
          QuestionType.text);
    });

    test('throws on unsupported question type', () {
      final bytes = _buildWorkbook(
        survey: [
          [TextCellValue('type'), TextCellValue('name'), TextCellValue('label')],
          [TextCellValue('fancy_widget'), TextCellValue('q1'), TextCellValue('Question')],
        ],
      );
      expect(
        () => XlsFormParser.parse(bytes),
        throwsA(isA<XlsFormParseException>()),
      );
    });

    test('round-trips through SurveyForm JSON', () {
      final bytes = _buildWorkbook(
        settings: [
          [TextCellValue('form_title')],
          [TextCellValue('Round Trip')],
        ],
        survey: [
          [TextCellValue('type'), TextCellValue('name'), TextCellValue('label')],
          [TextCellValue('integer'), TextCellValue('count'), TextCellValue('Count')],
        ],
      );

      final form = XlsFormParser.parse(bytes);
      final restored = SurveyForm.fromJson(form.toJson());
      expect(restored.name, 'Round Trip');
      expect(restored.questions.first.name, 'count');
      expect(restored.questions.first.type, QuestionType.integer);
    });
  });
}
