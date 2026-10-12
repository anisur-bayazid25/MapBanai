import 'package:flutter/material.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';

/// Survey, GIS and baseline verification share the same typed question UI.
Future<Map<String, dynamic>?> editFormAttributes(
  BuildContext context, {
  required SurveyForm form,
  required Map<String, dynamic> answers,
  String? username,
}) =>
    Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(
        builder: (context) => Scaffold(
              appBar: AppBar(title: Text(form.name)),
              body: SurveyFormRenderer(
                  form: form,
                  initialAnswers: answers,
                  initialUsername: username,
                  onSave: (value) async =>
                      Navigator.pop(context, Map<String, dynamic>.from(value))),
            )));
