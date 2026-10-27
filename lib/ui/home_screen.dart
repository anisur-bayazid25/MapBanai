import 'package:mapbanai/ui/common/user_name_dialog.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/services/spatial_file_import.dart';
import 'package:mapbanai/ui/open_spatial_file.dart';
import 'package:mapbanai/ui/help_screen.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/state/app_settings_provider.dart';
import 'package:mapbanai/services/background_gps_recorder.dart';
import 'package:mapbanai/services/backup_service.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/services/intent_handler.dart';
import 'package:mapbanai/services/photo_sync_service.dart';
import 'package:mapbanai/services/project_links.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';
import 'package:mapbanai/services/sync_orchestrator.dart';
import 'package:mapbanai/services/update_checker.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:mapbanai/services/webmap_generator.dart';
import 'package:mapbanai/ui/data_export_screen.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'package:mapbanai/ui/common/update_dialog.dart';
import 'package:mapbanai/ui/gis_mode_screen.dart';
import 'package:mapbanai/ui/guided_visit_screen.dart';
import 'package:mapbanai/ui/field_quality_screen.dart';
import 'package:mapbanai/ui/offline_maps_screen.dart';
import 'package:mapbanai/ui/gps_csv_viewer_screen.dart';
import 'package:mapbanai/ui/gps_mode_screen.dart';
import 'package:mapbanai/ui/import_flow_dialogs.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';
import 'package:mapbanai/ui/project_setup_screen.dart';
import 'package:mapbanai/ui/settings_screen.dart';
import 'package:mapbanai/ui/study_area_hub_screen.dart';
import 'package:mapbanai/ui/survey_history_screen.dart';
import 'package:mapbanai/ui/survey_screen.dart';
import 'package:mapbanai/ui/webmap_viewer_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.database});

  final AppDatabase? database;

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
    _database = widget.database ?? AppDatabase();
    IntentHandler.setOpenListener((path) => _handleIncomingProject(path));
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
      final hasBackups = await _backup.hasBackups();
      final newest = await _backup.newestBackup();
      debugPrint(
          '[Restore] _promptRestoreBackup: projects=${projects.length} hasBackups=$hasBackups newest=${newest?.path} exists=${newest != null ? newest.existsSync() : false}');
      if (projects.isNotEmpty ||
          !hasBackups ||
          BackgroundGps.instance.isRecording) return;
      if (!mounted) return;

      final restore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(ui(context, 'Previous data backup found')),
          content: Text(
            ui(context,
                'A backup from a previous MapBanai install was found. Restore settings and survey responses?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(ui(context, 'Not now')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(ui(context, 'Restore')),
            ),
          ],
        ),
      );
      if (restore != true || !mounted) return;

      debugPrint('[Restore] user confirmed restore, closing DB and copying');
      final settings = context.read<AppSettingsProvider>();
      await settings.prepareForRestore();
      var restored = false;
      try {
        await _database.close();
        restored = await _backup.restoreLatest();
      } finally {
        _database = AppDatabase();
        _backup = BackupService(_database);
        await settings.resumeAfterRestore();
      }
      await _loadProjects();
      if (!mounted) return;

      final projectState = context.read<ProjectState>();
      final first = _projects.isNotEmpty ? _projects.first.name : '';
      if (first.isNotEmpty)
        projectState.setSelectedProject(first, projectId: _projects.first.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored
              ? ui(context, 'Backup restored successfully.')
              : ui(context, 'Backup restore failed. Data was not changed.')),
        ),
      );
    } catch (e, st) {
      debugPrint('[Restore] _promptRestoreBackup failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ui(context, 'Restore failed: {v0}', [e]))),
        );
      }
    }
  }

  /// Handles a project file or link that opened MapBanai (Android "Open
  /// with MapBanai" / mapbanai:// deep link).
  Future<void> _handleIncomingProject([String? payload]) async {
    final raw = payload ?? await IntentHandler.getInitialOpen();
    if (raw == null || !mounted) return;

    if (raw.startsWith('http') || raw.startsWith('mapbanai:')) {
      final info = ProjectLinks.parse(raw);
      if (info == null || !mounted) return;
      final file = info.fileUri;
      if (file != null &&
          !file.startsWith('content://') &&
          !file.startsWith('file://')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ui(context,
                  'Online project links are not supported yet. Ask the sender for the project file (.mbproj).'),
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ui(context,
                'Project invite received. Open the .mbproj file in MapBanai to import it.'),
          ),
        ),
      );
      return;
    }

    // Native side materialized a content:// (or file://) URI into the app
    // cache and handed back a plain file path.
    final path = raw;
    if (!mounted) return;
    if (SpatialFileImport.supports(path)) {
      await openSpatialFile(context, _database, path);
      await _loadProjects();
      return;
    }
    await _runProjectImport(filePath: path);
  }

  Future<void> _runProjectImport({String? filePath}) async {
    final flow = ProjectSharingFlow(database: _database);
    await runProjectImport(
      context,
      flow: flow,
      filePath: filePath!,
      onImported: () {
        _loadProjects();
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  /// Import a project package directly from the device.
  Future<void> _startImportFlow() async {
    try {
      final path = await SafProjectFileSink().pickPackageFile();
      if (path == null || !mounted) return;
      await _runProjectImport(filePath: path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is ProjectImportException ||
                error is FormatException
            ? friendlyImportMessage(error)
            : ui(context, 'Could not open the file picker. Please try again.')),
      ));
    }
  }

  /// Non-intrusive background update check: never blocks startup, never
  /// auto-downloads. If a newer version exists a snackbar with a View action
  /// is shown.
  Future<void> _checkForUpdatesSilently() async {
    final update = await UpdateChecker.checkForUpdate();
    if (update == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(ui(context, 'Update v{v0} is available', [update.version])),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: ui(context, 'View'),
          onPressed: () => showUpdateDialog(context, update),
        ),
      ),
    );
  }

  Future<Project?> _resolveSelectedProject(ProjectState state) =>
      state.selectedProjectId != null
          ? _database.getProjectById(state.selectedProjectId!)
          : _database.getProjectByName(state.selectedProject);

  Future<void> _openFieldWorkflow({bool quality = false}) async {
    final project = await _resolveSelectedProject(context.read<ProjectState>());
    if (!mounted) return;
    if (project == null || project.archived) {
      _showSnack(ui(context, 'Select an active project first'));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => quality
          ? FieldQualityScreen(projectId: project.id, database: _database)
          : GuidedVisitScreen(projectId: project.id, database: _database),
    ));
    if (mounted) await _loadProjects();
  }

  Future<void> _handleSync() async {
    final projectState = context.read<ProjectState>();
    final selected = projectState.selectedProject;
    if (selected.isEmpty) {
      _showSnack(ui(context, 'Select a project first'));
      return;
    }
    final project = await _resolveSelectedProject(projectState);
    if (project == null) {
      _showSnack(ui(context, 'Project not found: {v0}', [selected]));
      return;
    }
    final config = await _database.getSyncConfig(project.id);
    if (config == null ||
        config.syncEndpointUrl == null ||
        config.syncEndpointUrl!.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(ui(context, 'Set up cloud sync for this project first'))),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            projectId: project.id,
            database: _database,
          ),
        ),
      );
      if (mounted) setState(() => _refreshTick++);
      return;
    }

    if (!mounted) return;
    final result = await showDialog<FullSyncResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SyncProgressDialog(
        database: _database,
        projectId: project.id,
        projectName: project.name,
      ),
    );
    if (result != null && mounted) {
      if (result.dataError != null) {
        final msg = result.dataError!;
        final isOffline = _isOfflineError(msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isOffline ? ui(context, 'No internet connection') : msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.summary)),
        );
      }
      setState(() => _refreshTick++);
    }
  }

  Future<void> _generateAndOpenWebMap() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final projectState = context.read<ProjectState>();
    final selected = projectState.selectedProject;
    if (selected.isEmpty) {
      _showSnack(ui(context, 'Select a project first'));
      return;
    }
    final project = await _resolveSelectedProject(projectState);
    if (project == null) {
      _showSnack(ui(context, 'Project not found: {v0}', [selected]));
      return;
    }
    // Show loading indicator while generating (can take a moment for large datasets)
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final dataService =
          WebMapDataService(_database, studyAreaStore: StudyAreaStore());
      final generator = WebMapGenerator(dataService: dataService);
      // Project-wise: only this project's data
      final featureCollection =
          await dataService.buildFeatureCollectionForProject(project.id);
      final count = (featureCollection['features'] as List).length;
      if (count > 1000 && mounted) {
        // Still generate but inform user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ui(
                  context,
                  'Generating webmap for {v0} features — this may take a moment...',
                  [count]))),
        );
      }
      final html = await generator.generateHtml(
          featureCollection: featureCollection, languageCode: languageCode);
      final file = await generator.writeToFile(html);
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => WebmapViewerScreen(
                htmlFile: file, database: _database, projectId: project.id)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ui(context, 'Failed to generate webmap: {v0}', [e]))),
      );
    }
  }

  bool _isOfflineError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('network error') ||
        lower.contains('no internet');
  }

  String _formatLastSynced(DateTime? dt, [AppLocalizations? l10n]) {
    if (dt == null) return l10n?.syncNever ?? 'Never synced';
    final local = dt.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSyncSquare(BuildContext context, String selected) {
    if (selected.isEmpty) {
      return _SquareModeCard(
        title: ui(context, 'Cloud Sync'),
        color: Color(0xFF6A1B9A),
        icon: Icons.cloud_off_outlined,
        onTap: null,
        subtitle: ui(context, 'No project selected'),
      );
    }
    final state = context.read<ProjectState>();
    int? projectId;
    for (final p in _projects) {
      if (state.selectedProjectId != null
          ? p.id == state.selectedProjectId
          : p.name == selected) {
        projectId = p.id;
        break;
      }
    }
    if (projectId == null) {
      return _SquareModeCard(
        title: ui(context, 'Cloud Sync'),
        color: Color(0xFF6A1B9A),
        icon: Icons.cloud_off_outlined,
        onTap: null,
        subtitle: ui(context, 'No project selected'),
      );
    }
    return FutureBuilder<SyncConfig?>(
      key: ValueKey(
          'syncSquare_${_refreshTick}_$selected|${state.selectedProjectId}'),
      future: _database.getSyncConfig(projectId),
      builder: (context, snapshot) {
        AppLocalizations? l10n;
        try {
          l10n = AppLocalizations.of(context);
        } catch (_) {}
        final cfg = snapshot.data;
        final hasConfig = cfg != null &&
            cfg.syncEndpointUrl != null &&
            cfg.syncEndpointUrl!.trim().isNotEmpty;
        return _SquareModeCard(
          title: l10n?.syncTitle ?? 'Cloud Sync',
          color: const Color(0xFF6A1B9A),
          icon:
              hasConfig ? Icons.cloud_sync_outlined : Icons.cloud_off_outlined,
          onTap: hasConfig || !hasConfig ? _handleSync : null,
          subtitle: hasConfig
              ? _formatLastSynced(cfg.lastSyncAt, l10n)
              : (l10n?.syncSetupTitle ?? 'Set up sync'),
        );
      },
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

  Future<void> _editMyName() async {
    final saved = await _database.getSetting('user_name') ?? '';
    if (!mounted) return;
    final name = await showDialog<String>(
        context: context, builder: (_) => UserNameDialog(initialName: saved));
    if (name == null || !mounted) return;
    if (name.isEmpty) {
      _showSnack(ui(context, 'Enter your name so submissions identify you.'));
      return;
    }
    await _database.setSetting('user_name', name);
    if (mounted) setState(() {});
  }

  Future<void> _myResponses() async {
    final project = await _resolveSelectedProject(context.read<ProjectState>());
    if (!mounted) return;
    if (project == null) {
      _showSnack(ui(context, 'Import or select a project first'));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SurveyHistoryScreen(projectId: project.id)));
    if (mounted) await _loadProjects();
  }

  Future<void> _promptUserNameOnce() async {
    final stored = await _database.getSetting('user_name');
    debugPrint(
        '[Restore] _promptUserNameOnce: searched key=user_name value=${stored ?? "null"} exists=${stored != null && stored.trim().isNotEmpty} — note: backup location does NOT use username, it is scanned via BackupService._backupRoot newestBackup()');
    if (stored != null && stored.trim().isNotEmpty) return;
    if (!mounted) return;

    final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const UserNameDialog(welcome: true));

    final name = result?.trim();
    if (name != null && name.isNotEmpty && mounted) {
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
    if (widget.database == null) _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectState>();
    final selected = projectState.selectedProject;
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            tooltip: ui(context, 'Menu'),
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              if (value == 'name') {
                await _editMyName();
              } else if (value == 'responses') {
                await _myResponses();
              } else if (value == 'help') {
                final project =
                    await _resolveSelectedProject(context.read<ProjectState>());
                if (!mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        HelpScreen(projectId: project?.externalId)));
              } else if (value == 'settings') {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SettingsScreen(database: _database)));
                _loadProjects();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'name',
                  child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text(ui(context, 'My name')))),
              PopupMenuItem(
                  value: 'responses',
                  child: ListTile(
                      leading: Icon(Icons.history_outlined),
                      title: Text(ui(context, 'My responses')))),
              PopupMenuItem(
                  value: 'help',
                  child: ListTile(
                      leading: Icon(Icons.help_outline),
                      title: Text(ui(context, 'Help & manager setup')))),
              PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(l10n?.settings ?? 'Settings'))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ScreenLayout.maxWidthAlign(
            context,
            Padding(
              padding: ScreenLayout.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: Image.asset(
                      'assets/logo/MapBanai_logo.png',
                      width: 260,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.homeSubtitle ?? 'Easy Geospatial Data Collection',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const SizedBox(height: 18),
                  _buildGpsRecordingBanner(context),
                  _buildProjectSelector(context, projectState, selected),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openFieldWorkflow(),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(ui(context, 'Visit a study site')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Reflow modes and utilities as screen/text size changes.
                  ResponsiveGrid(
                    minChildWidth: 130,
                    children: [
                      _SquareModeCard(
                        title: l10n?.surveyModeTitle ?? 'Survey Mode',
                        color: const Color(0xFF2E7D32),
                        icon: Icons.assignment_turned_in_outlined,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SurveyScreen(
                                  projectName: selected,
                                  projectId: projectState.selectedProjectId),
                            ),
                          );
                          _loadProjects();
                        },
                      ),
                      _SquareModeCard(
                        title: l10n?.studyAreaModeTitle ?? 'Study Area Mode',
                        color: const Color(0xFFE65100),
                        icon: Icons.explore_outlined,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => StudyAreaHubScreen(
                                    projectId: context
                                        .read<ProjectState>()
                                        .selectedProjectId)),
                          );
                          _loadProjects();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ResponsiveGrid(
                    minChildWidth: 130,
                    children: [
                      _SquareModeCard(
                        title: l10n?.gpsModeTitle ?? 'GPS Mode',
                        color: const Color(0xFF00695C),
                        icon: Icons.my_location_outlined,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const GpsModeScreen()),
                          );
                          _loadProjects();
                        },
                      ),
                      _SquareModeCard(
                        title: l10n?.gisModeTitle ?? 'GIS Mode',
                        color: const Color(0xFF1565C0),
                        icon: Icons.map_outlined,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GisModeScreen(
                                  projectName: selected,
                                  projectId: projectState.selectedProjectId),
                            ),
                          );
                          _loadProjects();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Utilities use up to three columns when their labels fit.
                  ResponsiveGrid(
                    minChildWidth: 110,
                    children: [
                      _SquareModeCard(
                        title: l10n?.gpsCsvViewerTitle ?? 'GPS CSV Viewer',
                        color: const Color(0xFF283593),
                        icon: Icons.table_chart_outlined,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const GpsCsvViewerScreen()),
                          );
                          _loadProjects();
                        },
                      ),
                      _buildSyncSquare(context, selected),
                      _SquareModeCard(
                        title: l10n?.webMapTitle ?? 'WebMap',
                        color: const Color(0xFF4A148C),
                        icon: Icons.public_outlined,
                        onTap: _generateAndOpenWebMap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openFieldWorkflow(quality: true),
                        icon: const Icon(Icons.rule_outlined),
                        label: Text(ui(context, 'Field quality checks')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const OfflineMapsScreen()),
                        ),
                        icon: const Icon(Icons.download_for_offline_outlined),
                        label: Text(ui(context, 'Offline maps')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCollectedData(projectState, selected),
                  const SizedBox(height: 20),
                  ResponsiveGrid(
                    minChildWidth: 180,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ProjectSetupScreen()),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.folder_open_rounded),
                        label:
                            Text(l10n?.projectSettings ?? 'Project settings'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SurveyHistoryScreen()),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.history_outlined),
                        label: Text(l10n?.history ?? 'History'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DataExportScreen(
                                  projectName: selected,
                                  projectId: projectState.selectedProjectId),
                            ),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.ios_share_outlined),
                        label: Text(l10n?.export ?? 'Export'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _startImportFlow,
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(l10n?.importProject ?? 'Import Project'),
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
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {}
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
                  l10n != null
                      ? l10n.gpsRecordingActive(bg.activeLogName)
                      : 'GPS recording active — "${bg.activeLogName}"',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.gpsRecordingHint ??
                'Logging continues with the screen off. Leave GPS Mode any time; come back here to stop.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          ResponsiveGrid(
            minChildWidth: 180,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GpsModeScreen()),
                  );
                  _loadProjects();
                },
                child: Text(l10n?.openGpsMode ?? 'Open GPS Mode'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await BackgroundGps.instance.stop();
                },
                child: Text(l10n?.stop ?? 'Stop'),
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
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {}
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: isDark ? cs.surfaceContainerHighest : Colors.blue.shade50,
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
                      ? (l10n?.noProjectSelected ??
                          'No project selected — tap to choose one')
                      : (l10n != null
                          ? l10n.projectSelectorTitle(selected)
                          : 'Current project: $selected'),
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
      _showSnack(ui(context,
          'No projects yet — open Project Settings to create one, or use Import Project to import a .mbproj file'));
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(ui(context, 'Select project')),
        children: [
          for (final project in _projects)
            RadioListTile<int>(
              title: Text(project.name),
              subtitle: Text(
                project.description.trim().isEmpty
                    ? ui(context, 'No description')
                    : project.description.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: project.id,
              groupValue: projectState.selectedProjectId,
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
    final project = _projects.firstWhere((p) => p.id == selected);
    projectState.setSelectedProject(project.name, projectId: project.id);
  }

  Widget _buildCollectedData(ProjectState projectState, String selected) {
    final cs = Theme.of(context).colorScheme;
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {}
    if (selected.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.green.shade800 : Colors.green.shade200),
        ),
        child: Text(
          l10n?.collectedDataHint ??
              'Select a project above to see its collected data.',
          style:
              TextStyle(color: isDark ? Colors.green.shade300 : Colors.green),
        ),
      );
    }

    int? projectId;
    for (final project in _projects) {
      if (projectState.selectedProjectId != null
          ? project.id == projectState.selectedProjectId
          : project.name == selected) {
        projectId = project.id;
        break;
      }
    }
    return FutureBuilder<({int survey, int gis})>(
      key:
          ValueKey('$_refreshTick|$selected|${projectState.selectedProjectId}'),
      future: _database.responseCountsForProject(projectId ?? 0),
      builder: (context, snapshot) {
        final counts = snapshot.data;
        final isDark2 = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark2 ? cs.surfaceContainerHighest : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark2 ? Colors.green.shade800 : Colors.green.shade200),
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
                  Expanded(
                      child: Text(
                    l10n != null
                        ? l10n.collectedDataTitle(selected)
                        : 'Collected data — $selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveGrid(
                minChildWidth: 150,
                children: [
                  _statTile(
                    label: l10n?.surveyResponses ?? 'Survey Responses',
                    value: counts?.survey.toString() ?? '…',
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                  _statTile(
                    label: l10n?.gisFeatures ?? 'GIS Features',
                    value: counts?.gis.toString() ?? '…',
                    icon: Icons.edit_location_alt_outlined,
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
    final isDark3 = Theme.of(context).brightness == Brightness.dark;
    final cs3 = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark3 ? cs3.surface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark3 ? Colors.green.shade800 : Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
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
          )),
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

class _SyncProgressDialog extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  final String projectName;

  const _SyncProgressDialog({
    required this.database,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<_SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<_SyncProgressDialog> {
  String _phase = 'Syncing data...';
  int _photoCurrent = 0;
  int _photoTotal = 0;
  String? _error;
  FullSyncResult? _result;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      // Phase 1: data
      setState(() => _phase = 'Syncing data...');
      final dataResult = await CloudSyncService(widget.database,
              studyAreaStore: StudyAreaStore())
          .syncProject(widget.projectId)
          .catchError((e) {
        // rethrow to handle offline vs generic
        throw e;
      });

      // Phase 2: photos with progress
      final photoService = PhotoSyncService(
        widget.database,
        maxPhotoBytes: PhotoSyncService.defaultMaxBytes,
      );
      // Set initial photo phase
      setState(() {
        _phase = 'Syncing photos...';
      });
      final photoResult = await photoService.syncPhotos(
        widget.projectId,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _photoCurrent = current;
              _photoTotal = total;
              _phase = 'Syncing photos ($current/$total)...';
            });
          }
        },
      );

      final full = FullSyncResult(
        data: dataResult,
        photos: photoResult,
        dataError: null,
      );

      setState(() {
        _result = full;
        _done = true;
        _phase = full.summary;
      });
    } catch (e) {
      final msg = e.toString();
      final isOffline = msg.toLowerCase().contains('socketexception') ||
          msg.toLowerCase().contains('failed host lookup') ||
          msg.toLowerCase().contains('network is unreachable') ||
          msg.toLowerCase().contains('connection refused') ||
          msg.toLowerCase().contains('network error') ||
          msg.toLowerCase().contains('no internet');
      setState(() {
        _error = isOffline ? 'No internet connection' : msg;
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_done
          ? (_error != null
              ? ui(context, 'Sync failed')
              : ui(context, 'Sync complete'))
          : ui(context, 'Syncing...')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_done) ...[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            Text(_phase, textAlign: TextAlign.center),
            if (_photoTotal > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  ui(context, '{v0}/{v1} photos', [_photoCurrent, _photoTotal]),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
          ] else if (_error != null) ...[
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ] else ...[
            Icon(Icons.check_circle_outline,
                color: Colors.green.shade700, size: 48),
            const SizedBox(height: 12),
            Text(
              _result?.summary ?? ui(context, 'Sync finished'),
              textAlign: TextAlign.center,
            ),
            if (_result != null && _result!.photos.total > 0) ...[
              const SizedBox(height: 8),
              Text(
                _result!.photos.summary,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
      actions: _done
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context, _result),
                child: Text(ui(context, 'Close')),
              ),
            ]
          : null,
    );
  }
}

class _SquareModeCard extends StatelessWidget {
  const _SquareModeCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
