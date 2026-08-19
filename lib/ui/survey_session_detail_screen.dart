import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/feature_detail_sheet.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

/// Shows the answers saved in a survey session (or the GIS feature captured),
/// with an option to edit a form-based response and delete the session.
class SurveySessionDetailScreen extends StatefulWidget {
  const SurveySessionDetailScreen({
    required this.session,
    required this.projectName,
    super.key,
  });

  final SurveySession session;
  final String projectName;

  @override
  State<SurveySessionDetailScreen> createState() =>
      _SurveySessionDetailScreenState();
}

class _SurveySessionDetailScreenState extends State<SurveySessionDetailScreen> {
  final AppDatabase _database = AppDatabase();
  late SurveySession _session;
  Map<String, dynamic>? _responses;
  SurveyForm? _form;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _load();
  }

  Future<void> _load() async {
    Map<String, dynamic> responses;
    try {
      responses =
          jsonDecode(_session.responses) as Map<String, dynamic>;
    } catch (_) {
      responses = {};
    }
    SurveyForm? form;
    final formName = responses['form_name'] as String?;
    if (formName != null) {
      final stored = await _database.getStoredFormByName(
        formName,
        projectId: _session.projectId,
      );
      if (stored != null) {
        try {
          form = SurveyForm.fromJson(
            jsonDecode(stored.json) as Map<String, dynamic>,
          );
        } catch (_) {
          form = null;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _responses = responses;
      _form = form;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _editAnswers() async {
    final form = _form;
    if (form == null) return;
    final currentAnswers = (_responses?['answers'] as Map?)?.cast<String, dynamic>() ?? {};
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Edit — ${form.name}')),
          body: SurveyFormRenderer(
            form: form,
            initialAnswers: currentAnswers,
            onSave: (answers) async {
              await _saveEditedAnswers(answers, form);
            },
            onComplete: () => Navigator.pop(context),
          ),
        ),
      ),
    );
    await _load();
  }

  Future<void> _saveEditedAnswers(
    Map<String, dynamic> answers,
    SurveyForm form,
  ) async {
    final responses = {
      ...?_responses,
      'answers': answers,
      'form_id': form.id,
      'form_name': form.name,
      'user_name': await _database.getSetting('user_name'),
      'edited_at': DateTime.now().toIso8601String(),
    };
    final title = answers['site_name']?.toString() ?? form.name;
    await _database.updateSurveySession(
      _session.id,
      title: title,
      responses: jsonEncode(responses),
    );
    if (!mounted) return;
    setState(() {
      _session = _session.copyWith(title: title, responses: jsonEncode(responses));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Answers updated')),
    );
  }

  Future<void> _editFeature() async {
    final r = _responses;
    if (r == null || r['feature_type'] == null) return;
    final featureType = r['feature_type'].toString();
    final vertices = _verticesOf(r);
    final fields = await _database.getProjectFields(_session.projectId);
    final fieldNames = fields.map((f) => f.name).toList();
    final existingFields = (r['fields'] as Map?)?.cast<String, dynamic>() ?? {};
    if (!mounted) return;

    final result = await showFeatureDetailSheet(
      context,
      featureType: featureType,
      latitude: (r['latitude'] as num?)?.toDouble(),
      longitude: (r['longitude'] as num?)?.toDouble(),
      accuracyM: (r['accuracy_m'] as num?)?.toDouble(),
      vertices: vertices.isEmpty ? null : vertices,
      fields: fieldNames,
      initialId: r['id']?.toString(),
      initialName: r['name']?.toString(),
      initialNotes: r['notes']?.toString(),
      initialFieldValues: {
        for (final entry in existingFields.entries)
          entry.key: entry.value.toString(),
      },
    );
    if (result == null) return;

    final updated = {
      ...r,
      'id': result.id,
      'name': result.name,
      'notes': result.notes,
      if (result.fieldValues.isNotEmpty) 'fields': result.fieldValues,
      'edited_at': DateTime.now().toIso8601String(),
    };
    await _database.updateSurveySession(
      _session.id,
      title: _session.title,
      responses: jsonEncode(updated),
    );
    if (!mounted) return;
    setState(() {
      _responses = updated;
      _session = _session.copyWith(responses: jsonEncode(updated));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature updated')),
    );
  }

  List<({double lat, double lon})> _verticesOf(Map<String, dynamic> r) {
    final raw = r['vertices'];
    if (raw is! List) return [];
    return [
      for (final v in raw)
        if (v is Map && v['latitude'] is num && v['longitude'] is num)
          (
            lat: (v['latitude'] as num).toDouble(),
            lon: (v['longitude'] as num).toDouble(),
          ),
    ];
  }

  Future<void> _deleteSession() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete response',
      message: 'Delete "${_session.title}"? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteSurveySession(_session.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String? _labelFor(String key) {
    final form = _form;
    if (form == null) return null;
    for (final question in form.questions) {
      if (question.name == key) return question.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Response'),
        actions: [
          IconButton(
            tooltip: 'Delete response',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteSession,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _session.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.projectName}  •  '
                  '${_formatDate(_session.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                if (_form != null) ...[
                  if (_session.status == 'saved')
                    FilledButton.icon(
                      onPressed: _editAnswers,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit answers'),
                    ),
                  const SizedBox(height: 16),
                ],
                if (_responses?['feature_type'] != null) ...[
                  const Text(
                    'GIS feature',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ..._featureEntries(),
                  const SizedBox(height: 8),
                  if (_session.status == 'saved')
                    FilledButton.icon(
                      onPressed: _editFeature,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit feature'),
                    ),
                  const SizedBox(height: 16),
                ],
                if ((_responses?['answers'] as Map?) != null) ...[
                  const Text(
                    'Saved answers',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ..._answerEntries(),
                ],
              ],
            ),
    );
  }

  List<Widget> _answerEntries() {
    final answers = (_responses?['answers'] as Map?)?.cast<String, dynamic>() ?? {};
    if (answers.isEmpty) {
      return [
        Text('No answers recorded.', style: TextStyle(color: Colors.grey.shade600)),
      ];
    }
    final entries = <Widget>[];
    answers.forEach((key, value) {
      final label = _labelFor(key) ?? key;
      final text = value == null || value.toString().isEmpty ? '—' : value.toString();
      entries.add(
        _kvTile(label, text),
      );
    });
    return entries;
  }

  List<Widget> _featureEntries() {
    final r = _responses!;
    final entries = <Widget>[
      _kvTile('Type', (r['feature_type'] ?? '').toString()),
      _kvTile('ID', r['id']?.toString() ?? '—'),
      _kvTile('Name', r['name']?.toString() ?? '—'),
      _kvTile('Notes', r['notes']?.toString() ?? '—'),
      if (r['latitude'] != null && r['longitude'] != null)
        _kvTile(
          'Coordinates',
          '${(r['latitude'] as num).toStringAsFixed(6)}, '
              '${(r['longitude'] as num).toStringAsFixed(6)}'
              '${r['accuracy_m'] != null ? '  ±${(r['accuracy_m'] as num).toStringAsFixed(1)} m' : ''}',
        ),
      if (r['length_m'] != null)
        _kvTile('Length', '${(r['length_m'] as num).toStringAsFixed(1)} m'),
      if (r['area_m2'] != null)
        _kvTile('Area', '${(r['area_m2'] as num).toStringAsFixed(1)} m²'),
      if (r['recorded_at'] != null) _kvTile('Recorded', r['recorded_at'].toString()),
    ];
    final fields = r['fields'];
    if (fields is Map) {
      fields.forEach((key, value) {
        entries.add(_kvTile(key.toString(), value.toString()));
      });
    }
    return entries;
  }

  Widget _kvTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}  $h:$m';
  }
}
