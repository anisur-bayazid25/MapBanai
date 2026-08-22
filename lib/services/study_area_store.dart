import 'dart:convert';
import 'dart:io';

import 'package:mapbanai/services/study_area_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    if (!file.existsSync()) return [];
    try {
      final text = await file.readAsString();
      if (text.trim().isEmpty) return [];
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return [
          for (final item in decoded)
            if (item is Map<String, dynamic>) StudyAreaSite.fromJson(item)
        ];
      }
      if (decoded is Map<String, dynamic> && decoded['sites'] is List) {
        return [
          for (final item in decoded['sites'] as List)
            if (item is Map<String, dynamic>) StudyAreaSite.fromJson(item)
        ];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSites(List<StudyAreaSite> sites) async {
    final file = await _file();
    final json = sites.map((s) => s.toJson()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json),
        flush: true);
  }

  Future<void> addSites(List<StudyAreaSite> newSites,
      {bool replace = false}) async {
    if (replace) {
      await saveSites(newSites);
      return;
    }
    final existing = await loadSites();
    final byId = {for (final s in existing) s.id: s};
    for (final s in newSites) {
      byId[s.id] = s;
    }
    await saveSites(byId.values.toList());
  }

  Future<void> updateSite(StudyAreaSite site) async {
    final sites = await loadSites();
    final idx = sites.indexWhere((s) => s.id == site.id);
    if (idx >= 0) {
      sites[idx] = site;
    } else {
      sites.add(site);
    }
    await saveSites(sites);
  }

  Future<void> deleteSite(String id) async {
    final sites = await loadSites();
    sites.removeWhere((s) => s.id == id);
    await saveSites(sites);
  }

  Future<void> clear() async {
    final file = await _file();
    if (file.existsSync()) await file.delete();
  }

  Future<String> filePath() async => (await _file()).path;
}
