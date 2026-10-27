import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/workflow_requirements_service.dart';
import 'package:mapbanai/services/google_maps_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/site_timeline_screen.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:provider/provider.dart';
import 'package:mapbanai/services/form_attribute_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/models/study_workflow.dart';
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
      this.initialSiteId,
      this.database,
      this.studyAreaStore});
  final int projectId;
  final int? resumeSessionId;
  final String? initialSiteId;
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
  WorkflowRequirements _requirements =
      WorkflowRequirements.defaults(StudyWorkflow.verification);
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

  Future<void> _openGoogleMaps() async {
    final site = _selectedSite;
    if (site == null) return;
    try {
      if (!await launchUrl(GoogleMapsLinks.site(site.latitude, site.longitude),
          mode: LaunchMode.externalApplication)) {
        _message(ui(context, 'Could not open Google Maps.'));
      }
    } catch (error) {
      _message(ui(context, 'Could not open Google Maps: {v0}', [error]));
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load() async {
    try {
      final project = await _db.getProjectById(widget.projectId);
      if (project == null) throw StateError('Project does not exist.');
      _requirements = await WorkflowRequirementsService(_db)
          .get(project.id, StudyWorkflow.verification);
      final workspace = await ProjectWorkspaceService(_db)
          .load(project.id, workflow: StudyWorkflow.verification);
      await ProjectVectorLayerService(_db)
          .linkExistingStudySites(workspace.project, _store);
      await ProjectVectorLayerService(_db)
          .ensureStudySites(workspace.project, workspace.layerId, _store);
      final sites = await _store.loadSites();

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
        _selectedSite =
            _sites.where((site) => site.id == widget.initialSiteId).firstOrNull;
        _forms = workspace.forms;
        _resumable = rows
            .where((row) =>
                GuidedVisitService.isVisit(row) &&
                (row.status == 'draft' ||
                    GuidedVisitService.visit(row)['site_sync'] == 'pending'))
            .toList();
        _loading = false;
      });
      if (resume != null) {
        _restore(resume);
      } else if (widget.initialSiteId != null && _selectedSite != null) {
        await _startVisit();
      }
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

  Future<void> _startVisit() async {
    final existing = _resumable
        .where((row) =>
            row.status == 'draft' &&
            GuidedVisitService.visit(row)['site_id'] == _selectedSite!.id)
        .firstOrNull;
    final row = existing ??
        await _service.start(projectId: widget.projectId, site: _selectedSite!);
    if (mounted) _restore(row);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _message(
          ui(context, '{v0}. Your last saved draft is preserved.', [error]));
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
    await ProjectWorkspaceService(_db).select(widget.projectId,
        formId: stored.id, workflow: StudyWorkflow.verification);
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
                title: Text(ui(context, 'Compare map and saved visit')),
                content: SingleChildScrollView(
                    child: Text(ui(
                        context,
                        'Current map (revision {v0}):\n{v1}\n\nSaved visit proposal:\n{v2}\n\nApplying the saved visit replaces current attributes and geometry. Both versions remain in revision history.',
                        [
                      current.revision,
                      const JsonEncoder.withIndent('  ')
                          .convert(current.stateSnapshot()),
                      const JsonEncoder.withIndent('  ').convert(proposal)
                    ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(ui(context, 'Keep current map'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(ui(context, 'Apply reviewed visit')))
                ]));
    if (accepted != true) return;
    final result = await _service.rebasePending(row,
        expectedCurrentToken: current.revisionToken);
    if (mounted) setState(() => _session = result.session);
    if (!result.mapApplied)
      _message(
          ui(context, 'Map update still needs review: {v0}', [result.error]));
  }

  Future<void> _addAttribute() async {
    final name = TextEditingController();
    final value = TextEditingController();
    final added = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(ui(context, 'Add information')),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration: InputDecoration(
                          labelText: ui(context, 'Field name'))),
                  TextField(
                      controller: value,
                      decoration:
                          InputDecoration(labelText: ui(context, 'Value')))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(ui(context, 'Cancel'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(ui(context, 'Add')))
                ]));
    if (added == true && name.text.trim().isNotEmpty && mounted) {
      final key = name.text.trim();
      if (_attributes.containsKey(key)) {
        _message(
            ui(context, 'This field already exists. Edit its value above.'));
      } else {
        setState(
            () => _attributes[key] = TextEditingController(text: value.text));
      }
    }
    name.dispose();
    value.dispose();
  }

  String _siteDescription(StudyAreaSite site) {
    final fields = {
      for (final e in site.attributes.entries)
        e.key.trim().toLowerCase(): e.value
    };
    return [fields['location'], fields['layer'], ui(context, site.status.label)]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' · ');
  }

  String _draftName(SurveySession row) {
    final snapshot = GuidedVisitService.visit(row)['site_after'];
    return snapshot is Map
        ? StudyAreaSite.fromJson(Map<String, dynamic>.from(snapshot))
            .displayName
        : ui(context, 'Saved visit');
  }

  Future<void> _chooseSite() async {
    var query = '';
    final sorted = List<StudyAreaSite>.from(_sites)
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final selected = await showModalBottomSheet<StudyAreaSite>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => FractionallySizedBox(
              heightFactor: .85,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, MediaQuery.viewInsetsOf(sheetContext).bottom),
                  child: StatefulBuilder(builder: (context, update) {
                    final matches = sorted
                        .where((site) =>
                            '${site.displayName} ${site.attributes.values.join(' ')} ${site.id}'
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                        .toList();
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(ui(context, 'Choose a site'),
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))),
                            IconButton(
                                tooltip: ui(context, 'Close'),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close))
                          ]),
                          TextField(
                              autofocus: false,
                              decoration: InputDecoration(
                                  labelText:
                                      ui(context, 'Search by name or location'),
                                  prefixIcon: Icon(Icons.search)),
                              onChanged: (value) =>
                                  update(() => query = value)),
                          const SizedBox(height: 8),
                          if (matches.isEmpty)
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(ui(context, 'No matching sites'))),
                          Expanded(
                              child: ListView.builder(
                                  itemCount: matches.length,
                                  itemBuilder: (context, index) {
                                    final site = matches[index];
                                    return ListTile(
                                        leading: const Icon(
                                            Icons.location_on_outlined),
                                        title: Text(site.displayName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        subtitle: Text(_siteDescription(site),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        onTap: () =>
                                            Navigator.pop(context, site));
                                  })),
                        ]);
                  })),
            ));
    if (selected != null && mounted) setState(() => _selectedSite = selected);
  }

  bool _primaryAttribute(String name) => const {
        'name',
        'site_name',
        'station_name',
        'facility_name',
        'sts_name',
        'label',
        'location',
        'address',
        'নাম',
        'ঠিকানা'
      }.contains(name.trim().toLowerCase());
  Widget _attributeField(MapEntry<String, TextEditingController> entry) =>
      Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TextField(
              controller: entry.value,
              decoration: InputDecoration(labelText: ui(context, entry.key))));
  @override
  Widget build(BuildContext context) {
    final row = _session;
    final metadata = row == null ? null : GuidedVisitService.visit(row);
    final response = row == null ? null : GuidedVisitService.decode(row);
    final photo = response == null ? null : response['photo'];
    final questionnaireReady =
        (!_requirements.questionnaire && response?['form_snapshot'] is! Map) ||
            (metadata?['form_validated'] == true &&
                metadata?['stored_form_id'] == _selectedForm?.id);
    final saved = row?.status == 'saved';
    return PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _leave();
        },
        child: Scaffold(
            appBar: AppBar(
                actions: [
                  if (_selectedSite != null)
                    IconButton(
                        tooltip: ui(context, 'Open in Google Maps'),
                        onPressed: _openGoogleMaps,
                        icon: const Icon(Icons.open_in_new_rounded))
                ],
                title: Text(ui(context, 'Guided visit{v0}',
                    [_project == null ? '' : ' — ${_project!.name}']))),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(ui(context, _error!)))
                    : AbsorbPointer(
                        absorbing: _busy,
                        child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_busy) const LinearProgressIndicator(),
                              if (row == null) ...[
                                ProjectWorkspaceBar(
                                    database: _db,
                                    workflow: StudyWorkflow.verification,
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
                                Text(ui(context,
                                    'Choose a baseline feature to verify, update and document.')),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    key: const ValueKey('choose-visit-site'),
                                    onPressed:
                                        _sites.isEmpty ? null : _chooseSite,
                                    icon: const Icon(Icons.search),
                                    label: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Text(
                                            _selectedSite?.displayName ??
                                                ui(context, 'Choose a site')))),
                                if (_selectedSite != null)
                                  Text(_siteDescription(_selectedSite!)),
                                const SizedBox(height: 12),
                                FilledButton(
                                    onPressed: _selectedSite == null
                                        ? null
                                        : () => _run(_startVisit),
                                    child: Text(ui(context, 'Start visit'))),
                                if (_selectedSite != null)
                                  TextButton.icon(
                                      icon: const Icon(Icons.timeline),
                                      label: Text(ui(context,
                                          'Site timeline / compare observations')),
                                      onPressed: () => Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (_) =>
                                                  SiteTimelineScreen(
                                                      database: _db,
                                                      store: _store,
                                                      projectId:
                                                          widget.projectId,
                                                      site: _selectedSite!)))),
                                if (_sites.isEmpty)
                                  Text(ui(context,
                                      'Import study-area features first to begin a guided baseline visit.')),
                                for (final draft in _resumable)
                                  ListTile(
                                      title: Text(_draftName(draft),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      subtitle: Text(draft.status == 'draft'
                                          ? ui(context, 'Resume saved draft')
                                          : ui(context,
                                              'Survey saved; map update needs attention')),
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
                                    ? ui(context,
                                        'Visit saved and study map updated.')
                                    : ui(context,
                                        'Visit and photo are saved. Study map update is pending.')),
                                if (metadata['reconciliation_error'] != null)
                                  Text(metadata['reconciliation_error']
                                      .toString()),
                                if (metadata['site_sync'] != 'applied')
                                  OutlinedButton(
                                      onPressed: () => _run(_reviewConflict),
                                      child: Text(
                                          ui(context, 'Review map conflict'))),
                                if (metadata['site_sync'] != 'applied')
                                  FilledButton(
                                      onPressed: () => _run(() async {
                                            final result =
                                                await _service.reconcile(row);
                                            if (mounted)
                                              setState(() =>
                                                  _session = result.session);
                                            if (!result.mapApplied)
                                              _message(ui(
                                                  context,
                                                  'Map still needs review: {v0}',
                                                  [result.error]));
                                          }),
                                      child: Text(
                                          ui(context, 'Retry map update'))),
                                Text(ui(context, '{v0} • Survey record {v1}',
                                    [_selectedSite!.displayName, row.id])),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                    onPressed: () => _run(() async {
                                          setState(() {
                                            _session = null;
                                            _selectedSite = null;
                                          });
                                          await _load();
                                        }),
                                    child: Text(
                                        ui(context, 'Visit another feature'))),
                              ] else ...[
                                Text(
                                    ui(context, '1. Verify {v0}',
                                        [_selectedSite!.displayName]),
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<StudyAreaStatus>(
                                    itemHeight: null,
                                    value:
                                        _status == StudyAreaStatus.notFound ||
                                                _status ==
                                                    StudyAreaStatus.needsReview
                                            ? _status
                                            : StudyAreaStatus.verified,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                        labelText:
                                            ui(context, 'Visit outcome')),
                                    items: const [
                                      StudyAreaStatus.verified,
                                      StudyAreaStatus.notFound,
                                      StudyAreaStatus.needsReview
                                    ]
                                        .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                                ui(context, status.label))))
                                        .toList(),
                                    onChanged: (status) =>
                                        setState(() => _status = status!)),
                                for (final entry in _attributes.entries.where(
                                    (entry) => _primaryAttribute(entry.key)))
                                  _attributeField(entry),
                                if (_attributes.keys
                                    .any((name) => !_primaryAttribute(name)))
                                  ExpansionTile(
                                      title: Text(
                                          ui(context, 'More site details')),
                                      children: [
                                        for (final entry in _attributes.entries
                                            .where((entry) =>
                                                !_primaryAttribute(entry.key)))
                                          _attributeField(entry)
                                      ]),
                                TextButton.icon(
                                    onPressed: _addAttribute,
                                    icon: const Icon(Icons.add),
                                    label:
                                        Text(ui(context, 'Add information'))),
                                const SizedBox(height: 16),
                                TextField(
                                    controller: _note,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                        labelText: ui(
                                            context, 'Change or review note'))),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    onPressed: () => _run(() async {
                                          if (![
                                            'Point',
                                            'LineString',
                                            'Polygon'
                                          ].contains(_geometry!['type'])) {
                                            await showDialog<void>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                        title: Text(ui(context,
                                                            'Multipart geometry')),
                                                        content:
                                                            SingleChildScrollView(
                                                                child: Text(ui(
                                                                    context,
                                                                    'This complete geometry is preserved. Edit its parts in GIS software and merge the revised GeoJSON to redraw it.\n\n{v0}',
                                                                    [
                                                              const JsonEncoder
                                                                      .withIndent(
                                                                      '  ')
                                                                  .convert(
                                                                      _geometry)
                                                            ]))),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: Text(ui(
                                                                  context,
                                                                  'Close')))
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
                                    label: Text(ui(
                                        context, 'Review or edit geometry'))),
                                const SizedBox(height: 20),
                                Text(ui(context, '2. Collect information'),
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<int>(
                                    itemHeight: null,
                                    value: _selectedForm?.id,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                        labelText:
                                            ui(context, 'Project survey form')),
                                    items: _forms
                                        .map((form) => DropdownMenuItem(
                                            value: form.id,
                                            child: Text(form.name)))
                                        .toList(),
                                    onChanged: (id) => setState(() =>
                                        _selectedForm = _forms
                                            .where((form) => form.id == id)
                                            .firstOrNull)),
                                const SizedBox(height: 12),
                                FilledButton.tonal(
                                    onPressed: _selectedForm == null
                                        ? null
                                        : () => _run(_openSurvey),
                                    child: Text(questionnaireReady
                                        ? ui(context, 'Review saved survey')
                                        : ui(context, 'Open survey'))),
                                if (_forms.isEmpty &&
                                    _requirements.questionnaire)
                                  Text(ui(context,
                                      'Add an XLSForm to this project before finishing a visit.')),
                                const SizedBox(height: 20),
                                Text(ui(context, '3. Geotagged evidence photo'),
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                Text(photo == null
                                    ? ui(
                                        context,
                                        _requirements.photo
                                            ? 'A photo is required before finishing.'
                                            : 'Photo is optional.')
                                    : ui(context,
                                        'Photo attached with embedded GPS.')),
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
                                        ? ui(context, 'Capture photo')
                                        : ui(context, 'Replace photo'))),
                                const SizedBox(height: 20),
                                if (!questionnaireReady)
                                  Text(ui(context,
                                      'Complete the required steps to finish. You can save a draft at any time.')),
                                FilledButton(
                                    onPressed: !questionnaireReady
                                        ? null
                                        : () => _run(() async {
                                              await _saveSite();
                                              final result = await _service
                                                  .finalize(_session!);
                                              if (mounted)
                                                setState(() =>
                                                    _session = result.session);
                                              if (!result.mapApplied)
                                                _message(ui(
                                                    context,
                                                    'Visit saved; map update needs review: {v0}',
                                                    [result.error]));
                                            }),
                                    child: Text(ui(context,
                                        'Finish visit and update map'))),
                                OutlinedButton(
                                    onPressed: () => _run(() async {
                                          await _saveSite();
                                          _message(ui(context,
                                              'Visit draft saved. You can resume it later.'));
                                        }),
                                    child: Text(ui(context, 'Save draft'))),
                                Text(ui(
                                    context,
                                    'Draft visit {v0}. Leaving this screen saves the feature edits.',
                                    [row.id])),
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
            content: Text(ui(context,
                'Could not save draft: {v0}. Answers remain here.', [error]))));
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
