import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_template_service.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';

class ProjectTemplatesScreen extends StatefulWidget {
  final AppDatabase database;
  final int? projectId;
  const ProjectTemplatesScreen(
      {super.key, required this.database, this.projectId});
  @override
  State<ProjectTemplatesScreen> createState() => _ProjectTemplatesScreenState();
}

class _ProjectTemplatesScreenState extends State<ProjectTemplatesScreen> {
  List<Map<String, dynamic>> _templates = [];
  bool _busy = false;
  late final _service = ProjectTemplateService(widget.database);
  @override
  void initState() {
    super.initState();
    _run(_load);
  }

  Future<void> _load() async {
    final items = await _service.list();
    if (mounted) setState(() => _templates = items);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _name(String title) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(title),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Name')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: const Text('Save'))
                ]));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Reusable templates')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
            'Reuse questionnaires and named layers for a new campaign. Templates contain setup only; each new project gets a fresh identity and needs its own cloud connection. Existing visits and photos stay in the original project.'),
        if (widget.projectId != null) ...[
          FilledButton.icon(
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save this project as template'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final name = await _name('Project template name');
                        if (name == null) return;
                        await _service.save(widget.projectId!, name);
                        await _load();
                      })),
          OutlinedButton.icon(
              icon: const Icon(Icons.layers_outlined),
              label: const Text('Save selected layer and questionnaire'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final name = await _name('Layer template name');
                        if (name == null) return;
                        await _service.save(widget.projectId!, name,
                            layerOnly: true);
                        await _load();
                      })),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_templates.isEmpty)
          const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  'No saved templates. Open a configured project → Reusable templates to save one.')),
        for (final template in _templates)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${template['name']}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                            '${template['kind']} • ${(template['forms'] as List).length} questionnaires'),
                        Wrap(spacing: 8, children: [
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        final name =
                                            await _name('New project name');
                                        if (name == null) return;
                                        final id = await _service.createProject(
                                            template, name);
                                        if (mounted)
                                          await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      ProjectDetailScreen(
                                                          projectId: id,
                                                          database: widget
                                                              .database)));
                                      }),
                              child: const Text('Create project')),
                          if (widget.projectId != null)
                            TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _run(() async {
                                          await _service.applyLayers(
                                              template, widget.projectId!);
                                          if (mounted)
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Layers and questionnaires added')));
                                        }),
                                child:
                                    const Text('Add layers to this project')),
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        await _service
                                            .remove('${template['id']}');
                                        await _load();
                                      }),
                              child: const Text('Remove template')),
                        ])
                      ]))),
      ]));
}
