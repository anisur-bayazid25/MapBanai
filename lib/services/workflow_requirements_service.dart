import 'dart:convert';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/study_workflow.dart';
import 'package:mapbanai/models/workflow_requirements.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/photo_store.dart';

class WorkflowRequirementsService {
  final AppDatabase db;
  WorkflowRequirementsService(this.db);
  Future<Map<StudyWorkflow, WorkflowRequirements>> load(int projectId) async {
    final raw = await db.getSetting('project_workspace_$projectId');
    final settings = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map;
    return decode(settings['workflow_requirements']);
  }

  static Map<StudyWorkflow, WorkflowRequirements> decode(dynamic raw) {
    if (raw != null && raw is! Map)
      throw const FormatException('Invalid workflow requirements.');
    return {
      for (final mode in StudyWorkflow.values)
        mode: WorkflowRequirements.fromJson(mode, (raw as Map?)?[mode.name])
    };
  }

  Future<WorkflowRequirements> get(
          int projectId, StudyWorkflow workflow) async =>
      (await load(projectId))[workflow]!;
  Future<void> save(
      int projectId, Map<StudyWorkflow, WorkflowRequirements> values) async {
    if (await db.getProjectById(projectId) == null)
      throw StateError('Project no longer exists.');
    await db.transaction(() async {
      final key = 'project_workspace_$projectId';
      final raw = await db.getSetting(key);
      final settings = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw));
      settings['workflow_requirements'] = {
        for (final mode in StudyWorkflow.values)
          mode.name:
              (values[mode] ?? WorkflowRequirements.defaults(mode)).toJson()
      };
      await db.setSetting(key, jsonEncode(settings));
    });
  }

  /// A valid photo already collected in the questionnaire can satisfy the rule.
  static Future<String?> photoError(
      Map<String, dynamic> answers, PhotoRecord? evidence) async {
    if (evidence != null) return FieldQualityService.validatePhoto(evidence);
    final candidates = <PhotoRecord>[];
    void inspect(dynamic value) {
      final photo = FieldQualityService.photo(value);
      if (photo != null) {
        candidates.add(photo);
        return;
      }
      if (value is Map) {
        for (final child in value.values) {
          inspect(child);
        }
      }
      if (value is List) {
        for (final child in value) {
          inspect(child);
        }
      }
    }

    inspect(answers);
    for (final photo in candidates) {
      if (await FieldQualityService.validatePhoto(photo) == null) return null;
    }
    return 'A geotagged photo is required.';
  }
}
