import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/xlsform_parser.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/import_flow_dialogs.dart';
import 'package:mapbanai/ui/project_qr_screen.dart';
import 'package:mapbanai/ui/survey_form_builder_screen.dart';
import 'package:mapbanai/ui/survey_form_detail_screen.dart';
import 'package:mapbanai/ui/survey_history_screen.dart';
import 'package:provider/provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({required this.projectId, super.key, this.database});

  final int projectId;
  final AppDatabase? database;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final AppDatabase _database = widget.database ?? AppDatabase();
  Project? _project;
  int _sessionCount = 0;
  List<ProjectField> _fields = [];
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
    final count = project == null
        ? 0
        : await _database.surveySessionCountForProject(project.id);
    final fields = project == null
        ? <ProjectField>[]
        : await _database.getProjectFields(project.id);
    final forms = project == null
        ? <StoredForm>[]
        : await _database.getStoredFormsForProject(project.id);
    final syncConfig = project == null
        ? null
        : await _database.getSyncConfig(project.id);
    if (!mounted) return;
    setState(() {
      _project = project;
      _sessionCount = count;
      _fields = fields;
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
      title: 'Project name',
      initial: current,
      hint: 'e.g. Riverbank survey',
    );
    if (name == null || name.trim().isEmpty || name.trim() == current) return;
    if (await _database.projectExists(name.trim())) {
      _showSnack('A project named "${name.trim()}" already exists');
      return;
    }
    await _database.updateProject(widget.projectId, name: name.trim());
    if (!mounted) return;
    context.read<ProjectState>().setSelectedProject(name.trim());
    await _load();
  }

  Future<void> _editDescription() async {
    final current = _project?.description ?? '';
    final description = await _showEditDialog(
      title: 'Project description',
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _setThreshold(double threshold) async {
    await _database.updateProject(widget.projectId, gpsThresholdM: threshold);
    await _load();
    _showSnack('GPS accuracy threshold set to ${threshold.round()} m');
  }

  Future<void> _toggleArchived() async {
    final project = _project;
    if (project == null) return;
    final action = project.archived ? 'Restore' : 'Archive';
    final confirmed = await showConfirmDialog(
      context,
      title: action,
      message: project.archived
          ? 'Restore "${project.name}"? It will appear in project setup again.'
          : 'Archive "${project.name}"? It will be hidden from project setup. '
              'Its data is kept and can be restored later.',
      confirmText: action,
      cancelText: 'Cancel',
    );
    if (!confirmed) return;
    final wasArchived = _project!.archived;
    await _database.archiveProject(widget.projectId, archived: !wasArchived);
    if (wasArchived) {
      if (!mounted) return;
      context.read<ProjectState>().setSelectedProject(_project!.name);
    }
    await _load();
    _showSnack(wasArchived ? 'Project restored' : 'Project archived');
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
        syncEndpointUrl: url.isEmpty ? null : url,
        syncApiKey: key.isEmpty ? null : key,
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
    final rawUrl = _syncUrlController.text.trim();
    if (rawUrl.isEmpty) {
      _showSyncSnack('Please enter a sync URL first', success: false);
      return;
    }
    Uri uri;
    try {
      uri = Uri.parse(rawUrl);
      if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        throw const FormatException('URL must start with http:// or https://');
      }
      if (uri.host.isEmpty) {
        throw const FormatException('Invalid URL');
      }
    } catch (e) {
      _showSyncSnack('Invalid URL: $e', success: false);
      return;
    }

    setState(() => _testingSync = true);
    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _showSyncSnack(
          'Connection failed: HTTP ${response.statusCode}',
          success: false,
        );
        return;
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        _showSyncSnack(
          'Connection failed: response is not valid JSON',
          success: false,
        );
        return;
      }
      if (decoded is Map<String, dynamic> && decoded['ok'] == true) {
        _showSyncSnack('Connection successful', success: true);
      } else {
        _showSyncSnack(
          'Connection failed: missing {ok: true} in response',
          success: false,
        );
      }
    } catch (e) {
      _showSyncSnack('Connection failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _testingSync = false);
    }
  }

  // ── data collection fields ──────────────────────────────────

  Future<void> _addField() async {
    final name = await _showEditDialog(
      title: 'Field name',
      initial: '',
      hint: 'e.g., Material, Condition, Owner',
    );
    if (name == null || name.trim().isEmpty) return;
    await _database.insertProjectField(widget.projectId, name.trim());
    await _load();
    _showSnack('Field "${name.trim()}" added');
  }

  Future<void> _renameField(ProjectField field) async {
    final name = await _showEditDialog(
      title: 'Field name',
      initial: field.name,
      hint: 'Field label shown in GIS data capture',
    );
    if (name == null || name.trim().isEmpty || name.trim() == field.name) return;
    await _database.renameProjectField(field.id, name.trim());
    await _load();
    _showSnack('Field renamed');
  }

  Future<void> _deleteField(ProjectField field) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete field',
      message: 'Delete "${field.name}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteProjectField(field.id);
    await _load();
    _showSnack('Field deleted');
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
      title: 'Delete form',
      message: 'Delete "${form.name}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteStoredForm(form.id);
    await _load();
    _showSnack('Form deleted');
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
      _showSnack('Could not read the selected file');
      return;
    }

    try {
      final form = XlsFormParser.parse(bytes, fileName: file.name);
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
        _showSnack('Updated "${form.name}" from XLSForm');
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
          'Imported "${form.name}" with ${form.questions.length} questions',
        );
      }
    } on XlsFormParseException catch (e) {
      _showSnack('Import failed: ${e.message}');
    } catch (e) {
      _showSnack('Import failed: $e');
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Project'),
        actions: [
          if (project != null) ...[
            PopupMenuButton<String>(
              key: const ValueKey('project-share-menu'),
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Share',
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _showExportOptions();
                  case 'qr':
                    _showQr();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.save_alt_rounded),
                    title: Text('Export / Share project'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'qr',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.qr_code_2_rounded),
                    title: Text('QR code'),
                  ),
                ),
              ],
            ),
          ],
          if (project != null && project.archived)
            TextButton.icon(
              onPressed: _toggleArchived,
              icon: const Icon(Icons.restore_outlined, size: 18),
              label: const Text('Restore'),
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
                    child: const Row(
                      children: [
                        Icon(Icons.archive_outlined, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Archived project', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _infoTile(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: project.description.isEmpty
                      ? 'No description'
                      : project.description,
                  onTap: _editDescription,
                ),
                const SizedBox(height: 12),
                _infoTile(
                  icon: Icons.inbox_outlined,
                  label: 'Survey responses',
                  value: '$_sessionCount collected',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SurveyHistoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'GPS settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Default max acceptable accuracy used when recording points '
                  'in this project.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 5, label: Text('5m')),
                    ButtonSegment(value: 10, label: Text('10m')),
                    ButtonSegment(value: 20, label: Text('20m')),
                    ButtonSegment(value: 50, label: Text('50m')),
                  ],
                  selected: {project.gpsThresholdM},
                  onSelectionChanged: (selection) => _setThreshold(selection.first),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: const Text('Edit project name'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editName,
                ),
                const SizedBox(height: 8),
                Text(
                  'Data collection fields',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Custom fields shown when recording a GIS feature in this '
                  'project (points, lines, polygons).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                if (_fields.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'No custom fields yet. Add one to collect extra '
                      'attributes with each GIS feature.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                else
                  for (final field in _fields) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.label_outline, size: 20),
                      title: Text(field.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Rename field',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _renameField(field),
                          ),
                          IconButton(
                            tooltip: 'Delete field',
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteField(field),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _addField,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add field'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Survey forms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Questionnaires used for data collection in this project. '
                  'You can create a form, edit it, or import an XLSForm '
                  '(.xlsx) file.',
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
                    child: const Text(
                      'No forms yet. Add one or import an XLSForm file.',
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
                            tooltip: 'Edit form',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editForm(form),
                          ),
                          IconButton(
                            tooltip: 'Delete form',
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addForm,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add form'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importXlsForm,
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Import XLSForm'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Cloud Sync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect this project to a Google Apps Script Web App for '
                  'background sync.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _syncUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Apps Script Web App URL',
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
                    labelText: 'API key',
                    hintText: 'Shared secret token',
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
                    'Last synced: ${_syncConfig!.lastSyncAt}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
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
                        label: Text(_savingSync ? 'Saving...' : 'Save'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingSync ? null : _testSyncConnection,
                        icon: _testingSync
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering_outlined, size: 18),
                        label:
                            Text(_testingSync ? 'Testing...' : 'Test Connection'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.archive_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text('Archive project'),
                  subtitle: Text(
                    'Hide from project setup; data is kept',
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