import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/site_observation_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/guided_visit_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SiteTimelineScreen extends StatefulWidget {
  final AppDatabase database;
  final StudyAreaStore store;
  final int projectId;
  final StudyAreaSite site;
  const SiteTimelineScreen(
      {super.key,
      required this.database,
      required this.store,
      required this.projectId,
      required this.site});
  @override
  State<SiteTimelineScreen> createState() => _SiteTimelineScreenState();
}

class _SiteTimelineScreenState extends State<SiteTimelineScreen> {
  List<SiteObservation>? _rows;
  String? _error;
  String? _formId;
  String? _field;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final site = (await widget.store.loadSites())
              .where((site) => site.id == widget.site.id)
              .firstOrNull ??
          widget.site;
      final rows = await SiteObservationService(widget.database)
          .load(widget.projectId, site);
      if (mounted)
        setState(() {
          _rows = rows;
          _error = null;
        });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _export() async {
    try {
      final directory = await getTemporaryDirectory();
      final file =
          File('${directory.path}/observations_${widget.site.featureUuid}.csv');
      await file.writeAsString(SiteObservationService.csv(widget.site, _rows!));
      await Share.shareXFiles([XFile(file.path)],
          text: '${widget.site.displayName} — observations');
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final forms = <String, String>{
      for (final row in _rows ?? <SiteObservation>[]) row.formId: row.formName
    };
    final formId =
        forms.containsKey(_formId) ? _formId : forms.keys.firstOrNull;
    final fields =
        SiteObservationService.numericFields(_rows ?? [], formId: formId);
    final field = fields.containsKey(_field) ? _field : fields.keys.firstOrNull;
    final comparable = (_rows ?? <SiteObservation>[])
        .where((row) => row.formId == formId)
        .toList();
    final measurements = comparable
        .where((row) => field != null && row.number(field) != null)
        .toList();
    return Scaffold(
        appBar: AppBar(title: const Text('Site timeline'), actions: [
          IconButton(
              tooltip: 'Export all observations as CSV',
              onPressed: _rows == null ? null : _export,
              icon: const Icon(Icons.ios_share))
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(widget.site.displayName,
              style: Theme.of(context).textTheme.titleLarge),
          SelectableText('Feature UUID: ${widget.site.featureUuid}'),
          const SizedBox(height: 12),
          const Text(
              'Each completed visit is a separate observation. Earlier measurements stay in the timeline. Comparisons use the same questionnaire and question name; keep measurement units consistent across versions.'),
          const SizedBox(height: 12),
          FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add observation / start visit'),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GuidedVisitScreen(
                        projectId: widget.projectId,
                        initialSiteId: widget.site.id,
                        database: widget.database,
                        studyAreaStore: widget.store)));
                await _load();
              }),
          if (_error != null) Text(_error!),
          if (_rows == null && _error == null) const LinearProgressIndicator(),
          if (_rows?.isEmpty == true)
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                    'No completed observations yet. Add the first visit.')),
          if (forms.isNotEmpty)
            DropdownButtonFormField<String>(
                value: formId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Questionnaire to compare'),
                items: forms.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) => setState(() {
                      _formId = value;
                      _field = null;
                    })),
          if (fields.isNotEmpty) ...[
            DropdownButtonFormField<String>(
                value: field,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Measurement (e.g. salinity)'),
                items: fields.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) => setState(() => _field = value)),
            if (measurements.length > 1)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                      'First: ${measurements.first.number(field!)} • Latest: ${measurements.last.number(field)} • Change: ${(measurements.last.number(field)! - measurements.first.number(field)!).toStringAsFixed(3)}')),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(columns: const [
                  DataColumn(label: Text('Visit date')),
                  DataColumn(label: Text('Value')),
                  DataColumn(label: Text('Change from previous'))
                ], rows: [
                  for (var i = 0; i < measurements.length; i++)
                    DataRow(cells: [
                      DataCell(Text(measurements[i]
                          .timestamp
                          .toLocal()
                          .toString()
                          .split('.')
                          .first)),
                      DataCell(Text('${measurements[i].number(field!)}')),
                      DataCell(Text(i == 0
                          ? '—'
                          : (measurements[i].number(field)! -
                                  measurements[i - 1].number(field)!)
                              .toStringAsFixed(3)))
                    ])
                ])),
          ],
          const SizedBox(height: 16),
          Text('All observations (${_rows?.length ?? 0})',
              style: Theme.of(context).textTheme.titleMedium),
          for (final row in (_rows ?? <SiteObservation>[]).reversed)
            Card(
                child: ExpansionTile(
                    title: Text(
                        '${row.formName} — ${row.timestamp.toLocal().toString().split('.').first}'),
                    subtitle: Text('${row.author} • ${row.outcome}'),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  SelectableText('Observation UUID: ${row.id}'),
                  if (row.note.isNotEmpty) Text(row.note),
                  for (final entry in row.answers.entries)
                    SelectableText('${entry.key}: ${entry.value}')
                ]))
        ]));
  }
}
