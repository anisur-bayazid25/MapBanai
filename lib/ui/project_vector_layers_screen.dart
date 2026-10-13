import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';

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
      final imported = await ProjectVectorLayerService.parseFiles(files);
      final combined = [...layers, ...imported];
      await service.save(widget.projectId, combined);
      if (mounted) setState(() => layers = combined);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
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
                'Add streets, buildings or waterbodies as reference layers. Select multiple ZIP bundles, or select each .shp with its .dbf, .shx, .prj and .cpg files. GeoJSON also works. Use WGS84 (EPSG:4326).'),
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
                              tooltip: 'Remove layer',
                              onPressed: busy
                                  ? null
                                  : () async {
                                      layers.remove(layer);
                                      await _save();
                                    },
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
