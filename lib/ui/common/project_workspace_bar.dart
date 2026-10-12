import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_workspace_service.dart';

class ProjectWorkspaceBar extends StatelessWidget {
  final AppDatabase database;
  final ProjectWorkspace? workspace;
  final Future<void> Function(ProjectWorkspace) onChanged;
  final bool enabled;
  const ProjectWorkspaceBar(
      {super.key,
      required this.database,
      required this.workspace,
      required this.onChanged,
      this.enabled = true});
  Future<void> _choose(BuildContext context) async {
    final projects = await database.getProjects();
    if (!context.mounted) return;
    final id = await showDialog<int>(
        context: context,
        builder: (context) =>
            SimpleDialog(title: const Text('Select project'), children: [
              if (projects.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Create a project from Home first.')),
              for (final project in projects)
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, project.id),
                    child: Text(project.name)),
            ]));
    if (id != null)
      await onChanged(await ProjectWorkspaceService(database).load(id));
  }

  Future<void> _addLayer(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('New study layer'),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Salinity — October')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: const Text('Create'))
                ]));
    if (name != null && name.isNotEmpty)
      await onChanged(await ProjectWorkspaceService(database)
          .addLayer(workspace!.project.id, name));
  }

  @override
  Widget build(BuildContext context) => Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: TextButton.icon(
                      onPressed: enabled ? () => _choose(context) : null,
                      icon: const Icon(Icons.folder_outlined),
                      label:
                          Text(workspace?.project.name ?? 'Select project'))),
              if (workspace != null)
                IconButton(
                    tooltip: 'Add study layer',
                    onPressed: enabled ? () => _addLayer(context) : null,
                    icon: const Icon(Icons.add))
            ]),
            if (workspace != null)
              Row(children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                        value: workspace!.layerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Study layer', isDense: true),
                        items: workspace!.layers
                            .map((layer) => DropdownMenuItem(
                                value: layer.id,
                                child: Text(layer.name,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: !enabled
                            ? null
                            : (id) async {
                                if (id != null)
                                  await onChanged(
                                      await ProjectWorkspaceService(database)
                                          .select(workspace!.project.id,
                                              layerId: id));
                              })),
                const SizedBox(width: 10),
                Expanded(
                    child: DropdownButtonFormField<int>(
                        value: workspace!.form?.id,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Survey form', isDense: true),
                        hint: const Text('Import a form'),
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
                                              formId: id));
                              })),
              ]),
          ])));
}
