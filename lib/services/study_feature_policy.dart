import 'package:mapbanai/services/study_area_service.dart';

class StudyFeaturePolicy {
  static bool requiresSurvey(StudyAreaStatus status, {bool isNew = false}) =>
      isNew ||
      status == StudyAreaStatus.newFeature ||
      status == StudyAreaStatus.updated;
}
