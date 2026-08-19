import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/survey_logic.dart';
import 'package:mapbanai/ui/photo_capture_screen.dart';

class SurveyFormRenderer extends StatefulWidget {
  final SurveyForm form;
  final VoidCallback? onComplete;
  final void Function(Map<String, dynamic> answers)? onSave;
  final Map<String, dynamic>? initialAnswers;

  const SurveyFormRenderer({
    required this.form,
    this.onComplete,
    this.onSave,
    this.initialAnswers,
    super.key,
  });

  @override
  State<SurveyFormRenderer> createState() => _SurveyFormRendererState();
}

class _SurveyFormRendererState extends State<SurveyFormRenderer> {
  late Map<String, dynamic> _answers;
  late Map<String, TextEditingController> _controllers;
  late Set<String> _visibleQuestions;

  @override
  void initState() {
    super.initState();
    _answers = Map.from(widget.initialAnswers ?? {});
    _controllers = {};
    _visibleQuestions = {};

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

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          ..._buildQuestions(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveForm,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save responses'),
            ),
          ),
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
    // Validate required fields
    for (final question in widget.form.questions) {
      if (!_visibleQuestions.contains(question.name)) continue;
      if (question.type == QuestionType.note ||
          question.type == QuestionType.calculated) {
        continue;
      }

      if (question.required && (_answers[question.name] == null || _answers[question.name].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${question.label} is required')),
        );
        return;
      }

      final constraintError = SurveyLogic.evaluateConstraint(
        question.constraint,
        _answers[question.name],
        question.constraintMessage,
      );
      if (constraintError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${question.label}: $constraintError')),
        );
        return;
      }
    }

    widget.onSave?.call(_answers);
    widget.onComplete?.call();
  }
}

class _QuestionWidget extends StatelessWidget {
  final Question question;
  final dynamic value;
  final TextEditingController? controller;
  final ValueChanged<dynamic> onChanged;

  const _QuestionWidget({
    required this.question,
    required this.value,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: question.label,
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
        if (question.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            question.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildInputWidget(),
      ],
    );
  }

  Widget _buildInputWidget() {
    switch (question.type) {
      case QuestionType.text:
        return TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter text',
          ),
        );

      case QuestionType.long_text:
        return TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 4,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter long text',
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
            hintText: 'Enter number',
          ),
        );

      case QuestionType.decimal:
        return TextField(
          controller: controller,
          onChanged: (text) => onChanged(double.tryParse(text)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter decimal number',
          ),
        );

      case QuestionType.yes_no:
        return SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'yes', label: Text('Yes')),
            ButtonSegment(value: 'no', label: Text('No')),
          ],
          selected: {if (value != null) value.toString()},
          onSelectionChanged: (selection) => onChanged(selection.first),
        );

      case QuestionType.select_one:
        return DropdownButtonFormField<String>(
          value: value?.toString(),
          onChanged: (newValue) => onChanged(newValue),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select an option',
          ),
          items: question.choices?.map((choice) {
            return DropdownMenuItem<String>(
              value: choice.name,
              child: Text(choice.label),
            );
          }).toList() ?? [],
        );

      case QuestionType.dropdown:
        return DropdownButtonFormField<String>(
          value: value?.toString(),
          onChanged: (newValue) => onChanged(newValue),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose an option',
          ),
          items: question.choices?.map((choice) {
            return DropdownMenuItem<String>(
              value: choice.name,
              child: Text(choice.label),
            );
          }).toList() ?? [],
        );

      case QuestionType.select_multiple:
        return _MultiSelectField(
          choices: question.choices ?? [],
          selectedValues: (value as List?)?.cast<String>() ?? [],
          onChanged: onChanged,
        );

      case QuestionType.date:
        return _DatePickerField(
          onChanged: onChanged,
          initialValue: value,
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
        );

      case QuestionType.gps_accuracy:
        return _GpsAccuracyField(
          value: value,
          onChanged: onChanged,
        );

      case QuestionType.image:
        return _PhotoField(value: value, onChanged: onChanged);

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
            question.label,
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
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  const _MultiSelectField({
    required this.choices,
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
            title: Text(choice.label),
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

  const _DatePickerField({
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
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
                  : 'Select date',
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
              initialValue != null ? initialValue.toString() : 'Select time',
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
                  : 'Select date and time',
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

  const _GpsCaptureField({
    required this.value,
    required this.onChanged,
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
                  : 'Tap to capture GPS location',
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
                : const Text('Capture'),
          ),
        ],
      ),
    );
  }
}

class _GpsAccuracyField extends StatefulWidget {
  final dynamic value;
  final ValueChanged<String> onChanged;

  const _GpsAccuracyField({
    required this.value,
    required this.onChanged,
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
              value != null ? 'Accuracy: $value m' : 'Tap to measure accuracy',
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
                : const Text('Measure'),
          ),
        ],
      ),
    );
  }
}

class _PhotoField extends StatelessWidget {
  final dynamic value;
  final void Function(dynamic) onChanged;

  const _PhotoField({required this.value, required this.onChanged});

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
                          ? 'Geotagged photo attached'
                          : 'Photo attached (not geotagged)',
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
                child: Text(photo == null ? 'Attach' : 'Replace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
