import 'dart:convert';
import 'dart:typed_data';

import 'package:mapbanai/data/app_database.dart';

/// Stores original project files in project settings so .mbproj sharing can
/// preserve source spreadsheets and scripts alongside normalized map layers.
class ProjectAssetService {
  ProjectAssetService(this.database);
  final AppDatabase database;

  String _key(int projectId) => 'project_assets_$projectId';

  Future<List<Map<String, dynamic>>> load(int projectId) async {
    final raw = await database.getSetting(_key(projectId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(
            (item) => item['name'] is String && item['bytes_base64'] is String)
        .toList();
  }

  Future<void> save(int projectId, List<Map<String, dynamic>> assets) async {
    var byteCount = 0;
    final names = <String>{};
    for (final asset in assets) {
      final name = (asset['name'] ?? '').toString().replaceAll('\\', '/');
      if (name.isEmpty ||
          name.startsWith('/') ||
          name.split('/').contains('..') ||
          asset['bytes_base64'] is! String ||
          !names.add(name.toLowerCase())) {
        throw const FormatException('Invalid or duplicate project file.');
      }
      final bytes = base64Decode(asset['bytes_base64'] as String);
      byteCount += bytes.length;
      if (byteCount > 64 * 1024 * 1024) {
        throw const FormatException(
            'Project attachments can total up to 64 MB.');
      }
    }
    await database.setSetting(_key(projectId), jsonEncode(assets));
  }

  Future<void> add(int projectId, String name, Uint8List bytes) async {
    final assets = await load(projectId);
    final normalized = name.replaceAll('\\', '/');
    assets.removeWhere((asset) =>
        (asset['name'] as String).toLowerCase() == normalized.toLowerCase());
    assets.add({'name': normalized, 'bytes_base64': base64Encode(bytes)});
    await save(projectId, assets);
  }
}
