import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/app_info.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/project_package.dart';

/// Builds .mbproj packages from a project stored in the local database.
///
/// Only the project DEFINITION is exported: metadata, per-project survey
/// forms (full SurveyForm JSON), project attribute fields, project settings
/// and the basemap/layer configuration snapshot. Survey responses, GPS
/// tracks, photos and app-level settings are never included.
class ProjectExporter {
  ProjectExporter(this._database);

  final AppDatabase _database;

  /// Builds the typed package payload for a project. Used by both the ZIP
  /// export and the inline-QR exporter so both share one code path.
  Future<ProjectPackageData> buildData(Project project) async {
    final exportedAt = DateTime.now().toUtc().toIso8601String();
    final externalId = project.externalId ?? _freshId(project.id);

    final fields = await _database.getProjectFields(project.id);
    final forms = await _database.getStoredFormsForProject(project.id);

    final formIndex = <Map<String, dynamic>>[];
    final formFiles = <Map<String, dynamic>>[];
    for (final form in forms) {
      final fileName = '${ProjectPackageFormat.formsDir}${form.id}.json';
      final parsedForm = _tryDecodeForm(form.json);
      formFiles.add({
        'id': form.id,
        'name': form.name,
        'description': form.description,
        'version': form.version,
        'created_at': form.createdAt.toUtc().toIso8601String(),
        'form': parsedForm,
      });
      formIndex.add({
        'file': fileName,
        'name': form.name,
        'version': form.version,
      });
    }

    final projectJson = <String, dynamic>{
      'project_id': externalId,
      'name': project.name,
      'description': project.description,
      'project_version': project.projectVersion,
      'created_at': project.createdAt.toUtc().toIso8601String(),
      'updated_at': project.createdAt.toUtc().toIso8601String(),
      'fields': fields.map((f) => f.name).toList(),
      'forms': formIndex,
    };

    final settingsJson = <String, dynamic>{
      'gps_accuracy_threshold_m': project.gpsThresholdM,
      'archived': project.archived,
    };

    final layersJson = <String, dynamic>{
      'basemap_id': 'osm',
      'basemaps': Basemap.defaults
          .map(
            (b) => {
              'id': b.id,
              'name': b.name,
              'url': b.url,
              'attribution': b.attribution,
            },
          )
          .toList(),
      'notes': 'MapLibre styles are generated at runtime from the basemap '
          'configuration; no tile data is embedded.',
    };

    return ProjectPackageData.from(
      ProjectPackageMeta(
        projectId: externalId,
        projectName: project.name,
        projectVersion: project.projectVersion,
        createdAt: project.createdAt.toUtc().toIso8601String(),
        exportedAt: exportedAt,
      ),
      projectJson,
      settingsJson,
      layersJson,
      formFiles,
      versionMetadata: ProjectPackageFormat.versionMetadata(
        appVersion: AppInfo.version,
        mapbanaiDbSchema: 8,
        packager: 'mapbanai-exporter/${AppInfo.version}',
      ),
    );
  }

  /// Serializes a project into the full .mbproj ZIP byte stream.
  Future<Uint8List> buildPackageBytes(Project project) async {
    final data = await buildData(project);

    final contentFiles = <String, Uint8List>{
      ProjectPackageFormat.projectFileName:
          Uint8List.fromList(utf8.encode(jsonEncode(data.project))),
      ProjectPackageFormat.settingsFileName:
          Uint8List.fromList(utf8.encode(jsonEncode(data.settings))),
      ProjectPackageFormat.layersFileName:
          Uint8List.fromList(utf8.encode(jsonEncode(data.layers))),
      ProjectPackageFormat.versionFileName: Uint8List.fromList(
        utf8.encode(
          jsonEncode(
            ProjectPackageFormat.versionMetadata(
              appVersion: AppInfo.version,
              mapbanaiDbSchema: 8,
              packager: 'mapbanai-exporter/${AppInfo.version}',
            ),
          ),
        ),
      ),
    };
    for (final form in data.forms) {
      final name = '${ProjectPackageFormat.formsDir}${form['id']}.json';
      contentFiles[name] =
          Uint8List.fromList(utf8.encode(jsonEncode(form)));
    }

    final checksums = <String, String>{};
    for (final path in contentFiles.keys.toList()..sort()) {
      checksums[path] = ProjectPackageFormat.sha256Hex(contentFiles[path]!);
    }

    final manifest = <String, dynamic>{
      'package_type': ProjectPackageFormat.packageType,
      'package_version': ProjectPackageFormat.supportedPackageVersion,
      'app_version': AppInfo.version,
      'project_id': data.meta.projectId,
      'project_version': data.meta.projectVersion,
      'project_name': data.meta.projectName,
      'created_at': data.meta.createdAt,
      'exported_at': data.exportedAt,
      'schema': {
        'package': ProjectPackageFormat.supportedPackageVersion,
        'mapbanai_db': 8,
      },
      'contents': contentFiles.keys.toList()..sort(),
      'checksums': checksums,
    };

    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        ProjectPackageFormat.manifestFileName,
        jsonEncode(manifest),
      ),
    );
    for (final path in contentFiles.keys.toList()..sort()) {
      archive.addFile(
        ArchiveFile(
          path,
          contentFiles[path]!.length,
          contentFiles[path],
        ),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive) ?? const []);
  }

  static Map<String, dynamic> _tryDecodeForm(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Fall through to the raw fallback below.
    }
    return {'raw': raw};
  }

  static String _freshId(int id) => 'legacy-$id';
}