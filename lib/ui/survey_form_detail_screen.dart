import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/survey_form_builder_screen.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

class SurveyFormDetailScreen extends StatefulWidget {
  const SurveyFormDetailScreen({
    required this.row,
    required this.projectName,
    super.key,
  });

  final StoredForm row;
  final String projectName;

  @override
  State<SurveyFormDetailScreen> createState() => _SurveyFormDetailScreenState();
}

class _SurveyFormDetailScreenState extends State<SurveyFormDetailScreen> {
  late final AppDatabase _database;
  late StoredForm _row;
  late SurveyForm _form;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _row = widget.row;
    _form = SurveyForm.fromJson(
        jsonDecode(widget.row.json) as Map<String, dynamic>);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _saveResponse(Map<String, dynamic> answers) async {
    try {
      final projectId = (_row.projectId ??
          await _database.getProjectIdByName(widget.projectName));
      if (projectId == null) {
        throw StateError('Project not found: ${widget.projectName}');
      }

      await _database.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value(
            answers['site_name']?.toString() ?? _form.name,
          ),
          status: const drift.Value('saved'),
          responses: drift.Value(jsonEncode({
            'form_id': _form.id,
            'form_snapshot': _form.toJson(),
            'layer_id':
                (await ProjectWorkspaceService(_database).load(projectId))
                    .layerId,
            'form_name': _form.name,
            'user_name': await _database.getSetting('user_name'),
            'answers': answers,
          })),
        ),
      );

      if (!mounted) return;
      _showSnack(ui(context, 'Saved response for {v0}', [widget.projectName]));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveDraftResponse(Map<String, dynamic> answers) async {
    try {
      final projectId = (_row.projectId ??
          await _database.getProjectIdByName(widget.projectName));
      if (projectId == null) {
        throw StateError('Project not found: ${widget.projectName}');
      }

      await _database.insertSurveySession(
        SurveySessionsCompanion(
          projectId: drift.Value(projectId),
          title: drift.Value(
            'Draft survey — ${answers['site_name']?.toString() ?? _form.name}',
          ),
          status: const drift.Value('draft'),
          responses: drift.Value(jsonEncode({
            'form_id': _form.id,
            'form_snapshot': _form.toJson(),
            'layer_id':
                (await ProjectWorkspaceService(_database).load(projectId))
                    .layerId,
            'form_name': _form.name,
            'user_name': await _database.getSetting('user_name'),
            'answers': answers,
          })),
        ),
      );

      if (!mounted) return;
      _showSnack(ui(context, 'Draft saved — resume it from History later'));
    } catch (e) {
      rethrow;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _editForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyFormBuilderScreen(
          existingForm: _form,
          onSave: (form) async {
            await _database.updateStoredForm(
              _row.id,
              name: form.name,
              description: form.description,
              json: jsonEncode(form.toJson()),
              version: form.version,
            );
            if (!mounted) return;
            setState(() {
              _form = form;
              _row = _row.copyWith(
                name: form.name,
                description: form.description,
                json: jsonEncode(form.toJson()),
              );
            });
            _showSnack(ui(context, 'Form "{v0}" updated', [form.name]));
          },
        ),
      ),
    );
  }

  Future<void> _deleteForm() async {
    final confirmed = await showConfirmDialog(
      context,
      title: ui(context, 'Delete form'),
      message: ui(context, 'Delete "{v0}"?', [_form.name]),
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteStoredForm(_row.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String get _typeLabel => _form.questions.isEmpty
      ? 'No questions'
      : '${_form.questions.length} '
          '${_form.questions.length == 1 ? 'question' : 'questions'}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ui(context, 'Form details')),
        actions: [
          IconButton(
            tooltip: ui(context, 'Delete form'),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteForm,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _form.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _form.description.isEmpty
                ? ui(context, 'No description')
                : _form.description,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            ui(context, '{v0} • version {v1}', [_typeLabel, _form.version]),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final username = await _database.getSetting('user_name');
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(ui(context, 'Survey Response'))),
                    body: SurveyFormRenderer(
                      form: _form,
                      initialUsername: username,
                      onSave: _saveResponse,
                      onSaveDraft: _saveDraftResponse,
                      onComplete: () => Navigator.pop(context),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_outlined),
            label: Text(ui(context, 'Run survey')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _editForm,
            icon: const Icon(Icons.edit_outlined),
            label: Text(ui(context, 'Edit form')),
          ),
          const SizedBox(height: 24),
          Text(
            ui(context, 'Questions'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (_form.questions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  ui(context, 'This form has no questions yet.'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            for (final question in _form.questions)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.help_outline,
                    size: 20,
                    color: Colors.indigo.shade600,
                  ),
                  title: Text(
                    question.label,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    question.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (question.required)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ui(context, 'required'),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        question.type.toString().split('.').last,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
