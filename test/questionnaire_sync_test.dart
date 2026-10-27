import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/questionnaire_sync_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';

void main() {
  test(
      'Google Sheets updates reuse XLSForm parser and preserve records and versions',
      () async {
    final db = AppDatabase.forTesting();
    try {
      final id = await db.insertProject(
          const ProjectsCompanion(name: drift.Value('Salinity')));
      final workspace = await ProjectWorkspaceService(db).load(id);
      await db.upsertSyncConfig(
          projectId: id,
          syncEndpointUrl: 'https://script.google.com/macros/s/test/exec',
          syncApiKey: 'enum-key');
      var label = 'Salinity (ppt)';
      final client = MockClient((request) async {
        final payload = jsonDecode(request.body);
        expect(payload['action'], 'get_questionnaire');
        expect(payload['apiKey'], 'enum-key');
        return http.Response(
            jsonEncode({
              'ok': true,
              'projectId': workspace.project.externalId,
              'sheets': {
                'survey': [
                  ['type', 'name', 'label', 'required', 'constraint'],
                  ['decimal', 'salinity', label, 'yes', '. >= 0'],
                  ['select_one water', 'water', 'Water type', 'yes', '']
                ],
                'choices': [
                  ['list_name', 'name', 'label'],
                  ['water', 'fresh', 'Fresh'],
                  ['water', 'salt', 'Saline']
                ],
                'settings': [
                  ['form_id', 'form_title', 'version'],
                  ['salinity', 'Salinity form', '1']
                ]
              }
            }),
            200);
      });
      final service = QuestionnaireSyncService(db, client: client);
      final first = await service.check(id);
      expect(first.changed, isTrue);
      expect(first.form.questions[1].choices!.length, 2);
      final firstId = (await service.apply(first))!;
      final session = await db.insertSurveySession(SurveySessionsCompanion(
          projectId: drift.Value(id),
          title: const drift.Value('Saved'),
          responses: drift.Value(jsonEncode({
            'form_snapshot': first.form.toJson(),
            'answers': {'salinity': '4'}
          }))));
      expect((await service.check(id)).changed, isFalse);
      label = 'Salinity at 25 C (ppt)';
      final second = await service.check(id);
      expect(second.form.version, 2);
      expect(second.changed, isTrue);
      final secondId = await service.apply(second);
      expect(secondId, isNot(firstId));
      expect((await db.getStoredFormsForProject(id)).length, 2);
      expect((await ProjectWorkspaceService(db).load(id)).forms.length, 1);
      expect((await ProjectWorkspaceService(db).load(id)).form!.id, secondId);
      expect(
          jsonDecode((await db.getSurveySession(session))!.responses)[
              'form_snapshot']['questions'][0]['label'],
          'Salinity (ppt)');
      expect(await service.apply(second), secondId);
      label = 'Salinity (ppt)';
      final reverted = await service.check(id);
      expect(reverted.form.version, 3);
      await service.apply(reverted);
      expect((await ProjectWorkspaceService(db).load(id)).schema!.version, 3);
      expect((await db.getStoredFormsForProject(id)).length,
          3); // retry never duplicates
    } finally {
      await db.close();
    }
  });
  test('wrong-project and unsupported XLSForms never mutate the database',
      () async {
    final db = AppDatabase.forTesting();
    try {
      final id = await db
          .insertProject(const ProjectsCompanion(name: drift.Value('Field')));
      final workspace = await ProjectWorkspaceService(db).load(id);
      await db.upsertSyncConfig(
          projectId: id, syncEndpointUrl: 'https://script.google.com/test');
      final wrong = QuestionnaireSyncService(db,
          client: MockClient((_) async => http.Response(
              jsonEncode({'ok': true, 'projectId': 'wrong'}), 200)));
      await expectLater(wrong.check(id), throwsFormatException);
      final bad = QuestionnaireSyncService(db,
          client: MockClient((_) async => http.Response(
              jsonEncode({
                'ok': true,
                'projectId': workspace.project.externalId,
                'sheets': {
                  'survey': [
                    ['type', 'name', 'label'],
                    ['begin_repeat', 'r', 'Repeat'],
                    ['text', 'x', 'X'],
                    ['end_repeat', '', '']
                  ]
                }
              }),
              200)));
      await expectLater(bad.check(id), throwsA(anything));
      expect(await db.getStoredFormsForProject(id), isEmpty);
    } finally {
      await db.close();
    }
  });
  test('shared connection is optional and imports without retyping', () async {
    final db = AppDatabase.forTesting();
    final other = AppDatabase.forTesting();
    try {
      final id = await db
          .insertProject(const ProjectsCompanion(name: drift.Value('Share')));
      await db.upsertSyncConfig(
          projectId: id,
          syncEndpointUrl: 'https://script.google.com/test',
          syncApiKey: 'enum-key');
      final project = (await db.getProjectById(id))!;
      final exporter = ProjectExporter(db);
      expect(
          (await exporter.buildData(project))
              .settings
              .containsKey('sync_connection'),
          isFalse);
      final package =
          await exporter.buildData(project, includeSyncConnection: true);
      final imported =
          await ProjectImporter(other).commitData(package, newCopy: false);
      expect((await other.getSyncConfig(imported.projectId))!.syncApiKey,
          'enum-key');
      expect((await other.getSyncConfig(imported.projectId))!.syncEndpointUrl,
          'https://script.google.com/test');
    } finally {
      await db.close();
      await other.close();
    }
  });
}
