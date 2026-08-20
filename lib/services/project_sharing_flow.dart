import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_package.dart';
import 'package:mapbanai/services/project_qr.dart';
import 'package:mapbanai/services/project_transfer_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abstraction over the OS file dialogs (Storage Access Framework on
/// Android). Injectable in widget/unit tests.
abstract class ProjectFileSink {
  /// Lets the user save a .mbproj. Returns the saved path or null when
  /// cancelled. No storage permission is required (SAF).
  Future<String?> savePackageBytes({
    required String fileName,
    required Uint8List bytes,
  });

  /// Lets the user pick a .mbproj. Returns the path or null when cancelled.
  Future<String?> pickPackageFile();
}

class SafProjectFileSink implements ProjectFileSink {
  @override
  Future<String?> savePackageBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save project',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['mbproj'],
        bytes: bytes,
      );
      if (path == null || path.isEmpty) return null;
      // file_picker writes bytes on Android already; make it explicit.
      try {
        final file = File(path);
        if (!await file.exists() || await file.length() != bytes.length) {
          await file.writeAsBytes(bytes, flush: true);
        }
      } catch (_) {
        // The picker may have handled ownership; ignore.
      }
      return path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> pickPackageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import project',
        type: FileType.custom,
        allowedExtensions: ['mbproj'],
      );
      final files = result?.files;
      if (files == null || files.isEmpty) return null;
      return files.first.path;
    } catch (_) {
      return null;
    }
  }
}

enum ProjectExportStatus { saved, cancelled, failed }

/// High-level orchestration for the project ⋮ menu:
///
///  * Export Project          → build .mbproj + SAF save
///  * Share Project           → build .mbproj + transfer provider(s)
///  * Import (file or QR row) → validate → conflict check → commit
///
/// Pure-Dart where the OS is not involved, so almost everything here is
/// unit-testable with a real Drift in-memory database.
class ProjectSharingFlow {
  ProjectSharingFlow({
    required AppDatabase database,
    ProjectFileSink? fileSink,
    List<ProjectTransferProvider>? transferProviders,
    ProjectImporter? importer,
  }) : _database = database,
       _fileSink = fileSink ?? SafProjectFileSink(),
       _importer = importer ?? ProjectImporter(database),
       _transferProviders = transferProviders ?? ProjectTransferProviders.available();

  final AppDatabase _database;
  final ProjectFileSink _fileSink;
  final ProjectImporter _importer;
  final List<ProjectTransferProvider> _transferProviders;

  ProjectExporter get exporter => ProjectExporter(_database);

  /// Builds the .mbproj bytes without touching any OS API.
  Future<Uint8List> build(Project project) => exporter.buildPackageBytes(project);

  /// Suggested filename: `Name_v<N>.mbproj`.
  String suggestedFileName(Project project) =>
      safeProjectFileName(project.name, project.projectVersion);

  /// Export → native save dialog. Never requires a storage permission.
  Future<ProjectExportStatus> exportProject(Project project) async {
    try {
      final bytes = await build(project);
      final path = await _fileSink.savePackageBytes(
        fileName: suggestedFileName(project),
        bytes: bytes,
      );
      if (path == null) return ProjectExportStatus.cancelled;
      return ProjectExportStatus.saved;
    } catch (_) {
      return ProjectExportStatus.failed;
    }
  }

  /// Writes a shareable copy of the package to the app's private temp dir.
  Future<File?> createShareFile(Project project) async {
    try {
      final bytes = await build(project);
      final dir = Directory(p.join(
        (await getTemporaryDirectory()).path,
        'mapbanai_share',
      ));
      await dir.create(recursive: true);
      final file = File(
        p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}_'
            '${suggestedFileName(project)}'),
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Runs every available transfer provider; returns true when one
  /// accepted the file.
  Future<bool> shareProject(Project project) async {
    final file = await createShareFile(project);
    if (file == null) return false;
    for (final provider in _transferProviders) {
      if (await provider.isAvailable()) {
        return await provider.shareProjectFile(file, title: project.name);
      }
    }
    return false;
  }

  // ── Import ─────────────────────────────────────────────────────────

  /// Validates a .mbproj path (throws [ProjectImportException]) and checks
  /// whether it collides with an existing project. Nothing is written yet.
  Future<ProjectImportSession> startFileImport(String path) async {
    final validated = await _importer.validateAndExtract(File(path));
    final conflict = await _importer.checkConflict(validated.data.meta);
    return ProjectImportSession._(validated, conflict);
  }

  /// Validates an inline QR payload (throws [FormatException] / returns
  /// session with data). Bootstrap codes are reported through
  /// [ProjectImportSession.allowBootstrap].
  Future<ProjectImportSession> startQrImport(String payload) async {
    final decoded = ProjectQr.parse(payload);
    if (decoded == null) {
      throw const FormatException('Not a MapBanai project code');
    }
    if (decoded['mode'] == 'bootstrap') {
      final meta = ProjectPackageMeta.fromJson({
        'project_id': decoded['project_id'],
        'project_name': decoded['project_name'],
        'project_version': decoded['project_version'],
        'created_at': '',
        'exported_at': decoded['exported_at'] ?? '',
      });
      return ProjectImportSession._(null, null, payload: payload)
        ..bootstrapMeta = meta;
    }
    final data = ProjectQr.inlineToData(decoded);
    final conflict = await _importer.checkConflict(data.meta);
    return ProjectImportSession._(
      null,
      conflict,
      qrData: data,
      payload: payload,
    );
  }

  /// Commits a started import. [decision] resolves a conflict
  /// (newCopy / replace). On success the temp dir of a file import is
  /// removed automatically.
  Future<ImportCommitResult> finishImport(
    ProjectImportSession session, {
    ImportDecision? decision,
  }) async {
    try {
      if (session.qrData != null) {
        return await _database.transaction(
          () => _importer.commitQrData(
            session.qrData!,
            newCopy: decision == ImportDecision.newCopy,
            replaceExistingId: decision == ImportDecision.replaceExisting
                ? session.conflict?.id
                : null,
          ),
        );
      }
      final package = session.package;
      if (package == null) {
        throw const ProjectImportException(
          ProjectImportError.internal,
          'Nothing to import.',
        );
      }
      try {
        return await _importer.commit(
          package,
          newCopy: decision == ImportDecision.newCopy,
          replaceExistingId: decision == ImportDecision.replaceExisting
              ? session.conflict?.id
              : null,
        );
      } finally {
        await package.discard();
      }
    } catch (e) {
      // Clean up a possibly-lingering extraction directory.
      session.package?.discard();
      rethrow;
    }
  }
}

class ProjectImportSession {
  ProjectImportSession._(
    this.package,
    this.conflict, {
    this.qrData,
    this.payload,
    this.allowBootstrap = false,
  });

  /// Set for file-based imports.
  final ValidatedPackage? package;

  /// The local project this package collides with, if any.
  final Project? conflict;

  /// Set for QR-based imports (inline mode).
  final ProjectPackageData? qrData;

  /// The original QR payload string (for bootstrap options).
  final String? payload;

  final bool allowBootstrap;

  /// Set for bootstrap-QR payloads (no importable data — instructions only).
  ProjectPackageMeta? bootstrapMeta;

  bool get isConflict => conflict != null;

  bool get isQr => qrData != null;

  ProjectPackageMeta get meta => qrData?.meta ?? package!.data.meta;

  Future<void> discard() async {
    await package?.discard();
  }
}