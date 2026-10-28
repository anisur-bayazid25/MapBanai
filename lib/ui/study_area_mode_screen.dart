import 'package:mapbanai/ui/common/confirm_field_data_removal.dart';
import 'package:mapbanai/ui/common/labeled_field.dart';
import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/workflow_requirements_service.dart';
import 'package:mapbanai/services/site_priority_service.dart';
import 'package:mapbanai/services/measure_units.dart';
import 'package:mapbanai/ui/common/map_chrome.dart';
import 'package:mapbanai/services/google_maps_links.dart';
import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'package:mapbanai/services/study_feature_policy.dart';
import 'package:mapbanai/services/study_category_style.dart';
import 'package:mapbanai/services/road_routing_service.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/spatial_file_import.dart';
import 'package:mapbanai/ui/site_timeline_screen.dart';
import 'package:mapbanai/services/form_attribute_service.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/history_cleanup_service.dart';
import 'package:mapbanai/ui/history_cleanup_screen.dart';
import 'package:mapbanai/ui/common/shapefile_companions.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/ui/common/project_workspace_bar.dart';
import 'package:mapbanai/ui/common/form_attribute_editor.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:provider/provider.dart';
import 'package:mapbanai/ui/common/basemap_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/study_area_merge_dialog.dart';
import 'package:mapbanai/ui/project_vector_layers_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/services/study_collection_service.dart';
import 'package:mapbanai/ui/study_collection_form_screen.dart';
import 'package:mapbanai/ui/study_workflow_setup_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbanai/ui/guided_visit_screen.dart';

class StudyAreaModeScreen extends StatefulWidget {
  const StudyAreaModeScreen(
      {super.key,
      this.store,
      this.initialSelectedSiteId,
      this.projectId,
      this.database,
      this.projectExternalId,
      this.initialImportPath,
      this.workflow = StudyWorkflow.verification,
      this.collectionRound,
      this.compactControls = false,
      this.viewOnly = false});

  final String? initialImportPath;
  final bool viewOnly;
  final StudyAreaStore? store;
  final String? initialSelectedSiteId;
  final int? projectId;
  final AppDatabase? database;
  final String? projectExternalId;
  final StudyWorkflow workflow;
  final CollectionRound? collectionRound;
  final bool compactControls;

  @override
  State<StudyAreaModeScreen> createState() => _StudyAreaModeScreenState();
}

class _StudyAreaModeScreenState extends State<StudyAreaModeScreen> {
  late final StudyAreaStore _store = widget.store ?? StudyAreaStore();
  late final AppDatabase _database = widget.database ?? AppDatabase();
  ProjectWorkspace? _workspace;
  late CollectionRound? _round = widget.collectionRound;
  Map<String, StudyAreaStatus> _collectionStatuses = {};
  late WorkflowRequirements _requirements =
      WorkflowRequirements.defaults(widget.workflow);
  bool _statusBusy = false;
  final Map<StudyAreaStatus, int> _statusCounts = {};
  void _recountStatuses() {
    _statusCounts.clear();
    for (final site in _sites) {
      final status = _status(site);
      _statusCounts[status] = (_statusCounts[status] ?? 0) + 1;
    }
  }

  bool get _collection => widget.workflow != StudyWorkflow.verification;
  StudyAreaStatus _status(StudyAreaSite site) => _collection
      ? _collectionStatuses[site.id] ?? StudyAreaStatus.pending
      : site.status.verificationStatus;
  final LocationService _locationService = LocationService();
  MapLibreMapController? _controller;
  bool _styleReady = false;
  Widget? _cachedMapWidget;
  String? _cachedMapStyle;
  String? _fittedWorkspace;
  String _selectedBasemapId = 'osm';
  MapStyleChoice? _offlineBasemap;
  String _fieldworker = 'Local fieldworker';
  bool _addingPoint = false;
  List<StudyAreaSite> _sites = [];
  StudyAreaSite? _selectedSite;
  final Map<String, Circle> _circles = {};
  final List<Circle> _referenceCircles = [];
  final List<Line> _referenceLines = [];
  final List<Fill> _referenceFills = [];
  final List<Symbol> _referenceSymbols = [];
  List<Map<String, dynamic>> _referenceLayers = [];
  final List<Symbol> _symbols = [];
  final Set<String> _markerImages = {};
  StudyAreaSite? _movingSite;
  LatLng? _movingCoordinates;
  Line? _routeLine;
  String? _routeSiteId;
  double? _routeDistanceM;
  List<LatLng>? _routeCoordinates;

  // GPS
  StreamSubscription<Position>? _posSub;
  Position? _currentPos;

  bool _isLoading = true;
  StudyAreaStatus? _filter;
  StudyCategoryStyle _categoryStyle = StudyCategoryStyle();
  String? _categoryWorkspaceKey;
  String? _drawType;
  StudyAreaSite? _drawingSite;
  final List<LatLng> _draft = [];
  final List<Line> _lines = [];
  final List<Fill> _fills = [];

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
    _loadOperator();
    _startLocation();
  }

  Future<void> _loadWorkspace() async {
    try {
      int? id = widget.projectId;
      if (id == null) {
        try {
          id = context.read<ProjectState>().selectedProjectId;
        } catch (_) {}
      }
      if (id != null && !widget.viewOnly) {
        final project = await _database.getProjectById(id);
        if (project != null)
          await ProjectVectorLayerService(_database)
              .linkExistingStudySites(project, _store);
        _workspace = await ProjectWorkspaceService(_database)
            .load(id, workflow: widget.workflow);
        final assigned = await _store.loadSites();
        final hasSites = assigned.any((site) =>
            GuidedVisitService.belongsToProject(site, _workspace!.project) &&
            site.layerId == _workspace!.layerId);
        if (!hasSites) {
          final raw =
              await _database.getSetting('project_vector_initialized_$id');
          final initialized =
              raw == null ? <dynamic>[] : jsonDecode(raw) as List;
          final source = (await ProjectVectorLayerService(_database).load(id))
              .where((layer) =>
                  layer['role'] != 'road' &&
                  layer['visible'] != false &&
                  layer['import_batch_id'] == null &&
                  !initialized.contains(layer['id']) &&
                  (layer['features'] as List).isNotEmpty &&
                  ((layer['workflows'] as List?)
                          ?.contains(widget.workflow.name) ??
                      true))
              .firstOrNull;
          if (source != null)
            _workspace = await ProjectWorkspaceService(_database).select(id,
                layerId: ProjectVectorLayerService.studyLayerId(source),
                workflow: widget.workflow);
        }
      }
      await _loadSites();
      if (widget.initialImportPath != null && !widget.viewOnly)
        await _importSites(pathOverride: widget.initialImportPath);
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(ui(context, 'Cannot load project: {v0}', [error]));
      }
    }
  }

  Future<void> _changeWorkspace(ProjectWorkspace workspace) async {
    if (!mounted) return;
    setState(() {
      _workspace = workspace;
      _selectedSite = null;
    });
    try {
      context.read<ProjectState>().setSelectedProject(workspace.project.name,
          projectId: workspace.project.id);
    } catch (_) {}
    await _loadSites();
    if (_sites.isNotEmpty) _fitBounds();
  }

  Future<void> _configureWorkflow() async {
    if (_workspace == null) return;
    final selection = await Navigator.push<StudyWorkflowSelection>(
        context,
        MaterialPageRoute(
            builder: (_) => StudyWorkflowSetupScreen(
                database: _database,
                projectId: _workspace!.project.id,
                workflow: widget.workflow)));
    if (selection == null || !mounted) return;
    _round = selection.round;
    await _changeWorkspace(selection.workspace);
  }

  Future<void> _openCollectionForm(StudyAreaSite site) async {
    final workspace = _workspace;
    if (workspace == null) return;
    if ((_requirements.questionnaire && workspace.form == null) ||
        (widget.workflow == StudyWorkflow.recurring && _round == null)) {
      _showSnack(
          ui(context, 'Select a questionnaire and collection round first.'));
      await _configureWorkflow();
      return;
    }
    if (_collection) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StudyCollectionFormScreen(
                  database: _database,
                  projectId: workspace.project.id,
                  site: site,
                  workflow: widget.workflow,
                  round: _round,
                  form: workspace.form)));
    } else {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GuidedVisitScreen(
                  database: _database,
                  studyAreaStore: _store,
                  projectId: workspace.project.id,
                  initialSiteId: site.id)));
    }
    if (mounted) await _loadSites();
  }

  Future<void> _setCollectionStatus(
      StudyAreaSite site, StudyAreaStatus status) async {
    if (_statusBusy || _workspace == null) return;
    if (status == StudyAreaStatus.completed &&
        (_requirements.questionnaire || _requirements.photo)) {
      await _openCollectionForm(site);
      return;
    }
    final workspace = _workspace!;
    final round = _round;
    setState(() => _statusBusy = true);
    try {
      await StudyCollectionService(_database).save(
          projectId: workspace.project.id,
          site: site,
          workflow: widget.workflow,
          round: round,
          outcome: status,
          statusOnly: true);
      if (!mounted ||
          _workspace?.project.id != workspace.project.id ||
          _workspace?.layerId != workspace.layerId ||
          _round?.id != round?.id) return;
      setState(() {
        final previous = _status(site);
        _collectionStatuses[site.id] = status;
        _statusCounts[previous] =
            ((_statusCounts[previous] ?? 1) - 1).clamp(0, _sites.length);
        _statusCounts[status] = (_statusCounts[status] ?? 0) + 1;
      });
      // Serialize native updates. A saved status must not reload all project
      // files or clear every site and road annotation on the map.
      _mapUpdates = _mapUpdates.then((_) async {
        final controller = _controller;
        if (!mounted || !_styleReady || controller == null) return;
        if (_filter != null) {
          await _renderMapMarkers();
          return;
        }
        final symbols =
            _symbols.where((s) => s.data?['site_id'] == site.id).toList();
        if (symbols.isEmpty) return;
        final current = _status(site);
        final color = switch (current) {
          StudyAreaStatus.completed => '#2E7D32',
          StudyAreaStatus.needsReview => '#F9A825',
          _ => '#E53935'
        };
        final image = 'mapbanai_${current.name}_${color.substring(1)}';
        if (!_markerImages.contains(image)) {
          await controller.addImage(image, _markerImage(current, color));
          _markerImages.add(image);
        }
        for (final symbol in symbols) {
          await controller.updateSymbol(
              symbol, SymbolOptions(iconImage: image));
        }
      }).catchError((Object error) {
        if (mounted) unawaited(_refreshMapMarkers());
      });
      await _mapUpdates;
    } catch (error) {
      _showSnack(ui(context, '{v0}', [error]));
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  Future<void> _openGoogleMaps(StudyAreaSite? site) async {
    final target = _controller?.cameraPosition?.target ??
        (_currentPos == null
            ? const LatLng(23.8103, 90.4125)
            : LatLng(_currentPos!.latitude, _currentPos!.longitude));
    final uri = site == null
        ? GoogleMapsLinks.area(target.latitude, target.longitude,
            zoom: _controller?.cameraPosition?.zoom ?? 16)
        : GoogleMapsLinks.site(site.latitude, site.longitude);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showSnack(ui(context, 'Could not open Google Maps.'));
      }
    } catch (error) {
      _showSnack(ui(context, 'Could not open Google Maps: {v0}', [error]));
    }
  }

  Future<void> _openTimeline(StudyAreaSite site) async {
    if (_workspace == null) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SiteTimelineScreen(
                database: _database,
                store: _store,
                projectId: _workspace!.project.id,
                site: site,
                workflow: widget.workflow,
                collectionRound: _round,
                storedForm: _workspace!.form)));
    if (mounted) await _loadSites();
  }

  String _statusLabel(StudyAreaStatus status) => ui(
      context,
      switch (status) {
        StudyAreaStatus.completed =>
          widget.workflow == StudyWorkflow.recurring ? 'Collected' : 'Done',
        StudyAreaStatus.needsReview => 'Needs review',
        _ => widget.workflow == StudyWorkflow.recurring
            ? 'Not collected'
            : 'Pending',
      });
  Color _statusColor(StudyAreaStatus status) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      StudyAreaStatus.completed =>
        dark ? Colors.green.shade300 : Colors.green.shade800,
      StudyAreaStatus.needsReview =>
        dark ? Colors.amber.shade300 : Colors.amber.shade900,
      _ => dark ? Colors.red.shade300 : Colors.red.shade800,
    };
  }

  Widget _collectionStatusAction(StudyAreaSite site, StudyAreaStatus target,
          IconData icon, String label, String tooltip) =>
      Tooltip(
          message: ui(context, tooltip),
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: _statusColor(target),
                  backgroundColor: _status(site) == target
                      ? _statusColor(target).withOpacity(.12)
                      : null,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
              onPressed:
                  _statusBusy ? null : () => _setCollectionStatus(site, target),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 20),
                const SizedBox(height: 4),
                Text(ui(context, label), textAlign: TextAlign.center),
              ])));

  Widget _verificationAction(
          String label, IconData icon, FutureOr<void> Function() action) =>
      OutlinedButton(
          onPressed: _statusBusy
              ? null
              : () async {
                  setState(() => _statusBusy = true);
                  try {
                    await action();
                  } finally {
                    if (mounted) setState(() => _statusBusy = false);
                  }
                },
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(ui(context, label), textAlign: TextAlign.center),
          ]));

  Future<void> _setVerificationStatus(
      StudyAreaSite site, StudyAreaStatus status) async {
    final updated = site.revised(
        latitude: site.latitude,
        longitude: site.longitude,
        attributes: Map.from(site.attributes),
        status: status,
        changeNote: status == StudyAreaStatus.pending
            ? 'Pending verification'
            : 'Needs review');
    await _saveVerificationUpdate(updated,
        successMessage: ui(context, status.label));
  }

  Widget _compactSelectedPanel() {
    final site = _selectedSite!;
    final status = _status(site);
    return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Align(
                            key: ValueKey(site.id),
                            alignment: Alignment.centerLeft,
                            child: Text(site.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700))))),
                IconButton.filledTonal(
                    tooltip: ui(context, 'Open in Google Maps'),
                    onPressed: () => _openGoogleMaps(site),
                    icon: const Icon(Icons.open_in_new_rounded)),
                IconButton(
                    tooltip: ui(context, 'Close feature'),
                    onPressed: () => setState(() => _selectedSite = null),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded))
              ]),
              Row(children: [
                Icon(
                    status == StudyAreaStatus.needsReview
                        ? Icons.flag_rounded
                        : status == StudyAreaStatus.completed
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                    size: 16,
                    color: _statusColor(status)),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(
                        _collection
                            ? _statusLabel(status)
                            : ui(context, status.label),
                        style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w600))),
                if (_statusBusy)
                  const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)))
              ]),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                        onPressed: _statusBusy
                            ? null
                            : () => _openCollectionForm(site),
                        icon: const Icon(Icons.assignment_outlined, size: 20),
                        label: Text(ui(
                            context,
                            _collection
                                ? (_workspace?.form == null
                                    ? 'Site observation'
                                    : 'Fill questionnaire')
                                : 'Verify with questionnaire'))),
                    IconButton.filledTonal(
                        tooltip: ui(context, 'Site timeline'),
                        onPressed: () => _openTimeline(site),
                        icon: const Icon(Icons.history_rounded)),
                    IconButton.filledTonal(
                        tooltip: ui(context, 'Center on site'),
                        onPressed: () => _controller?.animateCamera(
                            CameraUpdate.newLatLng(
                                LatLng(site.latitude, site.longitude))),
                        icon: const Icon(Icons.center_focus_strong_rounded)),
                    if (_collection)
                      SizedBox(
                          width: double.infinity,
                          child: ResponsiveGrid(
                              minChildWidth: 100,
                              maxColumns: 3,
                              children: [
                                if (widget.workflow == StudyWorkflow.visits ||
                                    !_requirements.questionnaire)
                                  _collectionStatusAction(
                                      site,
                                      StudyAreaStatus.completed,
                                      Icons.check_circle_outline,
                                      'Done',
                                      'Mark done'),
                                _collectionStatusAction(
                                    site,
                                    StudyAreaStatus.pending,
                                    Icons.radio_button_unchecked,
                                    widget.workflow == StudyWorkflow.recurring
                                        ? 'Not collected'
                                        : 'Pending',
                                    widget.workflow == StudyWorkflow.recurring
                                        ? 'Mark not collected'
                                        : 'Mark undone'),
                                _collectionStatusAction(
                                    site,
                                    StudyAreaStatus.needsReview,
                                    Icons.flag_outlined,
                                    'Needs review',
                                    'Needs review'),
                              ]))
                    else
                      SizedBox(
                          width: double.infinity,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            ResponsiveGrid(
                                minChildWidth: 100,
                                maxColumns: 3,
                                children: [
                                  _verificationAction(
                                      'Unchanged / Done',
                                      Icons.check_circle_outline,
                                      () => _markUnchanged(site)),
                                  _verificationAction(
                                      'Pending',
                                      Icons.radio_button_unchecked,
                                      () => _setVerificationStatus(
                                          site, StudyAreaStatus.pending)),
                                  _verificationAction(
                                      'Needs review',
                                      Icons.flag_outlined,
                                      () => _setVerificationStatus(
                                          site, StudyAreaStatus.needsReview)),
                                ]),
                            const SizedBox(height: 8),
                            ResponsiveGrid(
                                minChildWidth: 100,
                                maxColumns: 3,
                                children: [
                                  _verificationAction(
                                      'Location changed',
                                      Icons.edit_location_alt_outlined,
                                      () => _beginMove(site)),
                                  _verificationAction(
                                      'Edit feature',
                                      Icons.edit_outlined,
                                      () => _editSite(site)),
                                  _verificationAction(
                                      'Delete',
                                      Icons.delete_outline,
                                      () => _deleteSite(site)),
                                ]),
                          ]))
                  ]),
            ]));
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    List<StudyAreaSite> sites;
    try {
      if (_workspace != null && !widget.viewOnly) {
        await ProjectVectorLayerService(_database)
            .ensureStudySites(_workspace!.project, _workspace!.layerId, _store);
      }
      if (_workspace != null)
        _requirements = await WorkflowRequirementsService(_database)
            .get(_workspace!.project.id, widget.workflow);
      sites = await _store.loadSites();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(ui(context,
            'Cannot load study area: {v0}. Stored data was preserved.', [e]));
      }
      return;
    }
    try {
      _referenceLayers = _workspace == null || widget.viewOnly
          ? []
          : await ProjectVectorLayerService(_database)
              .load(_workspace!.project.id);
    } catch (_) {
      _referenceLayers = [];
    }
    final styleKey =
        'study_category:${_workspace?.project.externalId}:${_workspace?.layerId}';
    if (_categoryWorkspaceKey != styleKey) {
      _categoryWorkspaceKey = styleKey;
      final saved =
          widget.viewOnly ? null : await _database.getSetting(styleKey);
      try {
        _categoryStyle = saved == null
            ? StudyCategoryStyle()
            : StudyCategoryStyle.fromJson(jsonDecode(saved));
      } catch (_) {
        _categoryStyle = StudyCategoryStyle();
      }
    }
    if (_collection && _workspace != null) {
      if (widget.workflow == StudyWorkflow.recurring &&
          (_round == null || _round!.layerId != _workspace!.layerId)) {
        final rounds = await ProjectWorkspaceService(_database)
            .rounds(_workspace!.project.id, _workspace!.layerId);
        _round = rounds.lastOrNull;
      }
      _collectionStatuses =
          widget.workflow == StudyWorkflow.recurring && _round == null
              ? {}
              : await StudyCollectionService(_database).statuses(
                  _workspace!.project.id,
                  _workspace!.layerId,
                  widget.workflow,
                  _round);
    }
    if (!mounted) return;
    setState(() {
      _sites = widget.viewOnly
          ? sites
          : _workspace == null
              ? []
              : sites
                  .where((site) =>
                      GuidedVisitService.belongsToProject(
                          site, _workspace!.project) &&
                      site.layerId == _workspace!.layerId)
                  .toList();
      if (_selectedSite == null && widget.initialSelectedSiteId != null) {
        _selectedSite = _sites
            .where((s) => s.id == widget.initialSelectedSiteId)
            .firstOrNull;
      }
      _recountStatuses();
      _isLoading = false;
    });
    if (_styleReady) _refreshMapMarkers();
  }

  Future<void> _loadOperator() async {
    final name = (await _database.getSetting('user_name'))?.trim();
    if (mounted)
      setState(() => _fieldworker =
          name == null || name.isEmpty ? 'Local fieldworker' : name);
  }

  void _showHistory(StudyAreaSite site) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(ui(context, 'History: {v0}', [site.displayName])),
                content: SizedBox(
                    width: 520,
                    height: 450,
                    child: site.history.isEmpty
                        ? Text(ui(context,
                            'No recorded changes yet. Imported baseline is preserved when the first edit is saved.'))
                        : ListView(
                            children: site.history.reversed
                                .map((revision) => ExpansionTile(
                                        title: Text(
                                            '${revision.action} • ${revision.author}'),
                                        subtitle: Text(
                                            '${revision.timestamp.toLocal()}${revision.visitId == null ? '' : '\nVisit: ${revision.visitId}'}'),
                                        children: [
                                          if (revision.before != null) ...[
                                            Text(ui(context, 'Before'),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            SelectableText(
                                                const JsonEncoder.withIndent(
                                                        '  ')
                                                    .convert(revision.before))
                                          ],
                                          Text(ui(context, 'After'),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          SelectableText(
                                              const JsonEncoder.withIndent('  ')
                                                  .convert(revision.after)),
                                          if (revision.sessionId != null)
                                            Text(ui(
                                                context,
                                                'Survey response: {v0}',
                                                [revision.sessionId])),
                                          if (revision.photoPath != null)
                                            Text(ui(context, 'Photo: {v0}',
                                                [revision.photoPath]))
                                        ]))
                                .toList())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(ui(context, 'Close')))
                ]));
  }

  Future<void> _startLocation() async {
    final granted = await _locationService.ensurePermission();
    if (!granted || !mounted) return;
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final firstFix = _currentPos == null;
      _currentPos = pos;
      if (firstFix) setState(() {});
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    if (widget.database == null) _database.close();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onFeatureTapped.add(_onFeatureTapped);
  }

  Uint8List _markerImage(StudyAreaStatus status, String fillHex) {
    final image = img.Image(width: 44, height: 44, numChannels: 4);
    final fill = int.parse(fillHex.substring(1), radix: 16);
    final fillR = (fill >> 16) & 255,
        fillG = (fill >> 8) & 255,
        fillB = fill & 255;
    final borderHex = switch (status.verificationStatus) {
      StudyAreaStatus.pending => '#E53935',
      StudyAreaStatus.completed => '#2E7D32',
      StudyAreaStatus.needsReview => '#F9A825',
      _ => '#616161',
    };
    final border = int.parse(borderHex.substring(1), radix: 16);
    final borderR = (border >> 16) & 255,
        borderG = (border >> 8) & 255,
        borderB = border & 255;
    bool inside(double x, double y) {
      switch (status.verificationStatus) {
        case StudyAreaStatus.pending:
          final dx = x - 22, dy = y - 22;
          return dx * dx + dy * dy <= 19 * 19;
        case StudyAreaStatus.completed:
          return x >= 5 && x <= 39 && y >= 5 && y <= 39;
        case StudyAreaStatus.needsReview:
          final a = (22.0, 3.0), b = (41.0, 39.0), c = (3.0, 39.0);
          final d1 = (x - b.$1) * (a.$2 - b.$2) - (a.$1 - b.$1) * (y - b.$2);
          final d2 = (x - c.$1) * (b.$2 - c.$2) - (b.$1 - c.$1) * (y - c.$2);
          final d3 = (x - a.$1) * (c.$2 - a.$2) - (c.$1 - a.$1) * (y - a.$2);
          return !((d1 < 0 || d2 < 0 || d3 < 0) &&
              (d1 > 0 || d2 > 0 || d3 > 0));
        default:
          return false;
      }
    }

    bool borderPixel(double x, double y) {
      if (!inside(x, y)) return false;
      switch (status.verificationStatus) {
        case StudyAreaStatus.pending:
          final dx = x - 22, dy = y - 22;
          final d = dx * dx + dy * dy;
          return d >= 16 * 16;
        case StudyAreaStatus.completed:
          return x < 9 || x > 35 || y < 9 || y > 35;
        case StudyAreaStatus.needsReview:
          return !inside(x, y + 3) ||
              !inside(x, y - 3) ||
              !inside(x + 3, y) ||
              !inside(x - 3, y);
        default:
          return false;
      }
    }

    for (var y = 0; y < 44; y++) {
      for (var x = 0; x < 44; x++) {
        if (borderPixel(x.toDouble(), y.toDouble())) {
          image.setPixelRgba(x, y, borderR, borderG, borderB, 255);
        } else if (inside(x.toDouble(), y.toDouble())) {
          image.setPixelRgba(x, y, fillR, fillG, fillB, 255);
        }
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  Future<void> _markUnchanged(StudyAreaSite site) async {
    final updated = site.revised(
        latitude: site.latitude,
        longitude: site.longitude,
        attributes: Map.from(site.attributes),
        status: StudyAreaStatus.verified,
        changeNote: 'Location unchanged');
    await _saveVerificationUpdate(updated, successMessage: 'Marked unchanged');
  }

  Future<void> _saveVerificationUpdate(StudyAreaSite updated,
      {required String successMessage}) async {
    final workspace = _workspace;
    if (updated.projectId == null && workspace != null) {
      // Older imports can be matched to the open project by its external ID
      // while lacking the local database ID required by the sync outbox.
      updated.projectId = workspace.project.id;
    }
    if (updated.projectExternalId == null) {
      updated.projectExternalId = workspace?.project.externalId;
    }
    if (updated.layerId.isEmpty && workspace != null) {
      updated.layerId = workspace.layerId;
    }
    try {
      await _store.updateSite(updated,
          expectedRevision: updated.revision,
          expectedRevisionId: updated.revisionToken,
          author: _fieldworker);
      await StudyAreaOutboxService(_database).enqueue(updated, _fieldworker);
      await _loadSites();
      if (mounted) {
        setState(() => _selectedSite =
            _sites.where((s) => s.id == updated.id).firstOrNull);
        _showSnack(successMessage);
      }
    } on StudyAreaConflict {
      await _loadSites();
      if (mounted) {
        setState(() => _selectedSite =
            _sites.where((site) => site.id == updated.id).firstOrNull);
      }
      _showSnack(ui(context,
          'This feature changed elsewhere. Reopen it and review the latest version.'));
    } catch (error) {
      _showSnack(ui(context, 'Could not save the feature: {v0}', [error]));
    }
  }

  void _beginMove(StudyAreaSite site) {
    if (site.currentGeometry['type'] != 'Point') {
      _showSnack(ui(context,
          'Move is available for points. Use Redraw geometry for lines and areas.'));
      return;
    }
    setState(() {
      _movingSite = site;
      _movingCoordinates = LatLng(site.latitude, site.longitude);
      _selectedSite = null;
      _routeSiteId = null;
      _routeCoordinates = null;
      _routeDistanceM = null;
    });
    _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(site.latitude, site.longitude), 18));
    _refreshMapMarkers();
  }

  void _cancelMove() {
    final site = _movingSite;
    setState(() {
      _movingSite = null;
      _movingCoordinates = null;
      _selectedSite = site;
    });
    _refreshMapMarkers();
  }

  Future<void> _saveMove() async {
    final site = _movingSite, coordinates = _movingCoordinates;
    if (site == null || coordinates == null) return;
    final updated = site.revised(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        attributes: Map.from(site.attributes),
        status: StudyAreaStatus.updated,
        changeNote: 'Location changed');
    setState(() {
      _movingSite = null;
      _movingCoordinates = null;
    });
    await _saveVerificationUpdate(updated, successMessage: 'Location updated');
    await _refreshMapMarkers();
  }

  Future<void> _showRoadRoute(StudyAreaSite site) async {
    final position = _currentPos, workspace = _workspace;
    if (position == null || workspace == null) {
      _showSnack(position == null
          ? ui(context, 'Waiting for a GPS fix')
          : ui(context, 'Select a project first'));
      return;
    }
    try {
      final layers =
          await ProjectVectorLayerService(_database).load(workspace.project.id);
      final route = RoadRoutingService.shortestRoute(
          layers: layers,
          startLatitude: position.latitude,
          startLongitude: position.longitude,
          endLatitude: site.latitude,
          endLongitude: site.longitude);
      if (route == null) {
        _showSnack(ui(context,
            'No connected road route found. Add a road layer in Project settings.'));
        return;
      }
      setState(() {
        _routeSiteId = site.id;
        _routeDistanceM = route.distanceMeters;
        _routeCoordinates = route.coordinates
            .map((point) => LatLng(point[1], point[0]))
            .toList();
      });
      await _refreshMapMarkers();
      if (_routeCoordinates != null && _routeCoordinates!.isNotEmpty) {
        _controller?.animateCamera(CameraUpdate.newLatLngBounds(
            _boundsOf(_routeCoordinates!),
            left: 48,
            top: 200,
            right: 48,
            bottom: 300));
      }
    } catch (error) {
      _showSnack(
          ui(context, 'Could not calculate a road route: {v0}', [error]));
    }
  }

  LatLngBounds _boundsOf(List<LatLng> points) {
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final point in points.skip(1)) {
      south = math.min(south, point.latitude);
      north = math.max(north, point.latitude);
      west = math.min(west, point.longitude);
      east = math.max(east, point.longitude);
    }
    return LatLngBounds(
        southwest: LatLng(south, west), northeast: LatLng(north, east));
  }

  Future<void> _manageProjectLayers() async {
    final workspace = _workspace;
    if (workspace == null) {
      _showSnack(ui(context, 'Select a project first'));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProjectVectorLayersScreen(
            database: _database,
            projectId: workspace.project.id,
            workflow: widget.workflow)));
    if (!mounted) return;
    _workspace = await ProjectWorkspaceService(_database)
        .load(workspace.project.id, workflow: widget.workflow);
    await _loadSites();
  }

  void _onStyleLoaded() async {
    _styleReady = true;
    _markerImages.clear();
    final controller = _controller;
    if (controller != null) {
      await controller.setSymbolIconAllowOverlap(true);
      await controller.setSymbolIconIgnorePlacement(true);
    }
    _refreshMapMarkers();
  }

  Future<void> _mapUpdates = Future.value();
  int _mapRenderGeneration = 0;

  Future<void> _refreshMapMarkers() {
    final request = ++_mapRenderGeneration;
    _mapUpdates = _mapUpdates.then((_) async {
      if (!mounted || request != _mapRenderGeneration) return;
      await _renderMapMarkers();
    }).catchError((Object error) {
      _showSnack(ui(context,
          'Map preview failed: {v0}. Stored features are retained.', [error]));
    });
    return _mapUpdates;
  }

  Future<void> _renderMapMarkers() async {
    final controller = _controller;
    if (!mounted || !_styleReady || controller == null) return;
    // One platform operation per annotation type keeps large imported files
    // responsive when a point is selected or its status changes.
    await controller.clearCircles();
    await controller.clearSymbols();
    await controller.clearLines();
    await controller.clearFills();
    _circles.clear();
    _symbols.clear();
    _lines.clear();
    _fills.clear();
    _referenceCircles.clear();
    _referenceLines.clear();
    _referenceFills.clear();
    _referenceSymbols.clear();
    _routeLine = null;
    _categoryStyle.categories(_sites);
    List<LatLng> points(dynamic values) => (values as List)
        .map((v) => LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble()))
        .toList();
    for (final layer
        in _referenceLayers.where((item) => item['visible'] != false)) {
      final modes = layer['workflows'] as List?;
      if (modes != null && !modes.contains(widget.workflow.name)) continue;
      // Reference boundaries remain visible while collecting another layer.
      // The active layer already has editable annotations.
      if (!['road', 'reference'].contains(layer['role'])) continue;
      final batchId = layer['import_batch_id']?.toString();
      if ((batchId != null && layer['role'] == 'road') ||
          ProjectVectorLayerService.studyLayerId(layer) == _workspace?.layerId)
        continue;
      final color = (layer['color'] ?? '#467ca1').toString();
      final opacity =
          ((layer['opacity'] as num?)?.toDouble() ?? 0.8).clamp(0.0, 1.0);
      final circles = <CircleOptions>[];
      final lines = <LineOptions>[];
      final fills = <FillOptions>[];
      for (final feature in layer['features'] as List? ?? const []) {
        if (feature is! Map || feature['geometry'] is! Map) continue;
        final geometry = feature['geometry'] as Map;
        final coords = geometry['coordinates'];
        try {
          switch (geometry['type']) {
            case 'LineString':
              lines.add(LineOptions(
                  geometry: points(coords),
                  lineColor: color,
                  lineOpacity: opacity,
                  lineWidth: 2));
              break;
            case 'MultiLineString':
              for (final line in coords as List)
                lines.add(LineOptions(
                    geometry: points(line),
                    lineColor: color,
                    lineOpacity: opacity,
                    lineWidth: 2));
              break;
            case 'Polygon':
              fills.add(FillOptions(
                  geometry: (coords as List).map(points).toList(),
                  fillColor: color,
                  fillOpacity: opacity * 0.2,
                  fillOutlineColor: color));
              break;
            case 'MultiPolygon':
              for (final polygon in coords as List)
                fills.add(FillOptions(
                    geometry: (polygon as List).map(points).toList(),
                    fillColor: color,
                    fillOpacity: opacity * 0.2,
                    fillOutlineColor: color));
              break;
            case 'Point':
              circles.add(CircleOptions(
                  geometry: LatLng((coords[1] as num).toDouble(),
                      (coords[0] as num).toDouble()),
                  circleRadius: 4,
                  circleColor: color,
                  circleOpacity: opacity,
                  circleStrokeColor: '#FFFFFF',
                  circleStrokeWidth: 1));
              break;
            case 'MultiPoint':
              for (final point in coords as List)
                circles.add(CircleOptions(
                    geometry: LatLng((point[1] as num).toDouble(),
                        (point[0] as num).toDouble()),
                    circleRadius: 4,
                    circleColor: color,
                    circleOpacity: opacity,
                    circleStrokeColor: '#FFFFFF',
                    circleStrokeWidth: 1));
              break;
          }
        } catch (_) {}
      }
      if (circles.isNotEmpty) {
        _referenceCircles.addAll(await controller.addCircles(circles));
      }
      if (lines.isNotEmpty) {
        _referenceLines.addAll(await controller.addLines(lines));
      }
      if (fills.isNotEmpty) {
        _referenceFills.addAll(await controller.addFills(fills));
      }
    }
    final symbolOptions = <SymbolOptions>[];
    final symbolData = <Map<String, dynamic>>[];
    final lineOptions = <LineOptions>[];
    final lineData = <Map<String, dynamic>>[];
    final fillOptions = <FillOptions>[];
    final fillData = <Map<String, dynamic>>[];
    for (final site in _sites.where((s) =>
        (_movingSite == null || s.id != _movingSite!.id) &&
        !_referenceLayers.any((layer) =>
            layer['visible'] == false &&
            (layer['import_batch_id'] ?? layer['id']) == s.importBatchId) &&
        (_filter == null || _status(s) == _filter) &&
        _categoryStyle.visible(s))) {
      try {
        final color = _categoryStyle.color(site);
        final data = {'site_id': site.id};
        Future<void> drawPoint(double lon, double lat) async {
          final status = _status(site);
          final colorHex = _collection
              ? switch (status) {
                  StudyAreaStatus.completed => '#2E7D32',
                  StudyAreaStatus.needsReview => '#F9A825',
                  _ => '#E53935'
                }
              : _categoryStyle.color(site);
          final imageName = 'mapbanai_${status.name}_${colorHex.substring(1)}';
          if (!_markerImages.contains(imageName)) {
            await controller.addImage(
                imageName, _markerImage(status, colorHex));
            _markerImages.add(imageName);
          }
          symbolOptions.add(SymbolOptions(
            geometry: LatLng(lat, lon),
            iconImage: imageName,
            iconSize: _categoryStyle.radius / 12,
            iconAnchor: 'center',
          ));
          symbolData.add(data);
        }

        Future<void> drawGeometry(Map geom) async {
          final coords = geom['coordinates'];
          if (geom['type'] == 'GeometryCollection') {
            for (final child in geom['geometries'] as List) {
              await drawGeometry(child as Map);
            }
          } else if (geom['type'] == 'Point' || geom['type'] == 'MultiPoint') {
            final vertices =
                geom['type'] == 'Point' ? [coords] : coords as List;
            for (final vertex in vertices) {
              await drawPoint(
                  (vertex[0] as num).toDouble(), (vertex[1] as num).toDouble());
            }
          } else if (geom['type'] == 'LineString' ||
              geom['type'] == 'MultiLineString') {
            final lines =
                geom['type'] == 'LineString' ? [coords] : coords as List;
            for (final line in lines) {
              lineOptions.add(LineOptions(
                  geometry: points(line), lineColor: color, lineWidth: 3));
              lineData.add(data);
            }
          } else if (geom['type'] == 'Polygon' ||
              geom['type'] == 'MultiPolygon') {
            final polygons =
                geom['type'] == 'Polygon' ? [coords] : coords as List;
            for (final polygon in polygons) {
              fillOptions.add(FillOptions(
                  geometry: (polygon as List).map(points).toList(),
                  fillColor: color,
                  fillOpacity: 0.25,
                  fillOutlineColor: color));
              fillData.add(data);
            }
          }
        }

        await drawGeometry(site.currentGeometry);
        if (site.currentGeometry['type'] != 'Point' &&
            site.currentGeometry['type'] != 'MultiPoint') {
          await drawPoint(site.longitude, site.latitude);
        }
      } catch (_) {}
    }
    if (_drawType != null && _draft.length >= 2) {
      lineOptions.add(LineOptions(geometry: [
        ..._draft,
        if (_drawType == 'Polygon' && _draft.length >= 3) _draft.first
      ], lineColor: '#FF6F00', lineWidth: 4));
    }
    final moving = _movingCoordinates;
    if (_movingSite != null && moving != null) {
      final imageName = 'mapbanai_moving_marker';
      if (!_markerImages.contains(imageName)) {
        await controller.addImage(
            imageName, _markerImage(StudyAreaStatus.completed, '#1565C0'));
      }
      symbolOptions.add(SymbolOptions(
        geometry: moving,
        iconImage: imageName,
        iconSize: 0.65,
        iconAnchor: 'center',
      ));
      symbolData.add({'site_id': _movingSite!.id});
    }
    if (symbolOptions.isNotEmpty) {
      _symbols.addAll(await controller.addSymbols(symbolOptions, symbolData));
    }
    if (lineOptions.isNotEmpty) {
      _lines.addAll(await controller.addLines(lineOptions, lineData));
    }
    if (fillOptions.isNotEmpty) {
      _fills.addAll(await controller.addFills(fillOptions, fillData));
    }
    if (_routeSiteId != null &&
        _routeLine == null &&
        _routeCoordinates != null) {
      _routeLine = await controller.addLine(LineOptions(
          geometry: _routeCoordinates!, lineColor: '#1565C0', lineWidth: 5));
    }
    if (mounted) setState(() {});
    // Auto fit bounds if sites exist and no selection.
    if (_sites.isNotEmpty &&
        _selectedSite == null &&
        _drawType == null &&
        _movingSite == null) {
      final workspace =
          '${_workspace?.project.id}:${_workspace?.layerId}:${_sites.length}';
      if (_fittedWorkspace != workspace) {
        _fittedWorkspace = workspace;
        _fitBounds();
      }
    }
  }

  void _fitBounds() {
    if (_sites.isEmpty || _controller == null) return;
    if (_sites.length == 1) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(_sites.first.latitude, _sites.first.longitude), 15),
      );
      return;
    }
    double minLat = _sites.first.latitude;
    double maxLat = _sites.first.latitude;
    double minLon = _sites.first.longitude;
    double maxLon = _sites.first.longitude;
    for (final s in _sites) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLon) minLon = s.longitude;
      if (s.longitude > maxLon) maxLon = s.longitude;
    }
    if (minLat == maxLat) {
      minLat -= 0.0001;
      maxLat += 0.0001;
    }
    if (minLon == maxLon) {
      minLon -= 0.0001;
      maxLon += 0.0001;
    }
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
              southwest: LatLng(minLat, minLon),
              northeast: LatLng(maxLat, maxLon)),
          left: 32,
          top: 100,
          right: 32,
          bottom: 80),
    );
  }

  void _onFeatureTapped(dynamic point, LatLng coordinates, String id,
      String layerId, Annotation? annotation) {
    if (_drawType != null) return;
    if (annotation != null) {
      final data = switch (annotation) {
        Circle c => c.data,
        Symbol s => s.data,
        Line l => l.data,
        Fill f => f.data,
        _ => null
      };
      final siteId = data?['site_id']?.toString();
      if (siteId == null) return;
      final site = _sites.where((s) => s.id == siteId).firstOrNull;
      if (site == null) return;
      unawaited(_clearRoute());
      setState(() {
        _selectedSite = site;
        _movingSite = null;
        _routeSiteId = null;
        _routeDistanceM = null;
        _routeCoordinates = null;
      });
    }
  }

  Future<void> _clearRoute() async {
    final line = _routeLine;
    _routeLine = null;
    _routeSiteId = null;
    _routeDistanceM = null;
    _routeCoordinates = null;
    if (line != null && _controller != null && _styleReady) {
      try {
        await _controller!.removeLine(line);
      } catch (_) {/* Style changed. */}
    }
  }

  Future<void> _importSites({String? pathOverride}) async {
    if (_workspace == null || widget.viewOnly) {
      _showSnack(ui(context, 'Select a project first'));
      return;
    }
    final result = pathOverride == null
        ? await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
            withData: false,
          )
        : null;
    final path = pathOverride ??
        result?.files
            .where((file) => SpatialFileImport.supports(file.name))
            .firstOrNull
            ?.path;
    if (path == null) return;
    final ioFile = File(path);
    if (!SpatialFileImport.supports(path)) {
      _showSnack(ui(context,
          'Select GeoJSON, GeoPackage, SHP/ZIP, CSV, Excel or KML/KMZ.'));
      return;
    }
    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loadingDialogOpen = true;
    try {
      final workspace = _workspace!;
      final fileBytes = Uint8List.fromList(await ioFile.readAsBytes());
      final layerInputs = <String, Uint8List>{};
      if (result != null) {
        for (final file in result.files) {
          if (file.size > ProjectVectorLayerService.maxBytes) {
            throw const FormatException(
                'Select files totalling at most 64 MB.');
          }
          if (layerInputs.containsKey(file.name))
            throw const FormatException(
                'Duplicate filenames. Use separate ZIP files.');
          layerInputs[file.name] =
              file.bytes ?? await File(file.path!).readAsBytes();
        }
      } else {
        layerInputs[p.basename(path)] = fileBytes;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      loadingDialogOpen = false;
      if (!await resolveShapefileCompanions(context, layerInputs,
          result?.files.map((file) => file.path).whereType<String>() ?? [path],
          identifiers: result?.files
                  .map((file) => file.identifier)
                  .whereType<String>() ??
              const [])) return;
      if (!mounted) return;
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()));
      loadingDialogOpen = true;
      final batchId = const Uuid().v4();
      List<Map<String, dynamic>> projectLayers;
      List<StudyAreaSite> imported;
      try {
        projectLayers = await ProjectVectorLayerService.parseFiles(layerInputs);
        imported = [];
        for (final layer in projectLayers) {
          final parsed = StudyAreaService.parseGeoJson(jsonEncode(
              {'type': 'FeatureCollection', 'features': layer['features']}));
          for (final site in parsed) {
            imported.add(projectLayers.length == 1
                ? site
                : StudyAreaSite.fromJson({
                    ...site.toJson(),
                    'id': '${layer['name']}:${site.id}',
                    'attributes': {
                      ...site.attributes,
                      'layer': site.attributes['layer'] ?? layer['name']
                    }
                  }));
          }
        }
      } on FormatException {
        if (!['.kml', '.kmz'].contains(p.extension(path).toLowerCase())) {
          rethrow;
        }
        imported = await SpatialFileImport.read(ioFile);
        projectLayers = [
          {
            'id': const Uuid().v4(),
            'name': p.basenameWithoutExtension(path),
            'visible': true,
            'color': '#467ca1',
            'opacity': 0.8,
            'role': 'study_area',
            'features': imported
                .map((site) => <String, dynamic>{
                      'type': 'Feature',
                      'geometry': site.currentGeometry,
                      'properties': site.sourceProperties ?? site.attributes,
                    })
                .toList(),
            'source_files': [
              {
                'name': p.basename(path),
                'bytes_base64': base64Encode(fileBytes)
              }
            ],
          }
        ];
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      loadingDialogOpen = false;
      if (imported.isEmpty) {
        _showSnack(ui(context,
            'No sites found in file. Check format and lat/lon columns.'));
        return;
      }
      final warnings = projectLayers
          .map((layer) => layer['warning']?.toString() ?? '')
          .where((warning) => warning.isNotEmpty)
          .toSet();
      if (warnings.isNotEmpty) {
        final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                    title: Text(ui(context, 'Check imported files')),
                    content: Text(warnings.join('\n\n')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(ui(context, 'Cancel'))),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(ui(context, 'Continue')))
                    ]));
        if (proceed != true) return;
      }
      final fileName = p.basename(path);
      for (final layer in projectLayers) {
        layer['role'] = 'study_area';
        layer['workflows'] = [widget.workflow.name];
        layer['import_batch_id'] = batchId;
        layer['import_file_name'] = fileName;
        layer['study_layer_id'] = workspace.layerId;
      }
      final existing = await _store.loadSites();
      for (var i = 0; i < imported.length; i++) {
        var site = imported[i];
        if (site.projectExternalId != null &&
            site.projectExternalId != workspace.project.externalId) {
          throw const FormatException(
              'This file belongs to another project. Select that project before importing.');
        }
        if (site.projectExternalId != null &&
            site.layerId != workspace.layerId) {
          throw const FormatException(
              'This file belongs to another study layer. Select that layer before importing.');
        }
        if (site.projectExternalId == null) {
          final collision = existing.any((other) =>
              other.id == site.id &&
              (!GuidedVisitService.belongsToProject(other, workspace.project) ||
                  other.layerId != workspace.layerId));
          if (collision) {
            site = StudyAreaSite.fromJson({
              ...site.toJson(),
              'id':
                  '${workspace.project.externalId}:${workspace.layerId}:${site.id}'
            });
            imported[i] = site;
          }
        }
        site.projectId = workspace.project.id;
        site.projectExternalId = workspace.project.externalId;
        site.layerId = workspace.layerId;
        site.importBatchId = batchId;
        site.importFileName = fileName;
      }
      final preview = await _store.previewMerge(imported);
      if (!mounted) return;
      final choices = await showDialog<Map<String, StudyAreaMergeChoice>>(
          context: context,
          builder: (_) => StudyAreaMergeReviewDialog(preview: preview));
      if (choices == null) return;
      final vectorService = ProjectVectorLayerService(_database);
      var sourceOffset = 0;
      for (final layer in projectLayers) {
        final count = (layer['features'] as List).length;
        layer['study_site_ids'] = imported
            .skip(sourceOffset)
            .take(count)
            .map((site) => site.id)
            .toList();
        layer['study_source_project_id'] = workspace.project.externalId;
        sourceOffset += count;
      }
      final currentLayers = await vectorService.load(workspace.project.id);
      await vectorService
          .save(workspace.project.id, [...currentLayers, ...projectLayers]);
      StudyAreaMergeResult merged;
      try {
        merged = await _store.applyMerge(preview,
            resolutions: choices,
            author: _fieldworker,
            localProjectId: workspace.project.id);
      } catch (_) {
        await vectorService.save(workspace.project.id, currentLayers);
        rethrow;
      }
      final initializedKey =
          'project_vector_initialized_${workspace.project.id}';
      final initializedRaw = await _database.getSetting(initializedKey);
      final initialized = initializedRaw == null
          ? <String>{}
          : (jsonDecode(initializedRaw) as List)
              .map((id) => id.toString())
              .toSet();
      initialized.addAll(projectLayers.map((layer) => layer['id'].toString()));
      await _database.setSetting(
          initializedKey, jsonEncode(initialized.toList()));
      _workspace =
          await ProjectWorkspaceService(_database).load(workspace.project.id);
      await _loadSites();
      _showSnack(ui(
          context,
          'Imported {v0} new features, updated {v1}, kept {v2} local versions.',
          [merged.added, merged.updated, merged.kept]));
    } catch (e) {
      if (mounted && loadingDialogOpen) Navigator.of(context).pop();
      _showSnack(ui(context, 'Import failed: {v0}', [e]));
    }
  }

  Future<bool> _editSite(StudyAreaSite site) async {
    var draft = site;
    while (mounted) {
      var fillSurvey = false;
      final isNew = !_sites.any((existing) => existing.id == site.id);
      final updated = await showDialog<StudyAreaSite>(
          context: context,
          builder: (context) => _EditSiteDialog(
              site: draft,
              isNew: isNew,
              onSurveyChoice: (value) => fillSurvey = value));
      if (updated == null) return false;
      final schema = _workspace?.schema;
      final requiredSurvey =
          StudyFeaturePolicy.requiresSurvey(updated.status, isNew: isNew);
      if (requiredSurvey && schema == null) {
        _showSnack(ui(context,
            'New and updated features require a questionnaire. Select a survey form first.'));
        return false;
      }
      if (schema != null && (requiredSurvey || fillSurvey)) {
        final answers = await editFormAttributes(context,
            form: schema,
            username: _fieldworker,
            answers: FormAttributeService.prefill(
                schema, {...updated.attributes, ...updated.formAnswers},
                geometry: updated.currentGeometry));
        if (answers == null) return false;
        updated.formAnswers = answers;
        updated.formSnapshot = schema.toJson();
        for (final entry in answers.entries) {
          updated.attributes[entry.key] =
              entry.value is Map || entry.value is List
                  ? jsonEncode(entry.value)
                  : entry.value?.toString() ?? '';
        }
      }

      try {
        await _store.updateSite(updated,
            expectedRevision: site.revision,
            expectedRevisionId: site.revisionToken,
            author: _fieldworker);
      } on StudyAreaConflict {
        final preview = await _store.previewMerge([updated]);
        if (!mounted) return false;
        final choices = await showDialog<Map<String, StudyAreaMergeChoice>>(
            context: context,
            builder: (_) => StudyAreaMergeReviewDialog(preview: preview));
        if (choices == null) return false;
        try {
          await _store.applyMerge(preview,
              resolutions: choices, author: _fieldworker);
        } catch (e) {
          _showSnack(ui(context, 'Conflict resolution failed: {v0}', [e]));
          draft = updated;
          continue;
        }
        await _loadSites();
        if (!mounted) return true;
        setState(() =>
            _selectedSite = _sites.where((s) => s.id == site.id).firstOrNull);
        return true;
      } catch (e) {
        _showSnack(
            ui(context, 'Save failed: {v0}. Your edits are retained.', [e]));
        draft = updated;
        continue;
      }
      await StudyAreaOutboxService(_database).enqueue(updated, _fieldworker);
      await _loadSites();
      if (!mounted) return true;
      setState(() => _selectedSite = updated);
      _showSnack(ui(context, 'Feature saved'));
      return true;
    }
    return false;
  }

  void _startDrawing(String type, {StudyAreaSite? site}) {
    if (widget.viewOnly) return;
    if (_workspace == null) {
      _showSnack(ui(context, 'Select a project first'));
      return;
    }
    _draft.clear();
    if (site != null) {
      final coordinates = site.currentGeometry['coordinates'];
      final values =
          type == 'Polygon' ? (coordinates as List).first : coordinates;
      for (final value in values as List) {
        _draft.add(
            LatLng((value[1] as num).toDouble(), (value[0] as num).toDouble()));
      }
      if (type == 'Polygon' && _draft.length > 1 && _draft.first == _draft.last)
        _draft.removeLast();
    }
    setState(() {
      _drawType = type;
      _drawingSite = site;
      _selectedSite = null;
    });
    _refreshMapMarkers();
  }

  Future<void> _saveDrawing() async {
    final type = _drawType;
    if (type == null || _draft.length < (type == 'Polygon' ? 3 : 2)) {
      _showSnack(ui(
          context, 'Add at least {v0} vertices.', [type == 'Polygon' ? 3 : 2]));
      return;
    }
    final points = _draft.map((p) => [p.longitude, p.latitude]).toList();
    if (_draft.map((p) => '${p.longitude},${p.latitude}').toSet().length <
        (type == 'Polygon' ? 3 : 2)) {
      _showSnack(ui(context, 'Use distinct vertices.'));
      return;
    }
    if (type == 'Polygon') {
      var area = 0.0;
      for (var i = 0; i < points.length; i++) {
        final next = points[(i + 1) % points.length];
        area += points[i][0] * next[1] - next[0] * points[i][1];
      }
      if (area.abs() < 1e-12) {
        _showSnack(ui(context, 'Polygon vertices must enclose an area.'));
        return;
      }
      points.add(List<double>.from(points.first));
    }
    final geometry = <String, dynamic>{
      'type': type,
      'coordinates': type == 'Polygon'
          ? [
              points,
              if (_drawingSite?.currentGeometry['type'] == 'Polygon')
                ...(_drawingSite!.currentGeometry['coordinates'] as List)
                    .skip(1)
            ]
          : points
    };
    final previous = _drawingSite;
    final site = StudyAreaSite(
        id: previous?.id ?? 'new_${DateTime.now().microsecondsSinceEpoch}',
        latitude: _draft.first.latitude,
        longitude: _draft.first.longitude,
        geometry: geometry,
        attributes: previous == null
            ? {'name': 'New feature'}
            : Map.from(previous.attributes),
        sourceProperties: previous?.sourceProperties,
        revision: previous?.revision ?? 0,
        revisionId: previous?.revisionId,
        history: previous?.history,
        projectId: previous?.projectId ?? _workspace?.project.id,
        projectExternalId:
            previous?.projectExternalId ?? _workspace?.project.externalId,
        layerId: previous?.layerId ?? _workspace!.layerId,
        formAnswers: previous?.formAnswers,
        formSnapshot: previous?.formSnapshot,
        original: previous == null
            ? null
            : previous.original ??
                {
                  'geometry': previous.currentGeometry,
                  'attributes': Map.from(previous.attributes),
                  'status': previous.status.name
                },
        updatedAt: DateTime.now().toUtc(),
        changeNote: previous?.changeNote ?? '',
        status: previous == null
            ? StudyAreaStatus.newFeature
            : StudyAreaStatus.updated);
    final saved = await _editSite(site);
    if (!mounted || !saved) return;
    setState(() {
      _drawType = null;
      _drawingSite = null;
      _draft.clear();
    });
    _refreshMapMarkers();
  }

  Future<void> _addSurveyAtGps() async {
    final workspace = _workspace;
    final schema = workspace?.schema;
    if (workspace == null || schema == null) {
      _showSnack(ui(context, 'Select a project and survey form first.'));
      return;
    }
    final gps = _currentPos;
    if (gps == null ||
        DateTime.now().difference(gps.timestamp).inSeconds > 30) {
      _showSnack(ui(
          context, 'Wait for a fresh GPS location before recording a site.'));
      return;
    }
    final geometry = <String, dynamic>{
      'type': 'Point',
      'coordinates': [gps.longitude, gps.latitude]
    };
    final answers = await editFormAttributes(context,
        form: schema,
        username: _fieldworker,
        answers: FormAttributeService.prefill(schema, {}, geometry: geometry));
    if (answers == null || !mounted) return;
    final site = StudyAreaSite(
        id: 'new_${DateTime.now().microsecondsSinceEpoch}',
        latitude: gps.latitude,
        longitude: gps.longitude,
        geometry: geometry,
        status: StudyAreaStatus.newFeature,
        projectId: workspace.project.id,
        projectExternalId: workspace.project.externalId,
        layerId: workspace.layerId,
        formAnswers: answers,
        formSnapshot: schema.toJson(),
        attributes: {
          'name': 'New feature',
          'gps_accuracy_m': gps.accuracy.toString(),
          'gps_captured_at': gps.timestamp.toUtc().toIso8601String()
        });
    try {
      await _store.updateSite(site, author: _fieldworker);
      await StudyAreaOutboxService(_database).enqueue(site, _fieldworker);
      await _loadSites();
      if (mounted) setState(() => _selectedSite = site);
      _showSnack(ui(context, 'Survey feature saved'));
    } catch (e) {
      _showSnack(ui(context, 'Could not save feature: {v0}', [e]));
    }
  }

  Future<void> _addPointAtGps() async {
    if (_addingPoint || widget.viewOnly) return;
    if (_workspace == null) {
      _showSnack(ui(context, 'Select a project first'));
      return;
    }
    final gps = _currentPos;
    if (gps == null ||
        DateTime.now().difference(gps.timestamp).abs() >
            const Duration(seconds: 30) ||
        !gps.latitude.isFinite ||
        !gps.longitude.isFinite ||
        gps.latitude.abs() > 90 ||
        gps.longitude.abs() > 180) {
      _showSnack(ui(
          context, 'Wait for a fresh GPS location before recording a site.'));
      return;
    }
    setState(() => _addingPoint = true);
    try {
      await _loadOperator();
      if (!mounted) return;
      await _addSite(LatLng(gps.latitude, gps.longitude), gps: gps);
    } finally {
      if (mounted) setState(() => _addingPoint = false);
    }
  }

  Future<void> _addSite(LatLng coordinates, {Position? gps}) async {
    if (_workspace == null) {
      _showSnack(ui(context, 'Select a project first'));
      return;
    }
    final site = StudyAreaSite(
        id: 'new_${DateTime.now().microsecondsSinceEpoch}',
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        status: StudyAreaStatus.newFeature,
        projectId: _workspace?.project.id,
        projectExternalId: _workspace?.project.externalId,
        layerId: _workspace!.layerId,
        updatedAt: DateTime.now().toUtc(),
        attributes: {
          'name': 'New feature',
          if (gps != null) 'gps_accuracy_m': gps.accuracy.toString(),
          if (gps != null)
            'gps_captured_at': gps.timestamp.toUtc().toIso8601String()
        });
    await _editSite(site);
  }

  Future<void> _deleteSite(StudyAreaSite site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ui(context, 'Delete site')),
        content: Text(ui(context, 'Delete "{v0}"?', [site.displayName])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ui(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ui(context, 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final deletion = await _store.deleteSiteForSync(site, _fieldworker);
      try {
        await StudyAreaOutboxService(_database).enqueueDeletion(deletion);
      } catch (error) {
        // The durable journal is retried by Sync even if SQLite is unavailable.
        debugPrint('Deletion saved locally; outbox retry needed: $error');
      }
    } catch (error) {
      if (mounted)
        _showSnack(ui(context, 'Could not delete site: {v0}', [error]));
      return;
    }
    if (!mounted) return;
    setState(() => _selectedSite = null);
    await _loadSites();
    _showSnack(ui(context, 'Site deleted'));
  }

  Future<void> _exportSites() async {
    if (_sites.isEmpty) {
      _showSnack(ui(context, 'No sites to export'));
      return;
    }
    final format = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(ui(context, 'Export sites')),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'changes'),
              child: ListTile(
                  leading: const Icon(Icons.difference_outlined),
                  title: Text(ui(context, 'Changed features only (GeoJSON)')),
                  subtitle: Text(ui(
                      context,
                      '{v0} features, full history for team merge',
                      [_sites.where((s) => s.hasChanges).length])))),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'geojson'),
              child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text(ui(context, 'Updated map (GeoJSON)')),
                  subtitle: Text(ui(context,
                      'Full geometry, attributes and revision baseline')))),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'html'),
              child: ListTile(
                  leading: Icon(Icons.public),
                  title: Text(ui(context, 'Portable HTML map')),
                  subtitle: Text(
                      ui(context, 'View and filter features in a browser')))),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: ListTile(
              leading: Icon(Icons.table_chart_outlined),
              title: Text(ui(context, 'CSV')),
              subtitle: Text(ui(context, 'Excel-compatible CSV')),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'xlsx'),
            child: ListTile(
              leading: Icon(Icons.grid_on_outlined),
              title: Text(ui(context, 'Excel (XLSX)')),
              subtitle: Text(ui(context, 'Native Excel workbook')),
            ),
          ),
        ],
      ),
    );
    if (format == null) return;
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final dir = await getTemporaryDirectory();
      late File file;
      if (format == 'csv') {
        final csv = StudyAreaService.toCsv(_sites);
        file = File('${dir.path}/study_area_$stamp.csv');
        await file.writeAsString(csv, flush: true);
      } else if (format == 'geojson' ||
          format == 'html' ||
          format == 'changes') {
        file = File(
            '${dir.path}/study_area_${format == 'changes' ? 'changes_' : ''}$stamp.${format == 'changes' ? 'geojson' : format}');
        await file.writeAsString(
            format == 'geojson' || format == 'changes'
                ? StudyAreaService.toGeoJson(_sites,
                    changedOnly: format == 'changes')
                : await StudyAreaService.toHtml(_sites),
            flush: true);
      } else {
        final bytes = StudyAreaService.toExcelBytes(_sites);
        file = File('${dir.path}/study_area_$stamp.xlsx');
        await file.writeAsBytes(bytes, flush: true);
      }
      await Share.shareXFiles([XFile(file.path)],
          text: ui(context, 'MapBanai Study Area export'));
      _showSnack(ui(context, 'Export ready: {v0}',
          [file.path.split(Platform.pathSeparator).last]));
    } catch (e) {
      _showSnack(ui(context, 'Export failed: {v0}', [e]));
    }
  }

  Future<void> _clearAll() async {
    final workspace = _workspace;
    if (workspace == null || widget.viewOnly) return;
    final cleanup = HistoryCleanupService(_database, store: _store);
    final preview = await cleanup.preview(
        HistoryScope(
            projectId: workspace.project.id,
            layerId: workspace.layerId,
            includeDrafts: true),
        removePoints: true,
        allLayerPoints: true);
    if (!mounted) return;
    if (preview.points.isEmpty && preview.records.isEmpty) {
      _showSnack(
          ui(context, 'This layer has no points or survey history to clear.'));
      return;
    }
    var clearHistory = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
                title: Text(ui(context, 'Clear study layer')),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(ui(
                      context,
                      '{v0} / {v1}\n\nRemove all {v2} map points? This cannot be undone.',
                      [
                        workspace.project.name,
                        workspace.layer.name,
                        preview.points.length
                      ])),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ui(
                          context, 'Also clear survey history and sync queue')),
                      subtitle: Text(ui(
                          context,
                          '{v0} records, including {v1} waiting to sync. Cloud copies remain unchanged.',
                          [
                            preview.records.length,
                            preview.pendingCount
                          ])),
                      value: clearHistory,
                      onChanged: (value) =>
                          setDialogState(() => clearHistory = value!)),
                ])),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(ui(context, 'Cancel')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(ui(context, 'Review deletion')),
                  ),
                ],
              )),
    );
    if (ok != true || !mounted) return;
    final confirmed = await confirmFieldDataRemoval(context,
        title: ui(context, 'Clear study layer'),
        projectName: workspace.project.name,
        details: ui(
            context,
            '{v0}: {v1} map points and {v2} history records will be removed from this device. Cloud copies remain unchanged.',
            [
              workspace.layer.name,
              preview.points.length,
              clearHistory ? preview.records.length : 0
            ]),
        pendingCount: clearHistory ? preview.pendingCount : 0);
    if (!confirmed || !mounted) return;
    try {
      if (clearHistory) {
        await cleanup.delete(preview);
      } else {
        await _store.deleteSites(preview.points.map((site) => site.id).toSet(),
            expectedTokens: {
              for (final site in preview.points) site.id: site.revisionToken
            });
      }
    } catch (error) {
      _showSnack(ui(context, 'Could not clear sites: {v0}', [error]));
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedSite = null;
    });
    await _loadSites();
    _showSnack(clearHistory
        ? ui(context, 'Layer points, history and sync queue cleared')
        : ui(context, 'Layer points cleared; history kept'));
  }

  Future<void> _cleanupHistory() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HistoryCleanupScreen(
            database: _database,
            store: _store,
            projectId: _workspace?.project.id,
            layerId: _workspace?.layerId)));
    if (mounted) await _loadSites();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _buildStyleString(Basemap basemap) =>
      MapStyleChoice.online(basemap).style;

  Future<void> _showBasemapDialog() async {
    final choice =
        await showBasemapPicker(context, selectedId: _selectedBasemapId);
    if (choice == null || !mounted) return;
    setState(() {
      _selectedBasemapId = choice.id;
      _offlineBasemap = choice;
    });
    if (choice.bounds != null) {
      await _controller
          ?.animateCamera(CameraUpdate.newLatLngBounds(choice.bounds!));
    }
  }

  Widget _buildCachedMapView(Basemap basemap) {
    final style = _offlineBasemap?.style ?? _buildStyleString(basemap);
    if (_cachedMapWidget == null || _cachedMapStyle != style) {
      _cachedMapStyle = style;
      _cachedMapWidget = MapLibreMap(
        initialCameraPosition: CameraPosition(
          target: _currentPos != null
              ? LatLng(_currentPos!.latitude, _currentPos!.longitude)
              : const LatLng(23.8103, 90.4125),
          zoom: 12,
        ),
        onMapCreated: _onMapCreated,
        onMapClick: (_, coordinates) {
          if (_movingSite != null) {
            setState(() => _movingCoordinates = coordinates);
            _refreshMapMarkers();
            return;
          }
          if (_drawType != null) {
            setState(() => _draft.add(coordinates));
            _refreshMapMarkers();
          }
        },
        onMapLongClick: (_, coordinates) {
          if (_drawType == null && !widget.viewOnly) _addSite(coordinates);
        },
        onStyleLoadedCallback: _onStyleLoaded,
        styleString: style,
        myLocationEnabled: true,
        myLocationRenderMode: MyLocationRenderMode.normal,
        compassEnabled: true,
        compassViewPosition: CompassViewPosition.bottomRight,
        compassViewMargins: const math.Point(12, 128),
        annotationConsumeTapEvents: const [
          AnnotationType.circle,
          AnnotationType.symbol,
          AnnotationType.line,
          AnnotationType.fill,
        ],
      );
    }
    return _cachedMapWidget!;
  }

  @override
  Widget build(BuildContext context) {
    final basemap = Basemap.defaults.firstWhere(
      (b) => b.id == _selectedBasemapId,
      orElse: () => Basemap.defaults.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.viewOnly
                ? ui(context, 'Study Area — View only')
                : widget.compactControls
                    ? ui(context, widget.workflow.title)
                    : ui(context, 'Study Area Mode'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        actions: [
          if (!widget.compactControls && !_collection)
            IconButton(
                tooltip: ui(context, 'Open in Google Maps'),
                onPressed: () => _openGoogleMaps(_selectedSite),
                icon: const Icon(Icons.open_in_new_rounded)),
          if (ScreenLayout.isWide(context) && !widget.compactControls)
            IconButton(
              tooltip: ui(context, 'Import sites'),
              icon: const Icon(Icons.file_download_outlined,
                  color: Color(0xFF1565C0)),
              onPressed: widget.viewOnly
                  ? null
                  : () => widget.compactControls
                      ? _manageProjectLayers()
                      : _importSites(),
            ),
          if (ScreenLayout.isWide(context))
            IconButton(
              tooltip: ui(context, 'Export sites'),
              icon: const Icon(Icons.file_upload_outlined,
                  color: Color(0xFF2E7D32)),
              onPressed: _exportSites,
            ),
          if (!widget.viewOnly)
            IconButton(
                tooltip: ui(context, 'Add point at GPS'),
                icon: const Icon(Icons.add),
                onPressed: _addingPoint ? null : _addPointAtGps),
          IconButton(
            tooltip: ui(context, 'Basemap'),
            icon: const Icon(Icons.map_outlined),
            onPressed: _showBasemapDialog,
          ),
          if (ScreenLayout.isWide(context))
            IconButton(
              tooltip: ui(context, 'Project layers'),
              icon: const Icon(Icons.layers_outlined),
              onPressed: _manageProjectLayers,
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (widget.viewOnly && v != 'fit' && v != 'export') return;
              if (v == 'import') {
                if (widget.compactControls)
                  _manageProjectLayers();
                else
                  _importSites();
              }
              if (v == 'export') _exportSites();
              if (v == 'layers') _manageProjectLayers();
              if (v == 'clear') _clearAll();
              if (v == 'history_cleanup') _cleanupHistory();
              if (v == 'fit') _fitBounds();
            },
            itemBuilder: (context) => [
              if (!ScreenLayout.isWide(context)) ...[
                if (!widget.viewOnly && !widget.compactControls)
                  PopupMenuItem(
                      value: 'import',
                      child: Text(ui(context, 'Import sites'))),
                PopupMenuItem(
                    value: 'export', child: Text(ui(context, 'Export sites'))),
              ],
              if (!widget.viewOnly && !ScreenLayout.isWide(context))
                PopupMenuItem(
                    value: 'layers',
                    child: Text(
                        ui(context, 'Manage project files and road layers'))),
              if (widget.compactControls && _selectedSite != null)
                PopupMenuItem(
                    value: 'fit', child: Text(ui(context, 'Fit all sites'))),
              PopupMenuItem(
                  value: 'clear', child: Text(ui(context, 'Clear all sites'))),
              if (!widget.viewOnly)
                PopupMenuItem(
                    value: 'history_cleanup',
                    child: Text(ui(context, 'Clean up survey history'))),
            ],
          ),
        ],
      ),
      body: Column(children: [
        if (!widget.viewOnly && !widget.compactControls)
          ScreenLayout.mapPanel(
              context,
              ProjectWorkspaceBar(
                  database: _database,
                  workspace: _workspace,
                  onChanged: _changeWorkspace,
                  enabled: _drawType == null && !widget.viewOnly,
                  onAddPoint: widget.viewOnly ? null : _addSurveyAtGps)),
        Expanded(
            child: Stack(
          children: [
            _buildCachedMapView(basemap),
            Positioned(
                left: 8,
                bottom: 8,
                child: OfflineBasemapNotice(choice: _offlineBasemap)),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: ScreenLayout.mapPanel(
                  context,
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KeyedSubtree(
                            key: const ValueKey('study-map-header'),
                            child: _buildHeaderCard()),
                        if (!_isLoading && _sites.isEmpty)
                          Padding(
                              key: const ValueKey('study-empty-notice'),
                              padding: const EdgeInsets.only(top: 8),
                              child: MapControlSurface(
                                  child: Row(children: [
                                const Icon(Icons.location_off_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(ui(context, 'No sites yet'))),
                                if (!widget.viewOnly)
                                  IconButton(
                                      tooltip: ui(context, 'Import sites'),
                                      icon: const Icon(
                                          Icons.add_location_alt_outlined),
                                      onPressed: _manageProjectLayers),
                              ]))),
                      ])),
            ),
            if (_movingSite != null)
              Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(ui(context,
                                'Tap the map to place this feature at its new location.')),
                            const SizedBox(height: 8),
                            ResponsiveGrid(children: [
                              OutlinedButton(
                                  onPressed: _cancelMove,
                                  child: Text(ui(context, 'Cancel'))),
                              FilledButton(
                                  onPressed: _movingCoordinates == null
                                      ? null
                                      : _saveMove,
                                  child: Text(ui(context, 'Save location'))),
                            ])
                          ])))),
            if (_drawType != null)
              Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(ui(
                                context,
                                '{v0}: {v1} vertices. Tap map to add vertices.',
                                [_drawType, _draft.length])),
                            Wrap(spacing: 8, children: [
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _drawType = null;
                                      _drawingSite = null;
                                      _draft.clear();
                                    });
                                    _refreshMapMarkers();
                                  },
                                  child: Text(ui(context, 'Cancel'))),
                              TextButton(
                                  onPressed: () {
                                    if (_draft.isNotEmpty)
                                      setState(() => _draft.removeLast());
                                    _refreshMapMarkers();
                                  },
                                  child: Text(ui(context, 'Undo'))),
                              FilledButton(
                                  onPressed: _saveDrawing,
                                  child: Text(ui(context, 'Save feature')))
                            ]),
                          ])))),
            if (_selectedSite != null && widget.compactControls)
              MapSiteSheet(
                  key: ValueKey(_selectedSite!.id),
                  child: _compactSelectedPanel()),
            if (_selectedSite != null && !widget.compactControls)
              Positioned(
                  left: 12,
                  right: 72,
                  bottom: 12,
                  child: ScreenLayout.mapPanel(
                      context,
                      _collection
                          ? _compactSelectedPanel()
                          : _buildSelectedPanel())),
            if (!widget.compactControls || _selectedSite == null)
              Positioned(
                right: 12,
                bottom: widget.compactControls ? 20 : 120,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'locate_sa',
                      tooltip: ui(context, 'Center on GPS'),
                      onPressed: () {
                        final pos = _currentPos;
                        if (pos == null) {
                          _showSnack(ui(context, 'Waiting for GPS fix'));
                          return;
                        }
                        _controller?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                              LatLng(pos.latitude, pos.longitude), 16),
                        );
                      },
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'fit_sa',
                      tooltip: ui(context, 'Fit all sites'),
                      onPressed: _fitBounds,
                      child: const Icon(Icons.center_focus_strong_outlined),
                    ),
                  ],
                ),
              ),
          ],
        ))
      ]),
    );
  }

  Future<void> _chooseCategories() async {
    final style = StudyCategoryStyle.fromJson(_categoryStyle.toJson());
    final columns = _sites.expand((s) => s.attributes.keys).toSet().toList()
      ..sort();
    final applied = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              final categories = style.categories(_sites);
              return AlertDialog(
                  title: Text(ui(context, 'Categories & colors')),
                  content: SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        LabeledField(
                            label: ui(context, 'Color by column'),
                            child: DropdownButtonFormField<String>(
                                itemHeight: null,
                                value: style.column,
                                isExpanded: true,
                                decoration: const InputDecoration(),
                                hint: Text(ui(context, 'Single color')),
                                items: [
                                  DropdownMenuItem(
                                      value: null,
                                      child: Text(ui(context, 'Single color'))),
                                  DropdownMenuItem(
                                      value: '__verification_status__',
                                      child: Text(
                                          ui(context, 'Verification status'))),
                                  for (final column in columns)
                                    DropdownMenuItem(
                                        value: column, child: Text(column))
                                ],
                                onChanged: (value) => update(() {
                                      style.column = value;
                                      style.colors.clear();
                                      style.hidden.clear();
                                    }))),
                        Text(ui(context, 'Point size: {v0}',
                            [style.radius.round()])),
                        Slider(
                            value: style.radius,
                            min: 4,
                            max: 12,
                            divisions: 8,
                            onChanged: (value) =>
                                update(() => style.radius = value)),
                        if (style.column != null) ...[
                          ResponsiveGrid(children: [
                            TextButton(
                                onPressed: () =>
                                    update(() => style.hidden.clear()),
                                child: Text(ui(context, 'Show all'))),
                            TextButton(
                                onPressed: () => update(
                                    () => style.hidden.addAll(categories)),
                                child: Text(ui(context, 'Hide all')))
                          ]),
                          for (final category in categories)
                            Row(children: [
                              Checkbox(
                                  value: !style.hidden.contains(category),
                                  onChanged: (value) => update(() {
                                        if (value == true) {
                                          style.hidden.remove(category);
                                        } else {
                                          style.hidden.add(category);
                                        }
                                      })),
                              Expanded(
                                  child: Text(
                                      '$category (${_sites.where((s) => style.category(s) == category).length})')),
                              PopupMenuButton<String>(
                                  tooltip: ui(context, 'Category color'),
                                  onSelected: (color) => update(
                                      () => style.colors[category] = color),
                                  icon: Icon(Icons.circle,
                                      color: Color(int.parse(
                                          style.colors[category]!
                                              .replaceFirst('#', 'FF'),
                                          radix: 16))),
                                  itemBuilder: (_) => [
                                        for (final color
                                            in StudyCategoryStyle.palette)
                                          PopupMenuItem(
                                              value: color,
                                              child: Row(children: [
                                                Icon(Icons.circle,
                                                    color: Color(int.parse(
                                                        color.replaceFirst(
                                                            '#', 'FF'),
                                                        radix: 16))),
                                                const SizedBox(width: 8),
                                                Text(color)
                                              ]))
                                      ])
                            ])
                        ]
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(ui(context, 'Cancel'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(ui(context, 'Apply')))
                  ]);
            }));
    if (applied != true || !mounted) return;
    setState(() => _categoryStyle = style);
    if (!widget.viewOnly && _categoryWorkspaceKey != null)
      await _database.setSetting(
          _categoryWorkspaceKey!, jsonEncode(style.toJson()));
    await _refreshMapMarkers();
  }

  Future<void> _showUnvisitedSites() async {
    bool refreshing = false;
    String? error;
    final selected = await showModalBottomSheet<StudyAreaSite>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) =>
            StatefulBuilder(builder: (sheetContext, update) {
              final position = _currentPos;
              final fresh = position != null &&
                  DateTime.now().difference(position.timestamp).abs() <=
                      const Duration(minutes: 2);
              final rows = SitePriorityService.unvisited(_sites,
                  status: _status,
                  latitude: fresh ? position.latitude : null,
                  longitude: fresh ? position.longitude : null);
              final located =
                  rows.isNotEmpty && rows.first.distanceMeters != null;
              return SizedBox(
                  height: MediaQuery.sizeOf(sheetContext).height * .8,
                  child: Column(children: [
                    ListTile(
                        title: Text(ui(context, 'Nearest unvisited sites')),
                        subtitle: Text(ui(
                            context,
                            located
                                ? 'Straight-line distance from your GPS location.'
                                : 'No recent GPS location. Sites are sorted by name.')),
                        trailing: IconButton(
                            tooltip: ui(context, 'Refresh location'),
                            icon: refreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.my_location),
                            onPressed: refreshing
                                ? null
                                : () async {
                                    update(() {
                                      refreshing = true;
                                      error = null;
                                    });
                                    try {
                                      if (!await _locationService
                                          .ensurePermission())
                                        throw StateError(
                                            'Location permission is required.');
                                      final fix =
                                          await Geolocator.getCurrentPosition()
                                              .timeout(
                                                  const Duration(seconds: 15));
                                      if (mounted) _currentPos = fix;
                                    } catch (problem) {
                                      error = '$problem';
                                    }
                                    if (sheetContext.mounted)
                                      update(() => refreshing = false);
                                  })),
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(ui(context, error!))),
                    if (rows.isEmpty)
                      Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(ui(
                              context, 'No unvisited sites in this layer.'))),
                    Expanded(
                        child: ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (_, index) {
                              final row = rows[index];
                              return ListTile(
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(row.site.displayName),
                                  subtitle: row.distanceMeters == null
                                      ? null
                                      : Text(MeasureUnits.formatDistance(
                                          row.distanceMeters!)),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      Navigator.pop(sheetContext, row.site));
                            })),
                  ]));
            }));
    if (!mounted || selected == null) return;
    final filtered = _filter != null;
    setState(() {
      _selectedSite = selected;
      _filter = null;
    });
    if (filtered) await _refreshMapMarkers();
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(selected.latitude, selected.longitude), 16));
  }

  Future<void> _showStatusFilters() async {
    final selected = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        builder: (context) => SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: Text(ui(context, 'Categories & colors')),
                          onTap: () => Navigator.pop(context, 'style')),
                      Text(ui(context, 'Filter status'),
                          style: Theme.of(context).textTheme.titleLarge),
                      Flexible(
                          child: SingleChildScrollView(
                              child: Column(children: [
                        RadioListTile<String>(
                            value: 'all',
                            groupValue: _filter?.name ?? 'all',
                            title: Text(ui(context, 'All sites')),
                            onChanged: (value) =>
                                Navigator.pop(context, value)),
                        for (final status in [
                          StudyAreaStatus.pending,
                          StudyAreaStatus.completed,
                          StudyAreaStatus.needsReview
                        ])
                          RadioListTile<String>(
                              value: status.name,
                              groupValue: _filter?.name ?? 'all',
                              title: Text(_collection
                                  ? _statusLabel(status)
                                  : ui(context, status.label)),
                              secondary: Text('${_statusCounts[status] ?? 0}'),
                              onChanged: (value) =>
                                  Navigator.pop(context, value)),
                      ])))
                    ]))));
    if (!mounted || selected == null) return;
    if (selected == 'style') {
      await _chooseCategories();
      return;
    }
    setState(() => _filter = selected == 'all'
        ? null
        : StudyAreaStatus.values.firstWhere((s) => s.name == selected));
    await _refreshMapMarkers();
  }

  Widget _buildCompactHeader() => MapControlSurface(
      padding: const EdgeInsets.fromLTRB(12, 4, 6, 8),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Tooltip(
                      message: ui(context, 'Study workspace'),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _workspace == null || _statusBusy
                              ? null
                              : _configureWorkflow,
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                      Text(
                                          _workspace?.layer.name ??
                                              ui(context, 'Study area'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      if (_round != null)
                                        Text(_round!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                    ])),
                                const Icon(Icons.expand_more, size: 18)
                              ]))))),
              if (_selectedSite == null)
                IconButton(
                    tooltip: ui(context, 'Open in Google Maps'),
                    onPressed: () => _openGoogleMaps(null),
                    icon: const Icon(Icons.open_in_new_rounded)),
              IconButton(
                  tooltip: ui(context, 'Nearest unvisited sites'),
                  onPressed: _showUnvisitedSites,
                  icon: const Icon(Icons.near_me_outlined)),
              IconButton(
                  tooltip: ui(context, 'Filter status'),
                  onPressed: _showStatusFilters,
                  icon: const Icon(Icons.tune_rounded)),
            ]),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                          label: Text(ui(context, 'All sites')),
                          selected: _filter == null,
                          onSelected: (_) {
                            setState(() => _filter = null);
                            _refreshMapMarkers();
                          })),
                  for (final status in [
                    StudyAreaStatus.completed,
                    StudyAreaStatus.pending,
                    StudyAreaStatus.needsReview
                  ])
                    Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                            message: _collection
                                ? _statusLabel(status)
                                : ui(context, status.label),
                            child: ChoiceChip(
                                showCheckmark: false,
                                selected: _filter == status,
                                avatar: Icon(
                                    status == StudyAreaStatus.completed
                                        ? Icons.check_circle_outline
                                        : status == StudyAreaStatus.needsReview
                                            ? Icons.flag_outlined
                                            : Icons.circle_outlined,
                                    size: 18,
                                    color: _statusColor(status)),
                                label: Text('${_statusCounts[status] ?? 0}'),
                                onSelected: (_) {
                                  setState(() => _filter =
                                      _filter == status ? null : status);
                                  _refreshMapMarkers();
                                }))),
                ]))
          ]));

  Widget _buildHeaderCard() => widget.compactControls || _collection
      ? _buildCompactHeader()
      : Card(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ResponsiveGrid(minChildWidth: 180, children: [
                Text(
                    ui(context, '{v0} / {v1} features', [
                      _sites
                          .where((s) =>
                              (_filter == null ||
                                  s.status.verificationStatus == _filter) &&
                              _categoryStyle.visible(s))
                          .length,
                      _sites.length
                    ]),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                    tooltip: ui(context, 'Categories & colors'),
                    onPressed: _chooseCategories,
                    icon: const Icon(Icons.palette_outlined)),
                DropdownButton<StudyAreaStatus>(
                    isExpanded: true,
                    itemHeight: null,
                    value: _filter,
                    underline: const SizedBox.shrink(),
                    hint: Text(ui(context, 'All')),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(ui(context, 'All'))),
                      for (final status in [
                        StudyAreaStatus.pending,
                        StudyAreaStatus.completed,
                        StudyAreaStatus.needsReview
                      ])
                        DropdownMenuItem(
                            value: status,
                            child: Text(
                                '${ui(context, status.label)}: ${_sites.where((s) => s.status.verificationStatus == status).length}')),
                    ],
                    onChanged: (value) {
                      setState(() => _filter = value);
                      _refreshMapMarkers();
                    }),
              ])));

  String _siteField(StudyAreaSite site, List<String> keys,
      {String fallback = '—'}) {
    for (final key in keys) {
      for (final entry in site.attributes.entries) {
        if (entry.key.trim().toLowerCase() == key.toLowerCase() &&
            entry.value.trim().isNotEmpty) {
          return entry.value.trim();
        }
      }
    }
    return fallback;
  }

  Widget _buildSelectedPanel() {
    final site = _selectedSite!;
    final id =
        _siteField(site, ['id', 'feature_id', 'site_id'], fallback: site.id);
    final layer = _siteField(site, ['layer', 'layer_name'],
        fallback: _workspace?.layer.name ?? site.layerId);
    final name = _siteField(site, ['name', 'site_name', 'label'],
        fallback: site.displayName);
    final location =
        _siteField(site, ['location', 'locality', 'locality_name']);
    if (widget.viewOnly) {
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ui(context, 'ID  {v0}', [id])),
                    Text(ui(context, 'Layer  {v0}', [layer])),
                    Text(ui(context, 'Name  {v0}', [name])),
                    Text(ui(context, 'Location  {v0}', [location]))
                  ])));
    }
    final pos = _currentPos;
    final routeVisible = _routeSiteId == site.id && _routeDistanceM != null;
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ui(context, 'ID  {v0}', [id]),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _selectedSite = null;
                    _routeSiteId = null;
                    _routeCoordinates = null;
                    _routeDistanceM = null;
                    unawaited(_clearRoute());
                  }),
                ),
              ],
            ),
            Chip(
              label: Text(ui(context, site.status.label),
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: switch (site.status.verificationStatus) {
                StudyAreaStatus.completed => Colors.green.shade50,
                StudyAreaStatus.needsReview => Colors.amber.shade50,
                _ => Colors.red.shade50,
              },
              side: BorderSide(
                  color: Color(int.parse(
                      site.status.colorHex.replaceFirst('#', 'FF'),
                      radix: 16))),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            _detailRow('Layer', layer),
            _detailRow('Name', name),
            _detailRow('Location', location),
            if (site.currentGeometry['type'] == 'LineString' ||
                site.currentGeometry['type'] == 'Polygon')
              TextButton.icon(
                  onPressed: () => _startDrawing(
                      site.currentGeometry['type'] as String,
                      site: site),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: Text(ui(context, 'Redraw geometry'))),
            if (_workspace != null)
              TextButton.icon(
                  icon: const Icon(Icons.timeline),
                  label: Text(ui(context, 'Site timeline / add observation')),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SiteTimelineScreen(
                          database: _database,
                          store: _store,
                          projectId: _workspace!.project.id,
                          site: site)))),
            TextButton.icon(
                onPressed: () => _showHistory(site),
                icon: const Icon(Icons.history),
                label: Text(ui(context, 'Revision history ({v0})',
                    [site.history.length]))),
            if (routeVisible)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      ui(context, 'Shortest road route  {v0}',
                          [StudyAreaService.formatDistance(_routeDistanceM!)]),
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            if (pos == null)
              Text(ui(context, 'Waiting for GPS fix'),
                  style: TextStyle(fontSize: 11)),
            ResponsiveGrid(children: [
              OutlinedButton.icon(
                  onPressed: () => _markUnchanged(site),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(ui(context, 'Unchanged'))),
              OutlinedButton.icon(
                  onPressed: () => _beginMove(site),
                  icon: const Icon(Icons.location_on_outlined, size: 16),
                  label: Text(ui(context, 'Location changed'))),
            ]),
            ResponsiveGrid(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editSite(site),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(ui(context, 'Edit')),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: () => _deleteSite(site),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(ui(context, 'Location removed')),
                ),
              ],
            ),
            if (pos != null)
              SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                      onPressed: () => _showRoadRoute(site),
                      icon: const Icon(Icons.directions_outlined, size: 17),
                      label: Text(routeVisible
                          ? ui(context, 'Refresh road directions')
                          : ui(context, 'Show road directions')))),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  if (pos != null) {
                    _controller?.animateCamera(
                      CameraUpdate.newLatLng(
                          LatLng(site.latitude, site.longitude)),
                    );
                  }
                },
                icon: const Icon(Icons.center_focus_strong_outlined, size: 16),
                label: Text(ui(context, 'Center on site')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 68,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),
      ]));
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _EditSiteDialog extends StatefulWidget {
  final StudyAreaSite site;

  final bool isNew;
  final ValueChanged<bool>? onSurveyChoice;
  const _EditSiteDialog(
      {required this.site, this.isNew = false, this.onSurveyChoice});

  @override
  State<_EditSiteDialog> createState() => _EditSiteDialogState();
}

class _EditSiteDialogState extends State<_EditSiteDialog> {
  bool _fillSurvey = false;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late StudyAreaStatus _status;
  late List<MapEntry<String, TextEditingController>> _attrControllers;
  final _noteCtrl = TextEditingController();
  final _newKeyCtrl = TextEditingController();
  final _newValCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(text: widget.site.latitude.toString());
    _lonCtrl = TextEditingController(text: widget.site.longitude.toString());
    _status = widget.site.status.verificationStatus;
    _noteCtrl.text = widget.site.changeNote;
    _attrControllers = widget.site.attributes.entries
        .map((e) => MapEntry(e.key, TextEditingController(text: e.value)))
        .toList();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    for (final e in _attrControllers) {
      e.value.dispose();
    }
    _noteCtrl.dispose();
    _newKeyCtrl.dispose();
    _newValCtrl.dispose();
    super.dispose();
  }

  void _addAttribute() {
    final key = _newKeyCtrl.text.trim();
    if (key.isEmpty) return;
    if (_attrControllers.any((e) => e.key.toLowerCase() == key.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(ui(context, 'Attribute "{v0}" already exists', [key]))),
      );
      return;
    }
    setState(() {
      _attrControllers.add(
          MapEntry(key, TextEditingController(text: _newValCtrl.text.trim())));
      _newKeyCtrl.clear();
      _newValCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ui(context, 'Edit site {v0}', [widget.site.id])),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latCtrl,
                          enabled:
                              widget.site.currentGeometry['type'] == 'Point',
                          decoration: InputDecoration(
                            labelText: ui(context, 'Latitude'),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lonCtrl,
                          enabled:
                              widget.site.currentGeometry['type'] == 'Point',
                          decoration: InputDecoration(
                            labelText: ui(context, 'Longitude'),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 12),
              DropdownButtonFormField<StudyAreaStatus>(
                itemHeight: null,
                isExpanded: true,
                value: _status,
                decoration: InputDecoration(
                  labelText: ui(context, 'Status'),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  StudyAreaStatus.pending,
                  StudyAreaStatus.completed,
                  StudyAreaStatus.needsReview
                ]
                    .map((status) => DropdownMenuItem(
                        value: status, child: Text(ui(context, status.label))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 12),
              if (StudyFeaturePolicy.requiresSurvey(_status,
                  isNew: widget.isNew))
                Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(ui(context,
                        'Questionnaire required for new or updated features.')))
              else
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ui(context, 'Fill questionnaire (optional)')),
                    value: _fillSurvey,
                    onChanged: (value) {
                      setState(() => _fillSurvey = value ?? false);
                      widget.onSurveyChoice?.call(_fillSurvey);
                    }),
              if (widget.site.currentGeometry['type'] != 'Point')
                Text(
                    ui(context,
                        'Full line/polygon geometry is retained. Coordinates show its reference vertex.'),
                    style: TextStyle(fontSize: 12)),
              if (widget.site.original != null)
                ExpansionTile(
                    title: Text(ui(context, 'Original imported data')),
                    children: [
                      SelectableText(widget.site.original.toString())
                    ]),
              TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                      labelText: ui(context, 'Verification / change note')),
                  maxLines: 2),
              const SizedBox(height: 12),
              Text(ui(context, 'Attributes'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_attrControllers.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(ui(context, 'No attributes'),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
              for (int i = 0; i < _attrControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          _attrControllers[i].key,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _attrControllers[i].value,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _attrControllers[i].value.dispose();
                            _attrControllers.removeAt(i);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newKeyCtrl,
                      decoration: InputDecoration(
                        labelText: ui(context, 'New key'),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _newValCtrl,
                      decoration: InputDecoration(
                        labelText: ui(context, 'Value'),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addAttribute,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ui(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: () {
            final lat = double.tryParse(_latCtrl.text.trim());
            final lon = double.tryParse(_lonCtrl.text.trim());
            if (lat == null || lon == null || !lat.isFinite || !lon.isFinite) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ui(context, 'Invalid coordinates'))),
              );
              return;
            }
            if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(ui(context, 'Coordinates out of range'))),
              );
              return;
            }
            final attrs = {
              for (final e in _attrControllers) e.key: e.value.text.trim()
            };
            final updated = widget.site.revised(
              latitude: lat,
              longitude: lon,
              attributes: attrs,
              status: widget.isNew && _status == StudyAreaStatus.pending
                  ? StudyAreaStatus.newFeature
                  : _status == StudyAreaStatus.completed &&
                          widget.site.status.verificationStatus ==
                              StudyAreaStatus.completed
                      ? widget.site.status
                      : _status,
              changeNote: _noteCtrl.text.trim(),
            );
            Navigator.pop(context, updated);
          },
          child: Text(ui(context, 'Save')),
        ),
      ],
    );
  }
}
