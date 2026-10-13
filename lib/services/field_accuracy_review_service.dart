import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/field_quality_service.dart';
import 'package:mapbanai/services/study_area_service.dart';

class AccuracyFinding {
  final String key, title, source;
  final double accuracyM;
  final int? sessionId;
  final String? siteId;
  const AccuracyFinding(
      {required this.key,
      required this.title,
      required this.source,
      required this.accuracyM,
      this.sessionId,
      this.siteId});
}

/// Accuracy review never blocks capture and does not run form/duplicate checks.
class FieldAccuracyReviewService {
  final AppDatabase db;
  FieldAccuracyReviewService(this.db);
  String _key(String project) => 'accepted_accuracy:$project';
  Future<Map<String, dynamic>> accepted(String project) async {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(await db.getSetting(_key(project)) ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> accept(String project, AccuracyFinding finding) async {
    await db.transaction(() async {
      final reviews = await accepted(project);
      reviews[finding.key] = {
        'accepted_at': DateTime.now().toUtc().toIso8601String(),
        'accepted_by': await db.getSetting('user_name') ?? '',
        'accuracy_m': finding.accuracyM
      };
      await db.setSetting(_key(project), jsonEncode(reviews));
    });
  }

  Future<void> undo(String project, String key) async {
    await db.transaction(() async {
      final reviews = await accepted(project);
      reviews.remove(key);
      await db.setSetting(_key(project), jsonEncode(reviews));
    });
  }

  static List<AccuracyFinding> scan(
      {required List<SurveySession> sessions,
      required List<StoredForm> forms,
      required List<StudyAreaSite> sites,
      required double limitM,
      Set<String> acceptedKeys = const {}}) {
    if (!limitM.isFinite || limitM <= 0) {
      throw ArgumentError.value(limitM, 'limitM');
    }
    final findings = <String, AccuracyFinding>{};
    final definitions = <String, SurveyForm>{};
    for (final stored in forms) {
      try {
        final f = SurveyForm.fromJson(jsonDecode(stored.json));
        definitions[f.id] = f;
      } catch (_) {}
    }
    void inspect(Map<String, dynamic> response, String identity, String title,
        {int? sessionId, String? siteId}) {
      void add(dynamic raw, String source, List<dynamic> context) {
        final accuracy = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '');
        if (accuracy == null || !accuracy.isFinite || accuracy <= limitM) {
          return;
        }
        final key = sha256
            .convert(utf8
                .encode(jsonEncode([identity, source, accuracy, ...context])))
            .toString();
        if (!acceptedKeys.contains(key)) {
          findings[key] = AccuracyFinding(
              key: key,
              title: title,
              source: source,
              accuracyM: accuracy,
              sessionId: sessionId,
              siteId: siteId);
        }
      }

      final seenPhotos = <String>{};
      void photos(dynamic value) {
        final photo = FieldQualityService.photo(value);
        if (photo != null && seenPhotos.add(photo.path)) {
          add(photo.accuracy, 'Photo: ${photo.fileName}',
              [photo.path, photo.latitude, photo.longitude]);
          return;
        }
        if (value is Map) {
          for (final v in value.values) {
            photos(v);
          }
        }
        if (value is List) {
          for (final v in value) {
            photos(v);
          }
        }
      }

      photos(response['photo']);
      photos(response['answers']);
      photos(response['attributes']);
      add(response['accuracy_m'] ?? response['accuracy'], 'Recorded location', [
        response['latitude'],
        response['longitude'],
        response['gps_fix_timestamp']
      ]);
      SurveyForm? form;
      try {
        if (response['form_snapshot'] is Map) {
          form = SurveyForm.fromJson(
              Map<String, dynamic>.from(response['form_snapshot']));
        }
      } catch (_) {}
      form ??= definitions[response['form_id']];
      final answers = response['answers'];
      if (form != null && answers is Map) {
        for (final question
            in form.questions.where((q) => q.type == QuestionType.geopoint)) {
          final value = answers[question.name];
          if (value is! String) continue;
          final parts = value.trim().split(RegExp(r'[,\s]+'));
          if (parts.length < 3) continue;
          add(
              parts.length >= 4 ? parts[3] : parts[2],
              'Location: ${question.label}',
              [question.name, parts[0], parts[1]]);
        }
      }
    }

    final represented = <String>{};
    for (final session in sessions) {
      if (session.status == 'draft') continue;
      try {
        final response =
            Map<String, dynamic>.from(jsonDecode(session.responses));
        final siteId = response['site_id']?.toString() ??
            (response['site'] is Map
                ? response['site']['id']?.toString()
                : null);
        if (siteId != null) represented.add(siteId);
        inspect(
            response,
            siteId == null
                ? session.externalId ?? 'session:${session.id}'
                : 'site:$siteId',
            session.title,
            sessionId: session.id,
            siteId: siteId);
      } catch (_) {}
    }
    for (final site in sites) {
      if (represented.contains(site.id)) continue;
      inspect({
        'answers': site.formAnswers,
        'attributes': site.attributes,
        'form_snapshot': site.formSnapshot
      }, 'site:${site.id}', site.displayName, siteId: site.id);
    }
    return findings.values.toList()
      ..sort((a, b) => b.accuracyM.compareTo(a.accuracyM));
  }
}
