import 'package:mapbanai/models/study_workflow.dart';

class WorkflowRequirements {
  final bool questionnaire;
  final bool photo;
  const WorkflowRequirements(
      {required this.questionnaire, required this.photo});
  factory WorkflowRequirements.defaults(StudyWorkflow workflow) =>
      WorkflowRequirements(
          questionnaire: workflow != StudyWorkflow.visits, photo: false);
  factory WorkflowRequirements.fromJson(StudyWorkflow workflow, dynamic raw) {
    final defaults = WorkflowRequirements.defaults(workflow);
    if (raw == null) return defaults;
    if (raw is! Map ||
        raw['require_questionnaire'] is! bool ||
        raw['require_photo'] is! bool) {
      throw const FormatException('Invalid workflow requirements.');
    }
    return WorkflowRequirements(
        questionnaire: raw['require_questionnaire'],
        photo: raw['require_photo']);
  }
  Map<String, dynamic> toJson() =>
      {'require_questionnaire': questionnaire, 'require_photo': photo};
}
