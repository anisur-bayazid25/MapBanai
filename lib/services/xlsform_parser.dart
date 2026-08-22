import 'dart:typed_data';

import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/xlsx_reader.dart';

/// Parses XLSForm (.xlsx) workbooks into [SurveyForm] definitions.
///
/// Reads the standard `survey`, `choices` and optional `settings` sheets.
/// Supported: all core question types, select_one/select_multiple with list
/// references, dropdown appearance, required, relevance, constraint,
/// constraint_message, default, read_only and calculate rows.
///
/// Phase 4: ODK multi-language labels are parsed from headers like
/// `label::English (en)` / `label::Bangla (bn)` / `label::bn`.
/// Each question/choice keeps a `labelTranslations` map and a fallback
/// default label (preferring `label`, then `label::en`, then first translation).
class XlsFormParser {
  static const String _surveySheet = 'survey';
  static const String _choicesSheet = 'choices';
  static const String _settingsSheet = 'settings';

  /// Thrown when the workbook cannot be interpreted as a valid XLSForm.
  static const String sheetSurveyMissing = 'Missing "survey" sheet';
  static const String sheetChoicesMissing = 'Missing "choices" sheet';

  /// Parses raw .xlsx bytes into a [SurveyForm].
  static SurveyForm parse(Uint8List bytes, {String fileName = 'survey.xlsx'}) {
    final XlsxWorkbook workbook;
    try {
      workbook = XlsxWorkbookReader.read(bytes);
    } on XlsxReadException catch (e) {
      throw XlsFormParseException('Could not read the workbook: ${e.message}');
    }

    final surveyTable = workbook.sheet(_surveySheet);
    if (surveyTable == null) {
      throw XlsFormParseException(
        '$sheetSurveyMissing (found: '
        '${workbook.sheetNames.isEmpty ? 'no sheets' : workbook.sheetNames.join(', ')}). '
        'The workbook must be an XLSForm with a "survey" sheet.',
      );
    }

    final rows = surveyTable.rows;
    if (rows.length < 2) {
      throw XlsFormParseException('Survey sheet has no data rows');
    }

    final headers = _headers(rows.first);
    final typeCol = headers['type'];
    final nameCol = headers['name'];
    if (typeCol == null || nameCol == null) {
      throw XlsFormParseException(
        'Survey sheet must have "type" and "name" columns',
      );
    }

    final settings = _readSettings(workbook.sheet(_settingsSheet));
    final choices = _readChoices(workbook.sheet(_choicesSheet));

    // Localized column maps for the survey sheet.
    final labelColMap = _localizedColumns(headers, 'label');
    final hintColMap = _localizedColumns(headers, 'hint');
    final constraintMsgColMap = _localizedColumns(headers, 'constraint_message');

    final questions = <Question>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final typeRaw = _cell(row, typeCol);
      if (typeRaw == null || typeRaw.trim().isEmpty) continue;

      final parsed = _parseQuestion(
        row: row,
        headers: headers,
        typeCol: typeCol,
        nameCol: nameCol,
        labelColMap: labelColMap,
        hintColMap: hintColMap,
        constraintMsgColMap: constraintMsgColMap,
        rowIndex: i,
        choices: choices,
      );
      if (parsed != null) questions.add(parsed);
    }

    if (questions.isEmpty) {
      throw XlsFormParseException('No questions found in the survey sheet');
    }

    // Collect form-level languages from all questions + choices.
    final languageSet = <String>{};
    for (final q in questions) {
      languageSet.addAll(q.labelTranslations.keys);
      languageSet.addAll(q.hintTranslations.keys);
      languageSet.addAll(q.constraintMessageTranslations.keys);
      if (q.choices != null) {
        for (final c in q.choices!) {
          languageSet.addAll(c.labelTranslations.keys);
        }
      }
    }
    final languages = languageSet.toList()..sort();
    String? defaultLang;
    if (languages.isNotEmpty) {
      if (languages.contains('en')) {
        defaultLang = 'en';
      } else {
        defaultLang = languages.first;
      }
    }

    return SurveyForm(
      id: (settings['form_id'] as String? ?? '').trim().isNotEmpty
          ? settings['form_id']!.trim()
          : 'xls_${DateTime.now().millisecondsSinceEpoch}',
      name: (settings['form_title'] as String? ?? '').trim().isNotEmpty
          ? settings['form_title']!.trim()
          : _stripExtension(fileName),
      description: (settings['form_description'] as String? ?? '').trim(),
      questions: questions,
      version: settings['version'] is int ? settings['version'] as int : 1,
      languages: languages,
      defaultLanguage: defaultLang,
    );
  }

  // ── sheet reading helpers ────────────────────────────────────

  static String? _cell(List<String?> row, int column) {
    if (column < 0 || column >= row.length) return null;
    final value = row[column];
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  static Map<String, int> _headers(List<String?> firstRow) {
    final map = <String, int>{};
    for (int c = 0; c < firstRow.length; c++) {
      final header = firstRow[c]?.trim().toLowerCase();
      if (header == null || header.isEmpty) continue;
      if (!map.containsKey(header)) map[header] = c;
    }
    return map;
  }

  /// Returns a map languageCode -> columnIndex for a localized field.
  ///
  /// E.g. headers containing `label`, `label::English (en)`, `label::Bangla (bn)`
  /// produce `{default: 2, en: 3, bn: 4}`.
  static Map<String, int> _localizedColumns(
      Map<String, int> headers, String field) {
    final map = <String, int>{};
    for (final entry in headers.entries) {
      final key = entry.key;
      if (key == field) {
        map['default'] = entry.value;
      } else if (key.startsWith('$field::')) {
        final code = _extractLanguageCode(key);
        if (!map.containsKey(code)) {
          map[code] = entry.value;
        }
      }
    }
    return map;
  }

  /// Extracts a normalized language code from a lower-cased header like
  /// `label::english (en)` or `label::bangla (bn)` or `label::bn`.
  static String _extractLanguageCode(String header) {
    final sep = header.indexOf('::');
    if (sep == -1) return 'default';
    var suffix = header.substring(sep + 2).trim();
    // Parentheses win: `english (en)` -> `en`
    final paren = RegExp(r'\(([^)]+)\)').firstMatch(suffix);
    if (paren != null) {
      final inside = paren.group(1)!.trim().toLowerCase();
      final cleaned = inside.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (cleaned.isNotEmpty) return cleaned;
      if (inside.isNotEmpty) return inside;
    }
    suffix = suffix.toLowerCase().trim();
    if (suffix == 'english') return 'en';
    if (suffix == 'bangla' || suffix == 'bengali') return 'bn';
    // fallback: strip non-alphanumeric
    suffix = suffix.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (suffix.isEmpty) return 'default';
    return suffix;
  }

  /// Collects raw languageCode -> cell value for given column map and row.
  static Map<String, String> _collectLocalizedRaw(
      List<String?> row, Map<String, int> colMap) {
    final result = <String, String>{};
    for (final entry in colMap.entries) {
      final value = _cell(row, entry.value);
      if (value != null && value.isNotEmpty) {
        result[entry.key] = value;
      }
    }
    return result;
  }

  static String _pickDefaultLabel(Map<String, String> raw) {
    if (raw.isEmpty) return '';
    if (raw.containsKey('default')) return raw['default']!;
    if (raw.containsKey('en')) return raw['en']!;
    // Prefer first sorted key deterministic.
    final keys = raw.keys.toList()..sort();
    return raw[keys.first]!;
  }

  static Map<String, String> _translationsFromRaw(Map<String, String> raw) {
    final out = <String, String>{};
    for (final entry in raw.entries) {
      if (entry.key == 'default') continue;
      out[entry.key.toLowerCase()] = entry.value;
    }
    return out;
  }

  /// Legacy single-column lookup kept for backward compat / quick checks.
  /// Finds the column for a field, preferring the exact name, then common
  /// English forms (`label::English (en)`, `label::en`), then the first
  /// other localized variant (`label::*`).
  static int? _localizedColumn(Map<String, int> headers, String field) {
    final exact = headers[field];
    if (exact != null) return exact;
    for (final candidate in ['$field::english (en)', '$field::en', '$field::english']) {
      final hit = headers[candidate];
      if (hit != null) return hit;
    }
    final localized = headers.keys
        .where((k) => k.toLowerCase().startsWith('$field::'))
        .toList()
      ..sort();
    return localized.isEmpty ? null : headers[localized.first];
  }

  static int? _labelColumn(Map<String, int> headers) =>
      _localizedColumn(headers, 'label');

  static int? _hintColumn(Map<String, int> headers) =>
      _localizedColumn(headers, 'hint');

  static int? _constraintMessageColumn(Map<String, int> headers) =>
      _localizedColumn(headers, 'constraint_message');

  static Map<String, dynamic> _readSettings(XlsxSheet? settingsTable) {
    if (settingsTable == null) return {};
    final rows = settingsTable.rows;
    if (rows.isEmpty) return {};
    final headers = _headers(rows.first);

    final fieldCols = <String, int>{};
    for (final entry in headers.entries) {
      if (entry.key == 'form_title' ||
          entry.key == 'form_id' ||
          entry.key == 'form_description' ||
          entry.key == 'version') {
        fieldCols[entry.key] = entry.value;
      }
    }
    if (fieldCols.isEmpty) return {};

    final result = <String, dynamic>{};
    for (int i = 1; i < rows.length; i++) {
      for (final entry in fieldCols.entries) {
        final value = _cell(rows[i], entry.value);
        if (value != null) {
          if (entry.key == 'version') {
            result[entry.key] = int.tryParse(value) ?? value;
          } else {
            result[entry.key] = value;
          }
        }
      }
    }
    return result;
  }

  static Map<String, List<Choice>> _readChoices(XlsxSheet? choicesTable) {
    final result = <String, List<Choice>>{};
    if (choicesTable == null) return result;

    final rows = choicesTable.rows;
    if (rows.length < 2) return result;

    final headers = _headers(rows.first);
    final listCol = headers['list_name'];
    final nameCol = headers['name'];
    final labelColMap = _localizedColumns(headers, 'label');
    if (listCol == null || nameCol == null || labelColMap.isEmpty) return result;

    for (int i = 1; i < rows.length; i++) {
      final listName = _cell(rows[i], listCol);
      final name = _cell(rows[i], nameCol);
      if (listName == null || name == null) continue;

      final raw = _collectLocalizedRaw(rows[i], labelColMap);
      if (raw.isEmpty) continue;
      final defaultLabel = _pickDefaultLabel(raw);
      if (defaultLabel.isEmpty) continue;
      final translations = _translationsFromRaw(raw);
      result
          .putIfAbsent(listName, () => [])
          .add(Choice(name: name, label: defaultLabel, labelTranslations: translations));
    }
    return result;
  }

  // ── question parsing ─────────────────────────────────────────

  static Question? _parseQuestion({
    required List<String?> row,
    required Map<String, int> headers,
    required int typeCol,
    required int nameCol,
    required Map<String, int> labelColMap,
    required Map<String, int> hintColMap,
    required Map<String, int> constraintMsgColMap,
    required int rowIndex,
    required Map<String, List<Choice>> choices,
  }) {
    final typeRaw = _cell(row, typeCol) ?? '';
    final name = _cell(row, nameCol) ?? '';

    if (_isStructuralOrMeta(typeRaw)) {
      // ODK group/repeat containers and auto-computed metadata rows
      // (start/end/today/deviceid/username/…). Groups are flattened and
      // metadata is captured automatically by the app, so neither needs a
      // rendered question.
      return null;
    }

    if (name.isEmpty) {
      throw XlsFormParseException(
        'Row ${rowIndex + 1}: question is missing a name',
      );
    }

    final parsedType = _parseType(
      typeRaw,
      appearance: _cell(row, headers['appearance'] ?? -1),
    );
    final type = parsedType.type;
    final listName = parsedType.listName;

    List<Choice>? questionChoices;
    if (listName != null) {
      questionChoices = choices[listName];
      if (questionChoices == null || questionChoices.isEmpty) {
        throw XlsFormParseException(
          'Row ${rowIndex + 1}: choices list "$listName" was not found '
          'in the choices sheet',
        );
      }
    }

    // Label handling (multi-language)
    final labelRaw = _collectLocalizedRaw(row, labelColMap);
    final defaultLabel = _pickDefaultLabel(labelRaw);
    final labelTranslations = _translationsFromRaw(labelRaw);
    final effectiveLabel = defaultLabel.isNotEmpty ? defaultLabel : name;

    // Hint (optional, multi-language)
    final hintRaw = _collectLocalizedRaw(row, hintColMap);
    final hintDefault = hintRaw.isEmpty ? null : _pickDefaultLabel(hintRaw);
    final hintTranslations = _translationsFromRaw(hintRaw);

    // Constraint message (optional, multi-language)
    final constraintRaw = _collectLocalizedRaw(row, constraintMsgColMap);
    final constraintDefault =
        constraintRaw.isEmpty ? null : _pickDefaultLabel(constraintRaw);
    final constraintTranslations = _translationsFromRaw(constraintRaw);

    // Fallback for single-column forms where localized map may be empty:
    // keep previous simple column lookup for hint/constraint if needed.
    String? fallbackHint;
    String? fallbackConstraint;
    if (hintDefault == null && hintColMap.isEmpty) {
      fallbackHint = _cell(row, _hintColumn(headers) ?? -1);
    }
    if (constraintDefault == null && constraintMsgColMap.isEmpty) {
      fallbackConstraint = _cell(row, _constraintMessageColumn(headers) ?? -1);
    }

    return Question(
      name: name,
      label: effectiveLabel,
      type: type,
      hint: hintDefault ?? fallbackHint,
      required: _parseBool(_cell(row, headers['required'] ?? -1)),
      relevance: _cell(row, headers['relevant'] ?? headers['relevance'] ?? -1),
      constraint: _cell(row, headers['constraint'] ?? -1),
      constraintMessage: constraintDefault ?? fallbackConstraint,
      choices: questionChoices,
      defaultValue: _cell(row, headers['default'] ?? -1),
      readOnly: _parseBool(_cell(row, headers['read_only'] ?? -1)),
      calculation: _cell(row, headers['calculation'] ?? -1),
      labelTranslations: labelTranslations,
      hintTranslations: hintTranslations,
      constraintMessageTranslations: constraintTranslations,
    );
  }

  /// True for ODK structural (group/repeat) and auto metadata rows that are
  /// flattened or skipped during import. Space/underscore variants such as
  /// `begin group` and `begin_group` both normalize to `begingroup`.
  static bool _isStructuralOrMeta(String typeRaw) {
    final keyword = typeRaw.trim().split(RegExp(r'\s+')).first;
    final normalized = keyword.toLowerCase().replaceAll(RegExp('[_ ]'), '');
    switch (normalized) {
      // Auto-computed metadata (ODK `meta`): captured by the device/OS.
      case 'start':
      case 'end':
      case 'today':
      case 'deviceid':
      case 'username':
      case 'simserial':
      case 'subscriberid':
      case 'phonenumber':
      case 'audit':
      case 'backgroundaudio':
      case 'geotrace':
      case 'geoshape':
      case 'file':
      case 'audio':
      case 'video':
        return true;
      // Structural containers: flattened into a single linear form.
      case 'begingroup':
      case 'endgroup':
      case 'beginrepeat':
      case 'endrepeat':
        return true;
      default:
        return false;
    }
  }

  static ({QuestionType type, String? listName}) _parseType(
    String raw, {
    String? appearance,
  }) {
    final tokens = raw.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    var keyword = tokens.first.toLowerCase();
    var appearanceValue = appearance?.toLowerCase() ?? '';

    // Legacy XLSForms sometimes encode the appearance in the type itself.
    if (keyword == 'select_one_dropdown') {
      keyword = 'select_one';
      appearanceValue = appearanceValue.isEmpty ? 'dropdown' : appearanceValue;
    } else if (keyword == 'select_multiple_dropdown') {
      keyword = 'select_multiple';
      appearanceValue = appearanceValue.isEmpty ? 'dropdown' : appearanceValue;
    }

    if (keyword == 'text') {
      return (
        type: appearanceValue == 'multiline'
            ? QuestionType.long_text
            : QuestionType.text,
        listName: null,
      );
    }
    switch (keyword) {
      case 'note':
        return (type: QuestionType.note, listName: null);
      case 'int':
      case 'integer':
        return (type: QuestionType.integer, listName: null);
      case 'decimal':
        return (type: QuestionType.decimal, listName: null);
      case 'calculate':
        return (type: QuestionType.calculated, listName: null);
      case 'date':
        return (type: QuestionType.date, listName: null);
      case 'time':
        return (type: QuestionType.time, listName: null);
      case 'datetime':
      case 'datetimeethiopian':
        return (type: QuestionType.datetime, listName: null);
      case 'image':
      case 'photo':
        return (type: QuestionType.image, listName: null);
      case 'barcode':
        return (type: QuestionType.text, listName: null);
      case 'geopoint':
        return (type: QuestionType.geopoint, listName: null);
      case 'hidden':
        return (type: QuestionType.hidden, listName: null);
      case 'yesno':
        return (type: QuestionType.yes_no, listName: null);
      case 'gps_accuracy':
        return (type: QuestionType.gps_accuracy, listName: null);
      case 'select_one':
        return (
          type: appearanceValue.contains('dropdown')
              ? QuestionType.dropdown
              : QuestionType.select_one,
          listName: _listName(tokens),
        );
      case 'select_multiple':
        return (type: QuestionType.select_multiple, listName: _listName(tokens));
      default:
        throw XlsFormParseException(
          'Unsupported question type "$raw"',
        );
    }
  }

  static String? _listName(List<String> tokens) {
    if (tokens.length < 2) return null;
    for (final token in tokens.skip(1)) {
      if (token.startsWith('@')) continue;
      return token;
    }
    return null;
  }

  static bool _parseBool(String? value) {
    if (value == null) return false;
    switch (value.toLowerCase()) {
      case 'yes':
      case 'true':
      case '1':
      case 'y':
        return true;
      default:
        return false;
    }
  }

  static String _stripExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return fileName;
    return fileName.substring(0, dot);
  }
}

class XlsFormParseException implements Exception {
  final String message;

  XlsFormParseException(this.message);

  @override
  String toString() => message;
}
