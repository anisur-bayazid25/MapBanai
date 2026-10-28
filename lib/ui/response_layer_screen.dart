import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/response_layer_service.dart';
import 'package:mapbanai/models/survey_form.dart';

class ResponseLayerScreen extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  final String? initialLayerId;
  const ResponseLayerScreen(
      {super.key,
      required this.database,
      required this.projectId,
      this.initialLayerId});
  @override
  State<ResponseLayerScreen> createState() => _ResponseLayerScreenState();
}

class _ResponseLayerScreenState extends State<ResponseLayerScreen> {
  final _name = TextEditingController();
  ProjectWorkspace? _workspace;
  String? _layerId;
  String? _formId;
  String? _question;
  Set<String> _values = {};
  Set<String> _availableValues = {};
  Set<String> _gpsFields = {};
  int _filterRevision = 0;
  bool _boundary = false;
  bool _busy = true;
  int? _count;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final workspace =
          await ProjectWorkspaceService(widget.database).load(widget.projectId);
      if (mounted) setState(() => _workspace = workspace);
      if (widget.initialLayerId != null) {
        _layerId = widget.initialLayerId;
        _name.text =
            workspace.layers.where((l) => l.id == _layerId).firstOrNull?.name ??
                '';
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _review({bool create = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ResponseLayerService(widget.database);
      if (create) {
        await service.create(widget.projectId, _name.text,
            formId: _formId,
            layerId: _layerId,
            boundary: _boundary,
            question: _question,
            values: _values,
            gpsFields: _gpsFields);
        if (mounted) Navigator.pop(context, true);
      } else {
        final features = await service.features(widget.projectId,
            formId: _formId,
            layerId: _layerId,
            question: _question,
            values: _values,
            gpsFields: _gpsFields);
        if (mounted) setState(() => _count = features.length);
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  SurveyForm? get _schema => _workspace?.forms
      .map((row) => SurveyForm.fromJson(jsonDecode(row.json)))
      .where((form) => form.id == _formId)
      .lastOrNull;

  Future<void> _loadValues() async {
    final revision = ++_filterRevision;
    final selected =
        _schema?.questions.where((q) => q.name == _question).firstOrNull;
    if (selected == null) return;
    try {
      final observed = await ResponseLayerService(widget.database).answerValues(
          widget.projectId, _formId!, selected.name,
          multiple: selected.type == QuestionType.select_multiple,
          layerId: _layerId);
      if (mounted && revision == _filterRevision)
        setState(() {
          _availableValues = {
            ...?selected.choices?.map((c) => c.name),
            ...observed
          };
        });
    } catch (error) {
      if (mounted && revision == _filterRevision)
        setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = _workspace;
    final schema = _schema;
    final selectedQuestion =
        schema?.questions.where((q) => q.name == _question).firstOrNull;
    return Scaffold(
        appBar: AppBar(title: Text(ui(context, 'Create layer from responses'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(ui(context,
              'Copy saved survey or GIS records into a named project layer. Select a source layer and questionnaire to separate facilities, boundaries or measurement sites. This is a snapshot; original responses stay intact.')),
          const SizedBox(height: 16),
          TextField(
              controller: _name,
              decoration:
                  InputDecoration(labelText: ui(context, 'Layer name'))),
          if (workspace != null) ...[
            DropdownButtonFormField<String>(
                value: _layerId ?? '',
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: ui(context, 'Study layer')),
                items: [
                  DropdownMenuItem(
                      value: '', child: Text(ui(context, 'All layers'))),
                  for (final layer in workspace.layers)
                    DropdownMenuItem(value: layer.id, child: Text(layer.name)),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                          _layerId = value == '' ? null : value;
                          _count = null;
                          _loadValues();
                        })),
            DropdownButtonFormField<String>(
                value: _formId ?? '',
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: ui(context, 'Questionnaire')),
                items: [
                  DropdownMenuItem(
                      value: '',
                      child: Text(ui(context, 'All questionnaires'))),
                  for (final form in {
                    for (final row in workspace.forms)
                      (jsonDecode(row.json) as Map)['id']: row
                  }.values)
                    DropdownMenuItem(
                        value: (jsonDecode(form.json) as Map)['id'] as String,
                        child: Text(form.name)),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                          _formId = value == '' ? null : value;
                          _question = null;
                          _values = {};
                          _gpsFields = {};
                          _availableValues = {};
                          _filterRevision++;
                          _count = null;
                        })),
            if (schema != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  key: ValueKey('question:$_formId'),
                  value: _question ?? '',
                  isExpanded: true,
                  itemHeight: null,
                  decoration: InputDecoration(
                      labelText: ui(context, 'Filter question')),
                  items: [
                    DropdownMenuItem(
                        value: '', child: Text(ui(context, 'All answers'))),
                    for (final q in schema.questions.where((q) => ![
                          QuestionType.geopoint,
                          QuestionType.geotrace,
                          QuestionType.geoshape,
                          QuestionType.image,
                          QuestionType.note
                        ].contains(q.type)))
                      DropdownMenuItem(
                          value: q.name,
                          child: Text(q.labelFor(
                              Localizations.localeOf(context).languageCode))),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() {
                            _question = value == '' ? null : value;
                            _values = {};
                            _availableValues = {};
                            _count = null;
                          });
                          _loadValues();
                        }),
              if (_question != null) ...[
                Text(ui(context, 'Include any selected answer')),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final value in _availableValues.toList()..sort())
                    FilterChip(
                        label: Text(selectedQuestion?.choices
                                ?.where((c) => c.name == value)
                                .firstOrNull
                                ?.labelFor(Localizations.localeOf(context)
                                    .languageCode) ??
                            value),
                        selected: _values.contains(value),
                        onSelected: _busy
                            ? null
                            : (selected) => setState(() {
                                  if (selected) {
                                    _values.add(value);
                                  } else {
                                    _values.remove(value);
                                  }
                                  _count = null;
                                })),
                ]),
                if (_availableValues.isEmpty)
                  Text(ui(
                      context, 'No saved answer values for this selection.')),
              ],
              if (schema.questions
                  .any((q) => q.type == QuestionType.geopoint)) ...[
                const SizedBox(height: 12),
                Text(ui(context, 'GPS questions to map')),
                Text(ui(context,
                    'Choose one or more GPS questions, or keep the saved geometry. Each chosen GPS answer becomes a separate point.')),
                for (final q in schema.questions
                    .where((q) => q.type == QuestionType.geopoint))
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(q.labelFor(
                          Localizations.localeOf(context).languageCode)),
                      value: _gpsFields.contains(q.name),
                      onChanged: _busy
                          ? null
                          : (selected) => setState(() {
                                if (selected == true) {
                                  _gpsFields.add(q.name);
                                } else {
                                  _gpsFields.remove(q.name);
                                }
                                _count = null;
                              })),
              ],
            ],
          ],
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ui(context, 'Boundary / reference layer')),
              subtitle: Text(ui(context,
                  'Polygons only; visible behind other study layers.')),
              value: _boundary,
              onChanged:
                  _busy ? null : (value) => setState(() => _boundary = value)),
          if (_busy) const LinearProgressIndicator(),
          if (_count != null)
            Text(ui(context, '{v0} matching site(s)', [_count])),
          if (_error != null)
            Text(ui(context, _error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          OutlinedButton.icon(
              onPressed: _busy || workspace == null ? null : () => _review(),
              icon: const Icon(Icons.preview_outlined),
              label: Text(ui(context, 'Preview matching sites'))),
          FilledButton.icon(
              onPressed: _busy || workspace == null
                  ? null
                  : () => _review(create: true),
              icon: const Icon(Icons.layers_outlined),
              label: Text(ui(context, 'Create'))),
        ]));
  }
}
