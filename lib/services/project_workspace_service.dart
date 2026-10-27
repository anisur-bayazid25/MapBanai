import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_vector_layer_service.dart';
import 'package:uuid/uuid.dart';
import 'package:mapbanai/models/study_workflow.dart';

/// A project owns independent study layers and one shared active form.
/// Stored in AppSettings so database backups and upgrades preserve context.
class StudyLayer {
  final String id;
  final String name;
  final Set<String> workflows;
  const StudyLayer(this.id, this.name, {this.workflows = const {}});
  bool supports(StudyWorkflow mode) =>
      workflows.isEmpty || workflows.contains(mode.name);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (workflows.isNotEmpty) 'workflows': workflows.toList()
      };
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
  Future<Map<String, dynamic>> config(int projectId) async {
    final raw = await db.getSetting(_key(projectId));
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<ProjectWorkspace> load(int projectId,
      {StudyWorkflow? workflow}) async {
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
        layers.add(StudyLayer(item['id'], item['name'],
            workflows:
                (item['workflows'] as List? ?? []).cast<String>().toSet()));
    }
    for (final vector in await ProjectVectorLayerService(db).load(projectId)) {
      if (vector['role'] == 'road') continue;
      final id = ProjectVectorLayerService.studyLayerId(vector);
      if (!layers.any((layer) => layer.id == id)) {
        layers.add(StudyLayer(id, vector['name'].toString(),
            workflows:
                (vector['workflows'] as List? ?? []).cast<String>().toSet()));
      }
    }
    if (workflow != null)
      layers.removeWhere((layer) => !layer.supports(workflow));
    final selection = workflow == null
        ? config
        : Map<String, dynamic>.from(
            (config['workflows'] as Map?)?[workflow.name] as Map? ?? config);
    final layerId = layers.any((item) => item.id == selection['layer_id'])
        ? selection['layer_id'] as String
        : layers.first.id;
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
    final form =
        forms.where((row) => row.id == selection['form_id']).firstOrNull;
    return ProjectWorkspace(
        project, layers, layerId, forms, form ?? forms.firstOrNull);
  }

  Future<ProjectWorkspace> select(int projectId,
      {String? layerId, int? formId, StudyWorkflow? workflow}) async {
    final current = await load(projectId, workflow: workflow);
    if (layerId != null && !current.layers.any((item) => item.id == layerId)) {
      throw StateError('Study layer does not belong to this project');
    }
    if (formId != null && !current.forms.any((item) => item.id == formId)) {
      throw StateError('Form does not belong to this project');
    }
    final stored = await config(projectId);
    final selection = <String, dynamic>{
      'layer_id': layerId ?? current.layerId,
      'form_id': formId ?? current.form?.id,
    };
    if (workflow == null) {
      stored.addAll(selection);
    } else {
      final modes =
          Map<String, dynamic>.from(stored['workflows'] as Map? ?? {});
      modes[workflow.name] = {
        ...Map<String, dynamic>.from(modes[workflow.name] as Map? ?? {}),
        ...selection
      };
      stored['workflows'] = modes;
    }
    await db.setSetting(_key(projectId), jsonEncode(stored));
    return load(projectId, workflow: workflow);
  }

  Future<ProjectWorkspace> addLayer(int projectId, String name,
      {StudyWorkflow? workflow}) async {
    final current = await load(projectId);
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Enter a layer name');
    final layer = StudyLayer(const Uuid().v4(), clean,
        workflows: workflow == null ? {} : {workflow.name});
    final stored = await config(projectId);
    await db.setSetting(
        _key(projectId),
        jsonEncode({
          ...stored,
          'layers':
              [...current.layers, layer].map((item) => item.toJson()).toList(),
          'layer_id': layer.id,
          'form_id': current.form?.id,
        }));
    return workflow == null
        ? load(projectId)
        : select(projectId, layerId: layer.id, workflow: workflow);
  }

  Future<List<CollectionRound>> rounds(int projectId, String layerId) async =>
      ((await config(projectId))['collection_rounds'] as List? ?? [])
          .map((raw) => CollectionRound.fromJson(raw as Map))
          .where((round) => round.layerId == layerId)
          .toList();

  Future<void> selectRound(
      int projectId, StudyWorkflow workflow, String? roundId) async {
    final stored = await config(projectId);
    final modes = Map<String, dynamic>.from(stored['workflows'] as Map? ?? {});
    final selection =
        Map<String, dynamic>.from(modes[workflow.name] as Map? ?? {});
    if (roundId != null &&
        !((stored['collection_rounds'] as List? ?? []).any((round) =>
            round['id'] == roundId &&
            round['layer_id'] == selection['layer_id'])))
      throw StateError('This collection round belongs to another layer.');
    selection['round_id'] = roundId;
    modes[workflow.name] = selection;
    stored['workflows'] = modes;
    await db.setSetting(_key(projectId), jsonEncode(stored));
  }

  Future<CollectionRound> addRound(int projectId, String layerId, String name,
      {String period = '', String date = ''}) async {
    if (name.trim().isEmpty)
      throw ArgumentError('Enter a collection round name.');
    final workspace = await load(projectId, workflow: StudyWorkflow.recurring);
    if (!workspace.layers.any((layer) => layer.id == layerId))
      throw StateError('Choose a recurring layer from this project.');
    return db.transaction(() async {
      final stored = await config(projectId);
      final rounds =
          List<dynamic>.from(stored['collection_rounds'] as List? ?? []);
      if (rounds.any((raw) =>
          raw['layer_id'] == layerId &&
          raw['name'].toString().toLowerCase() == name.trim().toLowerCase()))
        throw StateError('A collection round with this name already exists.');
      final round = CollectionRound(
          id: const Uuid().v4(),
          name: name.trim(),
          layerId: layerId,
          period: period.trim(),
          date: date);
      rounds.add(round.toJson());
      stored['collection_rounds'] = rounds;
      await db.setSetting(_key(projectId), jsonEncode(stored));
      return round;
    });
  }
}
