import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/workflow_requirements_service.dart';

class WorkflowRequirementsScreen extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  const WorkflowRequirementsScreen(
      {super.key, required this.database, required this.projectId});
  @override
  State<WorkflowRequirementsScreen> createState() =>
      _WorkflowRequirementsScreenState();
}

class _WorkflowRequirementsScreenState
    extends State<WorkflowRequirementsScreen> {
  Map<StudyWorkflow, WorkflowRequirements>? _values;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await WorkflowRequirementsService(widget.database)
          .load(widget.projectId);
      if (mounted) setState(() => _values = values);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await WorkflowRequirementsService(widget.database)
          .save(widget.projectId, _values!);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(ui(context, 'Workflow requirements'))),
      body: _values == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Text(ui(context,
                  'Configure required steps before sharing this project with the field team. Share an updated project package after changing these settings.')),
              if (_error != null)
                Text(ui(context, _error!),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_values != null) ...[
                for (final mode in StudyWorkflow.values)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(children: [
                            ListTile(
                                title: Text(ui(context, mode.title),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600))),
                            SwitchListTile(
                                key: ValueKey('questionnaire-${mode.name}'),
                                title:
                                    Text(ui(context, 'Require questionnaire')),
                                value: _values![mode]!.questionnaire,
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() {
                                          _values![mode] = WorkflowRequirements(
                                              questionnaire: value,
                                              photo: _values![mode]!.photo);
                                        })),
                            SwitchListTile(
                                key: ValueKey('photo-${mode.name}'),
                                title: Text(
                                    ui(context, 'Require geotagged photo')),
                                value: _values![mode]!.photo,
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() {
                                          _values![mode] = WorkflowRequirements(
                                              questionnaire:
                                                  _values![mode]!.questionnaire,
                                              photo: value);
                                        })),
                          ]))),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(ui(context, 'Save requirements'))),
                if (_saving) const LinearProgressIndicator(),
              ]
            ]));
}
