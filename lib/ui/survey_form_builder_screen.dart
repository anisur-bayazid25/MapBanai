import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/xlsform_parser.dart';

Map<String, String>? _updatedTranslations(Map<String, String>? translations,
    String? previousDefault, String nextDefault) {
  if (translations == null) return null;
  return {
    for (final entry in translations.entries)
      entry.key: entry.value == previousDefault ? nextDefault : entry.value
  };
}

class SurveyFormBuilderScreen extends StatefulWidget {
  final SurveyForm? existingForm;
  final FutureOr<void> Function(SurveyForm form)? onSave;

  const SurveyFormBuilderScreen({
    this.existingForm,
    this.onSave,
    super.key,
  });

  @override
  State<SurveyFormBuilderScreen> createState() =>
      _SurveyFormBuilderScreenState();
}

class _SurveyFormBuilderScreenState extends State<SurveyFormBuilderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<Question> _questions;
  SurveyForm? _sourceForm;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingForm?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingForm?.description ?? '');
    _questions = List.from(widget.existingForm?.questions ?? []);
    _sourceForm = widget.existingForm;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _AddQuestionDialog(
        onSave: (question) {
          setState(() {
            _questions.add(question);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => _AddQuestionDialog(
        initialQuestion: _questions[index],
        onSave: (question) {
          setState(() {
            _questions[index] = question;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveForm() async {
    if (_saving) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ui(context, 'Please enter a form name'))),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ui(context, 'Please add at least one question'))),
      );
      return;
    }

    final form = SurveyForm(
      id: widget.existingForm?.id ??
          _sourceForm?.id ??
          'form_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      questions: List<Question>.from(_questions),
      groups: _sourceForm?.groups,
      languages: _sourceForm?.languages,
      defaultLanguage: _sourceForm?.defaultLanguage,
      version: _sourceForm?.version ?? 1,
      importWarnings: _sourceForm?.importWarnings ?? const [],
    );
    final names = <String>{for (final group in form.groups) group.name};
    for (final question in form.questions) {
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(question.name) ||
          !names.add(question.name)) {
        _showSnack(ui(context, 'Question names must be valid and unique: {v0}',
            [question.name]));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await widget.onSave?.call(form);
      if (mounted) Navigator.pop(context, form);
    } catch (error) {
      _showSnack(ui(context,
          'Could not save form: {v0}. Your form is still here.', [error]));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      _showSnack(ui(context, 'Could not read the selected file'));
      return;
    }

    try {
      final form = XlsFormParser.parse(
        bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      if (form.importWarnings.isNotEmpty) {
        final accepted = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(ui(context, 'XLSForm import limitations')),
                  content: SingleChildScrollView(
                      child: Text(form.importWarnings.join('\n\n'))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(ui(context, 'Cancel'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(ui(context, 'Import'))),
                  ],
                ));
        if (accepted != true || !mounted) return;
      }
      setState(() {
        _sourceForm = form;
        _nameController.text = form.name;
        _descriptionController.text = form.description;
        _questions = List.from(form.questions);
      });
      _showSnack(
        ui(context, 'Imported "{v0}" with {v1} questions',
            [form.name, form.questions.length]),
      );
    } on XlsFormParseException catch (e) {
      _showSnack(ui(context, 'Import failed: {v0}', [e.message]));
    } catch (e) {
      _showSnack(ui(context, 'Import failed: {v0}', [e]));
    }
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
        title: Text(ui(context, 'Survey Form Builder')),
        actions: [
          IconButton(
            tooltip: ui(context, 'Import from XLSForm (.xlsx)'),
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: _saving ? null : _importXlsForm,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveForm,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(ui(context, 'Save')),
              ),
            ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ui(context, 'Form Details'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: ui(context, 'Form name'),
                  hintText: ui(context, 'e.g., Riverbank Survey'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: ui(context, 'Description'),
                  hintText: ui(context, 'Brief description of this form'),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ui(context, 'Questions ({v0})', [_questions.length]),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _addQuestion,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(ui(context, 'Add')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_questions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      ui(context, 'No questions yet. Add one to get started.'),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ..._buildQuestionsList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuestionsList() {
    return [
      for (int i = 0; i < _questions.length; i++) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _questions[i].label,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_questions[i].type.toString().split('.').last} • ${_questions[i].name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () => _editQuestion(i),
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text(ui(context, 'Edit')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => _deleteQuestion(i),
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(ui(context, 'Delete'),
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_questions[i].relevance != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ui(context, 'Conditional: {v0}',
                          [_questions[i].relevance]),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

class _AddQuestionDialog extends StatefulWidget {
  final Question? initialQuestion;
  final void Function(Question question) onSave;

  const _AddQuestionDialog({
    this.initialQuestion,
    required this.onSave,
  });

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  late TextEditingController _labelController;
  late TextEditingController _nameController;
  late TextEditingController _hintController;
  late TextEditingController _relevanceController;
  late TextEditingController _constraintController;
  late TextEditingController _constraintMessageController;
  late TextEditingController _calculationController;
  late TextEditingController _defaultController;
  late QuestionType _selectedType;
  late bool _isRequired;
  late List<Choice> _choices;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.initialQuestion?.label ?? '');
    _nameController =
        TextEditingController(text: widget.initialQuestion?.name ?? '');
    _hintController =
        TextEditingController(text: widget.initialQuestion?.hint ?? '');
    _relevanceController =
        TextEditingController(text: widget.initialQuestion?.relevance ?? '');
    _constraintController =
        TextEditingController(text: widget.initialQuestion?.constraint ?? '');
    _constraintMessageController = TextEditingController(
        text: widget.initialQuestion?.constraintMessage ?? '');
    _calculationController =
        TextEditingController(text: widget.initialQuestion?.calculation ?? '');
    _defaultController =
        TextEditingController(text: widget.initialQuestion?.defaultValue ?? '');
    _selectedType = widget.initialQuestion?.type ?? QuestionType.text;
    _isRequired = widget.initialQuestion?.required ?? false;
    _choices = List.from(widget.initialQuestion?.choices ?? []);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _hintController.dispose();
    _relevanceController.dispose();
    _constraintController.dispose();
    _constraintMessageController.dispose();
    _calculationController.dispose();
    _defaultController.dispose();
    super.dispose();
  }

  void _save() {
    if (_labelController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ui(context, 'Label and name are required'))),
      );
      return;
    }

    final needsChoices = _selectedType == QuestionType.select_one ||
        _selectedType == QuestionType.select_multiple ||
        _selectedType == QuestionType.dropdown;
    if (needsChoices && _choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                ui(context, 'This question type needs at least one option'))),
      );
      return;
    }

    final question = Question(
      label: _labelController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      hint: _hintController.text.trim().isEmpty
          ? null
          : _hintController.text.trim(),
      required: _isRequired,
      relevance: _relevanceController.text.trim().isEmpty
          ? null
          : _relevanceController.text.trim(),
      constraint: _constraintController.text.trim().isEmpty
          ? null
          : _constraintController.text.trim(),
      constraintMessage: _constraintMessageController.text.trim().isEmpty
          ? null
          : _constraintMessageController.text.trim(),
      calculation: _calculationController.text.trim().isEmpty
          ? null
          : _calculationController.text.trim(),
      defaultValue: _defaultController.text.trim().isEmpty
          ? null
          : _defaultController.text.trim(),
      choices: needsChoices ? List.from(_choices) : null,
      readOnly: widget.initialQuestion?.readOnly ?? false,
      metadataType: widget.initialQuestion?.metadataType,
      labelTranslations: _updatedTranslations(
          widget.initialQuestion?.labelTranslations,
          widget.initialQuestion?.label,
          _labelController.text.trim()),
      hintTranslations: _updatedTranslations(
          widget.initialQuestion?.hintTranslations,
          widget.initialQuestion?.hint,
          _hintController.text.trim()),
      constraintMessageTranslations: _updatedTranslations(
          widget.initialQuestion?.constraintMessageTranslations,
          widget.initialQuestion?.constraintMessage,
          _constraintMessageController.text.trim()),
      groupPath: widget.initialQuestion?.groupPath,
    );

    widget.onSave(question);
  }

  void _addChoice() {
    showDialog<String>(
      context: context,
      builder: (context) => _ChoiceDialog(
        onSave: (name, label) {
          setState(() {
            _choices.add(Choice(name: name, label: label));
          });
        },
      ),
    );
  }

  void _editChoice(int index) {
    final choice = _choices[index];
    showDialog<String>(
      context: context,
      builder: (context) => _ChoiceDialog(
        initialName: choice.name,
        initialLabel: choice.label,
        onSave: (name, label) {
          setState(() {
            _choices[index] = Choice(
                name: name,
                label: label,
                labelTranslations: _updatedTranslations(
                    choice.labelTranslations, choice.label, label));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ui(context, 'Add Question'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: ui(context, 'Question label'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                readOnly: widget.initialQuestion != null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: ui(context, 'Field name (no spaces)'),
                  helperText: widget.initialQuestion != null
                      ? ui(context,
                          'Field names stay fixed so existing answers and form rules remain linked.')
                      : null,
                  hintText: ui(context, 'e.g., site_name'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hintController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: ui(context, 'Hint text (optional)'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<QuestionType>(
                itemHeight: null,
                isExpanded: true,
                value: _selectedType,
                onChanged: (newType) {
                  if (newType != null) {
                    setState(() {
                      _selectedType = newType;
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: ui(context, 'Question type'),
                ),
                items: [
                  DropdownMenuItem(
                      value: QuestionType.text,
                      child: Text(ui(context, 'Text'))),
                  DropdownMenuItem(
                      value: QuestionType.long_text,
                      child: Text(ui(context, 'Long text'))),
                  DropdownMenuItem(
                      value: QuestionType.integer,
                      child: Text(ui(context, 'Integer'))),
                  DropdownMenuItem(
                      value: QuestionType.decimal,
                      child: Text(ui(context, 'Decimal'))),
                  DropdownMenuItem(
                      value: QuestionType.yes_no,
                      child: Text(ui(context, 'Yes/No'))),
                  DropdownMenuItem(
                      value: QuestionType.select_one,
                      child: Text(ui(context, 'Select one'))),
                  DropdownMenuItem(
                      value: QuestionType.select_multiple,
                      child: Text(ui(context, 'Select multiple'))),
                  DropdownMenuItem(
                      value: QuestionType.dropdown,
                      child: Text(ui(context, 'Dropdown'))),
                  DropdownMenuItem(
                      value: QuestionType.date,
                      child: Text(ui(context, 'Date'))),
                  DropdownMenuItem(
                      value: QuestionType.time,
                      child: Text(ui(context, 'Time'))),
                  DropdownMenuItem(
                      value: QuestionType.datetime,
                      child: Text(ui(context, 'Date & time'))),
                  DropdownMenuItem(
                      value: QuestionType.geopoint,
                      child: Text(ui(context, 'GPS Point'))),
                  DropdownMenuItem(
                      value: QuestionType.gps_accuracy,
                      child: Text(ui(context, 'GPS accuracy'))),
                  DropdownMenuItem(
                      value: QuestionType.image,
                      child: Text(ui(context, 'Image'))),
                  DropdownMenuItem(
                      value: QuestionType.calculated,
                      child: Text(ui(context, 'Calculated'))),
                  DropdownMenuItem(
                      value: QuestionType.note,
                      child: Text(ui(context, 'Note'))),
                  DropdownMenuItem(
                      value: QuestionType.hidden,
                      child: Text(ui(context, 'Hidden'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _relevanceController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: ui(context, 'Relevance (optional)'),
                  hintText: ui(context, 'e.g., \${field_name} = "value"'),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedType == QuestionType.calculated)
                TextField(
                  controller: _calculationController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: ui(context, 'Calculation'),
                    hintText: ui(context, 'e.g., \${width} * \${length}'),
                  ),
                )
              else ...[
                TextField(
                  controller: _constraintController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: ui(context, 'Constraint (optional)'),
                    hintText: ui(context, 'e.g., . > 0 and . < 150'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _constraintMessageController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: ui(context, 'Constraint message (optional)'),
                    hintText:
                        ui(context, 'Shown when the constraint is violated'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_selectedType == QuestionType.select_one ||
                  _selectedType == QuestionType.select_multiple ||
                  _selectedType == QuestionType.dropdown) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ui(context, 'Options ({v0})', [_choices.length]),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    IconButton(
                      tooltip: ui(context, 'Add option'),
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _addChoice,
                    ),
                  ],
                ),
                if (_choices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      ui(context, 'No options yet. Add at least one.'),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  )
                else
                  for (int i = 0; i < _choices.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.radio_button_checked, size: 20),
                      title: Text(
                        '${_choices[i].name} — ${_choices[i].label}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _editChoice(i),
                      ),
                      onLongPress: () {
                        setState(() {
                          _choices.removeAt(i);
                        });
                      },
                    ),
                const SizedBox(height: 4),
              ],
              TextField(
                controller: _defaultController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: ui(context, 'Default value (optional)'),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: Text(ui(context, 'Required')),
                value: _isRequired,
                onChanged: (value) {
                  setState(() {
                    _isRequired = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minChildWidth: 150,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(ui(context, 'Cancel')),
                  ),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_outlined, size: 18),
                    label: Text(ui(context, 'Save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceDialog extends StatefulWidget {
  final String? initialName;
  final String? initialLabel;
  final void Function(String name, String label) onSave;

  const _ChoiceDialog({
    this.initialName,
    this.initialLabel,
    required this.onSave,
  });

  @override
  State<_ChoiceDialog> createState() => _ChoiceDialogState();
}

class _ChoiceDialogState extends State<_ChoiceDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final label = _labelController.text.trim();
    if (name.isEmpty || label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ui(context, 'Option name and label are required'))),
      );
      return;
    }
    widget.onSave(name, label);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialName == null
                  ? ui(context, 'Add Option')
                  : ui(context, 'Edit Option'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: ui(context, 'Value (no spaces)'),
                hintText: ui(context, 'e.g., mild'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: ui(context, 'Label'),
                hintText: ui(context, 'e.g., Mild'),
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minChildWidth: 150,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(ui(context, 'Cancel')),
                ),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_outlined, size: 18),
                  label: Text(ui(context, 'Save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
