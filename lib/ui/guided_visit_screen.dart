import 'package:mapbanai/state/project_state.dart';
import 'package:provider/provider.dart';
import 'package:mapbanai/services/form_attribute_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/ui/common/project_workspace_bar.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/geometry_capture_screen.dart';
import 'package:mapbanai/ui/photo_capture_screen.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

class GuidedVisitScreen extends StatefulWidget {
  const GuidedVisitScreen(
      {super.key,
      required this.projectId,
      this.resumeSessionId,
      this.database,
      this.studyAreaStore});
  final int projectId;
  final int? resumeSessionId;
  final AppDatabase? database;
  final StudyAreaStore? studyAreaStore;
  @override
  State<GuidedVisitScreen> createState() => _GuidedVisitScreenState();
}

class _GuidedVisitScreenState extends State<GuidedVisitScreen> {
  late final AppDatabase _db = widget.database ?? AppDatabase();
  late final StudyAreaStore _store = widget.studyAreaStore ?? StudyAreaStore();
  late final GuidedVisitService _service =
      GuidedVisitService(database: _db, sites: _store);
  ProjectWorkspace? _workspace;
  Project? _project;
  List<StudyAreaSite> _sites = [];
  List<StoredForm> _forms = [];
  List<SurveySession> _resumable = [];
  StudyAreaSite? _selectedSite;
  StoredForm? _selectedForm;
  SurveySession? _session;
  final Map<String, TextEditingController> _attributes = {};
  final TextEditingController _note = TextEditingController();
  Map<String, dynamic>? _geometry;
  StudyAreaStatus _status = StudyAreaStatus.verified;
  bool _loading = true;
  bool _busy = false;
  bool _allowPop = false;
  String? _error;
  String? _username;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _attributes.values) {
      controller.dispose();
    }
    _note.dispose();
    if (widget.database == null) _db.close();
    super.dispose();
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load() async {
    try {
      final project = await _db.getProjectById(widget.projectId);
      if (project == null) throw StateError('Project does not exist.');
      final workspace = await ProjectWorkspaceService(_db).load(project.id);
      final sites = await _store.loadSites();
      final forms = await _db.getStoredFormsForProject(project.id);
      final rows = await _db.getSurveySessionsByProject(project.id);
      _username = await _db.getSetting('user_name');
      SurveySession? resume;
      if (widget.resumeSessionId != null) {
        resume = await _db.getSurveySession(widget.resumeSessionId!);
        if (resume == null ||
            resume.projectId != project.id ||
            !GuidedVisitService.isVisit(resume))
          throw StateError('Linked visit does not belong to this project.');
      }
      if (!mounted) return;
      setState(() {
        _workspace = workspace;
        _selectedForm = workspace.form;
        _project = workspace.project;
        _sites = sites
            .where((site) =>
                GuidedVisitService.belongsToProject(site, workspace.project) &&
                site.layerId == workspace.layerId)
            .toList();
        _forms = forms;
        _resumable = rows
            .where((row) =>
                GuidedVisitService.isVisit(row) &&
                (row.status == 'draft' ||
                    GuidedVisitService.visit(row)['site_sync'] == 'pending'))
            .toList();
        _loading = false;
      });
      if (resume != null) _restore(resume);
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  void _restore(SurveySession row) {
    final metadata = GuidedVisitService.visit(row);
    final site = StudyAreaSite.fromJson(
        Map<String, dynamic>.from(metadata['site_after'] as Map));
    for (final controller in _attributes.values) {
      controller.dispose();
    }
    _attributes.clear();
    for (final entry in site.attributes.entries) {
      _attributes[entry.key] = TextEditingController(text: entry.value);
    }
    _note.text = site.changeNote;
    setState(() {
      _session = row;
      _selectedSite = site;
      _geometry = site.currentGeometry;
      _status = site.status == StudyAreaStatus.pending ||
              site.status == StudyAreaStatus.completed
          ? StudyAreaStatus.verified
          : site.status;
      _selectedForm = _forms
              .where((form) => form.id == metadata['stored_form_id'])
              .firstOrNull ??
          _workspace?.form;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _message('$error. Your last saved draft is preserved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  StudyAreaSite _editedSite() {
    final site = _selectedSite!;
    final attributes = {
      for (final entry in _attributes.entries) entry.key: entry.value.text
    };
    final geometry = _geometry!;
    dynamic coordinate = geometry['coordinates'];
    while (coordinate is List &&
        coordinate.isNotEmpty &&
        coordinate.first is List) {
      coordinate = coordinate.first;
    }
    final lat =
        coordinate is List && coordinate.length >= 2 && coordinate[1] is num
            ? (coordinate[1] as num).toDouble()
            : site.latitude;
    final lon =
        coordinate is List && coordinate.length >= 2 && coordinate[0] is num
            ? (coordinate[0] as num).toDouble()
            : site.longitude;
    final before = GuidedVisitService.visit(_session!)['site_before'] as Map;
    final changed =
        jsonEncode(before['attributes']) != jsonEncode(attributes) ||
            jsonEncode(before['geometry']) != jsonEncode(geometry);
    return StudyAreaSite.fromJson({
      ...site.toJson(),
      'attributes': attributes,
      'geometry': geometry,
      'latitude': lat,
      'longitude': lon,
      'status': (changed && _status == StudyAreaStatus.verified
              ? StudyAreaStatus.updated
              : _status)
          .name,
      'change_note': _note.text.trim(),
      'project_id': widget.projectId,
      'project_external_id': _project!.externalId
    });
  }

  Future<void> _saveSite() async {
    if (_session == null || _session!.status != 'draft') return;
    final edited = _editedSite();
    final row =
        await _service.saveDraft(session: _session!, revisedSite: edited);
    if (mounted)
      setState(() {
        _session = row;
        _selectedSite = edited;
        _status = edited.status;
      });
  }

  Future<void> _openSurvey() async {
    await _saveSite();
    final stored = _selectedForm;
    if (stored == null) throw StateError('Choose a project survey form.');
    await ProjectWorkspaceService(_db)
        .select(widget.projectId, formId: stored.id);
    var response = GuidedVisitService.decode(_session!);
    if (GuidedVisitService.visit(_session!)['stored_form_id'] != stored.id) {
      final row = await _service.saveDraft(
          session: _session!,
          storedForm: stored,
          answers: {},
          formValidated: false);
      if (mounted) setState(() => _session = row);
      response = GuidedVisitService.decode(row);
    }
    final form = SurveyForm.fromJson(Map<String, dynamic>.from(
        response['form_snapshot'] is Map
            ? response['form_snapshot'] as Map
            : jsonDecode(stored.json) as Map));
    final site = _editedSite();
    final answers = FormAttributeService.prefill(
        form,
        {
          ...site.attributes,
          ...site.formAnswers,
          ...Map<String, dynamic>.from(response['answers'] as Map)
        },
        geometry: site.currentGeometry);
    for (final question in form.questions) {
      if (answers.containsKey(question.name)) continue;
      final value = question.name == 'feature_id' || question.name == 'site_id'
          ? site.id
          : question.name == 'site_name'
              ? site.displayName
              : site.attributes[question.name];
      if (value != null &&
          (question.choices == null ||
              question.choices!.any((choice) => choice.name == value)))
        answers[question.name] = value;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _VisitSurveyRoute(
            form: form,
            answers: answers,
            username: _username,
            persist: (answers, validated) async {
              final row = await _service.saveDraft(
                  session: _session!,
                  answers: answers,
                  formValidated: validated);
              if (mounted) setState(() => _session = row);
            })));
  }

  Future<void> _leave() async {
    if (_busy) return;
    await _run(() async {
      await _saveSite();
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    });
  }

  Future<void> _reviewConflict() async {
    final row = _session!;
    final current = (await _store.loadSites())
        .where((site) => site.id == GuidedVisitService.visit(row)['site_id'])
        .firstOrNull;
    if (current == null)
      throw StateError(
          'The feature was removed. Review or restore the study map first.');
    final proposal = GuidedVisitService.visit(row)['site_after'] as Map;
    if (!mounted) return;
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Compare map and saved visit'),
                content: SingleChildScrollView(
                    child: Text(
                        'Current map (revision ${current.revision}):\n${const JsonEncoder.withIndent('  ').convert(current.stateSnapshot())}\n\nSaved visit proposal:\n${const JsonEncoder.withIndent('  ').convert(proposal)}\n\nApplying the saved visit replaces current attributes and geometry. Both versions remain in revision history.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep current map')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Apply reviewed visit'))
                ]));
    if (accepted != true) return;
    final result = await _service.rebasePending(row,
        expectedCurrentToken: current.revisionToken);
    if (mounted) setState(() => _session = result.session);
    if (!result.mapApplied)
      _message('Map update still needs review: ${result.error}');
  }

  Future<void> _addAttribute() async {
    final name = TextEditingController();
    final value = TextEditingController();
    final added = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Add information'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Field name')),
                  TextField(
                      controller: value,
                      decoration: const InputDecoration(labelText: 'Value'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Add'))
                ]));
    if (added == true && name.text.trim().isNotEmpty && mounted) {
      final key = name.text.trim();
      if (_attributes.containsKey(key)) {
        _message('This field already exists. Edit its value above.');
      } else {
        setState(
            () => _attributes[key] = TextEditingController(text: value.text));
      }
    }
    name.dispose();
    value.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = _session;
    final metadata = row == null ? null : GuidedVisitService.visit(row);
    final response = row == null ? null : GuidedVisitService.decode(row);
    final photo = response == null ? null : response['photo'];
    final saved = row?.status == 'saved';
    return PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _leave();
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text(
                    'Guided visit${_project == null ? '' : ' — ${_project!.name}'}')),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : AbsorbPointer(
                        absorbing: _busy,
                        child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_busy) const LinearProgressIndicator(),
                              if (row == null) ...[
                                ProjectWorkspaceBar(
                                    database: _db,
                                    workspace: _workspace,
                                    onChanged: (workspace) async {
                                      try {
                                        context
                                            .read<ProjectState>()
                                            .setSelectedProject(
                                                workspace.project.name,
                                                projectId:
                                                    workspace.project.id);
                                      } catch (_) {}
                                      if (workspace.project.id !=
                                          widget.projectId) {
                                        await Navigator.of(context)
                                            .pushReplacement(MaterialPageRoute(
                                                builder: (_) =>
                                                    GuidedVisitScreen(
                                                        projectId: workspace
                                                            .project.id,
                                                        database:
                                                            widget.database,
                                                        studyAreaStore: widget
                                                            .studyAreaStore)));
                                      } else {
                                        await _load();
                                      }
                                    }),
                                const Text(
                                    'Choose a baseline feature to verify, update and document.'),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                    value: _selectedSite?.id,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Baseline feature'),
                                    items: _sites
                                        .map((site) => DropdownMenuItem(
                                            value: site.id,
                                            child: Text(site.displayName)))
                                        .toList(),
                                    onChanged: (id) => setState(() =>
                                        _selectedSite = _sites
                                            .where((site) => site.id == id)
                                            .firstOrNull)),
                                const SizedBox(height: 12),
                                FilledButton(
                                    onPressed: _selectedSite == null
                                        ? null
                                        : () => _run(() async {
                                              final draft =
                                                  await _service.start(
                                                      projectId:
                                                          widget.projectId,
                                                      site: _selectedSite!);
                                              if (mounted) _restore(draft);
                                            }),
                                    child: const Text('Start visit')),
                                if (_sites.isEmpty)
                                  const Text(
                                      'Import study-area features first to begin a guided baseline visit.'),
                                for (final draft in _resumable)
                                  ListTile(
                                      title: Text(draft.title),
                                      subtitle: Text(draft.status == 'draft'
                                          ? 'Resume saved draft'
                                          : 'Survey saved; map update needs attention'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => _restore(draft)),
                              ] else if (saved) ...[
                                Icon(
                                    metadata!['site_sync'] == 'applied'
                                        ? Icons.check_circle
                                        : Icons.warning_amber,
                                    color: metadata['site_sync'] == 'applied'
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 48),
                                Text(metadata['site_sync'] == 'applied'
                                    ? 'Visit saved and study map updated.'
                                    : 'Visit and photo are saved. Study map update is pending.'),
                                if (metadata['reconciliation_error'] != null)
                                  Text(metadata['reconciliation_error']
                                      .toString()),
                                if (metadata['site_sync'] != 'applied')
                                  OutlinedButton(
                                      onPressed: () => _run(_reviewConflict),
                                      child: const Text('Review map conflict')),
                                if (metadata['site_sync'] != 'applied')
                                  FilledButton(
                                      onPressed: () => _run(() async {
                                            final result =
                                                await _service.reconcile(row);
                                            if (mounted)
                                              setState(() =>
                                                  _session = result.session);
                                            if (!result.mapApplied)
                                              _message(
                                                  'Map still needs review: ${result.error}');
                                          }),
                                      child: const Text('Retry map update')),
                                Text(
                                    'Visit ${metadata['id']} • Site ${metadata['site_id']} • Survey record ${row.id}'),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                    onPressed: () => _run(() async {
                                          setState(() {
                                            _session = null;
                                            _selectedSite = null;
                                          });
                                          await _load();
                                        }),
                                    child: const Text('Visit another feature')),
                              ] else ...[
                                Text('1. Verify ${_selectedSite!.displayName}',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                DropdownButtonFormField<StudyAreaStatus>(
                                    value: _status,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Visit outcome'),
                                    items: StudyAreaStatus.values
                                        .where((status) =>
                                            status != StudyAreaStatus.pending &&
                                            status != StudyAreaStatus.completed)
                                        .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status.label)))
                                        .toList(),
                                    onChanged: (status) =>
                                        setState(() => _status = status!)),
                                for (final entry in _attributes.entries)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextField(
                                          controller: entry.value,
                                          decoration: InputDecoration(
                                              labelText: entry.key))),
                                TextButton.icon(
                                    onPressed: _addAttribute,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add information')),
                                TextField(
                                    controller: _note,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                        labelText: 'Change or review note')),
                                OutlinedButton.icon(
                                    onPressed: () => _run(() async {
                                          if (![
                                            'Point',
                                            'LineString',
                                            'Polygon'
                                          ].contains(_geometry!['type'])) {
                                            await showDialog<void>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                        title: const Text(
                                                            'Multipart geometry'),
                                                        content:
                                                            SingleChildScrollView(
                                                                child: Text(
                                                                    'This complete geometry is preserved. Edit its parts in GIS software and merge the revised GeoJSON to redraw it.\n\n${const JsonEncoder.withIndent('  ').convert(_geometry)}')),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: const Text(
                                                                  'Close'))
                                                        ]));
                                            return;
                                          }
                                          final geometry = await Navigator.of(
                                                  context)
                                              .push<Map<String, dynamic>>(
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          GeometryCaptureScreen(
                                                              geometryType:
                                                                  _geometry![
                                                                          'type']
                                                                      as String,
                                                              initialGeometry:
                                                                  _geometry)));
                                          if (geometry != null && mounted)
                                            setState(
                                                () => _geometry = geometry);
                                        }),
                                    icon: const Icon(Icons.map),
                                    label:
                                        const Text('Review or edit geometry')),
                                const SizedBox(height: 20),
                                Text('2. Collect information',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                DropdownButtonFormField<int>(
                                    value: _selectedForm?.id,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Project survey form'),
                                    items: _forms
                                        .map((form) => DropdownMenuItem(
                                            value: form.id,
                                            child: Text(form.name)))
                                        .toList(),
                                    onChanged: (id) => setState(() =>
                                        _selectedForm = _forms
                                            .where((form) => form.id == id)
                                            .firstOrNull)),
                                FilledButton.tonal(
                                    onPressed: _selectedForm == null
                                        ? null
                                        : () => _run(_openSurvey),
                                    child: Text(
                                        metadata!['form_validated'] == true
                                            ? 'Review saved survey'
                                            : 'Open survey')),
                                if (_forms.isEmpty)
                                  const Text(
                                      'Add an XLSForm to this project before finishing a visit.'),
                                const SizedBox(height: 20),
                                Text('3. Geotagged evidence photo',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                Text(photo == null
                                    ? 'A photo is required before finishing.'
                                    : 'Photo attached with embedded GPS.'),
                                OutlinedButton.icon(
                                    onPressed: () => _run(() async {
                                          await _saveSite();
                                          final captured = await Navigator.of(
                                                  context)
                                              .push<PhotoRecord>(MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PhotoCaptureScreen()));
                                          if (captured != null) {
                                            final updated =
                                                await _service.saveDraft(
                                                    session: _session!,
                                                    photo: captured);
                                            if (mounted)
                                              setState(
                                                  () => _session = updated);
                                          }
                                        }),
                                    icon: const Icon(Icons.camera_alt),
                                    label: Text(photo == null
                                        ? 'Capture photo'
                                        : 'Replace photo')),
                                const SizedBox(height: 20),
                                FilledButton(
                                    onPressed: () => _run(() async {
                                          await _saveSite();
                                          final result = await _service
                                              .finalize(_session!);
                                          if (mounted)
                                            setState(() =>
                                                _session = result.session);
                                          if (!result.mapApplied)
                                            _message(
                                                'Visit saved; map update needs review: ${result.error}');
                                        }),
                                    child: const Text(
                                        'Finish visit and update map')),
                                OutlinedButton(
                                    onPressed: () => _run(() async {
                                          await _saveSite();
                                          _message(
                                              'Visit draft saved. You can resume it later.');
                                        }),
                                    child: const Text('Save draft')),
                                Text(
                                    'Draft visit ${row.id}. Leaving this screen saves the feature edits.'),
                              ],
                            ]))));
  }
}

class _VisitSurveyRoute extends StatefulWidget {
  const _VisitSurveyRoute(
      {required this.form,
      required this.answers,
      required this.persist,
      this.username});
  final SurveyForm form;
  final Map<String, dynamic> answers;
  final String? username;
  final Future<void> Function(Map<String, dynamic>, bool) persist;
  @override
  State<_VisitSurveyRoute> createState() => _VisitSurveyRouteState();
}

class _VisitSurveyRouteState extends State<_VisitSurveyRoute> {
  late Map<String, dynamic> _answers = Map.from(widget.answers);
  bool _leaving = false;
  bool _canPop = false;
  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await widget.persist(_answers, false);
      if (mounted) {
        setState(() => _canPop = true);
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Could not save draft: $error. Answers remain here.')));
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
          appBar: AppBar(title: Text(widget.form.name)),
          body: AbsorbPointer(
              absorbing: _leaving,
              child: SurveyFormRenderer(
                  form: widget.form,
                  initialAnswers: widget.answers,
                  initialUsername: widget.username,
                  onAnswersChanged: (answers) => _answers = answers,
                  onSave: (answers) => widget.persist(answers, true),
                  onSaveDraft: (answers) => widget.persist(answers, false),
                  onComplete: () {
                    setState(() => _canPop = true);
                    Navigator.pop(context);
                  }))));
}
