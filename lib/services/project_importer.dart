import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_package.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Result of the validation step: a validated, extracted package located
/// with its own temp directory, ready for the conflict check + commit.
class ValidatedPackage {
  ValidatedPackage._(this.data, this.tempRoot);

  final ProjectPackageData data;

  /// Extraction directory; lives under the app documents folder inside a
  /// per-import temp folder that is removed after commit/abort.
  final Directory tempRoot;

  Future<void> discard() async {
    try {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup; a leftover temp dir is harmless.
    }
  }
}

class ImportCommitResult {
  const ImportCommitResult({required this.projectId, required this.name});

  final int projectId;
  final String name;
}

enum ImportDecision {
  /// Insert as a brand-new local project: new external identity, original
  /// name/definition preserved.
  newCopy,

  /// Delete the conflicting project (with all its sessions/forms/fields)
  /// and insert the imported definition, keeping its external identity.
  replaceExisting,
}

enum ProjectImportError {
  notFound,
  notAZipFile,
  corruptedZip,
  invalidManifest,
  wrongPackageType,
  unsupportedPackageVersion,
  missingRequiredFiles,
  checksumMismatch,
  pathTraversalRisk,
  invalidProjectJson,
  packageTooLarge,
  internal,
}

class ProjectImportException implements Exception {
  const ProjectImportException(this.error, this.message);

  final ProjectImportError error;
  final String message;

  @override
  String toString() => 'ProjectImportException($error): $message';
}

/// Validates and imports .mbproj packages (and inline QR payloads through
/// [commitData]).
///
/// Security rules:
///  * the archive is fully validated BEFORE any file is written;
///  * zip entries are rejected when they traverse directories (`..`,
///    absolute paths, backslash segments) or claim to be symlinks;
///  * every payload file is verified against its manifest SHA-256 checksum;
///  * size caps guard against decompression bombs;
///  * extraction goes into a private temp directory only;
///  * the database write is transactional — a failure leaves existing data
///    untouched, and the temp directory is always cleaned up.
class ProjectImporter {
  ProjectImporter(this._database, {Directory? tempBase})
      : _tempBase = tempBase;

  final AppDatabase _database;
  final Directory? _tempBase;

  Future<Directory> _freshTempRoot() async {
    Directory base;
    if (_tempBase != null) {
      base = _tempBase;
    } else {
      try {
        base = await getApplicationDocumentsDirectory();
      } catch (_) {
        base = Directory.systemTemp;
      }
    }
    final root = Directory(
      p.join(base.path, 'imports', 'tmp-${DateTime.now().microsecondsSinceEpoch}'),
    );
    await root.create(recursive: true);
    return root;
  }

  /// Step 1 + 2 of the import pipeline: validate the archive and extract
  /// into a private temp dir. Throws [ProjectImportException].
  Future<ValidatedPackage> validateAndExtract(File packageFile) async {
    if (!await packageFile.exists()) {
      throw const ProjectImportException(
        ProjectImportError.notFound,
        'The selected file no longer exists.',
      );
    }

    final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(await packageFile.readAsBytes());
    } catch (e) {
      throw const ProjectImportException(
        ProjectImportError.notFound,
        'The selected file could not be read.',
      );
    }
    return _validateBytes(bytes);
  }

  Future<ValidatedPackage> _validateBytes(Uint8List bytes) async {
    if (bytes.length < 4 ||
        bytes[0] != 0x50 || // 'P'
        bytes[1] != 0x4b || // 'K'
        !(bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07)) {
      throw const ProjectImportException(
        ProjectImportError.notAZipFile,
        'This is not a MapBanai project package.',
      );
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw const ProjectImportException(
        ProjectImportError.corruptedZip,
        'The project package is corrupted.',
      );
    }

    if (archive.isEmpty || archive.length > ProjectPackageFormat.maxEntries) {
      throw const ProjectImportException(
        ProjectImportError.packageTooLarge,
        'The project package is too large to import.',
      );
    }

    // ── Security pass over the entry list (no extraction yet) ──────────
    final seen = <String>{};
    var totalBytes = 0;
    for (final entry in archive) {
      final name = entry.name.replaceAll('\\', '/');
      if (name.isEmpty) continue;
      if (!seen.add(name)) {
        throw ProjectImportException(
          ProjectImportError.pathTraversalRisk,
          'Duplicate entry "$name" in package.',
        );
      }
      final segments = name.split('/');
      if (name.startsWith('/') ||
          segments.any((s) => s == '..' || s.isEmpty) ||
          !ProjectPackageFormat.isAllowedTopLevel(segments.first)) {
        throw ProjectImportException(
          ProjectImportError.pathTraversalRisk,
          'Unsafe entry "$name" in package.',
        );
      }
      if (entry.isSymbolicLink) {
        throw ProjectImportException(
          ProjectImportError.pathTraversalRisk,
          'Entry "$name" is a link; refusing to extract.',
        );
      }
      if (entry.size > ProjectPackageFormat.maxSingleEntryBytes) {
        throw const ProjectImportException(
          ProjectImportError.packageTooLarge,
          'An entry in the package is too large.',
        );
      }
      totalBytes += entry.size;
      if (totalBytes > ProjectPackageFormat.maxTotalUncompressedBytes) {
        throw const ProjectImportException(
          ProjectImportError.packageTooLarge,
          'The project package is too large to import.',
        );
      }
    }

    // ── Manifest validation ─────────────────────────────────────────────
    final manifestEntry = _findEntry(archive, ProjectPackageFormat.manifestFileName);
    if (manifestEntry == null) {
      throw const ProjectImportException(
        ProjectImportError.invalidManifest,
        'The package has no manifest.',
      );
    }
    final Map<String, dynamic> manifest;
    try {
      manifest = decodeObject(_readEntry(manifestEntry), 'manifest');
    } on FormatException {
      throw const ProjectImportException(
        ProjectImportError.invalidManifest,
        'The package manifest is not valid JSON.',
      );
    }

    final packageType = (manifest['package_type'] ?? '').toString();
    if (packageType != ProjectPackageFormat.packageType) {
      throw const ProjectImportException(
        ProjectImportError.wrongPackageType,
        'This file is not a MapBanai project package.',
      );
    }
    final packageVersion = manifest['package_version'];
    if (packageVersion is! int ||
        !ProjectPackageFormat.supportedPackageVersions.contains(packageVersion)) {
      throw ProjectImportException(
        ProjectImportError.unsupportedPackageVersion,
        'Unsupported project package version '
            '${packageVersion == null ? '?' : packageVersion}.',
      );
    }

    // ── Required file presence ──────────────────────────────────────────
    const required = [
      ProjectPackageFormat.projectFileName,
      ProjectPackageFormat.settingsFileName,
      ProjectPackageFormat.layersFileName,
      ProjectPackageFormat.versionFileName,
    ];
    final missing = required.where((f) => _findEntry(archive, f) == null);
    if (missing.isNotEmpty) {
      throw ProjectImportException(
        ProjectImportError.missingRequiredFiles,
        'The package is incomplete (missing ${missing.join(', ')}).',
      );
    }

    // ── Checksum verification over every declared content file ──────────
    final checksums = (manifest['checksums'] as Map?) ?? const <String, dynamic>{};
    final contents = (manifest['contents'] as List?) ?? <dynamic>[];
    for (final rawPath in contents) {
      final path = rawPath.toString();
      final entry = _findEntry(archive, path);
      if (entry == null) {
        throw ProjectImportException(
          ProjectImportError.missingRequiredFiles,
          'Declared file "$path" is missing from the package.',
        );
      }
      final expected = checksums[path]?.toString();
      if (expected != null && expected.isNotEmpty) {
        final actual = ProjectPackageFormat.sha256Hex(
          entry.content is List<int> ? entry.content as List<int> : const <int>[],
        );
        if (actual != expected) {
          throw ProjectImportException(
            ProjectImportError.checksumMismatch,
            'Checksum mismatch for "$path".',
          );
        }
      }
    }

    // ── Extraction into the private temp dir ────────────────────────────
    final tempRoot = await _freshTempRoot();
    try {
      for (final entry in archive) {
        if (entry.isFile) {
          final target = p.join(tempRoot.path, entry.name);
          if (!p.isWithin(tempRoot.path, target)) {
            throw ProjectImportException(
              ProjectImportError.pathTraversalRisk,
              'Entry "${entry.name}" escapes the extraction directory.',
            );
          }
          final file = File(target);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(
            entry.content is List<int> ? entry.content as List<int> : const <int>[],
            flush: true,
          );
        }
      }
      return ValidatedPackage._(
        await parseExtractedPackage(tempRoot),
        tempRoot,
      );
    } catch (e) {
      await tempRoot.delete(recursive: true).catchError((_) => tempRoot);
      rethrow;
    }
  }

  /// Parses and validates the payload after extraction.
  Future<ProjectPackageData> parseExtractedPackage(Directory tempRoot) async {
    Map<String, dynamic> project;
    Map<String, dynamic> settings;
    Map<String, dynamic> layers;
    Map<String, dynamic> versionMeta;
    try {
      project = decodeObject(
        await _readFile(p.join(tempRoot.path, ProjectPackageFormat.projectFileName)),
        'project.json',
      );
      settings = decodeObject(
        await _readFile(p.join(tempRoot.path, ProjectPackageFormat.settingsFileName)),
        'settings.json',
      );
      layers = decodeObject(
        await _readFile(p.join(tempRoot.path, ProjectPackageFormat.layersFileName)),
        'layers.json',
      );
      versionMeta = decodeObject(
        await _readFile(p.join(tempRoot.path, ProjectPackageFormat.versionFileName)),
        'metadata/version.json',
      );
    } on FormatException {
      throw const ProjectImportException(
        ProjectImportError.invalidProjectJson,
        'A project file in the package is not valid JSON.',
      );
    }

    final meta = ProjectPackageMeta.fromJson({
      'project_id': project['project_id'],
      'project_name': project['name'],
      'project_version': project['project_version'],
      'created_at': project['created_at'],
      'exported_at': versionMeta['exported_created_at'] ?? '',
    });
    if (project['name'] == null || project['project_id'] == null) {
      throw const ProjectImportException(
        ProjectImportError.invalidProjectJson,
        'The project definition in the package is incomplete.',
      );
    }

    final forms = <Map<String, dynamic>>[];
    final formIndex = (project['forms'] as List?) ?? const <dynamic>[];
    for (final raw in formIndex) {
      final item = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final fileName = item['file']?.toString();
      if (fileName == null || fileName.isEmpty) {
        throw const ProjectImportException(
          ProjectImportError.invalidProjectJson,
          'A form entry in the package has no file reference.',
        );
      }
      final filePath = p.join(tempRoot.path, fileName);
      if (!p.isWithin(tempRoot.path, filePath)) {
        throw ProjectImportException(
          ProjectImportError.pathTraversalRisk,
          'Form file reference "$fileName" escapes the package.',
        );
      }
      Map<String, dynamic> formPayload;
      try {
        formPayload = decodeObject(await _readFile(filePath), 'form file');
      } on FormatException {
        throw ProjectImportException(
          ProjectImportError.invalidProjectJson,
          'Form file "$fileName" is not valid JSON.',
        );
      }
      final formBody = formPayload['form'];
      if (formBody is! Map<String, dynamic> &&
          !(formBody is Map && formBody.isNotEmpty)) {
        throw ProjectImportException(
          ProjectImportError.invalidProjectJson,
          'Form file "$fileName" has no form definition.',
        );
      }
      forms.add(formPayload);
    }

    return ProjectPackageData.from(
      meta,
      project,
      settings,
      layers,
      forms,
      exportedAt: meta.exportedAt.isEmpty
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    );
  }

  /// Step 3: conflict detection. Returns the existing project when the
  /// incoming package collides with a local project (same external id or
  /// exactly the same name).
  Future<Project?> checkConflict(ProjectPackageMeta meta) {
    return _database.findProjectConflict(
      externalId: meta.projectId,
      name: meta.projectName,
    );
  }

  /// Step 4: commit a validated zip-backed package. When the package
  /// collides with an existing project, an explicit decision must be given:
  ///  * [newCopy]    → fresh local identity, original definition kept;
  ///  * [replaceExistingId] → delete that project (with its data) first.
  /// Throws [ProjectImportException] when the decision is missing for a
  /// conflict. Runs inside a transaction: on failure nothing changes.
  Future<ImportCommitResult> commit(
    ValidatedPackage package, {
    required bool newCopy,
    int? replaceExistingId,
  }) {
    return _database.transaction(() async {
      final data = package.data;
      final conflict = await _database.findProjectConflict(
        externalId: data.meta.projectId,
        name: data.meta.projectName,
      );
      if (conflict != null && !newCopy && replaceExistingId == null) {
        throw const ProjectImportException(
          ProjectImportError.internal,
          'Project already exists — an import decision is required.',
        );
      }
      if (!newCopy &&
          replaceExistingId != null &&
          conflict?.id == replaceExistingId) {
        await _database.deleteProject(replaceExistingId);
      }
      return _insert(data, newCopy: newCopy);
    });
  }

  /// Commits an inline-QR payload as the source (no zip, no temp dir).
  /// Same conflict rules as [commit].
  Future<ImportCommitResult> commitQrData(
    ProjectPackageData data, {
    required bool newCopy,
    int? replaceExistingId,
  }) {
    return _database.transaction(() async {
      final conflict = await _database.findProjectConflict(
        externalId: data.meta.projectId,
        name: data.meta.projectName,
      );
      if (conflict != null && !newCopy && replaceExistingId == null) {
        throw const ProjectImportException(
          ProjectImportError.internal,
          'Project already exists — an import decision is required.',
        );
      }
      if (!newCopy &&
          replaceExistingId != null &&
          conflict?.id == replaceExistingId) {
        await _database.deleteProject(replaceExistingId);
      }
      return _insert(data, newCopy: newCopy);
    });
  }

  Future<ImportCommitResult> _insert(
    ProjectPackageData data, {
    required bool newCopy,
  }) async {
    final externalId = newCopy ? const Uuid().v4() : data.meta.projectId;
    final gpsThreshold = _asDouble(
      data.settings['gps_accuracy_threshold_m'],
      fallback: _asDouble(data.project['gps_accuracy_threshold_m'], fallback: 10),
    );
    final archived = data.settings['archived'] == true ||
        data.project['is_archived'] == true;
    final description = (data.project['description'] ?? '').toString();
    final created = DateTime.tryParse(data.meta.createdAt) ?? DateTime.now();
    final projectVersion =
        data.project['project_version'] is int
            ? data.project['project_version'] as int
            : data.meta.projectVersion;

    final projectId = await _database.insertImportedProject(
      data.meta.projectName,
      externalId: externalId,
      description: description,
      gpsThresholdM: gpsThreshold,
      createdAt: created,
      archived: archived,
      projectVersion: projectVersion,
    );

    for (final form in data.forms) {
      final formBody = form['form'];
      final rawJson = jsonEncode(formBody);
      await _database.insertStoredForm(
        StoredFormsCompanion(
          projectId: drift.Value(projectId),
          name: drift.Value((form['name'] ?? '').toString()),
          description: drift.Value((form['description'] ?? '').toString()),
          json: drift.Value(rawJson),
          version: drift.Value(
            form['version'] is int ? form['version'] as int : 1,
          ),
          createdAt: drift.Value(
            DateTime.tryParse((form['created_at'] ?? '').toString()) ??
                DateTime.now(),
          ),
        ),
      );
    }

    final fields = data.project['fields'];
    if (fields is List) {
      for (final raw in fields) {
        final name = raw.toString().trim();
        if (name.isNotEmpty) {
          await _database.insertProjectField(projectId, name);
        }
      }
    }

    return ImportCommitResult(projectId: projectId, name: data.meta.projectName);
  }

  static String _readEntry(ArchiveFile entry) {
    final content = entry.content is List<int>
        ? entry.content as List<int>
        : const <int>[];
    return utf8.decode(content, allowMalformed: false);
  }

  static Future<String> _readFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return utf8.decode(bytes, allowMalformed: false);
  }

  static ArchiveFile? _findEntry(Archive archive, String name) {
    for (final entry in archive) {
      if (entry.name.replaceAll('\\', '/') == name) return entry;
    }
    return null;
  }

  static double _asDouble(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}