import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/field_accuracy_review_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/field_quality_screen.dart';

void main() {
  late AppDatabase db;
  late int projectId;
  late Directory temp;
  setUp(() async {
    db = AppDatabase.forTesting();
    temp = await Directory.systemTemp.createTemp('accuracy-review-');
    projectId = await db.into(db.projects).insert(ProjectsCompanion.insert(
        name: 'CARE', externalId: const drift.Value('care')));
  });
  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });
  Future<void> insert(double accuracy, {String title = 'Field photo'}) async {
    await db.into(db.surveySessions).insert(SurveySessionsCompanion.insert(
        projectId: projectId,
        title: title,
        status: const drift.Value('saved'),
        externalId: drift.Value(title),
        responses: drift.Value(jsonEncode({
          'photo': {
            'path': 'test.jpg',
            'accuracy': accuracy,
            'captured_at': '2026-10-13T10:00:00Z',
            'latitude': 23.8,
            'longitude': 90.4
          },
          'answers': {
            'photo': {
              'path': 'test.jpg',
              'accuracy': accuracy,
              'captured_at': '2026-10-13T10:00:00Z',
              'latitude': 23.8,
              'longitude': 90.4
            }
          }
        }))));
  }

  Future<List<AccuracyFinding>> scan(double limit,
          {Set<String> accepted = const {}}) async =>
      FieldAccuracyReviewService.scan(
          sessions: await db.getSurveySessionsByProject(projectId),
          forms: [],
          sites: [],
          limitM: limit,
          acceptedKeys: accepted);
  test(
      'only readings strictly above limit; repeated photo reference is deduplicated',
      () async {
    await insert(100);
    await insert(50, title: 'At limit');
    await insert(10, title: 'Good');
    await insert(-1, title: 'Unknown');
    expect(await scan(50), hasLength(1));
    expect((await scan(50)).single.accuracyM, 100);
    expect(await scan(100), isEmpty);
    expect(await scan(10), hasLength(2));
  });
  test(
      'acceptance survives reload and limit changes; undo restores the finding',
      () async {
    await insert(100);
    final finding = (await scan(10)).single;
    await FieldAccuracyReviewService(db).accept('care', finding);
    final stored = await FieldAccuracyReviewService(db).accepted('care');
    expect(await scan(50, accepted: stored.keys.toSet()), isEmpty);
    expect(await FieldAccuracyReviewService(db).accepted('other-project'),
        isEmpty);
    await FieldAccuracyReviewService(db).undo('care', finding.key);
    expect(
        await scan(10,
            accepted: (await FieldAccuracyReviewService(db).accepted('care'))
                .keys
                .toSet()),
        hasLength(1));
    expect((await db.getSurveySessionsByProject(projectId)).single.responses,
        contains('test.jpg'));
  });
  test('a changed reading has a new review key', () async {
    await insert(100);
    final sessions = await db.getSurveySessionsByProject(projectId);
    final first = (await scan(10)).single;
    final response = jsonDecode(sessions.single.responses);
    response['photo']['accuracy'] = 150;
    response['answers']['photo']['accuracy'] = 150;
    await (db.update(db.surveySessions)
          ..where((t) => t.id.equals(sessions.single.id)))
        .write(SurveySessionsCompanion(
            responses: drift.Value(jsonEncode(response))));
    expect(await scan(10, accepted: {first.key}), hasLength(1));
  });
  test('geopoint accuracy uses comma accuracy and ODK fourth component',
      () async {
    final form = SurveyForm(
        id: 'gps',
        name: 'GPS',
        description: '',
        questions: [
          Question(
              name: 'point',
              label: 'Site location',
              type: QuestionType.geopoint)
        ]);
    for (final value in ['23.8,90.4,100', '23.8 90.4 0 80', '23.8,90.4,10']) {
      await db.into(db.surveySessions).insert(SurveySessionsCompanion.insert(
          projectId: projectId,
          title: value,
          status: const drift.Value('saved'),
          responses: drift.Value(jsonEncode({
            'form_snapshot': form.toJson(),
            'answers': {'point': value, 'salinity': 200}
          }))));
    }
    final issues = await scan(50);
    expect(issues.map((issue) => issue.accuracyM), [100, 80]);
  });
  test('accepting multiple findings concurrently keeps both decisions',
      () async {
    await insert(100);
    await insert(150, title: 'Second');
    final findings = await scan(10);
    final service = FieldAccuracyReviewService(db);
    await Future.wait(
        findings.map((finding) => service.accept('care', finding)));
    expect(await service.accepted('care'), hasLength(2));
  });

  testWidgets(
      'screen reviews accuracy only, accepts persistently, and applies selected limit',
      (tester) async {
    await insert(100);
    await insert(50, title: 'Second photo');
    await tester.pumpWidget(MaterialApp(
        home: FieldQualityScreen(
            projectId: projectId,
            database: db,
            studyAreaStore: StudyAreaStore(baseDir: temp))));
    await tester.pumpAndSettle();
    expect(find.text('Nearby feature review distance'), findsNothing);
    expect(find.text('Accept accuracy'), findsNWidgets(2));
    await tester.tap(find.text('Accept accuracy').first);
    await tester.pumpAndSettle();
    expect(find.text('Accept accuracy'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<double>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 m').last);
    await tester.pumpAndSettle();
    expect(find.text('No GPS readings above the limit need review.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(MaterialApp(
        home: FieldQualityScreen(
            projectId: projectId,
            database: db,
            studyAreaStore: StudyAreaStore(baseDir: temp))));
    await tester.pumpAndSettle();
    expect(find.text('50 m'), findsOneWidget);
    expect(find.text('Accept accuracy'), findsNothing);
  });
}
