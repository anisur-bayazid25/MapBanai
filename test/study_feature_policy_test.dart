import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/study_feature_policy.dart';
import 'package:mapbanai/services/study_area_service.dart';

void main() {
  test('only new and updated edit statuses require questionnaires', () {
    for (final status in StudyAreaStatus.values) {
      expect(
          StudyFeaturePolicy.requiresSurvey(status),
          status == StudyAreaStatus.newFeature ||
              status == StudyAreaStatus.updated);
    }
  });
  test('a newly created feature always requires a questionnaire', () {
    for (final status in StudyAreaStatus.values) {
      expect(StudyFeaturePolicy.requiresSurvey(status, isNew: true), true);
    }
  });
}
