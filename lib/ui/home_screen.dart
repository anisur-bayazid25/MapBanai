import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/services/background_gps_recorder.dart';
import 'package:mapbanai/services/backup_service.dart';
import 'package:mapbanai/services/intent_handler.dart';
import 'package:mapbanai/services/project_links.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';
import 'package:mapbanai/services/update_checker.dart';
import 'package:mapbanai/ui/data_export_screen.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'package:mapbanai/ui/common/update_dialog.dart';
import 'package:mapbanai/ui/gis_mode_screen.dart';
import 'package:mapbanai/ui/gps_mode_screen.dart';
import 'package:mapbanai/ui/import_flow_dialogs.dart';
import 'package:mapbanai/ui/project_setup_screen.dart';
import 'package:mapbanai/ui/settings_screen.dart';
import 'package:mapbanai/ui/survey_history_screen.dart';
import 'package:mapbanai/ui/survey_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AppDatabase _database;
  late BackupService _backup;
  Timer? _backupTimer;
  List<Project> _projects = [];
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _backup = BackupService(_database);
    BackgroundGps.instance.addListener(_onBackgroundGpsChanged);
    _loadProjects();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartupChecks();
    });
  }

  /// Runs the first-frame startup checks in order so dialogs do not stack:
  /// backup restore offer (needs to happen before anything reads the list),
  /// then the user-name prompt, then the silent update check and finally
  /// any incoming project file/link.
  Future<void> _handleStartupChecks() async {
    await _promptRestoreBackup();
    await _promptUserNameOnce();
    _checkForUpdatesSilently();
    _handleIncomingProject();
    _scheduleBackups();
  }

  /// Automated data-retention backup while the app is used: one snapshot
  /// shortly after launch, then every 6 hours. Purely best-effort.
  void _scheduleBackups() {
    _backupTimer?.cancel();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _backup.createBackup();
    });
    _backupTimer = Timer.periodic(const Duration(hours: 6), (_) {
      if (mounted) _backup.createBackup();
    });
  }

  /// On a fresh install (no projects yet) with a previous backup on disk,
  /// offer to restore settings and survey responses.
  Future<void> _promptRestoreBackup() async {
    try {
      final projects = await _database.getProjects(includeArchived: true);
      if (projects.isNotEmpty || !await _backup.hasBackups()) return;
      if (!mounted) return;

      final restore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Previous data backup found'),
          content: const Text(
            'A backup from a previous MapBanai install was found. '
            'Restore settings and survey responses?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (restore != true || !mounted) return;

      await _database.close();
      final restored = await _backup.restoreLatest();
      _database = AppDatabase();
      _backup = BackupService(_database);
      await _loadProjects();
      if (!mounted) return;

      final projectState = context.read<ProjectState>();
      final first = _projects.isNotEmpty ? _projects.first.name : '';
      if (first.isNotEmpty) projectState.setSelectedProject(first);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored
              ? 'Backup restored successfully.'
              : 'Backup restore failed. Data was not changed.'),
        ),
      );
    } catch (_) {
      // Restore is best-effort; a failure must never block startup.
    }
  }

  /// Handles a project file or link that opened MapBanai (Android "Open
  /// with MapBanai" / mapbanai:// deep link).
  Future<void> _handleIncomingProject() async {
    final raw = await IntentHandler.getInitialOpen();
    if (raw == null || !mounted) return;

    if (raw.startsWith('http') || raw.startsWith('mapbanai:')) {
      final info = ProjectLinks.parse(raw);
      if (info == null || !mounted) return;
      if (info.qrPayload != null && info.qrPayload!.isNotEmpty) {
        await _runProjectImport(qrPayload: info.qrPayload);
        return;
      }
      final file = info.fileUri;
      if (file != null && !file.startsWith('content://') && !file.startsWith('file://')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Online project links are not supported yet. Ask the sender '
              'for the project file (.mbproj) or a project QR code.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Project invite received. Open the .mbproj file in MapBanai to '
            'import it.',
          ),
        ),
      );
      return;
    }

    // Native side materialized a content:// (or file://) URI into the app
    // cache and handed back a plain file path.
    final path = raw;
    if (!mounted) return;
    await _runProjectImport(filePath: path);
  }

  Future<void> _runProjectImport({String? filePath, String? qrPayload}) async {
    final flow = ProjectSharingFlow(database: _database);
    await runProjectImport(
      context,
      flow: flow,
      filePath: filePath,
      qrPayload: qrPayload,
      onImported: () {
        _loadProjects();
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  /// Home → Import Project: choose a .mbproj file or paste a project code.
  Future<void> _startImportFlow() async {
    final source = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Import project'),
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open_rounded),
            title: const Text('Choose .mbproj file'),
            subtitle: const Text('Pick a project package from your device'),
            onTap: () => Navigator.pop(context, 'file'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2_rounded),
            title: const Text('Paste project code'),
            subtitle: const Text('Enter a MapBanai QR code or link'),
            onTap: () => Navigator.pop(context, 'paste'),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;

    if (source == 'file') {
      final path = await SafProjectFileSink().pickPackageFile();
      if (path == null || !mounted) return;
      await _runProjectImport(filePath: path);
      return;
    }

    final payload = await _promptPasteCode();
    if (payload == null || payload.trim().isEmpty || !mounted) return;
    await _runProjectImport(qrPayload: payload.trim());
  }

  Future<String?> _promptPasteCode() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste project code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Paste the MapBanai code here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  /// Non-intrusive background update check: never blocks startup, never
  /// auto-downloads. If a newer version exists a snackbar with a View action
  /// is shown.
  Future<void> _checkForUpdatesSilently() async {
    final update = await UpdateChecker.checkForUpdate();
    if (update == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update v${update.version} is available'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => showUpdateDialog(context, update),
        ),
      ),
    );
  }

  Future<void> _loadProjects() async {
    final projects = await _database.getProjects();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _refreshTick++;
    });
  }

  Future<void> _promptUserNameOnce() async {
    final stored = await _database.getSetting('user_name');
    if (stored != null && stored.trim().isNotEmpty) return;
    if (!mounted) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to MapBanai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your name — it will be attached to every survey '
              'response, GPS log entry and export. You can change it later '
              'in Settings.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'User name',
                hintText: 'e.g., John Doe',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    final name = result?.trim();
    if (name != null && name.isNotEmpty) {
      await _database.setSetting('user_name', name);
    }
  }

  void _onBackgroundGpsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BackgroundGps.instance.removeListener(_onBackgroundGpsChanged);
    _backupTimer?.cancel();
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectState>();
    final selected = projectState.selectedProject;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ScreenLayout.maxWidthAlign(
            context,
            Padding(
              padding: ScreenLayout.contentPadding(context),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  'assets/logo/MapBanai_logo.png',
                  width: 260,
                ),
                const SizedBox(height: 8),
                Text(
                  'Offline field data collection',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                _buildGpsRecordingBanner(context),
                _buildProjectSelector(context, projectState, selected),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'Survey Mode',
                  subtitle: 'Simple form-based field capture',
                  color: const Color(0xFF2E7D32),
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SurveyScreen(projectName: selected),
                      ),
                    );
                    _loadProjects();
                  },
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'GIS Mode',
                  subtitle: 'Map-based spatial editing and layers',
                  color: const Color(0xFF1565C0),
                  icon: Icons.map_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GisModeScreen(projectName: selected),
                      ),
                    );
                    _loadProjects();
                  },
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'GPS Mode',
                  subtitle: 'Live GPS readings and coordinate logging',
                  color: const Color(0xFF00695C),
                  icon: Icons.my_location_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GpsModeScreen()),
                    );
                    _loadProjects();
                  },
                ),
                const SizedBox(height: 24),
                _buildCollectedData(projectState, selected),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProjectSetupScreen()),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Open'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SurveyHistoryScreen()),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.history_outlined),
                        label: const Text('History'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DataExportScreen(projectName: selected),
                            ),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('Export'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _startImportFlow,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Import Project'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(database: _database),
                      ),
                    );
                    _loadProjects();
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildGpsRecordingBanner(BuildContext context) {
  final bg = BackgroundGps.instance;
  if (!bg.isRecording) return const SizedBox.shrink();
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'GPS recording active — "${bg.activeLogName}"',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Logging continues with the screen off. Leave GPS Mode any time; '
          'come back here to stop.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GpsModeScreen()),
                  );
                  _loadProjects();
                },
                child: const Text('Open GPS Mode'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await BackgroundGps.instance.stop();
                },
                child: const Text('Stop'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildProjectSelector(
    BuildContext context,
    ProjectState projectState,
    String selected,
  ) {
    return Material(
      color: Colors.blue.shade50,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickProject(context, projectState),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                color: selected.isEmpty ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.isEmpty
                      ? 'No project selected — tap to choose one'
                      : 'Current project: $selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProject(
    BuildContext context,
    ProjectState projectState,
  ) async {
    if (_projects.isEmpty) {
      _showSnack('Create a project first (Home → Open → New project)');
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select project'),
        children: [
          for (final project in _projects)
            RadioListTile<String>(
              title: Text(project.name),
              subtitle: Text(
                project.description.trim().isEmpty
                    ? 'No description'
                    : project.description.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: project.name,
              groupValue: projectState.selectedProject.isEmpty
                  ? null
                  : projectState.selectedProject,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
            ),
        ],
      ),
    );
    if (selected == null) return;
    projectState.setSelectedProject(selected);
  }

  Widget _buildCollectedData(ProjectState projectState, String selected) {
    if (selected.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Text(
          'Select a project above to see its collected data.',
          style: TextStyle(color: Colors.green),
        ),
      );
    }

    int? projectId;
    for (final project in _projects) {
      if (project.name == selected) {
        projectId = project.id;
        break;
      }
    }
    return FutureBuilder<({int survey, int gis})>(
      key: ValueKey('$_refreshTick|$selected'),
      future: _database.responseCountsForProject(projectId ?? 0),
      builder: (context, snapshot) {
        final counts = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Collected data — $selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      label: 'Survey Responses',
                      value: counts?.survey.toString() ?? '…',
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statTile(
                      label: 'GIS Features',
                      value: counts?.gis.toString() ?? '…',
                      icon: Icons.edit_location_alt_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
