import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Thrown when a workbook cannot be interpreted as a valid .xlsx file.
class XlsxReadException implements Exception {
  final String message;

  XlsxReadException(this.message);

  @override
  String toString() => message;
}

/// A single worksheet: name + raw string cell values (ragged rows are
/// padded with nulls to the sheet-wide maximum column index).
class XlsxSheet {
  final String name;
  final List<List<String?>> rows;

  XlsxSheet(this.name, this.rows);
}

/// A parsed workbook with case-insensitive sheet lookup.
class XlsxWorkbook {
  final List<XlsxSheet> sheets;

  XlsxWorkbook(this.sheets);

  /// Looks up a sheet by exact name, then by case-insensitive match.
  XlsxSheet? sheet(String name) {
    for (final sheet in sheets) {
      if (sheet.name == name) return sheet;
    }
    final lower = name.toLowerCase();
    for (final sheet in sheets) {
      if (sheet.name.toLowerCase() == lower) return sheet;
    }
    return null;
  }

  List<String> get sheetNames => [for (final sheet in sheets) sheet.name];
}

/// A dependency-free reader for .xlsx workbooks (ZIP of OOXML parts).
///
/// Unlike `excel`'s parser this reader is null-safe: cells that reference
/// missing shared strings, empty inline strings, or missing values are read
/// as null instead of crashing, so real-world files produced by Excel,
/// LibreOffice, Google Sheets, KoBoToolbox and openpyxl-style tools import
/// reliably.
class XlsxWorkbookReader {
  static const String _xlsHint =
      'If this is an older .xls file, open it in Excel and use '
      '"Save As" -> "Excel Workbook (*.xlsx)", then import the new file.';

  static XlsxWorkbook read(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw XlsxReadException(
        'This file is not a valid .xlsx workbook (expected a ZIP archive, '
        'found a different file format). $_xlsHint',
      );
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw XlsxReadException(
        'The workbook is corrupted and could not be opened ($e).',
      );
    }

    final workbookEntry = _entry(archive, 'xl/workbook.xml');
    if (workbookEntry == null) {
      throw XlsxReadException(
        'The workbook is missing xl/workbook.xml and is not a valid .xlsx '
        'file. $_xlsHint',
      );
    }

    final XmlDocument workbook;
    try {
      workbook = XmlDocument.parse(_entryText(workbookEntry));
    } catch (e) {
      throw XlsxReadException(
        'The workbook structure could not be read ($e).',
      );
    }

    final rels = _relationships(archive);
    final sharedStrings = _sharedStrings(archive, rels);
    final dateStyles = _dateStyles(archive);
    final date1904 = ['1', 'true'].contains(workbook
        .descendantsNamed('workbookPr')
        .firstOrNull
        ?.getAttribute('date1904'));

    final sheets = <XlsxSheet>[];
    for (final node in workbook.descendantsNamed('sheet')) {
      final name = node.getAttribute('name');
      if (name == null || name.isEmpty) continue;
      final rid = node.attributes
          .where((attribute) => attribute.name.local == 'id')
          .firstOrNull
          ?.value;
      final target = rid == null ? null : rels[rid];
      if (target == null) continue;

      final entry = _entry(archive, _resolveTarget(target));
      if (entry == null) continue;

      try {
        final sheetDoc = XmlDocument.parse(_entryText(entry));
        final sheetData = sheetDoc.descendantsNamed('sheetData').firstOrNull;
        sheets.add(XlsxSheet(
            name, _parseRows(sheetData, sharedStrings, dateStyles, date1904)));
      } catch (e) {
        throw XlsxReadException(
          'The sheet "$name" could not be read ($e).',
        );
      }
    }

    return XlsxWorkbook(sheets);
  }

  /// Decode Excel numeric dates only when a date/time style is present.
  static Map<int, String> _dateStyles(Archive archive) {
    final entry = _entry(archive, 'xl/styles.xml');
    if (entry == null) return const {};
    final doc = XmlDocument.parse(_entryText(entry));
    final custom = <int, String>{};
    for (final node in doc.descendantsNamed('numFmt')) {
      final id = int.tryParse(node.getAttribute('numFmtId') ?? '');
      if (id != null) custom[id] = node.getAttribute('formatCode') ?? '';
    }
    final formats = doc.descendantsNamed('cellXfs').firstOrNull;
    if (formats == null) return const {};
    final result = <int, String>{};
    var index = 0;
    for (final node in formats.childrenNamed('xf')) {
      final id = int.tryParse(node.getAttribute('numFmtId') ?? '');
      if (id != null) {
        if (id >= 14 && id <= 17) {
          result[index] = 'date';
        } else if ((id >= 18 && id <= 21) || (id >= 45 && id <= 47)) {
          result[index] = 'time';
        } else if (id == 22) {
          result[index] = 'datetime';
        } else if (custom.containsKey(id)) {
          final code = custom[id]!
              .replaceAll(RegExp(r'"[^"]*"|\\.|\[[^\]]*\]'), '')
              .toLowerCase();
          final date = RegExp(r'[yd]').hasMatch(code);
          final time = RegExp(r'[hs]').hasMatch(code);
          if (date || time)
            result[index] = date && time
                ? 'datetime'
                : date
                    ? 'date'
                    : 'time';
        }
      }
      index++;
    }
    return result;
  }

  // ── zip helpers ──────────────────────────────────────────────

  static ArchiveFile? _entry(Archive archive, String path) {
    for (final file in archive.files) {
      if (file.name == path) return file;
    }
    return null;
  }

  static String _entryText(ArchiveFile entry) {
    entry.decompress();
    return utf8.decode(entry.content as List<int>);
  }

  // ── workbook relationships ───────────────────────────────────

  static Map<String, String> _relationships(Archive archive) {
    final result = <String, String>{};
    final relsEntry = _entry(archive, 'xl/_rels/workbook.xml.rels');
    if (relsEntry == null) return result;

    final XmlDocument rels;
    try {
      rels = XmlDocument.parse(_entryText(relsEntry));
    } catch (_) {
      return result;
    }

    for (final node in rels.descendantsNamed('Relationship')) {
      final id = node.getAttribute('Id');
      final target = node.getAttribute('Target');
      if (id != null && target != null) {
        result[id] = target;
      }
    }
    return result;
  }

  static String _resolveTarget(String target) {
    var path = target.startsWith('/') ? target.substring(1) : target;
    if (!path.startsWith('xl/')) {
      path = 'xl/$path';
    }
    while (path.contains('../')) {
      path = path.replaceFirst('../', '');
    }
    return path;
  }

  // ── shared strings ───────────────────────────────────────────

  static List<String> _sharedStrings(
      Archive archive, Map<String, String> rels) {
    var target = 'xl/sharedStrings.xml';
    for (final entry in rels.entries) {
      if (entry.value.toLowerCase().endsWith('/sharedstrings')) {
        target = _resolveTarget(entry.value);
        break;
      }
    }

    final entry = _entry(archive, target);
    if (entry == null) return const [];

    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(_entryText(entry));
    } catch (_) {
      return const [];
    }

    final result = <String>[];
    for (final si in doc.descendantsNamed('si')) {
      result.add(_textOf(si));
    }
    return result;
  }

  /// Concatenates text of all `t` descendants, skipping phonetic runs.
  static String _textOf(XmlElement node) {
    final buffer = StringBuffer();
    for (final t in node.descendantsNamed('t')) {
      if (t.ancestors.any((a) => a is XmlElement && a.localName == 'rPh')) {
        continue;
      }
      buffer.write(t.innerText);
    }
    return buffer.toString();
  }

  // ── sheet rows ───────────────────────────────────────────────

  static List<List<String?>> _parseRows(
    XmlElement? sheetData,
    List<String> sharedStrings,
    Map<int, String> dateStyles,
    bool date1904,
  ) {
    if (sheetData == null) return const [];

    var maxColumn = 0;
    final rowMap = <int, Map<int, String?>>{};
    var maxRow = 0;

    for (final row in sheetData.childrenNamed('row')) {
      final rowNumber = int.tryParse(row.getAttribute('r') ?? '') ?? 0;
      final index = rowNumber - 1;
      if (index < 0) continue;
      if (index > maxRow) maxRow = index;

      final cells = rowMap.putIfAbsent(index, () => <int, String?>{});
      for (final cell in row.childrenNamed('c')) {
        final column = _columnFromRef(cell.getAttribute('r'));
        if (column == null) continue;
        var value = _cellValue(cell, sharedStrings);
        final format = dateStyles[int.tryParse(cell.getAttribute('s') ?? '')];
        if (format != null &&
            (cell.getAttribute('t') == null || cell.getAttribute('t') == 'n')) {
          final serial = double.tryParse(value ?? '');
          if (serial != null && serial.isFinite) {
            final base =
                date1904 ? DateTime.utc(1904) : DateTime.utc(1899, 12, 30);
            final adjusted = !date1904 && serial < 60 ? serial + 1 : serial;
            final date = base.add(Duration(
                microseconds:
                    (adjusted * Duration.microsecondsPerDay).round()));
            value = switch (format) {
              'time' => date.toIso8601String().substring(11, 19),
              'date' => date.toIso8601String().substring(0, 10),
              _ => date.toIso8601String().replaceFirst('Z', ''),
            };
          }
        }
        cells[column] = value;
        if (column + 1 > maxColumn) maxColumn = column + 1;
      }
    }

    final rows = <List<String?>>[];
    for (int r = 0; r <= maxRow; r++) {
      final cells = rowMap[r] ?? const <int, String?>{};
      final row = List<String?>.filled(maxColumn, null);
      cells.forEach((column, value) {
        row[column] = value;
      });
      rows.add(row);
    }
    return rows;
  }

  /// Parses a cell reference like "B5" into a zero-based column index.
  static int? _columnFromRef(String? ref) {
    if (ref == null || ref.isEmpty) return null;
    int column = 0;
    for (int i = 0; i < ref.length; i++) {
      final code = ref.codeUnitAt(i);
      if (code >= 0x41 && code <= 0x5A) {
        column = column * 26 + (code - 0x40);
      } else {
        break;
      }
    }
    return column > 0 ? column - 1 : null;
  }

  static String? _cellValue(XmlElement cell, List<String> sharedStrings) {
    final type = cell.getAttribute('t');
    switch (type) {
      case 's':
        final index = int.tryParse(
          cell.childrenNamed('v').firstOrNull?.innerText ?? '',
        );
        if (index == null || index < 0 || index >= sharedStrings.length) {
          return null;
        }
        return sharedStrings[index];
      case 'inlineStr':
        final inline = cell.childrenNamed('is').firstOrNull;
        if (inline == null) return null;
        final text = _textOf(inline);
        return text.isEmpty ? null : text;
      case 'b':
        final v = cell.childrenNamed('v').firstOrNull?.innerText;
        return v == '1' ? 'TRUE' : 'FALSE';
      case 'e':
      case 'str':
        return cell.childrenNamed('v').firstOrNull?.innerText;
      default:
        return cell.childrenNamed('v').firstOrNull?.innerText;
    }
  }
}

/// OOXML producers may use default namespaces or arbitrary prefixes (x:row).
extension _LocalXmlNames on XmlNode {
  Iterable<XmlElement> descendantsNamed(String name) => descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == name);
  Iterable<XmlElement> childrenNamed(String name) => children
      .whereType<XmlElement>()
      .where((element) => element.name.local == name);
}
