import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:mapbanai/services/study_area_outbox_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/common/shapefile_companions.dart';

class ProjectVectorLayersScreen extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  const ProjectVectorLayersScreen(
      {required this.database, required this.projectId, super.key});
  @override
  State<ProjectVectorLayersScreen> createState() =>
      _ProjectVectorLayersScreenState();
}

class _ProjectVectorLayersScreenState extends State<ProjectVectorLayersScreen> {
  late final service = ProjectVectorLayerService(widget.database);
  List<Map<String, dynamic>> layers = [];
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await service.load(widget.projectId);
      if (mounted) setState(() => layers = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await service.save(widget.projectId, layers);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _customColour(Map<String, dynamic> layer) async {
    final input = TextEditingController(text: layer['color'] as String);
    final colour = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Custom layer colour'),
                content: TextField(
                    controller: input,
                    maxLength: 7,
                    decoration: const InputDecoration(
                        labelText: 'Hex colour', hintText: '#267c76')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, input.text.trim()),
                      child: const Text('Apply'))
                ]));
    input.dispose();
    if (colour == null || !mounted) return;
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(colour)) {
      setState(
          () => error = 'Use a six-digit hex colour, for example #267c76.');
      return;
    }
    layer['color'] = colour;
    await _save();
  }

  Future<void> _import() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final selection = await FilePicker.platform
          .pickFiles(allowMultiple: true, type: FileType.any);
      if (selection == null) return;
      final files = <String, Uint8List>{};
      var total = 0;
      for (final file in selection.files) {
        total += file.size;
        if (total > ProjectVectorLayerService.maxBytes) {
          throw const FormatException('Select at most 64 MB of files.');
        }
        if (files.containsKey(file.name)) {
          throw const FormatException(
              'Duplicate filenames. Put each shapefile in its own ZIP.');
        }
        files[file.name] = file.bytes ?? await File(file.path!).readAsBytes();
      }
      if (!mounted ||
          !await resolveShapefileCompanions(context, files,
              selection.files.map((file) => file.path).whereType<String>(),
              identifiers: selection.files
                  .map((file) => file.identifier)
                  .whereType<String>())) return;
      final imported = await ProjectVectorLayerService.parseFiles(files);
      final combined = [...layers, ...imported];
      await service.save(widget.projectId, combined);
      final selected =
          imported.where((layer) => layer['role'] != 'road').firstOrNull;
      if (selected != null) {
        await ProjectWorkspaceService(widget.database).select(widget.projectId,
            layerId: ProjectVectorLayerService.studyLayerId(selected));
      }
      if (mounted) setState(() => layers = combined);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _removeLayer(Map<String, dynamic> layer) async {
    final batchId = (layer['import_batch_id'] ?? layer['id'])?.toString();
    final store = StudyAreaStore();
    final importedSites = batchId == null
        ? <StudyAreaSite>[]
        : (await store.loadSites())
            .where((site) => site.importBatchId == batchId)
            .toList();
    if (!mounted) return;
    final removeBatch = batchId != null;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title:
                  Text(removeBatch ? 'Remove imported file?' : 'Remove layer?'),
              content: Text(removeBatch
                  ? 'This will remove “${layer['import_file_name'] ?? layer['name']}”, its map layer, ${importedSites.length} imported points, and their local history.'
                  : 'This will remove “${layer['name']}” from this project.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final removedLayers = layers
          .where((item) => removeBatch
              ? (item['import_batch_id'] ?? item['id'])?.toString() == batchId
              : identical(item, layer))
          .toList();
      final remaining =
          layers.where((item) => !removedLayers.contains(item)).toList();
      await service.save(widget.projectId, remaining);
      if (removeBatch) {
        await StudyAreaOutboxService(widget.database)
            .deleteSites(importedSites);
        await store.deleteImportBatch(batchId);
      }
      if (mounted) {
        setState(() => layers = remaining);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(removeBatch
                ? 'Removed ${importedSites.length} imported points and their history.'
                : 'Layer removed.')));
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Could not remove layer: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: Scaffold(
          appBar: AppBar(title: const Text('Project vector layers')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            const Text(
                'Add study-area, facility or road layers. Supported files: shapefile or ZIP, CSV, Excel, GeoJSON and GeoPackage. Road layers can provide shortest-path directions in Study Area Mode. Use WGS84 (EPSG:4326).'),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: busy ? null : _import,
                icon: const Icon(Icons.add),
                label: const Text('Add vector layers')),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            if (layers.isEmpty && !busy)
              const Padding(
                  padding: EdgeInsets.all(20),
                  child:
                      Text('No reference layers added to this project yet.')),
            for (final layer in layers)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(layer['name'] as String),
                            subtitle: Text(
                                '${(layer['features'] as List).length} features'),
                            value: layer['visible'] != false,
                            onChanged: busy
                                ? null
                                : (v) async {
                                    layer['visible'] = v;
                                    await _save();
                                  }),
                        DropdownButtonFormField<String>(
                            value: [
                              'reference',
                              'study_area',
                              'facility',
                              'road'
                            ].contains(layer['role'])
                                ? layer['role'] as String
                                : 'reference',
                            decoration: const InputDecoration(
                                labelText: 'Layer type', isDense: true),
                            items: const [
                              DropdownMenuItem(
                                  value: 'reference',
                                  child: Text('Reference layer')),
                              DropdownMenuItem(
                                  value: 'study_area',
                                  child: Text('Study area')),
                              DropdownMenuItem(
                                  value: 'facility', child: Text('Facilities')),
                              DropdownMenuItem(
                                  value: 'road', child: Text('Road network')),
                            ],
                            onChanged: busy
                                ? null
                                : (value) async {
                                    if (value == null) return;
                                    layer['role'] = value;
                                    await _save();
                                    if (mounted) setState(() {});
                                  }),
                        if ((layer['source_files'] as List?)?.isNotEmpty ==
                            true)
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  '${(layer['source_files'] as List).length} source file(s) included in project package',
                                  style: const TextStyle(fontSize: 11))),
                        if ((layer['warning'] ?? '').toString().isNotEmpty)
                          Text(layer['warning'].toString()),
                        Row(children: [
                          TextButton(
                              onPressed:
                                  busy ? null : () => _customColour(layer),
                              child: const Text('Colour')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Wrap(spacing: 6, children: [
                            for (final hex in [
                              '#467ca1',
                              '#498a70',
                              '#aa896a',
                              '#8b79ae',
                              '#d48463',
                              '#353b46'
                            ])
                              InkWell(
                                  onTap: busy
                                      ? null
                                      : () async {
                                          layer['color'] = hex;
                                          await _save();
                                        },
                                  child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                          color: Color(int.parse(
                                                  hex.substring(1),
                                                  radix: 16) |
                                              0xff000000),
                                          shape: BoxShape.circle,
                                          border: layer['color'] == hex
                                              ? Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  width: 3)
                                              : null))),
                          ])),
                          IconButton(
                              tooltip: layer['import_batch_id'] == null
                                  ? 'Remove layer'
                                  : 'Remove imported file and its points',
                              onPressed:
                                  busy ? null : () => _removeLayer(layer),
                              icon: const Icon(Icons.delete_outline))
                        ]),
                        Row(children: [
                          const Text('Opacity'),
                          Expanded(
                              child: Slider(
                                  value: (layer['opacity'] as num).toDouble(),
                                  onChanged: busy
                                      ? null
                                      : (v) =>
                                          setState(() => layer['opacity'] = v),
                                  onChangeEnd: busy ? null : (v) => _save()))
                        ]),
                      ]))),
          ])));
}
