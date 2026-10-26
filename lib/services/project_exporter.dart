import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/app_info.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/project_package.dart';
import 'package:mapbanai/services/project_asset_service.dart';
import 'package:mapbanai/services/project_field_data_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:flutter/services.dart' show rootBundle, ServicesBinding;

/// Builds .mbproj packages from a project stored in the local database.
///
/// Definitions are always included; collected responses, Study Area state and
/// response photos can optionally travel with the same package.
class ProjectExporter {
  ProjectExporter(this._database, {this.studyAreaStore});

  final AppDatabase _database;
  final StudyAreaStore? studyAreaStore;

  /// Builds the typed package payload for a project. Used by both the ZIP
  /// export and the inline-QR exporter so both share one code path.
  Future<ProjectPackageData> buildData(Project project,
      {bool includeSyncConnection = false,
      bool includeResponses = false}) async {
    final exportedAt = DateTime.now().toUtc().toIso8601String();
    final workspace = await ProjectWorkspaceService(_database).load(project.id);
    final externalId = workspace.project.externalId!;

    final fields = await _database.getProjectFields(project.id);
    final forms = workspace.forms;

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
      'source_files': await ProjectAssetService(_database).load(project.id),
    };
    if (includeResponses) {
      projectJson['field_data'] =
          await ProjectFieldDataService(_database, store: studyAreaStore)
              .export(workspace.project);
    }

    final settingsJson = <String, dynamic>{
      'study_layers': workspace.layers.map((layer) => layer.toJson()).toList(),
      'active_layer_id': workspace.layerId,
      'active_form_schema_id': workspace.schema?.id,
      'gps_accuracy_threshold_m': project.gpsThresholdM,
      'archived': project.archived,
    };
    final studyCategoryStyles = <String, dynamic>{};
    for (final layer in workspace.layers) {
      final raw =
          await _database.getSetting('study_category:$externalId:${layer.id}');
      if (raw == null) continue;
      try {
        studyCategoryStyles[layer.id] = jsonDecode(raw);
      } catch (_) {}
    }
    settingsJson['study_category_styles'] = studyCategoryStyles;

    if (includeSyncConnection) {
      final sync = await _database.getSyncConfig(project.id);
      if (sync?.syncEndpointUrl?.isNotEmpty == true) {
        settingsJson['sync_connection'] = {
          'endpoint_url': sync!.syncEndpointUrl,
          'api_key': sync.syncApiKey ?? '',
        };
      }
    }

    final layersJson = <String, dynamic>{
      'basemap_id': 'osm',
      'vector_overlays':
          await ProjectVectorLayerService(_database).load(project.id),
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
  Future<Uint8List> buildPackageBytes(Project project,
      {bool includeSyncConnection = false,
      bool includeResponses = false}) async {
    final data = await buildData(project,
        includeSyncConnection: includeSyncConnection,
        includeResponses: includeResponses);

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
      contentFiles[name] = Uint8List.fromList(utf8.encode(jsonEncode(form)));
    }
    var servicesInitialized = true;
    try {
      ServicesBinding.instance;
    } catch (_) {
      servicesInitialized = false;
    }
    if (servicesInitialized) {
      for (final bundled in const {
        'assets/help/manager_apps_script.gs': 'assets/cloud_sync/Code.gs',
        'assets/help/Map.html': 'assets/cloud_sync/Map.html',
        'assets/help/Charts.html': 'assets/cloud_sync/Charts.html',
      }.entries) {
        final dataBytes = await rootBundle.load(bundled.key);
        contentFiles[bundled.value] = dataBytes.buffer
            .asUint8List(dataBytes.offsetInBytes, dataBytes.lengthInBytes);
      }
    }

    final checksums = <String, String>{};
    if (contentFiles.values.any((bytes) =>
            bytes.length > ProjectPackageFormat.maxSingleEntryBytes) ||
        contentFiles.values
                .fold<int>(0, (total, bytes) => total + bytes.length) >
            ProjectPackageFormat.maxTotalUncompressedBytes) {
      throw const FormatException(
          'This project package is too large. Export the project without responses and share response data separately.');
    }
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
}
