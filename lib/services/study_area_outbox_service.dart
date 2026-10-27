import 'package:mapbanai/services/study_area_store.dart';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/study_area_service.dart';

/// Makes study-area edits available to the existing per-project sync pipeline.
/// Stable feature IDs let an endpoint upsert later revisions of the same site.
class StudyAreaOutboxService {
  final AppDatabase db;
  StudyAreaOutboxService(this.db);
  static String exclusionKey(int projectId) =>
      'study_history_exclusions_$projectId';
  Future<void> enqueue(StudyAreaSite site, String author) =>
      enqueueBatch([site], author);

  Future<void> enqueueBatch(List<StudyAreaSite> sites, String author) async {
    for (final site in sites) {
      if (site.projectId == null) {
        throw StateError('Study site has no project');
      }
    }
    if (sites.isEmpty) return;
    await db.transaction(() async {
      final exclusions = <int, Map<String, dynamic>>{};
      final changedExclusions = <int>{};
      for (final site in sites) {
        final projectId = site.projectId!;
        if (!exclusions.containsKey(projectId)) {
          final raw = await db.getSetting(exclusionKey(projectId));
          exclusions[projectId] = raw == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(jsonDecode(raw) as Map);
        }
        final excluded = exclusions[projectId]!;
        if (excluded[site.id] == site.revisionToken) continue;
        if (excluded.remove(site.id) != null) changedExclusions.add(projectId);
        final geometry = site.currentGeometry;
        final type = geometry['type'].toString();
        final response = jsonEncode({
          'workflow': 'study_area_feature_v1',
          'feature_type': type.contains('Polygon')
              ? 'polygon'
              : type.contains('Line')
                  ? 'line'
                  : 'point',
          'geometry': geometry,
          'latitude': site.latitude,
          'longitude': site.longitude,
          'layer_id': site.layerId,
          'site_id': site.id,
          'name': site.displayName,
          'notes': site.changeNote,
          'user_name': author,
          'answers': site.formAnswers,
          'form_snapshot': site.formSnapshot,
          'form_id': site.formSnapshot?['id'],
          'form_name': site.formSnapshot?['name'],
          'attributes': site.attributes,
          'site': site.toJson(),
          'edited_at': site.updatedAt?.toIso8601String()
        });
        final stableId = 'study:${site.projectExternalId}:${site.id}';
        final existing = await (db.select(db.surveySessions)
              ..where((row) =>
                  row.externalId.equals(stableId) &
                  row.projectId.equals(site.projectId!)))
            .getSingleOrNull();
        if (existing != null) {
          // Comparing the site snapshot avoids requeuing an unchanged site when
          // centralized revision/collector audit fields differ from this envelope.
          final previous = jsonDecode(existing.responses) as Map;
          if (jsonEncode(previous['site']) == jsonEncode(site.toJson())) {
            continue;
          }
          await db.updateSurveySession(existing.id,
              title: site.displayName, responses: response, status: 'saved');
        } else {
          await db.insertSurveySession(SurveySessionsCompanion(
              projectId: Value(site.projectId!),
              externalId: Value(stableId),
              title: Value(site.displayName),
              status: const Value('saved'),
              responses: Value(response)));
        }
      }
      for (final projectId in changedExclusions) {
        await db.setSetting(
            exclusionKey(projectId), jsonEncode(exclusions[projectId]));
      }
    });
  }

  Future<void> enqueueDeletion(StudyAreaDeletion deletion) async {
    final site = deletion.site;
    if (site.projectId == null || site.projectExternalId == null)
      throw StateError('Study site has no project');
    await db.transaction(() async {
      final stableId = 'study:${site.projectExternalId}:${site.id}';
      final old = await (db.select(db.surveySessions)
            ..where((r) =>
                r.projectId.equals(site.projectId!) &
                r.externalId.equals(stableId)))
          .getSingleOrNull();
      if (old != null &&
          (jsonDecode(old.responses) as Map)['deletion_id'] ==
              deletion.operationId) return;
      final type = site.currentGeometry['type'].toString();
      final payload = jsonEncode({
        'workflow': 'study_area_feature_v1',
        'feature_type': type.contains('Polygon')
            ? 'polygon'
            : type.contains('Line')
                ? 'line'
                : 'point',
        'site_id': site.id,
        'feature_uuid': site.featureUuid,
        'layer_id': site.layerId,
        'site': site.toJson(),
        'name': site.displayName,
        'geometry': site.currentGeometry,
        'latitude': site.latitude,
        'longitude': site.longitude,
        'attributes': site.attributes,
        'user_name': deletion.deletedBy,
        'deleted': true,
        'operation': 'delete',
        'deletion_id': deletion.operationId,
        'deleted_at': deletion.deletedAt.toIso8601String(),
        'deleted_by': deletion.deletedBy
      });
      if (old == null) {
        await db.insertSurveySession(SurveySessionsCompanion(
            projectId: Value(site.projectId!),
            externalId: Value(stableId),
            title: Value('${site.displayName} — Deleted'),
            status: const Value('saved'),
            responses: Value(payload)));
      } else {
        await db.updateSurveySession(old.id,
            title: '${site.displayName} — Deleted',
            responses: payload,
            status: 'saved');
      }
    });
  }

  Future<void> deleteFeatureSession(int id) async {
    final row = await db.getSurveySession(id);
    if (row == null) return;
    if (row.status == 'draft') {
      await db.deleteSurveySession(id);
      return;
    }
    final payload = Map<String, dynamic>.from(jsonDecode(row.responses));
    if (payload['deleted'] == true) return;
    payload.addAll({
      'deleted': true,
      'operation': 'delete',
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_by': await db.getSetting('user_name') ?? 'Local fieldworker'
    });
    await db.updateSurveySession(id,
        title: '${row.title} — Deleted',
        status: 'saved',
        responses: jsonEncode(payload));
  }

  Future<void> deleteSites(List<StudyAreaSite> sites) async {
    final ids = sites
        .where((site) => site.projectId != null)
        .map((site) => 'study:${site.projectExternalId}:${site.id}')
        .toSet();
    if (ids.isEmpty) return;
    final rows = await (db.select(db.surveySessions)
          ..where((row) => row.externalId.isIn(ids)))
        .get();
    await db.transaction(() async {
      for (final row in rows) {
        await db.deleteSurveySession(row.id);
      }
    });
  }
}
