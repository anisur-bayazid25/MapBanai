import 'package:mapbanai/l10n/ui_text.dart';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/project_setup_screen.dart';
import 'package:mapbanai/ui/study_area_mode_screen.dart';
import 'package:mapbanai/ui/study_workflow_setup_screen.dart';
import 'package:provider/provider.dart';

class StudyAreaHubScreen extends StatefulWidget {
  final AppDatabase? database;
  final int? projectId;
  const StudyAreaHubScreen({super.key, this.database, this.projectId});
  @override
  State<StudyAreaHubScreen> createState() => _StudyAreaHubScreenState();
}

class _StudyAreaHubScreenState extends State<StudyAreaHubScreen> {
  late final _db = widget.database ?? AppDatabase();
  List<Project>? _projects;
  int? _projectId;
  String? _error;
  @override
  void initState() {
    super.initState();
    _projectId = widget.projectId;
    _load();
  }

  @override
  void dispose() {
    if (widget.database == null) _db.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final projects = await _db.getProjects();
      if (mounted)
        setState(() {
          _projects = projects;
          if (!projects.any((project) => project.id == _projectId))
            _projectId = projects.firstOrNull?.id;
        });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _open(StudyWorkflow workflow) async {
    final selection = await Navigator.push<StudyWorkflowSelection>(
        context,
        MaterialPageRoute(
            builder: (_) => StudyWorkflowSetupScreen(
                database: _db, projectId: _projectId!, workflow: workflow)));
    if (selection == null || !mounted) return;
    try {
      context.read<ProjectState>().setSelectedProject(
          selection.workspace.project.name,
          projectId: selection.workspace.project.id);
    } catch (_) {}
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StudyAreaModeScreen(
                database: _db,
                projectId: selection.workspace.project.id,
                workflow: workflow,
                collectionRound: selection.round,
                compactControls: true)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(ui(context, 'Study Area'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (_projects == null && _error == null)
          const LinearProgressIndicator(),
        if (_error != null) Text(ui(context, _error!)),
        if (_projects != null && _projects!.isNotEmpty) ...[
          DropdownButtonFormField<int>(
              value: _projectId,
              isExpanded: true,
              itemHeight: null,
              decoration: InputDecoration(
                  labelText: ui(context, 'Project'),
                  border: OutlineInputBorder()),
              items: _projects!
                  .map((project) => DropdownMenuItem(
                      value: project.id, child: Text(project.name)))
                  .toList(),
              onChanged: (id) => setState(() => _projectId = id)),
          const SizedBox(height: 20),
          Text(ui(context, 'Choose a workflow'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final workflow in StudyWorkflow.values)
            Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withOpacity(.5))),
                child: InkWell(
                    onTap: () => _open(workflow),
                    child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Icon(
                                      switch (workflow) {
                                        StudyWorkflow.verification =>
                                          Icons.fact_check_outlined,
                                        StudyWorkflow.recurring =>
                                          Icons.repeat_rounded,
                                        StudyWorkflow.visits =>
                                          Icons.location_on_outlined,
                                      },
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer)),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(ui(context, workflow.title),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 5),
                                    Text(ui(context, workflow.description),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant)),
                                  ])),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ])))),
        ],
        if (_projects?.isEmpty == true)
          Text(ui(context, 'Create or import a project to start.')),
        TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProjectSetupScreen(database: _db)));
              await _load();
            },
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(ui(context, 'Project settings'))),
      ]));
}
