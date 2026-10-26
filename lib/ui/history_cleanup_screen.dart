import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/history_cleanup_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_area_store.dart';

class HistoryCleanupScreen extends StatefulWidget {
  final AppDatabase database;
  final StudyAreaStore? store;
  final int? projectId;
  final String? layerId;
  const HistoryCleanupScreen(
      {super.key,
      required this.database,
      this.store,
      this.projectId,
      this.layerId});
  @override
  State<HistoryCleanupScreen> createState() => _HistoryCleanupScreenState();
}

class _HistoryCleanupScreenState extends State<HistoryCleanupScreen> {
  List<Project> _projects = [];
  List<HistoryRecord> _records = [];
  final Map<int, Map<String, String>> _layerNames = {};
  int? _projectId;
  String? _layerId, _day, _kind;
  String _syncState = 'all';
  bool _includeDrafts = false, _removePoints = false, _busy = true;
  String? _error;
  late final _service =
      HistoryCleanupService(widget.database, store: widget.store);

  @override
  void initState() {
    super.initState();
    _projectId = widget.projectId;
    _layerId = widget.layerId;
    _load();
  }

  Future<void> _load() async {
    try {
      final projects = await widget.database.getProjects(includeArchived: true);
      final records = (await widget.database.getSurveySessions())
          .map(HistoryRecord.new)
          .toList();
      for (final project in projects) {
        final workspace =
            await ProjectWorkspaceService(widget.database).load(project.id);
        _layerNames[project.id] = {
          for (final layer in workspace.layers) layer.id: layer.name
        };
      }
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _records = records;
        if (_projectId == null && projects.length == 1)
          _projectId = projects.single.id;
        _busy = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _busy = false;
        });
    }
  }

  HistoryScope? get _scope => _projectId == null
      ? null
      : HistoryScope(
          projectId: _projectId!,
          layerId: _layerId,
          day: _day,
          kind: _kind,
          syncState: _syncState,
          includeDrafts: _includeDrafts);

  Future<void> _review() async {
    final scope = _scope;
    if (scope == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview =
          await _service.preview(scope, removePoints: _removePoints);
      if (!mounted) return;
      if (preview.records.isEmpty) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Delete selected history?'),
                content: SingleChildScrollView(
                    child: Text('${preview.project.name}\n\n'
                        '${preview.records.length} history records will be deleted, including '
                        '${preview.pendingCount} waiting to sync.\n'
                        '${preview.removePoints ? '${preview.points.length} linked Study Area points will also be removed.\n' : 'Study Area points will stay on the map.\n'}'
                        '${preview.relatedCount > 0 ? '\nIncludes ${preview.relatedCount} other records linked to the same removed points.\n' : ''}'
                        '\nThis cannot be undone. Copies already uploaded to the cloud remain there.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete ${preview.records.length} records')),
                ],
              ));
      if (confirmed != true) return;
      final removed = await _service.delete(preview);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Deleted $removed history records${preview.removePoints ? ' and ${preview.points.length} map points' : ''}.')));
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    final matches = scope == null
        ? <HistoryRecord>[]
        : _records.where(scope.matches).toList();
    final projectRecords = _records
        .where((record) => record.session.projectId == _projectId)
        .toList();
    final layerIds = {
      ...?_layerNames[_projectId]?.keys,
      ...projectRecords.map((record) => record.layerId ?? ''),
      if (_layerId != null) _layerId!,
    }.toList()
      ..sort();
    final days = projectRecords
        .where(
            (record) => _layerId == null || (record.layerId ?? '') == _layerId)
        .map((record) => record.day)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(title: const Text('Clean up history')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            const Text(
                'Choose a project, then narrow the records by layer or recorded day. Deleting history also removes those records from the sync queue.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _projectId,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Project', border: OutlineInputBorder()),
              items: [
                for (final project in _projects)
                  DropdownMenuItem(
                      value: project.id,
                      child:
                          Text(project.name, overflow: TextOverflow.ellipsis))
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        _projectId = value;
                        _layerId = null;
                        _day = null;
                      }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _layerId ?? '*',
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Layer', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: '*', child: Text('All layers')),
                for (final id in layerIds)
                  DropdownMenuItem(
                      value: id,
                      child: Text(
                          id.isEmpty
                              ? 'No layer recorded'
                              : _layerNames[_projectId]?[id] ?? id,
                          overflow: TextOverflow.ellipsis))
              ],
              onChanged: _busy || _projectId == null
                  ? null
                  : (value) => setState(() {
                        _layerId = value == '*' ? null : value;
                        _day = null;
                      }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _day ?? '*',
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Recorded day (local time)',
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: '*', child: Text('All days')),
                for (final day in days)
                  DropdownMenuItem(value: day, child: Text(day))
              ],
              onChanged: _busy || _projectId == null
                  ? null
                  : (value) =>
                      setState(() => _day = value == '*' ? null : value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kind ?? '*',
              decoration: const InputDecoration(
                  labelText: 'Record type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: '*', child: Text('All record types')),
                DropdownMenuItem(
                    value: 'survey', child: Text('Survey responses')),
                DropdownMenuItem(
                    value: 'study', child: Text('Study Area points / imports')),
                DropdownMenuItem(value: 'gis', child: Text('GIS features')),
                DropdownMenuItem(value: 'visit', child: Text('Site visits'))
              ],
              onChanged: _busy
                  ? null
                  : (value) =>
                      setState(() => _kind = value == '*' ? null : value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _syncState,
              decoration: const InputDecoration(
                  labelText: 'Sync status', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'all', child: Text('All sync statuses')),
                DropdownMenuItem(
                    value: 'pending', child: Text('Waiting to sync')),
                DropdownMenuItem(value: 'synced', child: Text('Already synced'))
              ],
              onChanged:
                  _busy ? null : (value) => setState(() => _syncState = value!),
            ),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include unfinished drafts'),
                value: _includeDrafts,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _includeDrafts = value)),
            CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Also remove linked Study Area points'),
                subtitle: const Text(
                    'Includes other history records linked to those points. Imported source files and project settings are kept.'),
                value: _removePoints,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _removePoints = value!)),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                        '${matches.length} matching records\n${matches.where((record) => record.pending).length} waiting to sync',
                        style: Theme.of(context).textTheme.titleMedium))),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _busy || matches.isEmpty ? null : _review,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Review deletion')),
          ]),
        ));
  }
}
