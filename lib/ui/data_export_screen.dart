import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/data_export_service.dart';
import 'package:mapbanai/services/gis_export_service.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataExportScreen extends StatefulWidget {
  final String projectName;

  const DataExportScreen({required this.projectName, super.key});

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
        projects.where((p) => p.name == widget.projectName).map((p) => p.id),
      );
    });
  }

  Future<List<SurveySession>> _sessionsForSelection() async {
    final sessions = await _database.getSurveySessions();
    return sessions
        .where((s) => _selectedIds.contains(s.projectId))
        .toList();
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
      _showSnack('Select at least one project');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sessions = await _sessionsForSelection();
      final names = await _projectNameMap();
      final rows = <Map<String, dynamic>>[];
      final answerKeys = <String>[];
      for (final session in sessions) {
        Map<String, dynamic> responses;
        try {
          responses = jsonDecode(session.responses) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        if (responses['feature_type'] != null) continue; // GIS data only
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
        rows.add(flat);
      }
      if (rows.isEmpty) {
        _showSnack('No survey responses found for the selected project(s)');
        return;
      }
      final headers = [
        'project',
        'title',
        'created_at',
        'user_name',
        'form_name',
        ...answerKeys,
      ];
      final csv = '\uFEFF${DataExportService.exportSurveyResponsesAsCSV(rows, headers)}';
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
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportGisData() async {
    if (_selectedIds.isEmpty) {
      _showSnack('Select at least one project');
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
        _showSnack('No GIS features found for the selected project(s)');
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
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _chooseGisFormat() {
    return showDialog<String>(
      context: context,
      builder: (context) => const SimpleDialog(
        title: Text('Export GIS data as'),
        children: [
          _FormatOption(value: 'csv', icon: Icons.table_chart_outlined,
              title: 'CSV', subtitle: 'Tabular data with WKT geometry'),
          _FormatOption(value: 'kml', icon: Icons.map_outlined,
              title: 'KML', subtitle: 'Google Earth / GIS'),
          _FormatOption(value: 'geojson', icon: Icons.language,
              title: 'GeoJSON', subtitle: 'Web / QGIS'),
          _FormatOption(value: 'gpkg', icon: Icons.storage,
              title: 'GeoPackage', subtitle: 'SQLite + WKB geometry'),
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
      _showSnack('Sharing failed: $e');
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
      appBar: AppBar(title: const Text('Export Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select projects to export',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Survey responses export as CSV (Kobo/ODK style, one column '
              'per question). GIS data can be exported as CSV, KML, GeoJSON '
              'or GeoPackage files.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (_projects.isEmpty)
              const Text('No projects available.')
            else ...[
              for (final project in _projects)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(project.name),
                  subtitle: Text(
                    project.description.trim().isEmpty
                        ? 'No description'
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
                      ? 'Deselect all'
                      : 'Select all',
                ),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isLoading ? null : _exportSurveyCSV,
              icon: const Icon(Icons.table_chart_outlined, size: 18),
              label: const Text('Survey responses (CSV)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isLoading ? null : _exportGisData,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('GIS data'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator()
                  : _lastExport.isEmpty
                      ? Center(
                          child: Text(
                            'Choose an export option above — the file will '
                            'be shared or saved where you want it.',
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