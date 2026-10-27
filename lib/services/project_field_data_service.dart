import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/project_package.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Optional collected data inside a project package. Definitions-only exports
/// never call this service, and responses-only exports never include settings.
class ProjectFieldDataService {
  final AppDatabase db;
  final StudyAreaStore store;
  ProjectFieldDataService(this.db, {StudyAreaStore? store})
      : store = store ?? StudyAreaStore();

  Future<Map<String, dynamic>> export(Project project) async {
    final sessions = await db.getSurveySessionsByProject(project.id);
    final deletionSeed =
        await db.getSetting('project_study_deletions_${project.id}');
    final deletions = [
      ...await store.loadDeletions(),
      if (deletionSeed != null)
        ...(jsonDecode(deletionSeed) as List).map((raw) =>
            StudyAreaDeletion.fromJson(Map<String, dynamic>.from(raw as Map)))
    ];
    final pendingSeed = await db.getSetting('project_study_seed_${project.id}');
    final storedSites = pendingSeed == null
        ? await store.loadSites()
        : (jsonDecode(pendingSeed) as List)
            .map((raw) =>
                StudyAreaSite.fromJson(Map<String, dynamic>.from(raw as Map)))
            .toList();
    final sites = storedSites
        .where((site) => GuidedVisitService.belongsToProject(site, project));
    final photos = <String, Map<String, dynamic>>{};
    var photoBytes = 0;
    Future<dynamic> portable(dynamic value, {String? key}) async {
      if (value is Map)
        return {
          for (final entry in value.entries)
            entry.key.toString():
                await portable(entry.value, key: entry.key.toString())
        };
      if (value is List)
        return [for (final item in value) await portable(item)];
      if (value is! String) return value;
      if (['path', 'thumb', 'photo', 'photo_path'].contains(key) &&
          p.isAbsolute(value) &&
          value.replaceAll('\\', '/').split('/').contains('photos') &&
          ['.jpg', '.jpeg', '.png', '.webp']
              .contains(p.extension(value).toLowerCase())) {
        final file = File(value);
        if (await file.exists()) {
          final length = await file.length();
          if (photoBytes + length > 64 * 1024 * 1024) {
            throw const FormatException(
                'Response photos exceed 64 MB. Export responses separately or share a smaller project.');
          }
          final bytes = await file.readAsBytes();
          final id = ProjectPackageFormat.sha256Hex(bytes);
          if (!photos.containsKey(id)) {
            photoBytes += bytes.length;
            photos[id] = {
              'sha256': id,
              'extension': p.extension(value).toLowerCase(),
              'bytes_base64': base64Encode(bytes)
            };
          }
          return 'mbphoto:$id';
        }
      }
      if (value.startsWith('{') || value.startsWith('[')) {
        try {
          return jsonEncode(await portable(jsonDecode(value)));
        } on FormatException {/* Plain answer text is kept. */}
      }
      return value;
    }

    final exclusion =
        await db.getSetting(StudyAreaOutboxService.exclusionKey(project.id));
    final initialized =
        await db.getSetting('project_vector_initialized_${project.id}');
    final data = await portable({
      'version': 1,
      'sessions': [
        for (final session in sessions)
          {
            'local_id': session.id,
            'external_id': session.externalId,
            'title': session.title,
            'status': session.status,
            'responses': session.responses,
            'created_at': session.createdAt.toIso8601String(),
            'synced_at': session.syncedAt?.toIso8601String(),
            'photo_synced_at': session.photoSyncedAt?.toIso8601String(),
          }
      ],
      'study_sites': sites.map((site) => site.toJson()).toList(),
      'study_deletions': deletions
          .where((d) => GuidedVisitService.belongsToProject(d.site, project))
          .map((d) => d.toJson())
          .toList(),
      'history_exclusions': exclusion == null ? {} : jsonDecode(exclusion),
      'initialized_layer_ids':
          initialized == null ? [] : jsonDecode(initialized),
    });
    return Map<String, dynamic>.from(data as Map)
      ..['photos'] = photos.values.toList();
  }

  Future<void> import(Map? raw, Project project,
      {required bool newCopy}) async {
    if (raw == null) return;
    if (raw['version'] != 1 ||
        raw['sessions'] is! List ||
        raw['study_sites'] is! List) {
      throw const FormatException('Invalid project response data.');
    }
    final photoPaths = <String, String>{};
    var total = 0;
    for (final item in raw['photos'] as List? ?? const []) {
      if (item is! Map || item['bytes_base64'] is! String)
        throw const FormatException('Invalid packaged photo.');
      final bytes = base64Decode(item['bytes_base64']);
      final hash = ProjectPackageFormat.sha256Hex(bytes);
      final extension = item['extension']?.toString();
      total += bytes.length;
      if (hash != item['sha256'] ||
          !['.jpg', '.jpeg', '.png', '.webp'].contains(extension) ||
          total > 64 * 1024 * 1024) {
        throw const FormatException('Invalid or oversized packaged photos.');
      }
      final dir = Directory(
          p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, 'imported_$hash$extension'));
      if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
      photoPaths['mbphoto:$hash'] = file.path;
    }
    dynamic restore(dynamic value) {
      if (value is Map)
        return {
          for (final entry in value.entries)
            entry.key.toString(): restore(entry.value)
        };
      if (value is List) return value.map(restore).toList();
      if (value is String) {
        if (photoPaths.containsKey(value)) return photoPaths[value];
        if (value.startsWith('{') || value.startsWith('[')) {
          try {
            return jsonEncode(restore(jsonDecode(value)));
          } on FormatException {/* Plain text. */}
        }
      }
      return value;
    }

    final data = Map<String, dynamic>.from(restore(raw) as Map);
    final siteIds = <String, String>{
      for (final site in [
        ...data['study_sites'] as List,
        for (final deletion in data['study_deletions'] as List? ?? [])
          (deletion as Map)['site']
      ])
        if (site is Map && site['id'] is String)
          site['id']:
              newCopy ? '${project.externalId}:${site['id']}' : site['id']
    };
    Map<String, dynamic> remapSite(Map rawSite) {
      final site = Map<String, dynamic>.from(rawSite);
      site['id'] = siteIds[site['id']] ?? site['id'];
      site['project_id'] = project.id;
      site['project_external_id'] = project.externalId;
      return site;
    }

    final sessionIds = <int, int>{};
    for (final item in data['sessions'] as List) {
      if (item is! Map ||
          item['title'] is! String ||
          item['responses'] is! String ||
          !['draft', 'saved'].contains(item['status']))
        throw const FormatException('Invalid response record.');
      final response = jsonDecode(item['responses']) as Map<String, dynamic>;
      if (response['site'] is Map)
        response['site'] = remapSite(response['site']);
      if (response['site_id'] is String)
        response['site_id'] =
            siteIds[response['site_id']] ?? response['site_id'];
      if (response['workflow'] == 'study_collection_v1' ||
          response['workflow'] == 'study_area_feature_v1') {
        response['project_external_id'] = project.externalId;
        response['feature_uuid'] = const Uuid()
            .v5(Uuid.NAMESPACE_URL, 'mapbanai:feature:${response['site_id']}');
      }
      if (response['visit'] is Map) {
        final visit = Map<String, dynamic>.from(response['visit']);
        visit['project_id'] = project.id;
        visit['project_external_id'] = project.externalId;
        visit['site_id'] = siteIds[visit['site_id']] ?? visit['site_id'];
        for (final key in ['site_before', 'site_after']) {
          if (visit[key] is Map) visit[key] = remapSite(visit[key]);
        }
        response['visit'] = visit;
      }
      final externalId = response['workflow'] == 'study_area_feature_v1' &&
              response['site_id'] is String
          ? 'study:${project.externalId}:${response['site_id']}'
          : newCopy
              ? const Uuid().v4()
              : item['external_id']?.toString() ?? const Uuid().v4();
      final id = await db
          .into(db.surveySessions)
          .insert(SurveySessionsCompanion(
            projectId: Value(project.id),
            externalId: Value(externalId),
            title: Value(item['title']),
            status: Value(item['status']),
            responses: Value(jsonEncode(response)),
            createdAt: Value(
                DateTime.tryParse('${item['created_at']}') ?? DateTime.now()),
            syncedAt: Value(
                newCopy ? null : DateTime.tryParse('${item['synced_at']}')),
            photoSyncedAt: Value(newCopy
                ? null
                : DateTime.tryParse('${item['photo_synced_at']}')),
          ));
      if (item['local_id'] is int) sessionIds[item['local_id']] = id;
    }
    final sites = [
      for (final item in data['study_sites'] as List) remapSite(item as Map)
    ];
    for (final site in sites) {
      for (final revision in site['history'] as List? ?? const []) {
        if (revision is Map && sessionIds.containsKey(revision['session_id'])) {
          revision['session_id'] = sessionIds[revision['session_id']];
        }
      }
    }
    // SQLite import remains atomic. The map store consumes this durable seed
    // once when Study Area opens, then normal point deletion stays permanent.
    await db.setSetting('project_study_seed_${project.id}', jsonEncode(sites));
    await db.setSetting(
        'project_study_deletions_${project.id}',
        jsonEncode([
          for (final deletion in data['study_deletions'] as List? ?? [])
            {
              ...Map<String, dynamic>.from(deletion as Map),
              'site': remapSite(deletion['site'] as Map)
            }
        ]));
    if (data['initialized_layer_ids'] is List)
      await db.setSetting('project_vector_initialized_${project.id}',
          jsonEncode(data['initialized_layer_ids']));
    final excluded = data['history_exclusions'];
    if (excluded is Map && !newCopy)
      await db.setSetting(StudyAreaOutboxService.exclusionKey(project.id),
          jsonEncode(excluded));
  }
}
