import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_package.dart';
import 'package:mapbanai/services/project_workspace_service.dart';
import 'package:uuid/uuid.dart';

/// Local, backup-preserved definition snapshots. Never stores records or credentials.
class ProjectTemplateService {
  final AppDatabase db;
  ProjectTemplateService(this.db);
  static const _key = 'reusable_project_templates_v1';
  Future<List<Map<String, dynamic>>> list() async {
    final value = await db.getSetting(_key);
    return value == null
        ? []
        : (jsonDecode(value) as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
  }

  Future<void> save(int projectId, String name,
      {bool layerOnly = false}) async {
    if (name.trim().isEmpty) throw ArgumentError('Enter a template name');
    final workspace = await ProjectWorkspaceService(db).load(projectId);
    final data = await ProjectExporter(db).buildData(workspace.project);
    final settings = Map<String, dynamic>.from(data.settings)
      ..['archived'] = false;
    var forms = data.forms;
    if (layerOnly) {
      settings['study_layers'] = [workspace.layer.toJson()];
      forms = workspace.form == null
          ? []
          : data.forms
              .where((form) => form['id'] == workspace.form!.id)
              .toList();
    }
    await db.transaction(() async {
      final templates = await list();
      templates.add({
        'id': const Uuid().v4(),
        'name': name.trim(),
        'kind': layerOnly ? 'layer' : 'project',
        'project': data.project,
        'settings': settings,
        'layers': Map<String, dynamic>.from(data.layers)
          ..remove('vector_overlays'),
        'forms': forms
      });
      await db.setSetting(_key, jsonEncode(templates));
    });
  }

  Future<void> remove(String id) async => db.transaction(() async {
        final templates = await list();
        templates.removeWhere((item) => item['id'] == id);
        await db.setSetting(_key, jsonEncode(templates));
      });
  Future<int> createProject(Map<String, dynamic> template, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Enter a project name');
    return db.transaction(() async {
      if (await db.projectExists(clean))
        throw StateError('A project with this name already exists');
      final now = DateTime.now().toUtc().toIso8601String();
      final id = const Uuid().v4();
      final settings = Map<String, dynamic>.from(template['settings'] as Map)
        ..remove('sync_connection');
      settings['archived'] = false;
      final remap = <String, String>{'default': 'default'};
      settings['study_layers'] = [
        for (final raw in settings['study_layers'] as List? ?? [])
          {
            ...Map<String, dynamic>.from(raw),
            'id': remap.putIfAbsent('${raw['id']}', () => const Uuid().v4()),
            'name': raw['name']
          }
      ];
      settings['active_layer_id'] =
          remap[settings['active_layer_id']] ?? 'default';
      // A template starts fresh rounds and progress while retaining assignments.
      settings['collection_rounds'] = [];
      settings['study_workflows'] = {
        for (final entry in (settings['study_workflows'] as Map? ?? {}).entries)
          entry.key: {
            ...Map<String, dynamic>.from(entry.value),
            'layer_id': remap[entry.value['layer_id']] ?? 'default',
            'round_id': null
          }
      };
      final data = ProjectPackageData.from(
          ProjectPackageMeta(
              projectId: id,
              projectName: clean,
              projectVersion: 1,
              createdAt: now,
              exportedAt: now),
          {
            ...Map<String, dynamic>.from(template['project'] as Map),
            'name': clean,
            'project_id': id,
            'project_version': 1
          },
          settings,
          Map<String, dynamic>.from(template['layers'] as Map),
          (template['forms'] as List)
              .map((form) => Map<String, dynamic>.from(form as Map))
              .toList());
      return (await ProjectImporter(db).commitQrData(data, newCopy: false))
          .projectId;
    });
  }

  Future<void> applyLayers(Map<String, dynamic> template, int projectId) async {
    await db.transaction(() async {
      var workspace = await ProjectWorkspaceService(db).load(projectId);
      int? selectedForm;
      for (final raw in template['forms'] as List) {
        final json = jsonEncode(raw['form']);
        final same =
            workspace.forms.where((form) => form.json == json).firstOrNull;
        final formId = same?.id ??
            await db.insertStoredForm(StoredFormsCompanion(
                projectId: Value(projectId),
                name: Value('${raw['name']}'),
                json: Value(json),
                description: Value('${raw['description'] ?? ''}'),
                version: Value((raw['version'] as num).toInt())));
        selectedForm ??= formId;
        if ((raw['form'] as Map)['id'] ==
            (template['settings'] as Map)['active_form_schema_id'])
          selectedForm = formId;
      }
      for (final layer
          in (template['settings'] as Map)['study_layers'] as List? ?? []) {
        workspace = await ProjectWorkspaceService(db)
            .addLayer(projectId, '${layer['name']}');
      }
      if (selectedForm != null)
        await ProjectWorkspaceService(db)
            .select(projectId, formId: selectedForm);
    });
  }
}
