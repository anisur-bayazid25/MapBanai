import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'helpers/test_utils.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('Projects', () {
    test('createProject stores name, description and default threshold', () async {
      await db.createProject('Riverbank Survey',
          description: 'North bank erosion check');

      final project = await db.getProjectByName('Riverbank Survey');
      expect(project, isNotNull);
      expect(project!.description, 'North bank erosion check');
      expect(project.archived, isFalse);
      expect(project.gpsThresholdM, 10);
    });

    test('projectExists detects duplicates (case/space trimmed)', () async {
      await db.createProject('Riverbank');
      expect(await db.projectExists('  riverbank '), isFalse);
      expect(await db.projectExists('Riverbank'), isTrue);
    });

    test('getProjects excludes archived unless requested', () async {
      await db.createProject('Alpha');
      await db.createProject('Beta');
      final beta = await db.getProjectByName('Beta');
      await db.archiveProject(beta!.id, archived: true);

      final active = await db.getProjects();
      expect(active.map((p) => p.name), ['Alpha']);

      final all = await db.getProjects(includeArchived: true);
      expect(all.map((p) => p.name), ['Alpha', 'Beta']);
    });

    test('updateProject edits name, description and GPS threshold', () async {
      await db.createProject('Old Name');
      final project = await db.getProjectByName('Old Name');

      await db.updateProject(
        project!.id,
        name: 'New Name',
        description: 'Updated description',
        gpsThresholdM: 20,
      );

      final updated = await db.getProjectByName('New Name');
      expect(updated!.description, 'Updated description');
      expect(updated.gpsThresholdM, 20);
      expect(await db.getProjectByName('Old Name'), isNull);
    });

    test('archive and restore project keeps sessions', () async {
      await db.createProject('Riverbank');
      final project = await db.getProjectByName('Riverbank');
      await db.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(project!.id),
          title: const drift.Value('S1'),
          status: const drift.Value('saved'),
        ),
      );

      await db.archiveProject(project.id, archived: true);
      expect((await db.getProjectByName('Riverbank'))!.archived, isTrue);
      expect(await db.surveySessionCountForProject(project.id), 1);

      await db.archiveProject(project.id, archived: false);
      expect((await db.getProjectByName('Riverbank'))!.archived, isFalse);
    });
  });

  group('Survey sessions', () {
    test('insert and count sessions per project', () async {
      await db.createProject('Project A');
      await db.createProject('Project B');
      final a = await db.getProjectByName('Project A');
      final b = await db.getProjectByName('Project B');
      if (a == null || b == null) return;

      for (var i = 0; i < 3; i++) {
        await db.insertSurveySession(
          SurveySessionsCompanion(
            projectId: drift.Value(a.id),
            title: drift.Value('Session $i'),
            status: const drift.Value('saved'),
          ),
        );
      }
      await db.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(b.id),
          title: const drift.Value('Session 0'),
          status: const drift.Value('draft'),
        ),
      );

      expect(await db.surveySessionCountForProject(a.id), 3);
      expect(await db.surveySessionCountForProject(b.id), 1);
      expect(await db.getSurveySessions(), hasLength(4));
    });

    test('responses JSON round-trips with user name', () async {
      await db.createProject('Project A');
      final project = await db.getProjectByName('Project A');
      await db.setSetting('user_name', 'Tanvir');

      final responses = jsonEncode({
        'form_id': 'demo_form',
        'form_name': 'Demo Form',
        'user_name': await db.getSetting('user_name'),
        'answers': {'site_name': 'Site 1', 'height_m': 12},
      });
      await db.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(project!.id),
          title: const drift.Value('Site 1'),
          status: const drift.Value('saved'),
          responses: drift.Value(responses),
        ),
      );

      final rows = await db.getSurveySessions();
      final decoded = jsonDecode(rows.single.responses) as Map<String, dynamic>;
      expect(decoded['user_name'], 'Tanvir');
      expect(decoded['answers'], {'site_name': 'Site 1', 'height_m': 12});
    });
  });

  group('Stored forms', () {
    test('CRUD round trip', () async {
      final form = sampleSurveyForm();
      final json = jsonEncode(form.toJson());

      await db.insertStoredForm(
        StoredFormsCompanion(
          name: drift.Value(form.name),
          description: drift.Value(form.description),
          json: drift.Value(json),
        ),
      );

      final stored = await db.getStoredFormByName('Demo Form');
      expect(stored, isNotNull);
      expect(db.getStoredForms(), isA<Future<List<StoredForm>>>());

      await db.updateStoredForm(
        stored!.id,
        name: 'Demo Form v2',
        version: 2,
      );
      expect(await db.getStoredFormByName('Demo Form v2'), isNotNull);
      expect(await db.getStoredFormByName('Demo Form'), isNull);

      await db.deleteStoredForm(stored.id);
      expect(await db.getStoredForms(), isEmpty);
    });

    test('updateStoredForm replaces JSON content', () async {
      await db.insertStoredForm(
        const StoredFormsCompanion(
          name: drift.Value('Form'),
          json: drift.Value('{"a":1}'),
        ),
      );
      final stored = (await db.getStoredForms()).single;

      await db.updateStoredForm(stored.id, json: '{"b":2}');

      final reloaded = (await db.getStoredForms()).single;
      expect(reloaded.json, '{"b":2}');
    });
  });

  group('Settings', () {
    test('set and get round trip, upsert overwrites', () async {
      expect(await db.getSetting('user_name'), isNull);

      await db.setSetting('user_name', 'Tanvir');
      expect(await db.getSetting('user_name'), 'Tanvir');

      await db.setSetting('user_name', 'Rina');
      expect(await db.getSetting('user_name'), 'Rina');
    });
  });

  group('GPS logs', () {
    test('CRUD round trip', () async {
      await db.insertGpsLog(
        GpsLogsCompanion.insert(
          name: 'Morning Track',
          surveyor: const drift.Value('Tanvir'),
        ),
      );
      await db.insertGpsLog(
        GpsLogsCompanion.insert(name: 'Evening Track'),
      );

      var logs = await db.getGpsLogs();
      expect(logs, hasLength(2));
      expect(logs.first.surveyor, 'Tanvir');

      await db.renameGpsLog(logs.first.id, 'Renamed Track');
      logs = await db.getGpsLogs();
      expect(logs.first.name, 'Renamed Track');

      await db.deleteGpsLog(logs.first.id);
      expect(await db.getGpsLogs(), hasLength(1));
    });
  });

  group('Reset data', () {
    test('clears projects, sessions, forms and logs but keeps user name',
        () async {
      await db.setSetting('user_name', 'Tanvir');
      await db.createProject('Reset Project');
      final project = await db.getProjectByName('Reset Project');
      await db.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(project!.id),
          title: const drift.Value('Session to wipe'),
          status: const drift.Value('saved'),
        ),
      );
      await db.insertStoredForm(
        StoredFormsCompanion.insert(name: 'Form to wipe', json: '{}'),
      );
      await db.insertGpsLog(GpsLogsCompanion.insert(name: 'Log to wipe'));

      await db.resetAllData();

      expect(await db.getProjects(), isEmpty);
      expect(await db.getSurveySessions(), isEmpty);
      expect(await db.getStoredForms(), isEmpty);
      expect(await db.getGpsLogs(), isEmpty);
      expect(await db.getSetting('user_name'), 'Tanvir');
    });
  });
}