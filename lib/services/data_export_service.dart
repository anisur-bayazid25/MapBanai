import 'dart:convert';
import 'package:mapbanai/models/survey_form.dart';

/// Service for exporting survey data and forms to JSON format
class DataExportService {
  /// Export all survey responses as JSON
  static String exportSurveyResponses(
    List<Map<String, dynamic>> responses, {
    String? surveyor,
  }) {
    final json = {
      'export_date': DateTime.now().toIso8601String(),
      'export_version': 1,
      if (surveyor != null && surveyor.trim().isNotEmpty) 'surveyor': surveyor,
      'responses': responses,
    };
    return jsonEncode(json);
  }

  /// Export a single survey form as JSON
  static String exportSurveyForm(SurveyForm form) {
    return jsonEncode(form.toJson());
  }

  /// Export multiple survey forms as JSON
  static String exportSurveyForms(List<SurveyForm> forms) {
    final json = {
      'export_date': DateTime.now().toIso8601String(),
      'export_version': 1,
      'forms': forms.map((f) => f.toJson()).toList(),
    };
    return jsonEncode(json);
  }

  /// Format JSON response for display
  static String prettifyJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      return JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return jsonString;
    }
  }

  /// Generate a CSV export of survey responses
  static String exportSurveyResponsesAsCSV(
    List<Map<String, dynamic>> responses,
    List<String> headers,
  ) {
    final StringBuffer csv = StringBuffer();

    // Write headers
    csv.writeln(headers.join(','));

    // Write data rows
    for (final response in responses) {
      final row = headers
          .map((header) => _escapeCSV(response[header]?.toString() ?? ''))
          .toList();
      csv.writeln(row.join(','));
    }

    return csv.toString();
  }

  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// Service for importing survey data and forms from JSON
class DataImportService {
  /// Import survey forms from JSON
  static List<SurveyForm>? importSurveyForms(String jsonString) {
    try {
      final json = jsonDecode(jsonString);

      // Check if it's a single form or multiple
      if (json is Map && json.containsKey('form_id')) {
        // Single form
        return [SurveyForm.fromJson(Map<String, dynamic>.from(json))];
      } else if (json is Map && json.containsKey('forms')) {
        // Multiple forms export
        final forms = (json['forms'] as List)
            .map((f) => SurveyForm.fromJson(f))
            .toList();
        return forms;
      } else if (json is List) {
        // Array of forms
        return json.map((f) => SurveyForm.fromJson(f)).toList();
      }
    } catch (e) {
      print('Error importing forms: $e');
    }
    return null;
  }

  /// Import survey responses from JSON
  static List<Map<String, dynamic>>? importSurveyResponses(String jsonString) {
    try {
      final json = jsonDecode(jsonString);

      if (json is Map && json.containsKey('responses')) {
        // Export format
        return List<Map<String, dynamic>>.from(json['responses']);
      } else if (json is List) {
        // Array of responses
        return json.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error importing responses: $e');
    }
    return null;
  }

  /// Validate JSON format
  static bool isValidJSON(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }
}
