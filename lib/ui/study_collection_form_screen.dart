import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/workflow_requirements_service.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/ui/photo_capture_screen.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_collection_service.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

class StudyCollectionFormScreen extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  final StudyAreaSite site;
  final StudyWorkflow workflow;
  final CollectionRound? round;
  final StoredForm? form;
  final SurveySession? resumeSession;
  const StudyCollectionFormScreen(
      {super.key,
      required this.database,
      required this.projectId,
      required this.site,
      required this.workflow,
      this.round,
      this.form,
      this.resumeSession});
  @override
  State<StudyCollectionFormScreen> createState() =>
      _StudyCollectionFormScreenState();
}

class _StudyCollectionFormScreenState extends State<StudyCollectionFormScreen> {
  late final _service = StudyCollectionService(widget.database);
  SurveySession? _draft;
  Map<String, dynamic> _answers = {};
  bool _loading = true;
  bool _busy = false;
  bool _allowPop = false;
  bool _dirty = false;
  String? _error;
  String? _username;
  StoredForm? _activeForm;
  PhotoRecord? _photo;
  late WorkflowRequirements _requirements =
      WorkflowRequirements.defaults(widget.workflow);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final draft = widget.resumeSession ??
          await _service.draftFor(widget.projectId, widget.site,
              widget.workflow, widget.round, widget.form);
      _requirements = await WorkflowRequirementsService(widget.database)
          .get(widget.projectId, widget.workflow);
      _photo = FieldQualityService.photo(
          draft == null ? null : StudyCollectionService.data(draft)?['photo']);
      _username = await widget.database.getSetting('user_name');
      final snapshot = draft == null
          ? null
          : StudyCollectionService.data(draft)?['form_snapshot'];
      _activeForm = snapshot is Map && widget.form != null
          ? widget.form!.copyWith(json: jsonEncode(snapshot))
          : widget.form;
      if (mounted)
        setState(() {
          _draft = draft;
          _answers = Map<String, dynamic>.from(draft == null
              ? {}
              : StudyCollectionService.data(draft)!['answers'] as Map);
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = '$error';
          _loading = false;
        });
    }
  }

  Future<void> _save(Map<String, dynamic> answers,
      {required bool draft}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final row = await _service.save(
          projectId: widget.projectId,
          site: widget.site,
          workflow: widget.workflow,
          round: widget.round,
          form: _activeForm ?? widget.form,
          answers: answers,
          evidencePhoto: _photo,
          outcome: StudyAreaStatus.completed,
          draft: draft,
          previous: _draft);
      _draft = row;
      _answers = answers;
      _dirty = false;
      if (!mounted) return;
      if (!draft) {
        setState(() => _allowPop = true);
        Navigator.pop(context, true);
      } else
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ui(context, 'Draft saved'))));
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (_dirty) {
      try {
        await _save(_answers, draft: true);
      } catch (_) {
        return;
      }
    }
    if (!mounted || _error != null) return;
    setState(() => _allowPop = true);
    Navigator.pop(context, false);
  }

  Future<void> _capturePhoto() async {
    final captured = await Navigator.push<PhotoRecord>(
        context, MaterialPageRoute(builder: (_) => const PhotoCaptureScreen()));
    if (!mounted || captured == null) return;
    setState(() {
      _photo = captured;
      _dirty = true;
    });
    try {
      await _save(_answers, draft: true);
    } catch (_) {}
  }

  Widget _evidence() => Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(ui(
                context,
                _photo != null
                    ? 'Photo attached with embedded GPS.'
                    : _requirements.photo
                        ? 'A photo is required before finishing.'
                        : 'Photo is optional.')),
            OutlinedButton.icon(
                onPressed: _busy ? null : _capturePhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(ui(context,
                    _photo == null ? 'Capture photo' : 'Replace photo'))),
          ]));

  @override
  Widget build(BuildContext context) {
    final form = _activeForm ?? widget.form;
    return PopScope(
        canPop: _allowPop,
        onPopInvoked: (popped) {
          if (!popped) _leave();
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text(
                    widget.round?.name ?? ui(context, 'Site observation'))),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(ui(context, _error!),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    if (form != null) ...[
                      if (_requirements.photo || _photo != null)
                        ConstrainedBox(
                            constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.sizeOf(context).height * .25),
                            child: SingleChildScrollView(child: _evidence())),
                      Expanded(
                          child: AbsorbPointer(
                              absorbing: _busy,
                              child: SurveyFormRenderer(
                                  form: SurveyForm.fromJson(
                                      jsonDecode(form.json)),
                                  initialUsername: _username,
                                  initialAnswers: _answers,
                                  onAnswersChanged: (answers) {
                                    _answers = answers;
                                    _dirty = true;
                                  },
                                  onSaveDraft: (answers) =>
                                      _save(answers, draft: true),
                                  onSave: (answers) =>
                                      _save(answers, draft: false)))),
                    ] else
                      Expanded(
                          child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                            Text(widget.site.displayName,
                                style: Theme.of(context).textTheme.titleLarge),
                            _evidence(),
                            FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () async {
                                        try {
                                          await _save(_answers, draft: false);
                                        } catch (_) {}
                                      },
                                child: Text(ui(context, 'Mark done'))),
                            OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () async {
                                        try {
                                          await _save(_answers, draft: true);
                                        } catch (_) {}
                                      },
                                child: Text(ui(context, 'Save draft'))),
                          ])),
                  ])));
  }
}
