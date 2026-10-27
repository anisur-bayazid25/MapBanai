import 'package:mapbanai/ui/workflow_requirements_screen.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'package:mapbanai/ui/project_templates_screen.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/ui/help_screen.dart';
import 'package:mapbanai/ui/questionnaire_sync_screen.dart';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/xlsform_parser.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';
import 'package:mapbanai/services/project_asset_service.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/import_flow_dialogs.dart';
import 'package:mapbanai/ui/project_qr_screen.dart';
import 'package:mapbanai/ui/project_vector_layers_screen.dart';
import 'package:mapbanai/ui/survey_form_builder_screen.dart';
import 'package:mapbanai/ui/survey_form_detail_screen.dart';
import 'package:mapbanai/ui/survey_history_screen.dart';
import 'package:provider/provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen(
      {required this.projectId, super.key, this.database});

  final int projectId;
  final AppDatabase? database;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final AppDatabase _database = widget.database ?? AppDatabase();
  Project? _project;
  int _surveyCount = 0;
  int _featureCount = 0;
  List<StoredForm> _forms = [];
  bool _loading = true;

  // Cloud Sync
  final TextEditingController _syncUrlController = TextEditingController();
  final TextEditingController _syncApiKeyController = TextEditingController();
  SyncConfig? _syncConfig;
  bool _savingSync = false;
  bool _testingSync = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final projects = await _database.getProjects(includeArchived: true);
    Project? project;
    for (final item in projects) {
      if (item.id == widget.projectId) {
        project = item;
        break;
      }
    }
    if (project != null) {
      project =
          (await ProjectWorkspaceService(_database).load(project.id)).project;
    }
    final count = project == null
        ? (survey: 0, gis: 0)
        : await _database.responseCountsForProject(project.id);
    final forms = project == null
        ? <StoredForm>[]
        : await _database.getStoredFormsForProject(project.id);
    final syncConfig =
        project == null ? null : await _database.getSyncConfig(project.id);
    if (!mounted) return;
    setState(() {
      _project = project;
      _surveyCount = count.survey;
      _featureCount = count.gis;
      _forms = forms;
      _syncConfig = syncConfig;
      _syncUrlController.text = syncConfig?.syncEndpointUrl ?? '';
      _syncApiKeyController.text = syncConfig?.syncApiKey ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _syncUrlController.dispose();
    _syncApiKeyController.dispose();
    if (widget.database == null) {
      _database.close();
    }
    super.dispose();
  }

  Future<void> _editName() async {
    final current = _project?.name ?? '';
    final name = await _showEditDialog(
      title: ui(context, 'Project name'),
      initial: current,
      hint: 'e.g. Riverbank survey',
    );
    if (name == null || name.trim().isEmpty || name.trim() == current) return;
    if (await _database.projectExists(name.trim())) {
      _showSnack(
          ui(context, 'A project named "{v0}" already exists', [name.trim()]));
      return;
    }
    await _database.updateProject(widget.projectId, name: name.trim());
    if (!mounted) return;
    context
        .read<ProjectState>()
        .setSelectedProject(name.trim(), projectId: widget.projectId);
    await _load();
  }

  Future<void> _editDescription() async {
    final current = _project?.description ?? '';
    final description = await _showEditDialog(
      title: ui(context, 'Project description'),
      initial: current,
      hint: 'What is this project about?',
      maxLines: 3,
    );
    if (description == null || description == current) return;
    await _database.updateProject(widget.projectId, description: description);
    await _load();
  }

  Future<String?> _showEditDialog({
    required String title,
    required String initial,
    required String hint,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: title,
            hintText: hint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ui(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(ui(context, 'Save')),
          ),
        ],
      ),
    );
  }

  Future<void> _setThreshold(double threshold) async {
    await _database.updateProject(widget.projectId, gpsThresholdM: threshold);
    await _load();
    _showSnack(ui(
        context, 'GPS accuracy threshold set to {v0} m', [threshold.round()]));
  }

  Future<void> _toggleArchived() async {
    final project = _project;
    if (project == null) return;
    final action = project.archived ? 'Restore' : 'Archive';
    final confirmed = await showConfirmDialog(
      context,
      title: action,
      message: project.archived
          ? ui(
              context,
              'Restore "{v0}"? It will appear in project setup again.',
              [project.name])
          : ui(
              context,
              'Archive "{v0}"? It will be hidden from project setup. Its data is kept and can be restored later.',
              [project.name]),
      confirmText: action,
      cancelText: 'Cancel',
    );
    if (!confirmed) return;
    final wasArchived = _project!.archived;
    await _database.archiveProject(widget.projectId, archived: !wasArchived);
    if (wasArchived) {
      if (!mounted) return;
      context
          .read<ProjectState>()
          .setSelectedProject(_project!.name, projectId: widget.projectId);
    }
    await _load();
    _showSnack(wasArchived
        ? ui(context, 'Project restored')
        : ui(context, 'Project archived'));
  }

  Future<void> _showExportOptions() async {
    final project = _project;
    if (project == null || !mounted) return;
    final flow = ProjectSharingFlow(database: _database);
    await showExportProjectOptions(context, flow: flow, project: project);
  }

  void _showQr() {
    final project = _project;
    if (project == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectQrScreen(
          project: project,
          database: _database,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSyncSnack(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  Future<void> _saveSyncConfig() async {
    final project = _project;
    if (project == null) return;
    setState(() => _savingSync = true);
    try {
      final url = _syncUrlController.text.trim();
      final key = _syncApiKeyController.text.trim();
      await _database.upsertSyncConfig(
        projectId: project.id,
        syncEndpointUrl: url,
        syncApiKey: key,
      );
      final updated = await _database.getSyncConfig(project.id);
      if (!mounted) return;
      setState(() => _syncConfig = updated);
      _showSyncSnack('Sync settings saved', success: true);
    } catch (e) {
      _showSyncSnack('Failed to save sync settings: $e', success: false);
    } finally {
      if (mounted) setState(() => _savingSync = false);
    }
  }

  Future<void> _testSyncConnection() async {
    final project = _project;
    if (project == null) return;
    setState(() => _testingSync = true);
    try {
      final workspace =
          await ProjectWorkspaceService(_database).load(project.id);
      await CloudSyncService(_database).testConnection(
        endpoint: _syncUrlController.text,
        apiKey: _syncApiKeyController.text,
        projectId: workspace.project.externalId ?? project.externalId ?? '',
      );
      _showSyncSnack(
          'Connection verified: project, API key and data sheet are ready.',
          success: true);
    } catch (e) {
      _showSyncSnack(
          e is CloudSyncException
              ? e.message
              : 'Connection could not be checked. Verify internet access and manager setup.',
          success: false);
    } finally {
      if (mounted) setState(() => _testingSync = false);
    }
  }

  // ── survey forms ─────────────────────────────────────────────

  Future<void> _openForm(StoredForm form) async {
    final projectName = _project?.name;
    if (projectName == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyFormDetailScreen(
          row: form,
          projectName: projectName,
        ),
      ),
    );
    await _load();
  }

  Future<void> _addForm() async {
    final projectId = widget.projectId;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyFormBuilderScreen(
          onSave: (form) async {
            await _database.insertStoredForm(
              StoredFormsCompanion(
                projectId: drift.Value(projectId),
                name: drift.Value(form.name),
                description: drift.Value(form.description),
                json: drift.Value(jsonEncode(form.toJson())),
                version: drift.Value(form.version),
              ),
            );
          },
        ),
      ),
    );
    await _load();
  }

  Future<void> _editForm(StoredForm form) async {
    final parsed = SurveyForm.fromJson(
      jsonDecode(form.json) as Map<String, dynamic>,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyFormBuilderScreen(
          existingForm: parsed,
          onSave: (updated) async {
            await _database.updateStoredForm(
              form.id,
              name: updated.name,
              description: updated.description,
              json: jsonEncode(updated.toJson()),
              version: updated.version,
            );
          },
        ),
      ),
    );
    await _load();
  }

  Future<void> _deleteForm(StoredForm form) async {
    final confirmed = await showConfirmDialog(
      context,
      title: ui(context, 'Delete form'),
      message: ui(context, 'Delete "{v0}"?', [form.name]),
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteStoredForm(form.id);
    await _load();
    _showSnack(ui(context, 'Form deleted'));
  }

  Future<void> _importXlsForm() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _showSnack(ui(context, 'Could not read the selected file'));
      return;
    }

    try {
      final form = XlsFormParser.parse(bytes, fileName: file.name);
      if (form.importWarnings.isNotEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(ui(context, 'Review form import')),
            content: SingleChildScrollView(
                child: Text(form.importWarnings.join('\n\n'))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(ui(context, 'Cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(ui(context, 'Import form'))),
            ],
          ),
        );
        if (proceed != true) return;
      }
      final existing = await _database.getStoredFormByName(
        form.name,
        projectId: widget.projectId,
      );
      if (existing != null) {
        await _database.updateStoredForm(
          existing.id,
          name: form.name,
          description: form.description,
          json: jsonEncode(form.toJson()),
          version: existing.version + 1,
        );
        _showSnack(ui(context, 'Updated "{v0}" from XLSForm', [form.name]));
      } else {
        await _database.insertStoredForm(
          StoredFormsCompanion(
            projectId: drift.Value(widget.projectId),
            name: drift.Value(form.name),
            description: drift.Value(form.description),
            json: drift.Value(jsonEncode(form.toJson())),
            version: drift.Value(form.version),
          ),
        );
        _showSnack(
          ui(context, 'Imported "{v0}" with {v1} questions',
              [form.name, form.questions.length]),
        );
      }
      await ProjectAssetService(_database)
          .add(widget.projectId, file.name, bytes);
    } on XlsFormParseException catch (e) {
      _showSnack(ui(context, 'Import failed: {v0}', [e.message]));
    } catch (e) {
      _showSnack(ui(context, 'Import failed: {v0}', [e]));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? ui(context, 'Project')),
        actions: [
          IconButton(
              tooltip: ui(context, 'Help & manager setup'),
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HelpScreen(projectId: project?.externalId)))),
          IconButton(
              tooltip: ui(context, 'Reusable templates'),
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProjectTemplatesScreen(
                        database: _database, projectId: widget.projectId)));
                await _load();
              }),
          IconButton(
              tooltip: ui(context, 'Sync questionnaire'),
              icon: const Icon(Icons.cloud_download_outlined),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuestionnaireSyncScreen(
                        database: _database, projectId: widget.projectId)));
                await _load();
              }),
          if (project != null) ...[
            PopupMenuButton<String>(
              key: const ValueKey('project-share-menu'),
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: ui(context, 'Share'),
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _showExportOptions();
                  case 'qr':
                    _showQr();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.save_alt_rounded),
                    title: Text(ui(context, 'Export / Share project')),
                  ),
                ),
                PopupMenuItem(
                  value: 'qr',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.qr_code_2_rounded),
                    title: Text(ui(context, 'QR code')),
                  ),
                ),
              ],
            ),
          ],
          if (project != null && project.archived)
            TextButton.icon(
              onPressed: _toggleArchived,
              icon: const Icon(Icons.restore_outlined, size: 18),
              label: Text(ui(context, 'Restore')),
            ),
        ],
      ),
      body: _loading || project == null
          ? const AppLoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (project.archived)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(ui(context, 'Archived project'),
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _infoTile(
                  icon: Icons.description_outlined,
                  label: ui(context, 'Description'),
                  value: project.description.isEmpty
                      ? 'No description'
                      : project.description,
                  onTap: _editDescription,
                ),
                const SizedBox(height: 12),
                ListTile(
                    leading: const Icon(Icons.rule_rounded),
                    title: Text(ui(context, 'Workflow requirements')),
                    subtitle: Text(ui(context,
                        'Required questionnaires and photos for each workflow')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => WorkflowRequirementsScreen(
                                database: _database, projectId: project.id)))),
                const SizedBox(height: 12),
                _infoTile(
                  icon: Icons.inbox_outlined,
                  label: ui(context, 'Survey and map history'),
                  value: '$_surveyCount surveys · $_featureCount map records',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SurveyHistoryScreen(projectId: project.id),
                      ),
                    );
                    if (mounted) await _load();
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  ui(context, 'GPS settings'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ui(context,
                      'Default max acceptable accuracy used when recording points in this project.'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                ResponsiveChoice<double>(
                  segments: const [
                    ButtonSegment(value: 5, label: Text('5m')),
                    ButtonSegment(value: 10, label: Text('10m')),
                    ButtonSegment(value: 20, label: Text('20m')),
                    ButtonSegment(value: 50, label: Text('50m')),
                  ],
                  selected: {project.gpsThresholdM},
                  onSelectionChanged: (selection) =>
                      _setThreshold(selection.first),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: Text(ui(context, 'Edit project name')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editName,
                ),
                const SizedBox(height: 8),
                Text(
                  ui(context, 'Project files and map layers'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ui(context,
                      'Add study-area, facility and road layers. Source files travel with project exports.'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.layers_outlined),
                  title: Text(ui(context, 'Manage project files and layers')),
                  subtitle: Text(ui(context,
                      'Shapefile, CSV, Excel, GeoJSON and GeoPackage')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProjectVectorLayersScreen(
                            database: _database, projectId: widget.projectId)));
                    await _load();
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  ui(context, 'Survey forms'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ui(context,
                      'One questionnaire supplies Survey, GIS and Study Area questions. You can create a form, edit it, or import an XLSForm (.xlsx) file.'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                if (_forms.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      ui(context,
                          'No forms yet. Add one or import an XLSForm file.'),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                else
                  for (final form in _forms) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.assignment_outlined, size: 20),
                      title: Text(form.name),
                      subtitle: Text(
                        form.description.trim().isEmpty
                            ? 'v${form.version}'
                            : '${form.description.trim()} • v${form.version}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: ui(context, 'Edit form'),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editForm(form),
                          ),
                          IconButton(
                            tooltip: ui(context, 'Delete form'),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteForm(form),
                          ),
                        ],
                      ),
                      onTap: () => _openForm(form),
                    ),
                    const Divider(height: 1),
                  ],
                const SizedBox(height: 4),
                ResponsiveGrid(
                  minChildWidth: 180,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addForm,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(ui(context, 'Add form')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _importXlsForm,
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: Text(ui(context, 'Import XLSForm')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  ui(context, 'Cloud Sync'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ui(context,
                      'Connect this project to a Google Apps Script Web App for background sync.'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (project.externalId != null)
                  SelectableText('Project ID: ${project.externalId}',
                      style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: _syncUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: ui(context, 'Apps Script Web App URL'),
                    hintText: 'https://script.google.com/macros/s/.../exec',
                    prefixIcon: Icon(Icons.cloud_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _syncApiKeyController,
                  obscureText: _obscureApiKey,
                  obscuringCharacter: '•',
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: ui(context, 'API key'),
                    hintText: ui(context, 'Shared secret token'),
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscureApiKey = !_obscureApiKey,
                      ),
                    ),
                  ),
                ),
                if (_syncConfig?.lastSyncAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    ui(context, 'Last synced: {v0}', [_syncConfig!.lastSyncAt]),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 12),
                ResponsiveGrid(
                  minChildWidth: 180,
                  children: [
                    FilledButton.icon(
                      onPressed: _savingSync ? null : _saveSyncConfig,
                      icon: _savingSync
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_savingSync
                          ? ui(context, 'Saving...')
                          : ui(context, 'Save')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _testingSync ? null : _testSyncConnection,
                      icon: _testingSync
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering_outlined, size: 18),
                      label: Text(_testingSync
                          ? ui(context, 'Testing...')
                          : ui(context, 'Test Connection')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.archive_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(ui(context, 'Archive project')),
                  subtitle: Text(
                    ui(context, 'Hide from project setup; data is kept'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _toggleArchived,
                ),
              ],
            ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal.shade700, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
