import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/field_quality_screen.dart';
import 'package:mapbanai/ui/guided_visit_screen.dart';

class VisitMemoryStore extends StudyAreaStore {
  final List<StudyAreaSite> records;
  VisitMemoryStore(this.records);
  @override
  Future<List<StudyAreaSite>> loadSites() async => records;
}

void main() {
  testWidgets(
      'leaving survey preserves typed answers and feature changes as resumable visit draft',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting();
    final projectId = await db.insertProject(
        const ProjectsCompanion(name: drift.Value('Field project')));
    final site = StudyAreaSite(
        id: 'site',
        projectId: projectId,
        latitude: 23,
        longitude: 90,
        attributes: {'name': 'Baseline'});
    final store = VisitMemoryStore([site]);
    final form = SurveyForm(
        id: 'field',
        name: 'Field form',
        description: '',
        questions: [
          Question(
              name: 'condition',
              label: 'Condition',
              type: QuestionType.text,
              required: true)
        ]);
    await db.insertStoredForm(StoredFormsCompanion(
        projectId: drift.Value(projectId),
        name: drift.Value(form.name),
        json: drift.Value(jsonEncode(form.toJson()))));
    final stored = (await db.getStoredFormsForProject(projectId)).single;
    final service = GuidedVisitService(database: db, sites: store);
    var draft = await service.start(projectId: projectId, site: site);
    draft = await service.saveDraft(session: draft, storedForm: stored);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GuidedVisitScreen(
                                projectId: projectId,
                                resumeSessionId: draft.id,
                                database: db,
                                studyAreaStore: store))),
                    child: const Text('Open visit'))))));
    await tester.tap(find.text('Open visit'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextField && widget.decoration?.labelText == 'name'),
        'Corrected baseline');
    await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Change or review note'),
        'Field correction');
    await tester.tap(find.text('Open survey'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Observed in field');
    await tester.pageBack();
    await tester.pumpAndSettle();
    var row = (await db.getSurveySession(draft.id))!;
    expect(GuidedVisitService.decode(row)['answers']['condition'],
        'Observed in field');
    expect(GuidedVisitService.visit(row)['form_validated'], isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    row = (await db.getSurveySession(draft.id))!;
    expect(row.status, 'draft');
    expect(GuidedVisitService.visit(row)['site_after']['attributes']['name'],
        'Corrected baseline');
    expect(GuidedVisitService.visit(row)['site_after']['status'], 'updated');
    expect(find.text('Open visit'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });

  testWidgets(
      'quality screen uses accuracy limit and excludes nearby feature pairs',
      (tester) async {
    final db = AppDatabase.forTesting();
    final projectId = await db.insertProject(
        const ProjectsCompanion(name: drift.Value('Field project')));
    for (var index = 0; index < 2; index++) {
      await db.insertSurveySession(SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value('Point $index'),
          status: const drift.Value('saved'),
          responses: drift.Value(jsonEncode({
            'feature_type': 'point',
            'latitude': 23 + index * 0.00003,
            'longitude': 90,
            'accuracy_m': index == 0 ? 6 : 12
          }))));
    }
    await tester.pumpWidget(MaterialApp(
        home: FieldQualityScreen(
            projectId: projectId,
            database: db,
            studyAreaStore: VisitMemoryStore([]))));
    await tester.pumpAndSettle();
    expect(find.textContaining('m apart'), findsNothing);
    expect(find.text('Accept accuracy'), findsOneWidget);
    expect(find.textContaining('above your limit'), findsOneWidget);
    await tester.tap(find.text('10 m'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 m').last);
    await tester.pumpAndSettle();
    expect(find.text('5 m'), findsOneWidget);
    expect(find.textContaining('m apart'), findsNothing);
    expect(find.text('Accept accuracy'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
