import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/guided_visit_screen.dart';
import 'package:mapbanai/ui/study_area_hub_screen.dart';

class _Sites extends StudyAreaStore {
  @override
  Future<List<StudyAreaDeletion>> loadDeletions() async => [];
  final records = <StudyAreaSite>[];
  @override
  Future<List<StudyAreaSite>> loadSites() async => List.from(records);
  @override
  Future<void> addSites(List<StudyAreaSite> sites,
      {bool replace = false}) async {
    if (replace) records.clear();
    records.addAll(sites);
  }
}

Widget app(Widget child,
        {String language = 'en', double scale = 1}) =>
    MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: child);

void main() {
  test('GIS name fields ignore case and padding without changing identity', () {
    final site = StudyAreaSite(
        id: 'project:layer:123',
        latitude: 23,
        longitude: 90,
        attributes: {
          'ID': '68',
          ' Name ': 'Bow Bazar',
          'Location': 'Beside Rail Line'
        });
    final identity = site.featureUuid;
    expect(site.displayName, 'Bow Bazar');
    expect(site.attributes[' Name '], 'Bow Bazar');
    expect(site.id, 'project:layer:123');
    expect(site.featureUuid, identity);
    site.attributes = {'NAME': '   ', 'site-name': 'STS 12'};
    expect(site.displayName, 'STS 12');
    site.attributes = {'ID': 'e7ec9cb6-3428-4e11-a5e0-05c30a7755b0'};
    expect(site.displayName, '23.00000, 90.00000');
  });

  test('Bangla catalogue covers every message and interpolation', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final bn =
        jsonDecode(File('lib/l10n/app_bn.arb').readAsStringSync()) as Map;
    final keys =
        en.keys.cast<String>().where((key) => !key.startsWith('@')).toSet();
    expect(bn.keys.cast<String>().where((key) => !key.startsWith('@')).toSet(),
        keys);
    for (final key in keys) {
      expect(bn[key], isA<String>(), reason: key);
      expect((bn[key] as String).trim(), isNotEmpty, reason: key);
      final placeholders = (en['@$key'] as Map?)?['placeholders'] as Map? ?? {};
      for (final placeholder in placeholders.keys) {
        expect(bn[key], contains('{$placeholder}'), reason: key);
      }
    }
  });

  testWidgets('language switch changes app copy and keeps interpolation values',
      (tester) async {
    Widget copy() => Builder(
        builder: (context) => Column(children: [
              Text(ui(context, 'Field Verification')),
              Text(ui(context, 'Collection round')),
              Text(ui(context, 'Pending')),
              Text(ui(context, 'Bad state: Enter a collection round name.')),
              Text(ui(context, 'Form "{v0}" saved', ['Salinity 2027'])),
              Text(ui(context, 'e.g., \${width} * \${length}')),
            ]));
    await tester.pumpWidget(app(copy(), language: 'bn'));
    await tester.pumpAndSettle();
    expect(find.text('মাঠে যাচাই'), findsOneWidget);
    expect(find.text('সংগ্রহ পর্ব'), findsOneWidget);
    expect(find.text('বাকি'), findsOneWidget);
    expect(find.text('সংগ্রহ পর্বের নাম লিখুন।'), findsOneWidget);
    expect(find.textContaining('Salinity 2027'), findsOneWidget);
    expect(find.text('যেমন \${width} * \${length}'), findsOneWidget);
    await tester.pumpWidget(app(copy()));
    await tester.pumpAndSettle();
    expect(find.text('Field Verification'), findsOneWidget);
    expect(find.text('Collection round'), findsOneWidget);
  });

  testWidgets(
      'fresh uploaded layer is searchable by Name and Location without opening map first',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting();
    final store = _Sites();
    final projectId = await db
        .insertProject(const ProjectsCompanion(name: Value('CARE fieldwork')));
    final vectors = ProjectVectorLayerService(db);
    await vectors.save(projectId, [
      {
        'id': 'facilities',
        'name': 'Shyampur Facilities',
        'role': 'study_area',
        'visible': true,
        'color': '#467ca1',
        'opacity': 0.8,
        'workflows': ['verification'],
        'features': [
          for (final name in ['Bow Bazar', 'Rail STS'])
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [90.438, 23.689]
              },
              'properties': {'Name': name, 'Location': 'Beside Rail Line'}
            }
        ]
      }
    ]);
    await ProjectWorkspaceService(db).select(projectId,
        layerId: 'vector:facilities', workflow: StudyWorkflow.verification);
    await tester.pumpWidget(app(
        GuidedVisitScreen(
            projectId: projectId, database: db, studyAreaStore: store),
        language: 'bn',
        scale: 1.5));
    await tester.pumpAndSettle();
    expect(store.records, hasLength(2));
    await tester.tap(find.byKey(const ValueKey('choose-visit-site')));
    await tester.pumpAndSettle();
    expect(find.text('Bow Bazar'), findsOneWidget);
    expect(find.text('Rail STS'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Bow');
    await tester.pumpAndSettle();
    expect(find.text('Rail STS'), findsNothing);
    await tester.tap(find.text('Bow Bazar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ভিজিট শুরু'));
    await tester.tap(find.text('ভিজিট শুরু'));
    await tester.pumpAndSettle();
    expect(find.text('১. Bow Bazar যাচাই করুন'), findsOneWidget);
    final draft = (await db.getSurveySessionsByProject(projectId)).single;
    expect(GuidedVisitService.visit(draft)['site_id'], store.records.first.id);
    expect(GuidedVisitService.visit(draft)['site_after']['attributes']['Name'],
        'Bow Bazar');
    expect(tester.takeException(), isNull);
    // Opening from the map resumes the same draft, with the mode's selected layer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(GuidedVisitScreen(
        projectId: projectId,
        initialSiteId: store.records.first.id,
        database: db,
        studyAreaStore: store)));
    await tester.pumpAndSettle();
    expect(find.text('1. Verify Bow Bazar'), findsOneWidget);
    final heading = tester.getRect(find.text('1. Verify Bow Bazar'));
    final outcome =
        tester.getRect(find.byType(DropdownButtonFormField<StudyAreaStatus>));
    expect(outcome.top - heading.bottom, greaterThanOrEqualTo(16));
    final collectHeading = find.text('2. Collect information');
    await tester.ensureVisible(collectHeading);
    await tester.pumpAndSettle();
    final form = tester.getRect(find.byType(DropdownButtonFormField<int>).last);
    expect(form.top - tester.getRect(collectHeading).bottom,
        greaterThanOrEqualTo(16));

    expect((await db.getSurveySessionsByProject(projectId)), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });

  testWidgets('workflow hub uses Bangla at narrow width and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting();
    final id = await db
        .insertProject(const ProjectsCompanion(name: Value('Dhaka salinity')));
    await tester.pumpWidget(app(StudyAreaHubScreen(database: db, projectId: id),
        language: 'bn', scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('মাঠে যাচাই'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('পুনরাবৃত্ত তথ্য সংগ্রহ'), 200);
    expect(find.text('পুনরাবৃত্ত তথ্য সংগ্রহ'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('স্টাডি এরিয়া ভিজিট'), 200);
    expect(find.text('স্টাডি এরিয়া ভিজিট'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
