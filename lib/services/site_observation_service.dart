import 'dart:convert';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/study_collection_service.dart';

class SiteObservation {
  final String id;
  final DateTime timestamp;
  final String author;
  final String formId;
  final String formName;
  final Map<String, dynamic> answers;
  final Map<String, dynamic> form;
  final String outcome;
  final String note;
  final String roundName;
  final String period;
  final String workflow;
  const SiteObservation(this.id, this.timestamp, this.author, this.formId,
      this.formName, this.answers, this.form, this.outcome, this.note,
      {this.roundName = '', this.period = '', this.workflow = ''});
  double? number(String key) {
    for (final question in form['questions'] as List? ?? []) {
      if (question is Map &&
          question['name'] == key &&
          !['integer', 'decimal', 'calculated', 'gps_accuracy']
              .contains(question['type'])) {
        return null; // Numeric category codes and dates are not measurements.
      }
    }
    final value = answers[key];
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}

/// Separate child observations; the site's current attributes are only a summary.
/// Includes imported visit revisions, deduplicated against durable local interviews.
class SiteObservationService {
  final AppDatabase db;
  SiteObservationService(this.db);
  Future<List<SiteObservation>> load(int projectId, StudyAreaSite site) async {
    final project = await db.getProjectById(projectId);
    if (project == null ||
        !GuidedVisitService.belongsToProject(site, project)) {
      throw StateError('This feature belongs to another project.');
    }
    final observations = <String, SiteObservation>{};
    for (final revision in site.history) {
      if (revision.visitId == null) continue;
      if (revision.projectExternalId != null &&
          revision.projectExternalId != project.externalId) continue;
      final after = revision.after;
      final form =
          Map<String, dynamic>.from(after['form_snapshot'] as Map? ?? {});
      observations[revision.visitId!] = SiteObservation(
          revision.visitId!,
          revision.timestamp,
          revision.author,
          '${form['id'] ?? ''}',
          '${form['name'] ?? 'Imported visit'}',
          Map<String, dynamic>.from(after['form_answers'] as Map? ?? {}),
          form,
          '${after['status'] ?? ''}',
          '${after['change_note'] ?? ''}');
    }
    for (final row in await db.getSurveySessionsByProject(projectId)) {
      final collection = StudyCollectionService.data(row);
      if (row.status == 'saved' &&
          collection != null &&
          collection['site_id'] == site.id &&
          collection['record_kind'] == 'observation') {
        final id = row.externalId ?? 'local:${row.id}';
        final round = collection['collection_round'] as Map?;
        observations[id] = SiteObservation(
            id,
            DateTime.tryParse('${collection['observed_at']}') ?? row.createdAt,
            '${collection['user_name'] ?? ''}',
            '${collection['form_id'] ?? ''}',
            '${collection['form_name'] ?? ''}',
            Map<String, dynamic>.from(collection['answers'] as Map? ?? {}),
            Map<String, dynamic>.from(
                collection['form_snapshot'] as Map? ?? {}),
            '${collection['outcome'] ?? ''}',
            '${collection['note'] ?? ''}',
            roundName: '${round?['name'] ?? ''}',
            period: '${round?['period'] ?? ''}',
            workflow: '${collection['study_workflow'] ?? ''}');
      }
      if (row.status != 'saved' || !GuidedVisitService.isVisit(row)) continue;
      final visit = GuidedVisitService.visit(row);
      if (visit['site_id'] != site.id) continue;
      final response = GuidedVisitService.decode(row);
      final after = visit['site_after'] as Map? ?? {};
      final id = '${visit['id']}';
      observations[id] = SiteObservation(
          id,
          DateTime.tryParse('${visit['completed_at']}') ?? row.createdAt,
          '${response['user_name'] ?? ''}',
          '${response['form_id'] ?? ''}',
          '${response['form_name'] ?? 'Visit'}',
          Map<String, dynamic>.from(response['answers'] as Map? ?? {}),
          Map<String, dynamic>.from(response['form_snapshot'] as Map? ?? {}),
          '${after['status'] ?? ''}',
          '${after['change_note'] ?? ''}');
    }
    return observations.values.toList()
      ..sort((a, b) {
        final order = a.timestamp.compareTo(b.timestamp);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
  }

  static Map<String, String> numericFields(List<SiteObservation> rows,
      {String? formId}) {
    final fields = <String, String>{};
    for (final row
        in rows.where((row) => formId == null || row.formId == formId)) {
      for (final entry in row.answers.entries) {
        if (row.number(entry.key) == null) continue;
        fields[entry.key] = entry.key;
        for (final question in row.form['questions'] as List? ?? []) {
          if (question is Map && question['name'] == entry.key) {
            fields[entry.key] = '${question['label'] ?? entry.key}';
          }
        }
      }
    }
    return fields;
  }

  static String csv(StudyAreaSite site, List<SiteObservation> rows) {
    final keys = rows.expand((row) => row.answers.keys).toSet().toList()
      ..sort();
    String cell(dynamic value) {
      var text = value is Map || value is List ? jsonEncode(value) : '$value';
      if (value is String && RegExp(r'^[=+@\-]').hasMatch(text))
        text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    final data = <List<dynamic>>[
      [
        'feature_uuid',
        'site_id',
        'observation_uuid',
        'observed_at',
        'form_id',
        'form_version',
        'observer',
        'outcome',
        'note',
        'workflow',
        'collection_round',
        'period',
        ...keys
      ],
      for (final row in rows)
        [
          site.featureUuid,
          site.id,
          row.id,
          row.timestamp.toUtc().toIso8601String(),
          row.formId,
          row.form['version'] ?? '',
          row.author,
          row.outcome,
          row.note,
          row.workflow,
          row.roundName,
          row.period,
          for (final key in keys) row.answers[key] ?? ''
        ],
    ];
    return data.map((row) => row.map(cell).join(',')).join('\r\n');
  }
}
