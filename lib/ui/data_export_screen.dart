import 'package:mapbanai/l10n/ui_text.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/data_export_service.dart';
import 'package:mapbanai/services/gis_export_service.dart';
import 'package:mapbanai/services/webmap_data_service.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';
import 'package:mapbanai/ui/import_flow_dialogs.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataExportScreen extends StatefulWidget {
  final String projectName;
  final int? projectId;

  const DataExportScreen(
      {required this.projectName, this.projectId, super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final AppDatabase _database = AppDatabase();
  List<Project> _projects = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  String _lastExport = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final projects = await _database.getProjects(includeArchived: true);
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _selectedIds.clear();
      _selectedIds.addAll(
        projects
            .where((p) => widget.projectId != null
                ? p.id == widget.projectId
                : p.name == widget.projectName)
            .map((p) => p.id),
      );
    });
  }

  Future<List<SurveySession>> _sessionsForSelection() async {
    final sessions = await _database.getSurveySessions();
    return sessions
        .where((s) => _selectedIds.contains(s.projectId) && s.status != 'draft')
        .toList();
  }

  Future<void> _exportProjects({required bool withResponses}) async {
    if (_selectedIds.isEmpty) {
      _showSnack(ui(context, 'Select at least one project'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final flow = ProjectSharingFlow(database: _database);
      for (final project
          in _projects.where((project) => _selectedIds.contains(project.id))) {
        if (!mounted) return;
        await showExportProjectOptions(context,
            flow: flow,
            project: project,
            initialIncludeResponses: withResponses);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportResponsesJson() async {
    if (_selectedIds.isEmpty) {
      _showSnack(ui(context, 'Select at least one project'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sessions = await _sessionsForSelection();
      if (sessions.isEmpty) {
        _showSnack(ui(context, 'No saved responses to export'));
        return;
      }
      final names = await _projectNameMap();
      final content = DataExportService.exportSurveyResponses([
        for (final session in sessions)
          {
            'record_id': session.externalId,
            'project': names[session.projectId],
            'title': session.title,
            'created_at': session.createdAt.toIso8601String(),
            'responses': jsonDecode(session.responses),
          }
      ]);
      final file = await _writeTempFile(
          'responses_${_timestamp()}.json', content,
          encoding: utf8);
      await _shareFile(file, 'application/json');
      if (mounted)
        setState(() => _lastExport =
            '${sessions.length} saved records exported without project settings.');
    } catch (error) {
      _showSnack(ui(context, 'Export failed: {v0}', [error]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<int, String>> _projectNameMap() async {
    final projects = await _database.getProjects(includeArchived: true);
    return {for (final p in projects) p.id: p.name};
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}';
  }

  Future<void> _exportSurveyCSV() async {
    if (_selectedIds.isEmpty) {
      _showSnack(ui(context, 'Select at least one project'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sessions = await _sessionsForSelection();
      final names = await _projectNameMap();
      final rows = <Map<String, dynamic>>[];
      final answerKeys = <String>[];
      final visitKeys = <String>[];
      for (final session in sessions) {
        Map<String, dynamic> responses;
        try {
          responses = jsonDecode(session.responses) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        if (responses['feature_type'] != null) continue; // GIS data only
        if (responses['workflow'] == 'study_collection_v1' &&
            responses['record_kind'] == 'status') continue;
        final answers = responses['answers'];
        if (answers is! Map) continue; // form responses only
        final flat = <String, dynamic>{
          'project': names[session.projectId] ?? '',
          'title': session.title,
          'created_at': session.createdAt.toLocal().toIso8601String(),
          'user_name': responses['user_name'] ?? '',
          'form_name': responses['form_name'] ?? '',
        };
        answers.forEach((key, value) {
          final k = key.toString();
          flat[k] = value;
          if (!answerKeys.contains(k)) answerKeys.add(k);
        });
        final visit = responses['visit'];
        if (responses['workflow'] == 'guided_visit_v1' && visit is Map) {
          final site = visit['site_after'];
          final photo = responses['photo'];
          final metadata = {
            'mapbanai_visit_id': visit['id'],
            'mapbanai_site_id': visit['site_id'],
            'mapbanai_site_status': site is Map ? site['status'] : null,
            'mapbanai_map_update': visit['site_sync'],
            'mapbanai_photo_accuracy_m':
                photo is Map ? photo['accuracy'] : null,
          };
          metadata.forEach((key, value) {
            var column = key;
            while (flat.containsKey(column)) {
              column = '${column}_meta';
            }
            flat[column] = value;
            if (!visitKeys.contains(column)) visitKeys.add(column);
          });
        }
        if (responses['workflow'] == 'study_collection_v1') {
          final round = responses['collection_round'] as Map? ?? {};
          final metadata = {
            'mapbanai_workflow': responses['study_workflow'],
            'mapbanai_site_id': responses['site_id'],
            'mapbanai_layer_id': responses['layer_id'],
            'mapbanai_round_id': responses['round_id'],
            'mapbanai_collection_round': round['name'],
            'mapbanai_period': round['period'],
            'mapbanai_round_date': round['date'],
            'mapbanai_outcome': responses['outcome'],
            'mapbanai_observed_at': responses['observed_at']
          };
          for (final entry in metadata.entries) {
            var column = entry.key;
            while (flat.containsKey(column)) {
              column = '${column}_meta';
            }
            flat[column] = entry.value;
            if (!visitKeys.contains(column)) visitKeys.add(column);
          }
        }
        rows.add(flat);
      }
      if (rows.isEmpty) {
        _showSnack(ui(
            context, 'No survey responses found for the selected project(s)'));
        return;
      }
      final headers = [
        'project',
        'title',
        'created_at',
        'user_name',
        'form_name',
        ...answerKeys,
        ...visitKeys,
      ];
      final csv =
          '\uFEFF${DataExportService.exportSurveyResponsesAsCSV(rows, headers)}';
      final file = await _writeTempFile(
        'survey_responses_${_timestamp()}.csv',
        csv,
        encoding: utf8,
      );
      await _shareFile(file, 'text/csv');
      if (mounted) {
        setState(() => _lastExport = 'Survey responses CSV • ${rows.length} '
            'responses • ${file.path.split(Platform.pathSeparator).last}');
      }
    } catch (e) {
      _showSnack(ui(context, 'Export failed: {v0}', [e]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportSpatialAnswers() async {
    if (_selectedIds.isEmpty) {
      _showSnack(ui(context, 'Select at least one project'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final features = <dynamic>[];
      final service = WebMapDataService(_database);
      for (final id in _selectedIds) {
        final collection = await service.buildFeatureCollectionForProject(id);
        features.addAll(collection['features'] as List);
      }
      if (features.isEmpty) {
        _showSnack(ui(context, 'No saved map data in the selected projects'));
        return;
      }
      final file = await _writeTempFile('field_map_${_timestamp()}.geojson',
          jsonEncode({'type': 'FeatureCollection', 'features': features}),
          encoding: utf8);
      await _shareFile(file, 'application/geo+json');
    } catch (e) {
      _showSnack(ui(context, 'Map export failed: {v0}', [e]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportGisData() async {
    if (_selectedIds.isEmpty) {
      _showSnack(ui(context, 'Select at least one project'));
      return;
    }
    final format = await _chooseGisFormat();
    if (format == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final sessions = await _sessionsForSelection();
      final names = await _projectNameMap();
      final data = sessions.map(
        (s) => SurveySessionDatum(
          id: s.id,
          projectId: s.projectId,
          responses: s.responses,
        ),
      );
      final features = GisExportService.extractFeatures(data.toList(), names);
      if (features.isEmpty) {
        _showSnack(
            ui(context, 'No GIS features found for the selected project(s)'));
        return;
      }
      final stamp = _timestamp();
      switch (format) {
        case 'csv':
          final file = await _writeTempFile(
            'gis_export_$stamp.csv',
            GisExportService.toCsv(features),
            encoding: utf8,
          );
          await _shareFile(file, 'text/csv');
        case 'kml':
          final file = await _writeTempFile(
            'gis_export_$stamp.kml',
            GisExportService.toKml(features),
            encoding: utf8,
          );
          await _shareFile(
            file,
            'application/vnd.google-earth.kml+xml',
          );
        case 'geojson':
          final file = await _writeTempFile(
            'gis_export_$stamp.geojson',
            GisExportService.toGeoJson(features),
            encoding: utf8,
          );
          await _shareFile(file, 'application/geo+json');
        case 'gpkg':
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}${Platform.pathSeparator}gis_export_$stamp.gpkg',
          );
          await GisExportService.toGeoPackage(features, file);
          await _shareFile(file, 'application/geopackage+sqlite3');
          if (file.existsSync()) file.deleteSync();
      }
      if (mounted) {
        setState(() => _lastExport =
            'GIS data ${format.toUpperCase()} • ${features.length} features');
      }
    } catch (e) {
      _showSnack(ui(context, 'Export failed: {v0}', [e]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _chooseGisFormat() {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(ui(context, 'Export GIS data as')),
        children: [
          _FormatOption(
              value: 'csv',
              icon: Icons.table_chart_outlined,
              title: ui(context, 'CSV'),
              subtitle: ui(context, 'Tabular data with WKT geometry')),
          _FormatOption(
              value: 'kml',
              icon: Icons.map_outlined,
              title: ui(context, 'KML'),
              subtitle: ui(context, 'Google Earth / GIS')),
          _FormatOption(
              value: 'geojson',
              icon: Icons.language,
              title: ui(context, 'GeoJSON'),
              subtitle: ui(context, 'Web / QGIS')),
          _FormatOption(
              value: 'gpkg',
              icon: Icons.storage,
              title: ui(context, 'GeoPackage'),
              subtitle: ui(context, 'SQLite + WKB geometry')),
        ],
      ),
    );
  }

  Future<File> _writeTempFile(
    String name,
    String content, {
    required Encoding encoding,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsString(content, encoding: encoding);
    return file;
  }

  Future<void> _shareFile(File file, String mimeType) async {
    if (!mounted) return;
    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'MapBanai export',
      );
    } catch (e) {
      _showSnack(ui(context, 'Sharing failed: {v0}', [e]));
    }
    if (file.existsSync()) file.deleteSync();
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
      appBar: AppBar(title: Text(ui(context, 'Export Data'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              ui(context, 'Select projects to export'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              ui(context,
                  'Share a full project with responses, a project setup without responses, or only saved responses. Project packages include GIS files, forms, settings, web URL and API key by default.'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (_projects.isEmpty)
              Text(ui(context, 'No projects available.'))
            else ...[
              for (final project in _projects)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(project.name),
                  subtitle: Text(
                    project.description.trim().isEmpty
                        ? ui(context, 'No description')
                        : project.description.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _selectedIds.contains(project.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds.add(project.id);
                      } else {
                        _selectedIds.remove(project.id);
                      }
                    });
                  },
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedIds.length == _projects.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_projects.map((p) => p.id));
                    }
                  });
                },
                child: Text(
                  _selectedIds.length == _projects.length
                      ? ui(context, 'Deselect all')
                      : ui(context, 'Select all'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _exportProjects(withResponses: true),
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(ui(context, 'Project with responses (.mbproj)')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _exportProjects(withResponses: false),
              icon: const Icon(Icons.folder_copy_outlined),
              label: Text(ui(context, 'Project without responses (.mbproj)')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _exportResponsesJson,
              icon: const Icon(Icons.description_outlined),
              label: Text(ui(context, 'Responses only (JSON)')),
            ),
            const SizedBox(height: 16),
            Text(ui(context, 'Other response formats')),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isLoading ? null : _exportSurveyCSV,
              icon: const Icon(Icons.table_chart_outlined, size: 18),
              label: Text(ui(context, 'Survey responses (CSV)')),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isLoading ? null : _exportGisData,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(ui(context, 'GIS data')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _exportSpatialAnswers,
              icon: const Icon(Icons.layers_outlined, size: 18),
              label: Text(ui(context, 'Survey and GIS map (GeoJSON)')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: _isLoading
                  ? const AppLoadingIndicator()
                  : _lastExport.isEmpty
                      ? Center(
                          child: Text(
                            ui(context,
                                'Choose an export option above — the file will be shared or saved where you want it.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _lastExport,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String value;
  final IconData icon;
  final String title;
  final String subtitle;

  const _FormatOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.of(context).pop(value),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.teal.shade700),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
