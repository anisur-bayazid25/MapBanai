import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:mapbanai/services/study_area_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StudyAreaConflict implements Exception {
  final StudyAreaSite current;
  final StudyAreaSite incoming;
  final String message;
  StudyAreaConflict(this.current, this.incoming,
      [this.message =
          'This feature changed after it was opened. Review the current version before saving.']);
  @override
  String toString() => message;
}

enum StudyAreaMergeChoice { keepLocal, useIncoming, preserveAsNew }

class StudyAreaMergePreview {
  final List<StudyAreaSite> incoming;
  final List<StudyAreaConflict> conflicts;
  final Map<String, String?> expectedTokens;
  final int additions;
  final int updates;
  final int unchanged;
  StudyAreaMergePreview(
      {required this.incoming,
      required this.conflicts,
      required this.expectedTokens,
      required this.additions,
      required this.updates,
      required this.unchanged});
}

class StudyAreaMergeResult {
  final int added;
  final int updated;
  final int kept;
  StudyAreaMergeResult(this.added, this.updated, this.kept);
}

/// Persists Study Area sites to a JSON file under app documents.
/// Keeps implementation simple and testable without Drift migrations.
class StudyAreaStore {
  final Directory? _baseDir;

  StudyAreaStore({Directory? baseDir}) : _baseDir = baseDir;

  Future<Directory> _storeDir() async {
    final base = _baseDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'study_area'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<File> _file() async {
    final dir = await _storeDir();
    return File(p.join(dir.path, 'study_area_sites.json'));
  }

  Future<List<StudyAreaSite>> loadSites() async {
    final file = await _file();
    if (!file.existsSync()) {
      final backup = File('${file.path}.bak');
      if (backup.existsSync()) {
        await backup.copy(file.path);
      } else {
        return [];
      }
    }
    final text = await file.readAsString();
    return text.length > 256 * 1024
        ? Isolate.run(() => _decodeSites(text))
        : _decodeSites(text);
  }

  static List<StudyAreaSite> _decodeSites(String text) {
    if (text.trim().isEmpty) {
      throw const FormatException(
          'Study area file is empty; restore a backup before saving.');
    }
    final decoded = jsonDecode(text);
    final rows = decoded is List
        ? decoded
        : decoded is Map
            ? decoded['sites']
            : null;
    if (rows is! List || rows.any((row) => row is! Map<String, dynamic>)) {
      throw const FormatException(
          'Study area file is invalid; the original file was preserved.');
    }
    return rows
        .map((row) => StudyAreaSite.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static final Map<String, Future<void>> _pendingWrites = {};
  String get _writeKey => _baseDir?.absolute.path ?? 'application_documents';

  Future<void> _serialize(Future<void> Function() operation) {
    final next = (_pendingWrites[_writeKey] ?? Future<void>.value())
        .then((_) => operation());
    _pendingWrites[_writeKey] = next.catchError((Object _) {});
    return next;
  }

  Future<void> _write(List<StudyAreaSite> sites) async {
    final ids = <String>{};
    for (final site in sites) {
      if (site.id.trim().isEmpty || !ids.add(site.id)) {
        throw FormatException('Empty or duplicate feature ID: ${site.id}');
      }
    }
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    final rows = sites.map((site) => site.toJson()).toList();
    final encoded = sites.length > 200
        ? await Isolate.run(() => jsonEncode(rows))
        : jsonEncode(rows);
    await temporary.writeAsString(encoded, flush: true);
    if (file.existsSync()) {
      if (backup.existsSync()) await backup.delete();
      await file.rename(backup.path);
    }
    try {
      await temporary.rename(file.path);
    } catch (_) {
      if (!file.existsSync() && backup.existsSync()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }

  Future<void> saveSites(List<StudyAreaSite> sites) {
    // Snapshot mutable records before queueing the write.
    final snapshot = sites
        .map((s) => StudyAreaSite.fromJson(
            jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>))
        .toList();
    return _serialize(() async {
      await loadSites(); // Never overwrite a malformed baseline silently.
      await _write(snapshot);
    });
  }

  Future<void> replaceProjectSites(
          int projectId, String externalId, List<StudyAreaSite> replacement) =>
      _serialize(() async {
        final current = await loadSites();
        final kept = current.where((site) => site.projectExternalId != null
            ? site.projectExternalId != externalId
            : site.projectId != projectId);
        await _write([...kept, ...replacement]);
      });

  Future<void> addSites(List<StudyAreaSite> newSites, {bool replace = false}) {
    final snapshot = newSites
        .map((s) => StudyAreaSite.fromJson(
            jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>))
        .toList();
    return _serialize(() async {
      final existing = await loadSites();
      if (replace) {
        await _write(snapshot);
        return;
      }
      final ids = existing.map((s) => s.id).toSet();
      for (final site in snapshot) {
        if (!ids.add(site.id)) {
          throw FormatException(
              'Duplicate feature ID ${site.id}. Import cancelled to preserve field changes.');
        }
      }
      await _write([...existing, ...snapshot]);
    });
  }

  Future<void> updateSite(StudyAreaSite site,
      {int? expectedRevision,
      String? expectedRevisionId,
      String author = 'Local fieldworker',
      String? visitId,
      int? sessionId,
      int? formId,
      String? photoPath}) {
    final snapshot = StudyAreaSite.fromJson(
        jsonDecode(jsonEncode(site.toJson())) as Map<String, dynamic>);
    final expectedToken = expectedRevisionId ?? site.revisionToken;
    final expectedVersion = expectedRevision ?? site.revision;
    return _serialize(() async {
      final sites = await loadSites();
      final idx = sites.indexWhere((s) => s.id == site.id);
      final previous = idx >= 0 ? sites[idx] : null;
      if (previous == null && expectedVersion > 0) {
        throw StateError(
            'This feature was removed after it was opened. Reopen the study area before saving.');
      }
      if (previous != null && visitId != null) {
        final visits = previous.history.where((r) => r.visitId == visitId);
        if (visits.isNotEmpty) {
          if (studyAreaCanonicalJson(visits.last.after) !=
              studyAreaCanonicalJson(snapshot.stateSnapshot())) {
            throw StateError(
                'Visit $visitId was already applied with different information. Reopen the visit before editing.');
          }
          _copyRevision(previous, site);
          return;
        }
      }
      if (previous != null &&
          (previous.revisionToken != expectedToken ||
              previous.revision != expectedVersion)) {
        throw StudyAreaConflict(previous, snapshot);
      }
      _recordRevision(snapshot, previous,
          author: author,
          visitId: visitId,
          sessionId: sessionId,
          formId: formId,
          photoPath: photoPath,
          action: previous == null ? 'create' : 'edit');
      if (idx >= 0) {
        sites[idx] = snapshot;
      } else {
        sites.add(snapshot);
      }
      await _write(sites);
      _copyRevision(snapshot, site);
    });
  }

  static StudyAreaSite _snapshot(StudyAreaSite site) => StudyAreaSite.fromJson(
      jsonDecode(jsonEncode(site.toJson())) as Map<String, dynamic>);

  static void _copyRevision(StudyAreaSite saved, StudyAreaSite target) {
    target.revision = saved.revision;
    target.revisionId = saved.revisionId;
    target.history = List.from(saved.history);
    target.updatedAt = saved.updatedAt;
    target.original = saved.original;
  }

  static void _recordRevision(StudyAreaSite incoming, StudyAreaSite? previous,
      {required String author,
      String action = 'edit',
      String? visitId,
      int? sessionId,
      int? formId,
      String? photoPath}) {
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    final previousHistory = previous?.history ?? <StudyAreaRevision>[];
    final historyById = {
      for (final r in [...previousHistory, ...incoming.history]) r.id: r
    };
    incoming.history = historyById.values.toList();
    incoming.history.add(StudyAreaRevision(
        id: id,
        parentId: previous?.revisionToken,
        timestamp: now,
        author: author.trim().isEmpty ? 'Local fieldworker' : author.trim(),
        action: action,
        before: previous?.stateSnapshot(),
        after: incoming.stateSnapshot(),
        visitId: visitId,
        sessionId: sessionId,
        formId: formId,
        projectId: incoming.projectId,
        projectExternalId: incoming.projectExternalId,
        photoPath: photoPath));
    incoming.revision = (previous?.revision ?? 0) + 1;
    incoming.revisionId = id;
    incoming.updatedAt = now;
    incoming.original ??= previous?.original ?? previous?.stateSnapshot();
  }

  static bool _sameState(StudyAreaSite a, StudyAreaSite b) =>
      studyAreaCanonicalJson(a.comparisonSnapshot()) ==
      studyAreaCanonicalJson(b.comparisonSnapshot());

  static bool _descendsFrom(StudyAreaSite site, String token) =>
      site.history.any((r) => r.id == token || r.parentId == token);

  Future<StudyAreaMergePreview> previewMerge(
      List<StudyAreaSite> incoming) async {
    final copies = incoming.map(_snapshot).toList();
    final ids = <String>{};
    for (final site in copies) {
      if (site.id.isEmpty || !ids.add(site.id))
        throw FormatException(
            'Empty or duplicate incoming feature ID: ${site.id}');
    }
    final local = {for (final site in await loadSites()) site.id: site};
    final conflicts = <StudyAreaConflict>[];
    final expected = <String, String?>{};
    var additions = 0, updates = 0, unchanged = 0;
    for (final site in copies) {
      final current = local[site.id];
      expected[site.id] = current?.revisionToken;
      if (current == null) {
        additions++;
      } else if (_sameState(current, site)) {
        unchanged++;
      } else if (_descendsFrom(site, current.revisionToken) &&
          site.projectExternalId == current.projectExternalId) {
        updates++;
      } else if (_descendsFrom(current, site.revisionToken)) {
        unchanged++;
      } else {
        conflicts.add(StudyAreaConflict(current, site,
            'Both versions of ${site.displayName} contain different information. Choose how to merge them.'));
      }
    }
    return StudyAreaMergePreview(
        incoming: copies,
        conflicts: conflicts,
        expectedTokens: expected,
        additions: additions,
        updates: updates,
        unchanged: unchanged);
  }

  Future<StudyAreaMergeResult> applyMerge(StudyAreaMergePreview preview,
      {Map<String, StudyAreaMergeChoice> resolutions = const {},
      String author = 'Local fieldworker',
      int? localProjectId}) async {
    late StudyAreaMergeResult result;
    await _serialize(() async {
      final sites = await loadSites();
      final local = {for (final s in sites) s.id: s};
      for (final incoming in preview.incoming) {
        if (local[incoming.id]?.revisionToken !=
            preview.expectedTokens[incoming.id]) {
          throw StateError(
              'Features changed while the import was being reviewed. Reopen the import to compare the latest versions.');
        }
      }
      var added = 0, updated = 0, kept = 0;
      final conflictingIds =
          preview.conflicts.map((c) => c.incoming.id).toSet();
      for (final item in preview.incoming) {
        var incoming = _snapshot(item);
        final previous = local[incoming.id];
        if (incoming.projectExternalId != null) {
          // An exchanged local integer cannot select a project on this phone.
          incoming.projectId = localProjectId ?? previous?.projectId;
        }
        final choice = conflictingIds.contains(incoming.id)
            ? resolutions[incoming.id]
            : null;
        if (conflictingIds.contains(incoming.id) && choice == null)
          throw StateError(
              'Choose a resolution for feature ${incoming.id}. No changes were imported.');
        if (localProjectId != null &&
            previous != null &&
            previous.projectExternalId == incoming.projectExternalId) {
          previous.projectId = localProjectId;
        }
        if (choice == StudyAreaMergeChoice.keepLocal ||
            (choice == null &&
                previous != null &&
                (_sameState(previous, incoming) ||
                    _descendsFrom(previous, incoming.revisionToken)))) {
          kept++;
          continue;
        }
        if (choice == StudyAreaMergeChoice.preserveAsNew) {
          final sourceId = incoming.id;
          final json = incoming.toJson();
          json['id'] =
              '${incoming.id}_copy_${const Uuid().v4().substring(0, 8)}';
          incoming = StudyAreaSite.fromJson(json);
          incoming.attributes['source_feature_id'] = sourceId;
          incoming.status = StudyAreaStatus.newFeature;
          _recordRevision(incoming, null,
              author: author, action: 'import_copy');
          local[incoming.id] = incoming;
          added++;
          continue;
        }
        // Team revisions keep their complete lineage when introduced locally.
        if (previous == null) {
          if (incoming.history.isEmpty)
            _recordRevision(incoming, null, author: author, action: 'import');
          local[incoming.id] = incoming;
          added++;
        } else {
          _recordRevision(incoming, previous,
              author: author,
              action: choice == StudyAreaMergeChoice.useIncoming
                  ? 'resolve_use_incoming'
                  : 'team_merge');
          local[incoming.id] = incoming;
          updated++;
        }
      }
      await _write(local.values.toList());
      result = StudyAreaMergeResult(added, updated, kept);
    });
    return result;
  }

  Future<void> deleteSite(String id) => _serialize(() async {
        final sites = await loadSites();
        sites.removeWhere((s) => s.id == id);
        await _write(sites);
      });

  Future<void> deleteSites(Set<String> ids,
          {Map<String, String>? expectedTokens}) =>
      _serialize(() async {
        final sites = await loadSites();
        if (expectedTokens != null) {
          for (final site in sites.where((site) => ids.contains(site.id))) {
            if (expectedTokens[site.id] != site.revisionToken) {
              throw StateError('A map point changed. Reload before deleting.');
            }
          }
        }
        sites.removeWhere((site) => ids.contains(site.id));
        await _write(sites);
      });

  Future<int> deleteImportBatch(String batchId) async {
    var removed = 0;
    await _serialize(() async {
      final sites = await loadSites();
      final kept = sites.where((site) {
        if (site.importBatchId != batchId) return true;
        removed++;
        return false;
      }).toList();
      if (removed > 0) await _write(kept);
    });
    return removed;
  }

  Future<int> assignUnclaimedSites(
      {required int projectId,
      required String projectExternalId,
      required String layerId,
      Set<String>? ids}) async {
    var count = 0;
    await _serialize(() async {
      final sites = await loadSites();
      for (final site in sites) {
        if (ids != null && !ids.contains(site.id)) continue;
        if (site.projectId != null || site.projectExternalId != null) continue;
        site.projectId = projectId;
        site.projectExternalId = projectExternalId;
        site.layerId = layerId;
        count++;
      }
      await _write(sites);
    });
    return count;
  }

  Future<void> clear() => _serialize(() async {
        final file = await _file();
        if (file.existsSync()) await file.delete();
        final backup = File('${file.path}.bak');
        if (backup.existsSync()) await backup.delete();
      });

  Future<String> filePath() async => (await _file()).path;

  Future<String> getOperatorName() async {
    final file = File(p.join((await _storeDir()).path, 'operator_name.txt'));
    if (!file.existsSync()) return 'Local fieldworker';
    final name = (await file.readAsString()).trim();
    return name.isEmpty ? 'Local fieldworker' : name;
  }

  Future<void> setOperatorName(String name) => _serialize(() async {
        final file =
            File(p.join((await _storeDir()).path, 'operator_name.txt'));
        await file.writeAsString(name.trim(), flush: true);
      });
}
