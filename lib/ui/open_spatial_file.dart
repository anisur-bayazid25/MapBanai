import 'package:mapbanai/l10n/ui_text.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/spatial_file_import.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/study_area_mode_screen.dart';

Future<void> openSpatialFile(
    BuildContext context, AppDatabase db, String path) async {
  try {
    final projects = await db.getProjects();
    if (!context.mounted) return;
    final choice = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
                title: Text(ui(context, 'Open study-area map')),
                children: [
                  Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(ui(context,
                          'Choose where this map belongs. Importing lets you verify and update its features.'))),
                  for (final project in projects)
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, project.id),
                        child: Text(project.name)),
                  SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, -1),
                      child: Text(ui(context, 'New project'))),
                  SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, -2),
                      child: Text(ui(context, 'View only — do not import'))),
                ]));
    if (choice == null || !context.mounted) return;
    if (choice == -2) {
      final sites = await SpatialFileImport.read(File(path));
      if (sites.isEmpty)
        throw const FormatException('No spatial features found.');
      final directory =
          await Directory.systemTemp.createTemp('mapbanai_preview_');
      final store = StudyAreaStore(baseDir: directory);
      try {
        await store.saveSites(sites);
        if (!context.mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StudyAreaModeScreen(
                store: store, database: db, viewOnly: true)));
      } finally {
        await directory.delete(recursive: true);
      }
      return;
    }
    var projectId = choice;
    if (choice == -1) {
      final controller = TextEditingController();
      final name = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(ui(context, 'New project')),
                  content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: ui(context, 'Project name'))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(ui(context, 'Cancel'))),
                    FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        child: Text(ui(context, 'Create')))
                  ]));
      if (name == null || name.isEmpty) return;
      // Check the file before creating a project.
      if ((await SpatialFileImport.read(File(path))).isEmpty)
        throw const FormatException('No spatial features found.');
      projectId = await db.insertProject(ProjectsCompanion.insert(name: name));
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StudyAreaModeScreen(
            projectId: projectId, database: db, initialImportPath: path)));
  } catch (error) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ui(context, 'Could not open map: {v0}', [error]))));
  }
}
