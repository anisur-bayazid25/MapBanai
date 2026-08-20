import 'dart:convert';

import 'package:crypto/crypto.dart';

/// MapBanai project package (.mbproj) format definition.
///
/// A package is a ZIP archive with a manifest.json at its root. Every
/// payload file except the manifest is covered by a SHA-256 checksum in
/// the manifest, so a corrupted or tampered archive is rejected before
/// anything is extracted to disk.
///
/// Package layout v1:
/// ```
/// manifest.json          package envelope (no checksum for itself)
/// project.json           project metadata + form file index
/// settings.json          project-level settings (GPS accuracy, archived)
/// layers.json            basemap / style configuration snapshot
/// form/<id>.json         one file per stored survey form
/// metadata/version.json  schema versions of packager + database
/// assets/                reserved for project assets (empty in v1)
/// maps/                  reserved for offline map artifacts (empty in v1)
/// ```
class ProjectPackageFormat {
  ProjectPackageFormat._();

  static const String packageType = 'mapbanai_project';

  /// Package format version this app can READ.
  static const int supportedPackageVersion = 1;

  /// Package format versions we accept when importing (future-proofing:
  /// append smaller numbers here when a new major format is introduced).
  static const List<int> supportedPackageVersions = [1];

  static const String manifestFileName = 'manifest.json';
  static const String projectFileName = 'project.json';
  static const String settingsFileName = 'settings.json';
  static const String layersFileName = 'layers.json';
  static const String versionFileName = 'metadata/version.json';
  static const String formsDir = 'form/';
  static const String assetsDir = 'assets/';
  static const String mapsDir = 'maps/';

  /// Hard safety limits applied on import (memory/disk abuse guard).
  /// A single project definition is tiny (forms are JSON text); the limits
  /// are generous but bounded.
  static const int maxEntries = 4000;
  static const int maxTotalUncompressedBytes = 256 * 1024 * 1024;
  static const int maxSingleEntryBytes = 64 * 1024 * 1024;

  static String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

  static Map<String, dynamic> versionMetadata({
    required String appVersion,
    required int mapbanaiDbSchema,
    String? packager,
  }) => {
    'package_format_version': supportedPackageVersion,
    'app_version': appVersion,
    'mapbanai_db_schema': mapbanaiDbSchema,
    'serialized_by': packager ?? 'mapbanai-unknown',
  };

  /// True when the top-level path of a zip entry is allowed in the package.
  static bool isAllowedTopLevel(String firstSegment) {
    switch (firstSegment) {
      case 'manifest.json':
      case 'project.json':
      case 'settings.json':
      case 'layers.json':
      case 'form':
      case 'metadata':
      case 'assets':
      case 'maps':
        return true;
      default:
        return false;
    }
  }
}

/// Typed metadata extracted from the manifest / project payload of an
/// imported package. Never trusts raw strings; everything is validated
/// before use.
class ProjectPackageMeta {
  const ProjectPackageMeta({
    required this.projectId,
    required this.projectName,
    required this.projectVersion,
    required this.createdAt,
    required this.exportedAt,
  });

  final String projectId;
  final String projectName;
  final int projectVersion;
  final String createdAt;
  final String exportedAt;

  factory ProjectPackageMeta.fromJson(Map<String, dynamic> json) {
    final id = (json['project_id'] ?? '').toString().trim();
    final name = (json['project_name'] ?? '').toString().trim();
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('package metadata is missing identity');
    }
    return ProjectPackageMeta(
      projectId: id,
      projectName: name,
      projectVersion: _asInt(json['project_version'], fallback: 1),
      createdAt: (json['created_at'] ?? '').toString(),
      exportedAt: (json['exported_at'] ?? '').toString(),
    );
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

/// Fully validated project payload ready to be committed to the database.
/// Comes from a .mbproj zip (all files parsed) or from an inline QR payload
/// (same content, no zip envelope).
class ProjectPackageData {
  const ProjectPackageData({
    required this.meta,
    required this.project,
    required this.settings,
    required this.layers,
    required this.forms,
    required this.exportedAt,
  });

  final ProjectPackageMeta meta;

  /// project.json parsed (name, description, gps, archived, forms index).
  final Map<String, dynamic> project;

  /// settings.json parsed (gps accuracy threshold).
  final Map<String, dynamic> settings;

  /// layers.json parsed (basemap snapshot).
  final Map<String, dynamic> layers;

  /// Parsed form payloads: [{id, name, description, version, created_at,
  /// form: <SurveyForm JSON>}].
  final List<Map<String, dynamic>> forms;

  final String exportedAt;

  static ProjectPackageData from(
    ProjectPackageMeta meta,
    Map<String, dynamic> project,
    Map<String, dynamic> settings,
    Map<String, dynamic> layers,
    List<Map<String, dynamic>> forms,
    {String? exportedAt,
    Map<String, dynamic>? versionMetadata}) {
    final metaExport = meta.exportedAt.isNotEmpty
        ? meta.exportedAt
        : exportedAt ?? DateTime.now().toUtc().toIso8601String();
    return ProjectPackageData(
      meta: meta,
      project: project,
      settings: settings,
      layers: layers,
      forms: forms,
      exportedAt: metaExport,
    );
  }
}

/// Decodes JSON defensively; throws [FormatException] for anything that is
/// not an object.
Map<String, dynamic> decodeObject(String raw, String what) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$what must be a JSON object');
  }
  return decoded;
}

/// Sanitizes a user-supplied export filename so it cannot escape the
/// save location: keeps letters, digits, . _ - ( ) and spaces, maps every
/// other character to '_' and collapses whitespace runs.
String safeProjectFileName(String projectName, int projectVersion) {
  final base = projectName
      .trim()
      .replaceAll(RegExp(r'[^\w. \-()]', unicode: true), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll('.', '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final clean = base.isEmpty ? 'Project' : base;
  return '${clean}_v$projectVersion.mbproj';
}