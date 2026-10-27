import 'package:mapbanai/l10n/ui_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_collection_service.dart';
import 'package:mapbanai/ui/project_vector_layers_screen.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';

class StudyWorkflowSelection {
  final ProjectWorkspace workspace;
  final CollectionRound? round;
  const StudyWorkflowSelection(this.workspace, this.round);
}

/// Choose the field context before opening the map, keeping the map uncluttered.
class StudyWorkflowSetupScreen extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  final StudyWorkflow workflow;
  const StudyWorkflowSetupScreen(
      {super.key,
      required this.database,
      required this.projectId,
      required this.workflow});
  @override
  State<StudyWorkflowSetupScreen> createState() =>
      _StudyWorkflowSetupScreenState();
}

class _StudyWorkflowSetupScreenState extends State<StudyWorkflowSetupScreen> {
  ProjectWorkspace? _workspace;
  List<CollectionRound> _rounds = [];
  String? _roundId;
  String? _error;
  late final _service = ProjectWorkspaceService(widget.database);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final workspace =
          await _service.load(widget.projectId, workflow: widget.workflow);
      final rounds = await _service.rounds(widget.projectId, workspace.layerId);
      final config = await _service.config(widget.projectId);
      final saved =
          (config['workflows'] as Map?)?[widget.workflow.name] as Map?;
      if (mounted)
        setState(() {
          _workspace = workspace;
          _rounds = rounds;
          _error = null;
          if (!rounds.any((round) => round.id == _roundId))
            _roundId = rounds
                    .where((round) => round.id == saved?['round_id'])
                    .firstOrNull
                    ?.id ??
                rounds.lastOrNull?.id;
        });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _select({String? layerId, int? formId}) async {
    try {
      await _service.select(widget.projectId,
          layerId: layerId, formId: formId, workflow: widget.workflow);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _newRound() async {
    final name = TextEditingController(
        text: ui(context, 'Round {v0}', [_rounds.length + 1]));
    final period = TextEditingController();
    final date = TextEditingController(
        text: DateTime.now().toIso8601String().substring(0, 10));
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                scrollable: true,
                title: Text(ui(context, 'New collection round')),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration: InputDecoration(
                          labelText: ui(context, 'Collection round'))),
                  TextField(
                      controller: period,
                      decoration: InputDecoration(
                          labelText:
                              ui(context, 'Period / season (optional)'))),
                  TextField(
                      controller: date,
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: ui(context, 'Date'),
                          suffixIcon: Icon(Icons.calendar_month)),
                      onTap: () async {
                        final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100));
                        if (picked != null)
                          date.text = picked.toIso8601String().substring(0, 10);
                      }),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(ui(context, 'Cancel'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(ui(context, 'Create')))
                ]));
    if (accepted == true) {
      try {
        final round = await _service.addRound(
            widget.projectId, _workspace!.layerId, name.text,
            period: period.text, date: date.text);
        _roundId = round.id;
        await _load();
      } catch (error) {
        if (mounted) setState(() => _error = '$error');
      }
    }
    name.dispose();
    period.dispose();
    date.dispose();
  }

  Future<void> _open() async {
    try {
      final round = _rounds.where((item) => item.id == _roundId).firstOrNull;
      if (widget.workflow == StudyWorkflow.recurring && round == null)
        throw StateError('Create or select a collection round first.');
      await _service.select(widget.projectId,
          layerId: _workspace!.layerId,
          formId: _workspace!.form?.id,
          workflow: widget.workflow);
      await _service.selectRound(widget.projectId, widget.workflow, round?.id);
      if (mounted)
        Navigator.pop(context, StudyWorkflowSelection(_workspace!, round));
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = _workspace;
    return Scaffold(
        appBar: AppBar(title: Text(ui(context, widget.workflow.title))),
        body: workspace == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(ui(context, _error!)))
            : ListView(padding: const EdgeInsets.all(20), children: [
                Text(workspace.project.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(ui(context, widget.workflow.description)),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                    value: workspace.layerId,
                    isExpanded: true,
                    itemHeight: null,
                    decoration: InputDecoration(
                        labelText: ui(context, 'Site layer'),
                        border: OutlineInputBorder()),
                    items: workspace.layers
                        .map((layer) => DropdownMenuItem(
                            value: layer.id,
                            child: Text(layer.id == 'default'
                                ? ui(context, 'Main study area')
                                : layer.name)))
                        .toList(),
                    onChanged: (id) => _select(layerId: id)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                    value: workspace.form?.id,
                    isExpanded: true,
                    itemHeight: null,
                    decoration: InputDecoration(
                        labelText: ui(context, 'Questionnaire'),
                        border: OutlineInputBorder()),
                    hint: Text(ui(context, 'Add a project questionnaire')),
                    items: workspace.forms
                        .map((form) => DropdownMenuItem(
                            value: form.id, child: Text(form.name)))
                        .toList(),
                    onChanged: (id) => _select(formId: id)),
                if (widget.workflow == StudyWorkflow.recurring) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _roundId,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: InputDecoration(
                          labelText: ui(context, 'Collection round'),
                          border: OutlineInputBorder()),
                      hint: Text(ui(context, 'Create your first round')),
                      items: _rounds
                          .map((round) => DropdownMenuItem(
                              value: round.id,
                              child: Text([round.name, round.period, round.date]
                                  .where((part) => part.isNotEmpty)
                                  .join(' · '))))
                          .toList(),
                      onChanged: (id) => setState(() => _roundId = id)),
                  TextButton.icon(
                      onPressed: _newRound,
                      icon: const Icon(Icons.add),
                      label: Text(ui(context, 'New collection round'))),
                  TextButton.icon(
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(ui(context, 'Create layer from responses')),
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MeasurementLayerScreen(
                                    database: widget.database,
                                    projectId: widget.projectId)));
                        await _load();
                      }),
                ],
                Wrap(spacing: 12, runSpacing: 8, children: [
                  TextButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(ui(context, 'Project layers')),
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProjectVectorLayersScreen(
                                    database: widget.database,
                                    projectId: widget.projectId,
                                    workflow: widget.workflow)));
                        await _load();
                      }),
                  TextButton.icon(
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(ui(context, 'Project settings')),
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProjectDetailScreen(
                                    database: widget.database,
                                    projectId: widget.projectId)));
                        await _load();
                      }),
                ]),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 20),
                FilledButton.icon(
                    onPressed: _open,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(ui(context, 'Open map'))),
              ]));
  }
}

class MeasurementLayerScreen extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  const MeasurementLayerScreen(
      {super.key, required this.database, required this.projectId});
  @override
  State<MeasurementLayerScreen> createState() => _MeasurementLayerScreenState();
}

class _MeasurementLayerScreenState extends State<MeasurementLayerScreen> {
  List<StoredForm> _forms = [];
  StoredForm? _form;
  String? _field;
  final _name = TextEditingController();
  bool _nameInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInitialized) {
      _nameInitialized = true;
      _name.text = ui(context, 'Measurement sites');
    }
  }

  bool _busy = true;
  String? _error;
  int? _count;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final workspace =
          await ProjectWorkspaceService(widget.database).load(widget.projectId);
      if (mounted)
        setState(() {
          _forms = workspace.forms;
          _form = _forms.firstOrNull;
          _busy = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = '$error';
        });
    }
  }

  Future<void> _review({bool create = false}) async {
    if (_form == null || _field == null) {
      setState(() => _error = 'Select a questionnaire and measurement.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = StudyCollectionService(widget.database);
      final schema = SurveyForm.fromJson(jsonDecode(_form!.json));
      final features = await service.measurementFeatures(
          widget.projectId, schema.id, _field!);
      if (!mounted) return;
      setState(() => _count = features.length);
      if (create) {
        await service.createMeasurementLayer(
            widget.projectId, _name.text, schema.id, _field!);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _form == null
        ? <Question>[]
        : SurveyForm.fromJson(jsonDecode(_form!.json))
            .questions
            .where((q) => [
                  QuestionType.decimal,
                  QuestionType.integer,
                  QuestionType.calculated
                ].contains(q.type))
            .toList();
    return Scaffold(
        appBar: AppBar(title: Text(ui(context, 'Create measurement layer'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(ui(context,
              'Select the questionnaire and measurement to separate, such as salinity. Only saved responses with that measurement and a point location become sites. Original responses stay intact.')),
          const SizedBox(height: 16),
          TextField(
              controller: _name,
              decoration:
                  InputDecoration(labelText: ui(context, 'Layer name'))),
          DropdownButtonFormField<int>(
              value: _form?.id,
              isExpanded: true,
              itemHeight: null,
              decoration:
                  InputDecoration(labelText: ui(context, 'Questionnaire')),
              items: _forms
                  .map((form) =>
                      DropdownMenuItem(value: form.id, child: Text(form.name)))
                  .toList(),
              onChanged: _busy
                  ? null
                  : (id) => setState(() {
                        _form = _forms.firstWhere((form) => form.id == id);
                        _field = null;
                        _count = null;
                      })),
          DropdownButtonFormField<String>(
              value: _field,
              isExpanded: true,
              itemHeight: null,
              decoration:
                  InputDecoration(labelText: ui(context, 'Measurement')),
              items: questions
                  .map((q) => DropdownMenuItem(
                      value: q.name,
                      child: Text(q.labelFor(
                          Localizations.localeOf(context).languageCode))))
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        _field = value;
                        _count = null;
                      })),
          const SizedBox(height: 20),
          if (_busy) const LinearProgressIndicator(),
          if (_count != null)
            Text(ui(context, '{v0} matching site(s)', [_count])),
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          OutlinedButton.icon(
              onPressed: _busy ? null : () => _review(),
              icon: const Icon(Icons.preview_outlined),
              label: Text(ui(context, 'Preview matching sites'))),
          FilledButton.icon(
              onPressed: _busy ? null : () => _review(create: true),
              icon: const Icon(Icons.add_location_alt),
              label: Text(ui(context, 'Create recurring layer'))),
        ]));
  }
}
