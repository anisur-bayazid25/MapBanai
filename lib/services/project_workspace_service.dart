import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:uuid/uuid.dart';

/// A project owns independent study layers and one shared active form.
/// Stored in AppSettings so database backups and upgrades preserve context.
class StudyLayer {
  final String id;
  final String name;
  const StudyLayer(this.id, this.name);
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class ProjectWorkspace {
  final Project project;
  final List<StudyLayer> layers;
  final String layerId;
  final List<StoredForm> forms;
  final StoredForm? form;
  const ProjectWorkspace(
      this.project, this.layers, this.layerId, this.forms, this.form);
  StudyLayer get layer => layers.firstWhere((item) => item.id == layerId);
  SurveyForm? get schema =>
      form == null ? null : SurveyForm.fromJson(jsonDecode(form!.json));
}

class ProjectWorkspaceService {
  final AppDatabase db;
  ProjectWorkspaceService(this.db);
  String _key(int projectId) => 'project_workspace_$projectId';
  Future<ProjectWorkspace> load(int projectId) async {
    var project = await db.getProjectById(projectId);
    if (project == null) throw StateError('Project no longer exists');
    if (project.externalId == null) {
      await (db.update(db.projects)..where((row) => row.id.equals(projectId)))
          .write(ProjectsCompanion(externalId: Value(const Uuid().v4())));
      project = (await db.getProjectById(projectId))!;
    }
    Map<String, dynamic> config = {};
    final raw = await db.getSetting(_key(projectId));
    if (raw != null) config = Map<String, dynamic>.from(jsonDecode(raw));
    final layers = <StudyLayer>[const StudyLayer('default', 'Main study area')];
    for (final item in config['layers'] as List? ?? []) {
      if (item['id'] != 'default' &&
          !item['id'].toString().startsWith('vector:'))
        layers.add(StudyLayer(item['id'], item['name']));
    }
    for (final vector in await ProjectVectorLayerService(db).load(projectId)) {
      if (vector['role'] == 'road') continue;
      final id = ProjectVectorLayerService.studyLayerId(vector);
      if (!layers.any((layer) => layer.id == id)) {
        layers.add(StudyLayer(id, vector['name'].toString()));
      }
    }
    final layerId = layers.any((item) => item.id == config['layer_id'])
        ? config['layer_id'] as String
        : 'default';
    final allForms = await db.getStoredFormsForProject(projectId);
    final latestRaw = await db.getSetting('questionnaire_latest_$projectId');
    final latest = latestRaw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(latestRaw));
    final validLatest = {
      for (final entry in latest.entries)
        if (allForms.any((row) => row.id == entry.value)) entry.key: entry.value
    };
    final forms = allForms.where((row) {
      try {
        final schemaId = (jsonDecode(row.json) as Map)['id'];
        return !validLatest.containsKey(schemaId) ||
            validLatest[schemaId] == row.id;
      } catch (_) {
        return true;
      }
    }).toList();
    final form = forms.where((row) => row.id == config['form_id']).firstOrNull;
    return ProjectWorkspace(
        project, layers, layerId, forms, form ?? forms.firstOrNull);
  }

  Future<ProjectWorkspace> select(int projectId,
      {String? layerId, int? formId}) async {
    final current = await load(projectId);
    if (layerId != null && !current.layers.any((item) => item.id == layerId)) {
      throw StateError('Study layer does not belong to this project');
    }
    if (formId != null && !current.forms.any((item) => item.id == formId)) {
      throw StateError('Form does not belong to this project');
    }
    await db.setSetting(
        _key(projectId),
        jsonEncode({
          'layers': current.layers.map((item) => item.toJson()).toList(),
          'layer_id': layerId ?? current.layerId,
          'form_id': formId ?? current.form?.id,
        }));
    return load(projectId);
  }

  Future<ProjectWorkspace> addLayer(int projectId, String name) async {
    final current = await load(projectId);
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Enter a layer name');
    final layer = StudyLayer(const Uuid().v4(), clean);
    await db.setSetting(
        _key(projectId),
        jsonEncode({
          'layers':
              [...current.layers, layer].map((item) => item.toJson()).toList(),
          'layer_id': layer.id,
          'form_id': current.form?.id,
        }));
    return load(projectId);
  }
}
