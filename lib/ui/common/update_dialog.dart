import 'package:flutter/material.dart';
import 'package:mapbanai/services/update_checker.dart';
import 'package:mapbanai/services/update_downloader.dart';

/// Shows the "update available" dialog with release notes and a
/// Download & Install button wired to [UpdateDownloader]. The dialog stays
/// open and shows download progress; it is dismissed when the installer
/// has been handed off.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo update) {
  return showDialog<void>(
    context: context,
    builder: (context) => _UpdateDialog(update: update),
  );
}

/// Shows a "You're up to date" confirmation dialog.
Future<void> showUpToDateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      title: const Text("You're up to date"),
      content: const Text('No newer version is available.'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo update;

  const _UpdateDialog({required this.update});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  bool _failed = false;
  bool _needsInstallPermission = false;
  String _error = '';

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _failed = false;
      _needsInstallPermission = false;
      _error = '';
      _progress = 0;
    });
    try {
      final file = await UpdateDownloader.download(
        widget.update.downloadUrl,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await UpdateDownloader.openInstaller(file);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _failed = true;
        _needsInstallPermission = error is InstallPermissionException;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Version ${widget.update.version} is available'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New version: ${widget.update.version}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: widget.update.releaseNotes.trim().isEmpty
                    ? Text(
                        'No release notes were provided.',
                        style: theme.textTheme.bodySmall,
                      )
                    : Text(widget.update.releaseNotes.trim()),
              ),
            ),
            const SizedBox(height: 16),
            if (_downloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                'Downloading... ${(_progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ] else if (_failed) ...[
              Text(
                _error.trim().isEmpty
                    ? 'Download failed. Please check your connection and '
                        'try again.'
                    : 'Download failed. $_error',
                style: TextStyle(color: Colors.red.shade800),
              ),
              if (_needsInstallPermission) ...[
                const SizedBox(height: 8),
                Text(
                  'Open the device settings and enable "Allow from this '
                  'source", then tap Download & Install again.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_needsInstallPermission)
          FilledButton.icon(
            onPressed: _downloading
                ? null
                : () => UpdateDownloader.requestInstallPermission(),
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Allow installation'),
          ),
        FilledButton.icon(
          onPressed: _downloading ? null : _downloadAndInstall,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Download & Install'),
        ),
      ],
    );
  }
}
