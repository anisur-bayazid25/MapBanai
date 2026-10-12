import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/xlsform_parser.dart';
import 'package:mapbanai/services/xlsx_reader.dart';

class QuestionnaireUpdate {
  final int projectId;
  final SurveyForm form;
  final String fingerprint;
  final bool changed;
  final int? previousFormId;
  const QuestionnaireUpdate(this.projectId, this.form, this.fingerprint,
      this.changed, this.previousFormId);
}

/// Downloads worksheet rows from the project's Apps Script, then reuses XLSForm parsing.
class QuestionnaireSyncService {
  final AppDatabase db;
  final http.Client? client;
  QuestionnaireSyncService(this.db, {this.client});
  static String _fingerprint(SurveyForm form) {
    final schema = form.toJson()..remove('version');
    return sha256.convert(utf8.encode(jsonEncode(schema))).toString();
  }

  Future<QuestionnaireUpdate> check(int projectId) async {
    final workspace = await ProjectWorkspaceService(db).load(projectId);
    final config = await db.getSyncConfig(projectId);
    final uri = Uri.tryParse(config?.syncEndpointUrl ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException(
          "Configure this project's HTTPS Apps Script URL first.");
    }
    final httpClient = client ?? http.Client();
    try {
      final response = await _fetch(
          httpClient,
          uri,
          jsonEncode({
            'action': 'get_questionnaire',
            'projectId': workspace.project.externalId,
            'apiKey': config?.syncApiKey ?? ''
          })).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200)
        throw const FormatException(
            'Questionnaire server did not respond successfully.');
      if (response.bodyBytes.length > 10 * 1024 * 1024)
        throw const FormatException('Questionnaire response is too large.');
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        throw const FormatException(
            'Apps Script must return questionnaire JSON. Add the questionnaire handler to its deployment.');
      }
      if (data is! Map || data['ok'] != true)
        throw const FormatException(
            'Questionnaire unavailable. Check the Apps Script setup and API key.');
      if (data['projectId'] != workspace.project.externalId)
        throw const FormatException(
            'Questionnaire belongs to another project.');
      final rawSheets = data['sheets'];
      if (rawSheets is! Map || rawSheets['survey'] is! List)
        throw const FormatException(
            'Server must supply XLSForm survey, choices and settings sheets.');
      final sheets = <XlsxSheet>[];
      for (final name in ['survey', 'choices', 'settings']) {
        final rows = rawSheets[name];
        if (rows == null) continue;
        if (rows is! List || rows.length > 10000)
          throw const FormatException('Invalid or oversized worksheet.');
        final cells = <List<String?>>[];
        for (final row in rows) {
          if (row is! List || row.length > 200)
            throw const FormatException('Invalid worksheet row.');
          cells.add(
              [for (final cell in row) cell == null ? null : cell.toString()]);
        }
        sheets.add(XlsxSheet(name, cells));
      }
      final parsed = await Isolate.run(() => XlsFormParser.parseWorkbook(
          XlsxWorkbook(sheets),
          fileName: data['fileName'] is String
              ? data['fileName']
              : 'online_survey.xlsx'));
      final fingerprint = _fingerprint(parsed);
      final forms = await db.getStoredFormsForProject(projectId);
      StoredForm? previous;
      for (final row in forms) {
        final form = SurveyForm.fromJson(jsonDecode(row.json));
        if (form.id == parsed.id &&
            (previous == null || row.version > previous.version))
          previous = row;
      }
      final changed = previous == null ||
          _fingerprint(SurveyForm.fromJson(jsonDecode(previous.json))) !=
              fingerprint;
      final version = previous == null
          ? parsed.version
          : (parsed.version > previous.version
              ? parsed.version
              : previous.version + (changed ? 1 : 0));
      final form =
          SurveyForm.fromJson({...parsed.toJson(), 'version': version});
      return QuestionnaireUpdate(
          projectId, form, fingerprint, changed, previous?.id);
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<int?> apply(QuestionnaireUpdate update) async {
    if (!update.changed) return null;
    return db.transaction(() async {
      final workspace =
          await ProjectWorkspaceService(db).load(update.projectId);
      final rows = await db.getStoredFormsForProject(update.projectId);
      for (final row in rows) {
        final existing = SurveyForm.fromJson(jsonDecode(row.json));
        if (existing.id == update.form.id &&
            row.version == update.form.version &&
            _fingerprint(existing) == update.fingerprint) return row.id;
        if (existing.id == update.form.id &&
            row.version >= update.form.version) {
          throw const FormatException(
              'The local questionnaire changed. Check for updates again.');
        }
      }
      final id = await db.insertStoredForm(StoredFormsCompanion(
          projectId: drift.Value(update.projectId),
          name: drift.Value('${update.form.name} (v${update.form.version})'),
          description: drift.Value(update.form.description),
          json: drift.Value(jsonEncode(update.form.toJson())),
          version: drift.Value(update.form.version)));
      final latestKey = 'questionnaire_latest_${update.projectId}';
      final rawLatest = await db.getSetting(latestKey);
      final latest = rawLatest == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(rawLatest));
      latest[update.form.id] = id;
      await db.setSetting(latestKey, jsonEncode(latest));
      if (workspace.form == null || workspace.schema?.id == update.form.id) {
        await ProjectWorkspaceService(db).select(update.projectId, formId: id);
      }
      await db.setSetting('questionnaire_updated_${update.projectId}',
          DateTime.now().toUtc().toIso8601String());
      return id;
    });
  }

  Future<http.Response> _fetch(http.Client client, Uri uri, String body) async {
    var method = 'POST';
    String? payload = body;
    for (var hop = 0; hop < 6; hop++) {
      final request = http.Request(method, uri)..followRedirects = false;
      if (payload != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = payload;
      }
      final stream = await client.send(request);
      final buffer = BytesBuilder(copy: false);
      var length = 0;
      await for (final chunk in stream.stream) {
        length += chunk.length;
        if (length > 10 * 1024 * 1024)
          throw const FormatException('Questionnaire response is too large.');
        buffer.add(chunk);
      }
      final response = http.Response.bytes(
          buffer.takeBytes(), stream.statusCode,
          headers: stream.headers);
      if (response.statusCode < 301 || response.statusCode > 308)
        return response;
      final location = response.headers['location'];
      if (location == null)
        throw const FormatException('Missing redirect target.');
      final next = uri.resolve(location);
      final host = next.host.toLowerCase();
      if (next.scheme != 'https' ||
          !(host.endsWith('.google.com') ||
              host.endsWith('.googleusercontent.com'))) {
        throw const FormatException('Unexpected questionnaire redirect.');
      }
      uri = next;
      method = 'GET';
      payload = null; // Apps Script ContentService cached result.
    }
    throw const FormatException('Too many questionnaire redirects.');
  }
}
