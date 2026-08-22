import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/survey_logic.dart';
import 'package:mapbanai/ui/photo_capture_screen.dart';

/// Renders a [SurveyForm] with ODK multi-language support.
///
/// If the form defines `label::Bangla (bn)` / `label::English (en)` etc.,
/// a language switcher is shown at the top and all question labels, hints,
/// constraint messages and choice labels switch accordingly.
class SurveyFormRenderer extends StatefulWidget {
  final SurveyForm form;
  final VoidCallback? onComplete;
  final void Function(Map<String, dynamic> answers)? onSave;
  final void Function(Map<String, dynamic> answers)? onSaveDraft;
  final Map<String, dynamic>? initialAnswers;
  /// Initial form language override (e.g. 'bn' or 'en'). If null, renderer
  /// picks the app locale when available, else the form's defaultLanguage
  /// or 'en' or first available language.
  final String? initialLanguage;

  const SurveyFormRenderer({
    required this.form,
    this.onComplete,
    this.onSave,
    this.onSaveDraft,
    this.initialAnswers,
    this.initialLanguage,
    super.key,
  });

  @override
  State<SurveyFormRenderer> createState() => _SurveyFormRendererState();
}

class _SurveyFormRendererState extends State<SurveyFormRenderer> {
  late Map<String, dynamic> _answers;
  late Map<String, TextEditingController> _controllers;
  late Set<String> _visibleQuestions;
  late String _formLanguage;
  late List<String> _availableLanguages;

  @override
  void initState() {
    super.initState();
    _answers = Map.from(widget.initialAnswers ?? {});
    _controllers = {};
    _visibleQuestions = {};

    // Determine available languages for this form.
    _availableLanguages = widget.form.effectiveLanguages;
    // Also consider widget.form.languages which is sorted.
    if (_availableLanguages.isEmpty && widget.form.languages.isNotEmpty) {
      _availableLanguages = List.from(widget.form.languages);
    }

    // Choose initial language: explicit prop > form default > 'en' if present > first.
    if (widget.initialLanguage != null &&
        _availableLanguages.contains(widget.initialLanguage!.toLowerCase())) {
      _formLanguage = widget.initialLanguage!.toLowerCase();
    } else if (widget.form.defaultLanguage != null &&
        _availableLanguages.contains(widget.form.defaultLanguage!.toLowerCase())) {
      _formLanguage = widget.form.defaultLanguage!.toLowerCase();
    } else if (_availableLanguages.contains('en')) {
      _formLanguage = 'en';
    } else if (_availableLanguages.isNotEmpty) {
      _formLanguage = _availableLanguages.first;
    } else {
      _formLanguage = 'default';
    }

    // Initialize controllers for text-like fields
    for (final question in widget.form.questions) {
      if (question.type == QuestionType.text ||
          question.type == QuestionType.long_text ||
          question.type == QuestionType.integer ||
          question.type == QuestionType.decimal) {
        final initial =
            _answers[question.name]?.toString() ?? question.defaultValue ?? '';
        _controllers[question.name] = TextEditingController(text: initial);
        if (initial.isNotEmpty) {
          _answers[question.name] = initial;
        }
      }
    }

    _updateVisibility();
    _updateCalculations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If app locale is bn/en and form supports it, prefer it on first load
    // unless user already manually switched (we only auto-switch once).
    if (_availableLanguages.length > 1 && _formLanguage == 'en') {
      try {
        final appLocale = Localizations.localeOf(context).languageCode;
        if (_availableLanguages.contains(appLocale) && appLocale != _formLanguage) {
          // Don't force if form default is explicitly en; keep default.
          // Only auto-switch when form default was not explicitly en?
          // For simplicity, if app is bn and form has bn, switch to bn.
          if (appLocale == 'bn') {
            // Use microtask to avoid setState during build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _formLanguage != 'bn') {
                setState(() => _formLanguage = 'bn');
              }
            });
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateVisibility() {
    _visibleQuestions.clear();
    for (final question in widget.form.questions) {
      if (question.type == QuestionType.hidden) continue;
      if (question.isRelevant(_answers)) {
        _visibleQuestions.add(question.name);
      }
    }
  }

  void _updateCalculations() {
    // Iterate until stable so calculations can chain off each other.
    var changed = true;
    var passes = 0;
    while (changed && passes < widget.form.questions.length) {
      changed = false;
      passes++;
      for (final question in widget.form.questions) {
        if (question.type != QuestionType.calculated &&
            question.calculation == null) {
          continue;
        }
        final result = SurveyLogic.evaluateCalculation(
          question.calculation ?? question.defaultValue,
          _answers,
        );
        if (result != null && _answers[question.name] != result) {
          _answers[question.name] = result;
          changed = true;
        }
      }
    }
  }

  void _updateAnswer(String questionName, dynamic value) {
    setState(() {
      _answers[questionName] = value;
      _updateCalculations();
      _updateVisibility();
    });
  }

  String _languageDisplay(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return 'English';
      case 'bn':
        return 'Bangla';
      default:
        if (code == 'default') return 'Default';
        // Capitalize
        if (code.isEmpty) return code;
        return code[0].toUpperCase() + code.substring(1);
    }
  }

  Widget _buildLanguageSwitcher(AppLocalizations? l10n) {
    if (_availableLanguages.length <= 1) return const SizedBox.shrink();
    // Sort for stable order: en first, then bn, then others.
    final sorted = List<String>.from(_availableLanguages);
    sorted.sort((a, b) {
      if (a == 'en') return -1;
      if (b == 'en') return 1;
      if (a == 'bn') return -1;
      if (b == 'bn') return 1;
      return a.compareTo(b);
    });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.translate_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.formLanguage ?? 'Form language',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (l10n != null)
                  Text(
                    l10n.formLanguageHint,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _formLanguage,
            underline: const SizedBox.shrink(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            onChanged: (value) {
              if (value != null) setState(() => _formLanguage = value);
            },
            items: [
              for (final code in sorted)
                DropdownMenuItem(
                  value: code,
                  child: Text(_languageDisplay(code)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.form.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.form.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageSwitcher(l10n),
          if (_availableLanguages.length > 1) const SizedBox(height: 16),
          if (_availableLanguages.length <= 1) const SizedBox(height: 8),
          ..._buildQuestions(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveForm,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n?.saveResponses ?? 'Save responses'),
            ),
          ),
          if (widget.onSaveDraft != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saveDraft,
                icon: const Icon(Icons.edit_note),
                label: Text(l10n?.saveAsDraft ?? 'Save as draft'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildQuestions() {
    final widgets = <Widget>[];

    for (int i = 0; i < widget.form.questions.length; i++) {
      final question = widget.form.questions[i];

      if (!_visibleQuestions.contains(question.name)) {
        continue;
      }

      widgets.add(
        _QuestionWidget(
          question: question,
          languageCode: _formLanguage,
          value: _answers[question.name],
          controller: _controllers[question.name],
          onChanged: (value) => _updateAnswer(question.name, value),
        ),
      );
      widgets.add(const SizedBox(height: 20));
    }

    return widgets;
  }

  void _saveForm() {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    // Validate required fields
    for (final question in widget.form.questions) {
      if (!_visibleQuestions.contains(question.name)) continue;
      if (question.type == QuestionType.note ||
          question.type == QuestionType.calculated) {
        continue;
      }

      if (question.required && (_answers[question.name] == null || _answers[question.name].toString().isEmpty)) {
        final label = question.labelFor(_formLanguage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n != null ? l10n.requiredField(label) : '$label is required')),
        );
        return;
      }

      final constraintError = SurveyLogic.evaluateConstraint(
        question.constraint,
        _answers[question.name],
        question.constraintMessageFor(_formLanguage),
      );
      if (constraintError != null) {
        final label = question.labelFor(_formLanguage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n != null ? l10n.constraintError(label, constraintError) : '$label: $constraintError')),
        );
        return;
      }
    }

    widget.onSave?.call(_answers);
    widget.onComplete?.call();
  }

  /// Saves whatever has been filled in so far without applying required /
  /// constraint validation, so interrupted surveys can be resumed later.
  void _saveDraft() {
    widget.onSaveDraft?.call(Map<String, dynamic>.from(_answers));
    widget.onComplete?.call();
  }
}

class _QuestionWidget extends StatelessWidget {
  final Question question;
  final String languageCode;
  final dynamic value;
  final TextEditingController? controller;
  final ValueChanged<dynamic> onChanged;

  const _QuestionWidget({
    required this.question,
    required this.languageCode,
    required this.value,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = question.labelFor(languageCode);
    final displayHint = question.hintFor(languageCode);
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: displayLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (question.required)
                TextSpan(
                  text: ' *',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        if (displayHint != null) ...[
          const SizedBox(height: 4),
          Text(
            displayHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildInputWidget(l10n),
      ],
    );
  }

  Widget _buildInputWidget(AppLocalizations? l10n) {
    switch (question.type) {
      case QuestionType.text:
        return TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.enterText ?? 'Enter text',
          ),
        );

      case QuestionType.long_text:
        return TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 4,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.enterLongText ?? 'Enter long text',
            alignLabelWithHint: true,
          ),
        );

      case QuestionType.integer:
        return TextField(
          controller: controller,
          onChanged: (text) => onChanged(int.tryParse(text)),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.enterNumber ?? 'Enter number',
          ),
        );

      case QuestionType.decimal:
        return TextField(
          controller: controller,
          onChanged: (text) => onChanged(double.tryParse(text)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.enterDecimal ?? 'Enter decimal number',
          ),
        );

      case QuestionType.yes_no:
        return SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'yes', label: Text(l10n?.yes ?? 'Yes')),
            ButtonSegment(value: 'no', label: Text(l10n?.no ?? 'No')),
          ],
          selected: {if (value != null) value.toString()},
          onSelectionChanged: (selection) => onChanged(selection.first),
        );

      case QuestionType.select_one:
        return DropdownButtonFormField<String>(
          value: value?.toString(),
          onChanged: (newValue) => onChanged(newValue),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.selectOption ?? 'Select an option',
          ),
          items: question.choices?.map((choice) {
            return DropdownMenuItem<String>(
              value: choice.name,
              child: Text(choice.labelFor(languageCode)),
            );
          }).toList() ?? [],
        );

      case QuestionType.dropdown:
        return DropdownButtonFormField<String>(
          value: value?.toString(),
          onChanged: (newValue) => onChanged(newValue),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.chooseOption ?? 'Choose an option',
          ),
          items: question.choices?.map((choice) {
            return DropdownMenuItem<String>(
              value: choice.name,
              child: Text(choice.labelFor(languageCode)),
            );
          }).toList() ?? [],
        );

      case QuestionType.select_multiple:
        return _MultiSelectField(
          choices: question.choices ?? [],
          languageCode: languageCode,
          selectedValues: (value as List?)?.cast<String>() ?? [],
          onChanged: onChanged,
        );

      case QuestionType.date:
        return _DatePickerField(
          onChanged: onChanged,
          initialValue: value,
          languageCode: languageCode,
        );

      case QuestionType.time:
        return _TimePickerField(
          onChanged: onChanged,
          initialValue: value,
        );

      case QuestionType.datetime:
        return _DateTimePickerField(
          onChanged: onChanged,
          initialValue: value,
        );

      case QuestionType.geopoint:
        return _GpsCaptureField(
          value: value,
          onChanged: onChanged,
          languageCode: languageCode,
        );

      case QuestionType.gps_accuracy:
        return _GpsAccuracyField(
          value: value,
          onChanged: onChanged,
          languageCode: languageCode,
        );

      case QuestionType.image:
        return _PhotoField(value: value, onChanged: onChanged, languageCode: languageCode);

      case QuestionType.calculated:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.functions_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value != null
                      ? value.toString()
                      : 'Not computed yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );

      case QuestionType.note:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            question.labelFor(languageCode),
            style: TextStyle(color: Colors.blue.shade900),
          ),
        );

      case QuestionType.hidden:
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}

class _MultiSelectField extends StatefulWidget {
  final List<Choice> choices;
  final String languageCode;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  const _MultiSelectField({
    required this.choices,
    required this.languageCode,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  State<_MultiSelectField> createState() => _MultiSelectFieldState();
}

class _MultiSelectFieldState extends State<_MultiSelectField> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(_MultiSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = List.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final choice in widget.choices)
          CheckboxListTile(
            title: Text(choice.labelFor(widget.languageCode)),
            value: _selected.contains(choice.name),
            onChanged: (checked) {
              setState(() {
                if (checked ?? false) {
                  _selected.add(choice.name);
                } else {
                  _selected.remove(choice.name);
                }
                widget.onChanged(_selected);
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final dynamic initialValue;
  final String languageCode;

  const _DatePickerField({
    required this.onChanged,
    this.initialValue,
    this.languageCode = 'default',
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              initialValue != null
                  ? initialValue.toString().split('T')[0]
                  : (l10n?.selectDate ?? 'Select date'),
            ),
            const Icon(Icons.calendar_today_outlined),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final dynamic initialValue;

  const _TimePickerField({
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          onChanged(picked.format(context));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              initialValue != null ? initialValue.toString() : (l10n?.selectTime ?? 'Select time'),
            ),
            const Icon(Icons.schedule_outlined),
          ],
        ),
      ),
    );
  }
}

class _DateTimePickerField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final dynamic initialValue;

  const _DateTimePickerField({
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate == null) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime == null) return;
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        onChanged(combined.toIso8601String());
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              initialValue != null
                  ? DateTime.tryParse(initialValue.toString())?.toLocal().toString() ?? initialValue.toString()
                  : (l10n?.selectDateTime ?? 'Select date and time'),
            ),
            const Icon(Icons.event_outlined),
          ],
        ),
      ),
    );
  }
}

class _GpsCaptureField extends StatefulWidget {
  final dynamic value;
  final ValueChanged<String> onChanged;
  final String languageCode;

  const _GpsCaptureField({
    required this.value,
    required this.onChanged,
    this.languageCode = 'default',
  });

  @override
  State<_GpsCaptureField> createState() => _GpsCaptureFieldState();
}

class _GpsCaptureFieldState extends State<_GpsCaptureField> {
  bool _capturing = false;

  static String _formatGpsValue(String value) {
    final parts = value.split(',');
    if (parts.length < 2) return value;
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    final acc = parts.length > 2 ? double.tryParse(parts[2].trim()) : null;
    final latText = lat == null ? parts[0].trim() : lat.toStringAsFixed(5);
    final lonText = lon == null ? parts[1].trim() : lon.toStringAsFixed(5);
    final accText = acc == null ? '' : '  ±${acc.round()} m';
    return 'Lat: $latText, Lon: $lonText$accText';
  }

  Future<void> _capture() async {
    setState(() {
      _capturing = true;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      widget.onChanged(
        '${position.latitude},${position.longitude},${position.accuracy.round()}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value != null
                  ? _formatGpsValue(value.toString())
                  : (l10n?.tapToCaptureGps ?? 'Tap to capture GPS location'),
              style: TextStyle(
                color: value != null ? Colors.blue : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _capturing ? null : _capture,
            child: _capturing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n?.captureGps ?? 'Capture'),
          ),
        ],
      ),
    );
  }
}

class _GpsAccuracyField extends StatefulWidget {
  final dynamic value;
  final ValueChanged<String> onChanged;
  final String languageCode;

  const _GpsAccuracyField({
    required this.value,
    required this.onChanged,
    this.languageCode = 'default',
  });

  @override
  State<_GpsAccuracyField> createState() => _GpsAccuracyFieldState();
}

class _GpsAccuracyFieldState extends State<_GpsAccuracyField> {
  bool _capturing = false;

  Future<void> _capture() async {
    setState(() {
      _capturing = true;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      widget.onChanged('${position.accuracy.round()}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get accuracy: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value != null ? 'Accuracy: $value m' : (l10n?.tapToMeasureAccuracy ?? 'Tap to measure accuracy'),
              style: TextStyle(
                color: value != null ? Colors.blue : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _capturing ? null : _capture,
            child: _capturing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n?.measureAccuracy ?? 'Measure'),
          ),
        ],
      ),
    );
  }
}

class _PhotoField extends StatelessWidget {
  final dynamic value;
  final void Function(dynamic) onChanged;
  final String languageCode;

  const _PhotoField({required this.value, required this.onChanged, this.languageCode = 'default'});

  PhotoRecord? get _photo {
    if (value is PhotoRecord) return value as PhotoRecord;
    if (value is Map) {
      return PhotoRecord.fromJson(Map<String, dynamic>.from(value as Map));
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value as String);
        if (decoded is Map) {
          return PhotoRecord.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _capture(BuildContext context) async {
    final record = await Navigator.of(context).push<PhotoRecord>(
      MaterialPageRoute(builder: (_) => const PhotoCaptureScreen()),
    );
    if (record != null) {
      onChanged(jsonEncode(record.toJson()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null && photo.thumbPath.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photo.thumbPath),
                width: 120,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(
                photo?.isGeotagged == true
                    ? Icons.photo_camera_outlined
                    : Icons.photo_camera_back_outlined,
                color: photo?.isGeotagged == true ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  photo == null
                      ? 'Tap to attach photo (geotagged)'
                      : photo.isGeotagged
                          ? (l10n?.geotaggedPhoto ?? 'Geotagged photo attached')
                          : (l10n?.photoAttached ?? 'Photo attached (not geotagged)'),
                  style: TextStyle(
                    color: photo == null ? Colors.grey : Colors.blue.shade800,
                    fontSize: 13,
                  ),
                ),
              ),
              if (photo != null)
                IconButton(
                  tooltip: 'Remove photo',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged(null),
                ),
              ElevatedButton(
                onPressed: () => _capture(context),
                child: Text(photo == null ? (l10n?.attachPhoto ?? 'Attach') : (l10n?.replacePhoto ?? 'Replace')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
