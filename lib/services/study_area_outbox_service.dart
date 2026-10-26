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
