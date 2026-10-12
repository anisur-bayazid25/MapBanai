import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';

void main() {
  late Directory directory;
  late StudyAreaStore alice;
  late StudyAreaStore bob;
  final baseline = StudyAreaSite(
      id: 'site-001',
      latitude: 23,
      longitude: 90,
      attributes: {'name': 'Original', 'count': '12'},
      sourceProperties: {'name': 'Original', 'count': 12},
      projectId: 7);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('study_team_');
    alice = StudyAreaStore(baseDir: Directory('${directory.path}/alice'));
    bob = StudyAreaStore(baseDir: Directory('${directory.path}/bob'));
    await alice.saveSites([baseline]);
    await bob.saveSites([baseline]);
  });
  tearDown(() => directory.delete(recursive: true));
  test('clearing displayed sites preserves other projects', () async {
    await alice.saveSites([
      baseline,
      StudyAreaSite(
          id: 'other-project',
          latitude: 24,
          longitude: 91,
          attributes: {},
          projectId: 8),
    ]);
    await alice.deleteSites({'site-001'});
    expect((await alice.loadSites()).single.id, 'other-project');
  });
  Future<StudyAreaSite> edit(StudyAreaStore store, String name,
      {String? visitId}) async {
    final current = (await store.loadSites()).single;
    final updated = current.revised(
        latitude: 23,
        longitude: 90,
        attributes: {...current.attributes, 'name': name},
        status: StudyAreaStatus.updated,
        changeNote: 'Visited');
    await store.updateSite(updated,
        author: name,
        visitId: visitId,
        sessionId: 42,
        formId: 3,
        photoPath: '/field/photo.jpg');
    return updated;
  }

  test(
      'optimistic revisions reject stale edits and preserve durable linked history',
      () async {
    final stale = (await alice.loadSites()).single;
    final updated = await edit(alice, 'Alice', visitId: 'visit-1');
    expect(updated.revision, 1);
    expect(updated.history.length, 1);
    final record = (await alice.loadSites()).single.history.single;
    expect(record.before!['attributes']['name'], 'Original');
    expect(record.after['attributes']['name'], 'Alice');
    expect(record.author, 'Alice');
    expect(record.visitId, 'visit-1');
    expect(record.sessionId, 42);
    expect(record.projectId, 7);
    expect(record.photoPath, '/field/photo.jpg');
    final staleEdit = stale.revised(
        latitude: 23,
        longitude: 90,
        attributes: {'name': 'Stale'},
        status: StudyAreaStatus.updated);
    await expectLater(
        alice.updateSite(staleEdit), throwsA(isA<StudyAreaConflict>()));
    expect((await alice.loadSites()).single.attributes['name'], 'Alice');
    await alice.updateSite(updated, visitId: 'visit-1');
    expect((await alice.loadSites()).single.history.length, 1,
        reason: 'replayed completed visit must be idempotent');
    final different = updated.revised(
        latitude: 23,
        longitude: 90,
        attributes: {'name': 'Different'},
        status: StudyAreaStatus.updated);
    await expectLater(
        alice.updateSite(different, visitId: 'visit-1'), throwsStateError);
  });
  test(
      'GeoJSON team export retains exact typed state, IDs, revisions and history',
      () async {
    final changed = await edit(alice, 'Alice');
    final incoming =
        StudyAreaService.parseGeoJson(StudyAreaService.toGeoJson([changed]))
            .single;
    expect(incoming.revisionToken, changed.revisionToken);
    expect(incoming.revision, 1);
    expect(studyAreaCanonicalJson(incoming.stateSnapshot()),
        studyAreaCanonicalJson(changed.stateSnapshot()));
    expect(incoming.history.single.before!['source_properties']['count'], 12);
    final preview = await bob.previewMerge([incoming]);
    expect(preview.conflicts, isEmpty);
    expect(preview.updates, 1);
    final merged = await bob.applyMerge(preview, author: 'Bob import');
    expect(merged.updated, 1);
    final result = (await bob.loadSites()).single;
    expect(result.attributes['name'], 'Alice');
    expect(result.history.length, 2);
    expect(result.history.last.action, 'team_merge');
    final repeated = await bob.previewMerge([incoming]);
    expect(repeated.conflicts, isEmpty);
    expect(repeated.unchanged, 1);
  });
  test(
      'divergent team branches require resolution and keep both alternatives audited',
      () async {
    final fromAlice = await edit(alice, 'Alice');
    final fromBob = await edit(bob, 'Bob');
    final incoming =
        StudyAreaService.parseGeoJson(StudyAreaService.toGeoJson([fromAlice]));
    final preview = await bob.previewMerge(incoming);
    expect(preview.conflicts.length, 1);
    await expectLater(bob.applyMerge(preview), throwsStateError);
    expect((await bob.loadSites()).single.revisionToken, fromBob.revisionToken);
    final result = await bob.applyMerge(preview,
        resolutions: {'site-001': StudyAreaMergeChoice.useIncoming},
        author: 'Team lead');
    expect(result.updated, 1);
    final merged = (await bob.loadSites()).single;
    expect(merged.history.length, 3);
    expect(merged.history.last.before!['attributes']['name'], 'Bob');
    expect(merged.history.last.after['attributes']['name'], 'Alice');
    expect(merged.history.last.author, 'Team lead');
    expect(merged.original!['attributes']['name'], 'Original');
  });
  test('keep-local and preserve-as-new are explicit, lossless conflict choices',
      () async {
    final incoming = await edit(alice, 'Alice');
    await edit(bob, 'Bob');
    var preview = await bob.previewMerge([incoming]);
    await bob.applyMerge(preview,
        resolutions: {incoming.id: StudyAreaMergeChoice.keepLocal});
    expect((await bob.loadSites()).single.attributes['name'], 'Bob');
    preview = await bob.previewMerge([incoming]);
    final result = await bob.applyMerge(preview,
        resolutions: {incoming.id: StudyAreaMergeChoice.preserveAsNew},
        author: 'Reviewer');
    expect(result.added, 1);
    final rows = await bob.loadSites();
    expect(rows.length, 2);
    final copy = rows.firstWhere((s) => s.id != incoming.id);
    expect(copy.attributes['name'], 'Alice');
    expect(copy.attributes['source_feature_id'], incoming.id);
    expect(copy.history.last.action, 'import_copy');
    expect(copy.status, StudyAreaStatus.newFeature);
  });
  test('import review invalidated by a concurrent local edit is atomic',
      () async {
    final incoming = await edit(alice, 'Alice');
    final preview = await bob.previewMerge([incoming]);
    await edit(bob, 'Bob newer');
    await expectLater(bob.applyMerge(preview), throwsStateError);
    expect((await bob.loadSites()).single.attributes['name'], 'Bob newer');
  });
  test(
      'changed-only export omits untouched baselines and retains all changed features',
      () async {
    final empty = jsonDecode(
        StudyAreaService.toGeoJson(await alice.loadSites(), changedOnly: true));
    expect(empty['features'], isEmpty);
    await edit(alice, 'Alice');
    final changes = jsonDecode(
        StudyAreaService.toGeoJson(await alice.loadSites(), changedOnly: true));
    expect(changes['features'].length, 1);
    expect(changes['mapbanai_exchange']['changed_only'], true);
  });
  test('initial imported baselines are audited without becoming field changes',
      () async {
    final raw = StudyAreaSite(id: 'extra', latitude: 24, longitude: 91);
    final result = await alice.applyMerge(await alice.previewMerge([raw]),
        author: 'Importer');
    expect(result.added, 1);
    final imported =
        (await alice.loadSites()).firstWhere((s) => s.id == 'extra');
    expect(imported.history.single.action, 'import');
    expect(imported.hasChanges, false);
  });

  test('team lineage uses stable project UUID rather than foreign local ID',
      () async {
    final local = (await bob.loadSites()).single;
    local.projectExternalId = 'project-uuid';
    await bob.saveSites([local]);
    final remote = (await alice.loadSites()).single;
    remote.projectExternalId = 'project-uuid';
    remote.projectId = 999;
    await alice.saveSites([remote]);
    final changed = await edit(alice, 'Remote fieldworker');
    final incoming =
        StudyAreaService.parseGeoJson(StudyAreaService.toGeoJson([changed]));
    final preview = await bob.previewMerge(incoming);
    expect(preview.conflicts, isEmpty);
    await bob.applyMerge(preview);
    final merged = (await bob.loadSites()).single;
    expect(merged.projectId, 7);
    expect(merged.projectExternalId, 'project-uuid');
    expect(merged.history.last.projectExternalId, 'project-uuid');
  });
}
