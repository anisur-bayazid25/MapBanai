import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows the project QR transfer code.
///
/// Small projects get a self-contained **inline** code — scanning it on
/// another phone imports the complete project definition. Large projects
/// get a **bootstrap** code that carries the project identity and lets the
/// receiving phone verify a separately transferred .mbproj.
class ProjectQrScreen extends StatefulWidget {
  const ProjectQrScreen({required this.project, super.key, this.database});

  /// The project row (local). Only its id/name/version are shown.
  final Project project;

  final AppDatabase? database;

  @override
  State<ProjectQrScreen> createState() => _ProjectQrScreenState();
}

class _ProjectQrScreenState extends State<ProjectQrScreen> {
  late final AppDatabase _database = widget.database ?? AppDatabase();
  String? _payload;
  String? _error;
  bool _inline = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void dispose() {
    if (widget.database == null) _database.close();
    super.dispose();
  }

  Future<void> _build() async {
    try {
      final exporter = ProjectExporter(_database);
      final data = await exporter.buildData(widget.project);
      if (!mounted) return;
      String payload;
      var inline = true;
      try {
        payload = ProjectQr.encodeInline(data);
      } on ProjectTooLargeForQrException {
        // Bootstrap code with the package checksum.
        inline = false;
        final bytes = await exporter.buildPackageBytes(widget.project);
        final checksum =
            ProjectQr.sha256HexBytes(bytes);
        payload = ProjectQr.encodeBootstrap(
          projectId: data.meta.projectId,
          projectName: data.meta.projectName,
          projectVersion: data.meta.projectVersion,
          checksum: checksum,
        );
      }
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _inline = inline;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not generate the project code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Project QR code')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _payload == null
              ? (_error != null
                    ? Text(_error!, style: theme.textTheme.bodyMedium)
                    : const CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.project.name,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Version ${_versionLabel()}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _payload!,
                          version: QrVersions.auto,
                          size: 240,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _inline
                            ? 'Scan or paste this code on another phone to '
                                'import this project.'
                            : 'Project is too large for direct QR transfer.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (!_inline) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Share the project file instead; this code lets the '
                          'receiving phone confirm it got the right project.',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Paste this code into MapBanai → Import → '
                        'Paste project code:',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _payload!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _versionLabel() {
    if (widget.project.projectVersion <= 1) return '1';
    return '${widget.project.projectVersion}';
  }
}