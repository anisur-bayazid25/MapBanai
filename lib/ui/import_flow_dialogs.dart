import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_package.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';

/// Friendly, non-technical message for an import failure. Normal
/// enumerators should never see "database"/"JSON"/GIS jargon.
String friendlyImportMessage(Object error) {
  if (error is ProjectImportException) {
    switch (error.error) {
      case ProjectImportError.notFound:
        return 'The project file is no longer available. Try sharing it again.';
      case ProjectImportError.notAZipFile:
      case ProjectImportError.wrongPackageType:
        return 'This file is not a MapBanai project package.';
      case ProjectImportError.corruptedZip:
        return 'The project file is damaged and cannot be opened.';
      case ProjectImportError.invalidManifest:
        return 'The project file is missing its information and cannot be opened.';
      case ProjectImportError.unsupportedPackageVersion:
        return 'This project file was created by a newer version of MapBanai. '
            'Please update MapBanai and try again.';
      case ProjectImportError.missingRequiredFiles:
        return 'The project file is incomplete and cannot be opened.';
      case ProjectImportError.checksumMismatch:
        return 'The project file failed its safety check and was not imported.';
      case ProjectImportError.pathTraversalRisk:
        return 'This project file is not safe to open.';
      case ProjectImportError.invalidProjectJson:
        return 'The project file is not a valid MapBanai project.';
      case ProjectImportError.packageTooLarge:
        return 'The project file is too large to import on this device.';
      case ProjectImportError.internal:
        return 'The project could not be imported. Please try again.';
    }
  }
  if (error is FormatException) {
    return error.message == 'Unsupported project code version'
        ? 'This project code was created by a newer version of MapBanai. '
            'Please update MapBanai and try again.'
        : 'This is not a valid MapBanai project code.';
  }
  return 'The project could not be imported. Please try again.';
}

enum ImportChoice { newCopy, replaceExisting, cancel }

/// Runs the full import flow for a chosen file path or QR payload:
/// validate → conflict? decision → commit → success/failure message.
/// [onImported] is called after a successful commit (e.g. to refresh the
/// project list).
Future<void> runProjectImport(
  BuildContext context, {
  required ProjectSharingFlow flow,
  String? filePath,
  String? qrPayload,
  required VoidCallback onImported,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  ProjectImportSession? session;
  try {
    session = qrPayload != null && qrPayload.isNotEmpty
        ? await flow.startQrImport(qrPayload)
        : await flow.startFileImport(filePath!);

    if (session.allowBootstrap && session.bootstrapMeta != null) {
      navigator.pop();
      await _showBootstrapMessage(context, session.bootstrapMeta!);
      return;
    }

    ImportChoice choice = ImportChoice.cancel;
    if (session.isConflict) {
      navigator.pop();
      choice = await showProjectConflictDialog(context, session.meta)
          ?? ImportChoice.cancel;
      if (choice == ImportChoice.cancel) return;
    } else {
      navigator.pop();
    }

    if (!context.mounted) return;
    final importDecision = switch (choice) {
      ImportChoice.newCopy => ImportDecision.newCopy,
      ImportChoice.replaceExisting => ImportDecision.replaceExisting,
      ImportChoice.cancel => null,
    };
    await flow.finishImport(session, decision: importDecision);
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Project imported successfully.')),
    );
    onImported();
  } catch (error) {
    navigator.pop();
    if (!context.mounted) return;
    await showImportErrorDialog(context, error);
  }
}

/// "Project already exists." → Import as new copy / Replace / Cancel.
Future<ImportChoice?> showProjectConflictDialog(
  BuildContext context,
  ProjectPackageMeta meta,
) {
  return showDialog<ImportChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Project already exists'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${meta.projectName}" (version ${meta.projectVersion}) is '
            'already on this device.',
          ),
          const SizedBox(height: 12),
          const Text(
            'You can add it as a new copy, or replace the existing project. '
            'Replacing deletes the current project and everything collected '
            'in it.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ImportChoice.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ImportChoice.newCopy),
          child: const Text('Import as new copy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ImportChoice.replaceExisting),
          child: const Text('Replace existing project'),
        ),
      ],
    ),
  );
}

Future<void> _showBootstrapMessage(
  BuildContext context,
  ProjectPackageMeta meta,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Project code'),
      content: Text(
        '"${meta.projectName}" (version ${meta.projectVersion}).\n\n'
        'This code carries project information only. Ask the sender for the '
        'project file (.mbproj) or an import QR code to add it to this phone.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showImportErrorDialog(BuildContext context, Object error) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import failed'),
      content: Text(friendlyImportMessage(error)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Export → SAVE PROJECT FILE / SHARE PROJECT bottom sheet.
Future<void> showExportProjectOptions(
  BuildContext context, {
  required ProjectSharingFlow flow,
  required Project project,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export "${project.name}" (v${project.projectVersion})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'The project package includes forms, questions, settings and '
              'layers. Collected data and photos are never exported.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('SAVE PROJECT FILE'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('SHARE PROJECT'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (confirmed == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  if (confirmed) {
    final status = await flow.exportProject(project);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (status) {
          ProjectExportStatus.saved => 'Project exported successfully.',
          ProjectExportStatus.cancelled => 'Export cancelled.',
          ProjectExportStatus.failed => 'Export failed. Please try again.',
        }),
      ),
    );
  } else {
    final shared = await flow.shareProject(project);
    if (!context.mounted) return;
    if (shared) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sharing project…')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sharing is not available right now.')),
      );
    }
  }
}