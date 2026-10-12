import 'dart:convert';
import 'package:mapbanai/models/survey_form.dart';

class FormAttributeService {
  static Map<String, dynamic> prefill(
      SurveyForm form, Map<String, dynamic> existing,
      {Map<String, dynamic>? geometry, double? accuracy}) {
    final answers = Map<String, dynamic>.from(existing);
    final assignedGeometryTypes = <QuestionType>{};
    for (final question in form.questions) {
      final value = answers[question.name];
      if (question.type == QuestionType.select_multiple && value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) answers[question.name] = decoded;
        } catch (_) {
          answers[question.name] =
              value.split(RegExp(r'\s+')).where((v) => v.isNotEmpty).toList();
        }
      }
      if (value != null && value.toString().isNotEmpty || geometry == null)
        continue;
      if (assignedGeometryTypes.contains(question.type)) continue;
      if (question.type == QuestionType.geopoint &&
          geometry['type'] == 'Point') {
        final coordinates = geometry['coordinates'] as List;
        answers[question.name] =
            '${coordinates[1]},${coordinates[0]},${accuracy ?? 0}';
        assignedGeometryTypes.add(question.type);
      } else if (question.type == QuestionType.geoshape &&
              geometry['type'] == 'Polygon' ||
          question.type == QuestionType.geotrace &&
              geometry['type'] == 'LineString') {
        answers[question.name] = jsonEncode(geometry);
        assignedGeometryTypes.add(question.type);
      }
    }
    return answers;
  }
}
