import 'dart:convert';
import 'package:drift/drift.dart';

import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';

String historyLocalDay(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// Decode once so changing filters over large histories stays inexpensive.
class HistoryRecord {
  final SurveySession session;
  final Map<String, dynamic> data;
  HistoryRecord(this.session) : data = _decode(session.responses);

  static Map<String, dynamic> _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } on FormatException {
      return {};
    }
  }

  Map get _visit => data['visit'] is Map ? data['visit'] as Map : {};
  Map get _site => data['site'] is Map ? data['site'] as Map : {};
  String? get siteId =>
      (data['site_id'] ?? _visit['site_id'] ?? _site['id'])?.toString();
  String? get layerId => (data['layer_id'] ??
          _visit['layer_id'] ??
          _site['layer_id'] ??
          (data['workflow'] == 'study_area_feature_v1' ? 'default' : null))
      ?.toString();
  String get kind => data['workflow'] == 'study_area_feature_v1'
      ? 'study'
      : data['workflow'] == 'guided_visit_v1'
          ? 'visit'
          : data['feature_type'] != null
              ? 'gis'
              : 'survey';
  String get day => historyLocalDay(session.createdAt);
  bool get pending => session.status != 'draft' && session.syncedAt == null;
  String? get siteRevision => _site.isEmpty
      ? null
      : StudyAreaSite.fromJson(Map<String, dynamic>.from(_site)).revisionToken;
}

class HistoryScope {
  final int projectId;
  final String? layerId;
  final String? day;
  final String? kind;
  final String syncState;
  final bool includeDrafts;
  const HistoryScope(
      {required this.projectId,
      this.layerId,
      this.day,
      this.kind,
      this.syncState = 'all',
      this.includeDrafts = false});

  bool matches(HistoryRecord record) =>
      record.session.projectId == projectId &&
      (includeDrafts || record.session.status != 'draft') &&
      (layerId == null || (record.layerId ?? '') == layerId) &&
      (day == null || record.day == day) &&
      (kind == null || record.kind == kind) &&
      (syncState == 'all' ||
          (syncState == 'pending' && record.pending) ||
          (syncState == 'synced' && record.session.syncedAt != null));
}

class HistoryCleanupPreview {
  final Project project;
  final List<HistoryRecord> records;
  final List<StudyAreaSite> points;
  final int matchedCount;
  final bool removePoints;
  const HistoryCleanupPreview(
      {required this.project,
      required this.records,
      required this.points,
      required this.matchedCount,
      required this.removePoints});
  int get pendingCount => records.where((record) => record.pending).length;
  int get relatedCount => records.length - matchedCount;
}

/// The history table is also the sync outbox. Removing rows here removes both.
class HistoryCleanupService {
  final AppDatabase db;
  final StudyAreaStore store;
  HistoryCleanupService(this.db, {StudyAreaStore? store})
      : store = store ?? StudyAreaStore();

  Future<HistoryCleanupPreview> preview(HistoryScope scope,
      {bool removePoints = false, bool allLayerPoints = false}) async {
    final project = await db.getProjectById(scope.projectId);
    if (project == null) throw StateError('Project no longer exists.');
    if (removePoints &&
        await db.getSetting('project_study_seed_${project.id}') != null) {
      await ProjectVectorLayerService(db)
          .ensureStudySites(project, scope.layerId ?? 'default', store);
    }
    final all = (await db.getSurveySessionsByProject(scope.projectId))
        .map(HistoryRecord.new)
        .toList();
    final selected = all.where(scope.matches).toList();
    final selectedIds = selected.map((record) => record.session.id).toSet();
    final siteIds =
        selected.map((record) => record.siteId).whereType<String>().toSet();
    final points = removePoints
        ? (await store.loadSites())
            .where((site) =>
                GuidedVisitService.belongsToProject(site, project) &&
                (allLayerPoints
                    ? site.layerId == scope.layerId
                    : siteIds.contains(site.id)))
            .toList()
        : <StudyAreaSite>[];
    final removedIds = points.map((site) => site.id).toSet();
    // A removed point must not be recreated by an older visit on another day.
    final records = removePoints
        ? all
            .where((record) =>
                selectedIds.contains(record.session.id) ||
                removedIds.contains(record.siteId))
            .toList()
        : selected;
    return HistoryCleanupPreview(
        project: project,
        records: records,
        points: points,
        matchedCount: selected.length,
        removePoints: removePoints);
  }

  Future<int> delete(HistoryCleanupPreview preview) async {
    final expected = {
      for (final record in preview.records) record.session.id: record
    };
    var deleted = 0;
    await db.transaction(() async {
      final current = await db.getSurveySessionsByProject(preview.project.id);
      for (final session in current) {
        final record = expected[session.id];
        if (record != null &&
            (session.responses != record.session.responses ||
                session.status != record.session.status ||
                session.syncedAt != record.session.syncedAt)) {
          throw StateError(
              'Some records changed. Reload the preview before deleting.');
        }
      }
      final key = StudyAreaOutboxService.exclusionKey(preview.project.id);
      final raw = await db.getSetting(key);
      final exclusions = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      for (final record
          in preview.records.where((record) => record.kind == 'study')) {
        final siteId = record.siteId, revision = record.siteRevision;
        if (siteId != null && revision != null) exclusions[siteId] = revision;
      }
      await db.setSetting(key, jsonEncode(exclusions));
      final ids = expected.keys.toList();
      for (var offset = 0; offset < ids.length; offset += 400) {
        deleted += await (db.delete(db.surveySessions)
              ..where((row) =>
                  row.projectId.equals(preview.project.id) &
                  row.id.isIn(ids.skip(offset).take(400))))
            .go();
      }
      if (preview.removePoints && preview.points.isNotEmpty) {
        await store.deleteSites(preview.points.map((site) => site.id).toSet(),
            expectedTokens: {
              for (final site in preview.points) site.id: site.revisionToken
            });
      }
    });
    return deleted;
  }
}
