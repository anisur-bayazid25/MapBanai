import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/study_area_service.dart';

/// Makes study-area edits available to the existing per-project sync pipeline.
/// Stable feature IDs let an endpoint upsert later revisions of the same site.
class StudyAreaOutboxService {
  final AppDatabase db;
  StudyAreaOutboxService(this.db);
  Future<void> enqueue(StudyAreaSite site, String author) async {
    if (site.projectId == null) throw StateError('Study site has no project');
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
    await db.transaction(() async {
      final existing = await (db.select(db.surveySessions)
            ..where((row) =>
                row.externalId.equals(stableId) &
                row.projectId.equals(site.projectId!)))
          .getSingleOrNull();
      if (existing != null) {
        // Comparing the site snapshot avoids requeuing an unchanged site when
        // centralized revision/collector audit fields differ from this envelope.
        final previous = jsonDecode(existing.responses) as Map;
        if (jsonEncode(previous['site']) == jsonEncode(site.toJson())) return;
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
    });
  }
}
