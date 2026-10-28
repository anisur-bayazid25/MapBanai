import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/response_layer_screen.dart';
import 'package:mapbanai/ui/common/project_workspace_bar.dart';
import 'package:mapbanai/ui/questionnaire_sync_screen.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/import_flow_dialogs.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';
import 'package:mapbanai/ui/survey_form_builder_screen.dart';
import 'package:mapbanai/ui/survey_form_detail_screen.dart';
import 'package:provider/provider.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({required this.projectName, this.projectId, super.key});

  final String projectName;
  final int? projectId;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final AppDatabase _database = AppDatabase();
  late String _projectName = widget.projectName;
  late int? _projectId = widget.projectId;
  List<StoredForm> _storedForms = [];
  ProjectWorkspace? _workspace;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStoredForms();
  }

  Future<Project?> _resolveProject() => _projectId != null
      ? _database.getProjectById(_projectId!)
      : _database.getProjectByName(_projectName);

  Future<void> _loadStoredForms() async {
    final project = await _resolveProject();
    final projectId = project?.id;
    final workspace = projectId == null
        ? null
        : await ProjectWorkspaceService(_database).load(projectId);
    final rows = workspace?.forms ?? <StoredForm>[];
    if (!mounted) return;
    setState(() {
      _projectId = projectId;
      _storedForms = rows;
      _workspace = workspace;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _openFormBuilder() async {
    if (_projectId == null) {
      _showSnack(ui(context, 'Select a project before building a form'));
      return;
    }
    final projectId = _projectId;
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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(ui(context, 'Form "{v0}" saved', [form.name]))),
              );
            }
            await _loadStoredForms();
          },
        ),
      ),
    );
  }

  // ── project menu (rename / delete / share) ──────────────────

  Future<void> _renameProject() async {
    final current = _projectName;
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ui(context, 'Rename project')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: ui(context, 'Project name'),
            hintText: ui(context, 'e.g. Riverbank survey'),
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
    final clean = name?.trim();
    if (clean == null || clean.isEmpty || clean == current) return;
    if (await _database.projectExists(clean)) {
      _showSnack(ui(context, 'A project named "{v0}" already exists', [clean]));
      return;
    }
    final project = await _resolveProject();
    if (project == null || !mounted) return;
    await _database.updateProject(project.id, name: clean);
    if (!mounted) return;
    context
        .read<ProjectState>()
        .setSelectedProject(clean, projectId: project.id);
    setState(() => _projectName = clean);
    _showSnack(ui(context, 'Project renamed to "{v0}"', [clean]));
  }

  Future<void> _openProjectSettings() async {
    final project = await _resolveProject();
    if (project == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: project.id),
      ),
    );
  }

  Future<void> _deleteProject() async {
    final project = await _resolveProject();
    if (project == null || !mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: ui(context, 'Delete project'),
      message: ui(
          context,
          'Delete "{v0}" and all its survey responses and GIS features? This cannot be undone.',
          [project.name]),
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteProject(project.id);
    if (!mounted) return;
    final state = context.read<ProjectState>();
    if (state.selectedProjectId != null
        ? state.selectedProjectId == project.id
        : _projectName == state.selectedProject) {
      context.read<ProjectState>().clearSelectedProject();
    }
    Navigator.of(context).pop();
    _showSnack(ui(context, 'Project "{v0}" deleted', [project.name]));
  }

  Future<void> _shareProject() async {
    final project = await _resolveProject();
    if (project == null || !mounted) return;
    final flow = ProjectSharingFlow(database: _database);
    await showExportProjectOptions(context, flow: flow, project: project);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ui(context, 'Survey Mode')),
        actions: [
          IconButton(
            tooltip: ui(context, 'Build or import a survey form'),
            icon: const Icon(Icons.library_add_outlined),
            onPressed: _openFormBuilder,
          ),
          PopupMenuButton<String>(
            tooltip: ui(context, 'Project options'),
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _renameProject();
                case 'delete':
                  _deleteProject();
                case 'share':
                  _shareProject();
                case 'settings':
                  _openProjectSettings();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(ui(context, 'Project settings')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_rename_outline, size: 18),
                    SizedBox(width: 8),
                    Text(ui(context, 'Rename project')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.ios_share_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(ui(context, 'Share project')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text(ui(context, 'Delete project'),
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              ui(context, 'Select a survey form'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              ui(context, 'Project: {v0}', [_projectName]),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                label: Text(ui(context, 'Sync questionnaire')),
                icon: const Icon(Icons.cloud_download_outlined),
                onPressed: _projectId == null
                    ? null
                    : () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => QuestionnaireSyncScreen(
                                database: _database, projectId: _projectId!)));
                        await _loadStoredForms();
                      }),
            ProjectWorkspaceBar(
                database: _database,
                workspace: _workspace,
                onChanged: (workspace) async {
                  context.read<ProjectState>().setSelectedProject(
                      workspace.project.name,
                      projectId: workspace.project.id);
                  setState(() {
                    _workspace = workspace;
                    _projectId = workspace.project.id;
                    _projectName = workspace.project.name;
                    _storedForms = workspace.forms;
                  });
                }),
            OutlinedButton.icon(
                icon: const Icon(Icons.layers_outlined),
                label: Text(ui(context, 'Create layer from responses')),
                onPressed: _projectId == null
                    ? null
                    : () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ResponseLayerScreen(
                                    database: _database,
                                    projectId: _projectId!)));
                        await _loadStoredForms();
                      }),
            const SizedBox(height: 16),
            if (_loading)
              const AppLoadingIndicator()
            else if (_storedForms.isEmpty)
              _buildEmptyForms(context)
            else
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Text(
                    ui(context, 'My forms'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  for (final row in _storedForms) ...[
                    _StoredFormCard(
                      row: row,
                      onTap: () => _openStoredFormDetail(row),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyForms(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        color: Colors.indigo.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.indigo.shade200),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openFormBuilder,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 56,
                  color: Colors.indigo.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  ui(context, 'Start building survey form'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ui(context,
                      'No forms yet for this project. Tap to build or import your first survey form.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStoredFormDetail(StoredForm row) async {
    if (row.projectId != null)
      await ProjectWorkspaceService(_database)
          .select(row.projectId!, formId: row.id);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyFormDetailScreen(
          row: row,
          projectName: _projectName,
        ),
      ),
    );
    await _loadStoredForms();
  }
}

class _StoredFormCard extends StatelessWidget {
  final StoredForm row;
  final VoidCallback onTap;

  const _StoredFormCard({
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final form =
        SurveyForm.fromJson(jsonDecode(row.json) as Map<String, dynamic>);
    return Card(
      elevation: 2,
      color: Colors.indigo.shade50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo.shade900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      form.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.checklist_rtl_outlined,
                          size: 16,
                          color: Colors.indigo.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ui(context, '{v0} questions',
                              [form.questions.length]),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.indigo.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.indigo),
            ],
          ),
        ),
      ),
    );
  }
}
