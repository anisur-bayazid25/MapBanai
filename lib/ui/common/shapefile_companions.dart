import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:path/path.dart' as p;

Future<bool> resolveShapefileCompanions(
    BuildContext context, Map<String, Uint8List> files, Iterable<String> paths,
    {Iterable<String> identifiers = const []}) async {
  await ProjectVectorLayerService.addShapefileCompanions(files, paths);
  bool missingAttributes() {
    final names = files.keys.map((name) => name.toLowerCase()).toSet();
    return names
        .where((name) => name.endsWith('.shp'))
        .any((name) => !names.contains(p.setExtension(name, '.dbf')));
  }

  final shapes =
      files.keys.where((name) => name.toLowerCase().endsWith('.shp')).toList();
  const channel = MethodChannel('mapbanai/shapefile_folders');
  void merge(Map<dynamic, dynamic>? companions) {
    if (companions == null) return;
    final names = files.keys.map((name) => name.toLowerCase()).toSet();
    for (final entry in companions.entries) {
      final name = entry.key.toString();
      if (entry.value is Uint8List && names.add(name.toLowerCase()))
        files[name] = entry.value as Uint8List;
    }
  }

  if (shapes.isNotEmpty && defaultTargetPlatform == TargetPlatform.android) {
    try {
      merge(await channel.invokeMapMethod('readGranted',
          {'names': shapes, 'identifiers': identifiers.toList()}));
    } on MissingPluginException {
      /* Desktop/test embedding without Android. */
    } on PlatformException {/* Let the user choose the folder again. */}
  }
  if (!missingAttributes()) return true;
  if (!context.mounted) return false;
  final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Shapefile companion files'),
            content: const Text(
                'The matching DBF attribute file is not accessible. '
                'Choose the folder containing the SHP, DBF, SHX, PRJ and CPG files, '
                'or import geometry only. You can also select those files together.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, 'geometry'),
                  child: const Text('Geometry only')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, 'folder'),
                  child: const Text('Choose folder')),
            ],
          ));
  if (action == 'geometry') return true;
  if (action != 'folder') return false;
  if (defaultTargetPlatform == TargetPlatform.android) {
    final companions =
        await channel.invokeMapMethod('chooseFolder', {'names': shapes});
    if (companions == null) return false;
    merge(companions);
  } else {
    final folder = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Folder containing shapefile companions');
    if (folder == null || !context.mounted) return false;
    await ProjectVectorLayerService.addShapefileCompanions(
        files, shapes.map((name) => p.join(folder, p.basename(name))));
  }
  if (missingAttributes()) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Matching DBF not found in that folder. Select SHP and companions together or import their ZIP.')));
    return false;
  }
  return true;
}
