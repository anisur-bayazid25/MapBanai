import 'package:mapbanai/ui/common/labeled_field.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/models/study_workflow.dart';

class ProjectWorkspaceBar extends StatelessWidget {
  final AppDatabase database;
  final ProjectWorkspace? workspace;
  final Future<void> Function(ProjectWorkspace) onChanged;
  final bool enabled;
  final VoidCallback? onAddPoint;
  final StudyWorkflow? workflow;
  const ProjectWorkspaceBar(
      {super.key,
      required this.database,
      required this.workspace,
      required this.onChanged,
      this.enabled = true,
      this.workflow,
      this.onAddPoint});
  Future<void> _choose(BuildContext context) async {
    final projects = await database.getProjects();
    if (!context.mounted) return;
    final id = await showDialog<int>(
        context: context,
        builder: (context) =>
            SimpleDialog(title: Text(ui(context, 'Select project')), children: [
              if (projects.isEmpty)
                Padding(
                    padding: EdgeInsets.all(16),
                    child:
                        Text(ui(context, 'Create a project from Home first.'))),
              for (final project in projects)
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, project.id),
                    child: Text(project.name)),
            ]));
    if (id != null)
      await onChanged(
          await ProjectWorkspaceService(database).load(id, workflow: workflow));
  }

  Future<void> _addLayer(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(ui(context, 'New study layer')),
                content: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                        labelText: ui(context, 'Name'),
                        hintText: ui(context, 'e.g. Salinity — October'))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(ui(context, 'Cancel'))),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: Text(ui(context, 'Create')))
                ]));
    if (name != null && name.isNotEmpty)
      await onChanged(await ProjectWorkspaceService(database)
          .addLayer(workspace!.project.id, name, workflow: workflow));
  }

  @override
  Widget build(BuildContext context) => Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                          onPressed: enabled ? () => _choose(context) : null,
                          icon: const Icon(Icons.folder_outlined),
                          label: Text(workspace?.project.name ??
                              ui(context, 'Select project'))))),
              if (workspace != null && onAddPoint != null)
                IconButton(
                    tooltip: ui(context, 'Record survey at GPS'),
                    onPressed: enabled ? onAddPoint : null,
                    icon: const Icon(Icons.add))
            ]),
            if (workspace != null)
              ResponsiveGrid(children: [
                LabeledField(
                    label: ui(context, 'Study layer'),
                    child: DropdownButtonFormField<String>(
                        itemHeight: null,
                        value: workspace!.layerId,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items: [
                          ...workspace!.layers
                              .map((layer) => DropdownMenuItem(
                                  value: layer.id,
                                  child: Text(
                                      layer.id == 'default'
                                          ? ui(context, 'Main study area')
                                          : layer.name,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          DropdownMenuItem(
                              value: '__add_layer__',
                              child: Text(ui(context, 'Add new Layer'))),
                        ],
                        onChanged: !enabled
                            ? null
                            : (id) async {
                                if (id == '__add_layer__') {
                                  await _addLayer(context);
                                  return;
                                }
                                if (id != null)
                                  await onChanged(
                                      await ProjectWorkspaceService(database)
                                          .select(workspace!.project.id,
                                              layerId: id, workflow: workflow));
                              })),
                LabeledField(
                    label: ui(context, 'Survey form'),
                    child: DropdownButtonFormField<int>(
                        itemHeight: null,
                        value: workspace!.form?.id,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        hint: Text(ui(context, 'Import a form')),
                        items: workspace!.forms
                            .map((form) => DropdownMenuItem(
                                value: form.id,
                                child: Text(form.name,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: !enabled
                            ? null
                            : (id) async {
                                if (id != null)
                                  await onChanged(
                                      await ProjectWorkspaceService(database)
                                          .select(workspace!.project.id,
                                              formId: id, workflow: workflow));
                              })),
              ]),
          ])));
}
