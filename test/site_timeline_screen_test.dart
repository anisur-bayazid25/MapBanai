import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/site_timeline_screen.dart';

class TimelineStore extends StudyAreaStore {
  final List<StudyAreaSite> sites;
  TimelineStore(this.sites);
  @override
  Future<List<StudyAreaSite>> loadSites() async => sites;
}

void main() {
  testWidgets(
      'mobile timeline compares separate visits and opens linked visit selector',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting();
    addTearDown(() async {
      await db.close();
    });
    final id = await db
        .insertProject(const ProjectsCompanion(name: drift.Value('Salinity')));
    final project = (await ProjectWorkspaceService(db).load(id)).project;
    final site = StudyAreaSite(
        id: 'site',
        projectId: id,
        projectExternalId: project.externalId,
        latitude: 23,
        longitude: 90,
        attributes: {
          'name': 'Station 1'
        },
        history: [
          for (var i = 0; i < 2; i++)
            StudyAreaRevision(
                id: 'revision-$i',
                visitId: 'visit-$i',
                timestamp: DateTime.utc(2026, 10, i + 1),
                author: 'Fieldworker',
                projectExternalId: project.externalId,
                after: {
                  'form_snapshot': {
                    'id': 'salt',
                    'name': 'Salinity',
                    'questions': [
                      {
                        'name': 'salt',
                        'label': 'Salinity (ppt)',
                        'type': 'decimal'
                      }
                    ]
                  },
                  'form_answers': {'salt': i == 0 ? 4.5 : 7.25},
                  'status': 'verified'
                })
        ]);
    final store = TimelineStore([site]);
    await tester.pumpWidget(MaterialApp(
        home: SiteTimelineScreen(
            database: db, store: store, projectId: id, site: site)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Change: 2.750'), findsOneWidget);
    expect(find.text('All observations (2)'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('7.25'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Add observation / start visit'));
    await tester.pumpAndSettle();
    expect(find.text('Guided visit — Salinity'), findsOneWidget);
    expect(find.text('Station 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
