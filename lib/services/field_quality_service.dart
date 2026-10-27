import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:math' as math;

import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/geotag_writer.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/services/study_area_service.dart';
import 'package:mapbanai/services/survey_logic.dart';

class FieldQualityIssue {
  final String code;
  final String message;
  final int? sessionId;
  final String? siteId;
  final String? relatedSiteId;
  final int? relatedSessionId;
  const FieldQualityIssue(this.code, this.message,
      {this.sessionId, this.siteId, this.relatedSiteId, this.relatedSessionId});
}

class FieldQualityService {
  /// A hostile/accidental exponential regex must never block the UI isolate.
  static Future<List<String>> validateAnswersInWorker(
      SurveyForm form, Map<String, dynamic> answers,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final port = ReceivePort();
    Isolate? worker;
    try {
      worker = await Isolate.spawn(
          _validateWorker, [port.sendPort, form.toJson(), answers]);
      final result = await port.first.timeout(timeout);
      return List<String>.from(result as List);
    } on TimeoutException {
      return [
        'Form validation exceeded its time limit. Review this record and its expressions; validation is incomplete.'
      ];
    } finally {
      worker?.kill(priority: Isolate.immediate);
      port.close();
    }
  }

  static void _validateWorker(List<dynamic> arguments) async {
    final reply = arguments[0] as SendPort;
    try {
      final form = SurveyForm.fromJson(Map<String, dynamic>.from(arguments[1]));
      final answers = Map<String, dynamic>.from(arguments[2]);
      reply.send([
        ...validateAnswers(form, answers),
        ...(await validateMedia(form, answers)).map((error) => 'Photo: $error')
      ]);
    } catch (error) {
      reply.send(['Form validation failed: $error']);
    }
  }

  static bool empty(dynamic value) =>
      value == null ||
      value.toString().trim().isEmpty ||
      (value is List && value.isEmpty);

  /// Matches the renderer's question and enclosing-group visibility.
  static List<String> validateAnswers(
      SurveyForm form, Map<String, dynamic> answers) {
    final errors = <String>[];
    final groups = form.groupByName;
    final groupVisibility = {
      for (final entry in groups.entries)
        entry.key: entry.value.isRelevant(answers)
    };
    if (form.groups.any((group) => group.isRepeat))
      errors.add('Repeated records are unsupported in this form.');
    for (final question in form.questions) {
      if (question.type == QuestionType.hidden ||
          question.type == QuestionType.note ||
          question.type == QuestionType.calculated) continue;
      if (!question.isRelevant(answers) ||
          question.groupPath.any((name) => groupVisibility[name] == false))
        continue;
      final value = answers[question.name];
      if (question.required && empty(value)) {
        errors.add('${question.label}: required answer missing');
        continue;
      }
      if (empty(value)) continue;
      if (question.type == QuestionType.integer &&
          int.tryParse(value.toString()) == null)
        errors.add('${question.label}: invalid whole number');
      if (question.type == QuestionType.decimal &&
          (double.tryParse(value.toString()) == null ||
              !double.parse(value.toString()).isFinite))
        errors.add('${question.label}: invalid number');

      if (question.choices != null) {
        final selected = value is List ? value : [value.toString()];
        if (selected.any((item) =>
            !question.choices!.any((choice) => choice.name == item.toString())))
          errors.add(
              '${question.label}: an answer is no longer in the choices list');
      }
      if (question.type == QuestionType.date ||
          question.type == QuestionType.datetime) {
        final parsed = DateTime.tryParse(value.toString());
        final match =
            RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value.toString());
        final localDate = match == null ? null : DateTime.tryParse(match[0]!);
        if (parsed == null ||
            match == null ||
            localDate == null ||
            localDate.year != int.parse(match[1]!) ||
            localDate.month != int.parse(match[2]!) ||
            localDate.day != int.parse(match[3]!))
          errors.add('${question.label}: invalid date');
      }
      if (question.type == QuestionType.time && !_validTime(value.toString()))
        errors.add('${question.label}: invalid time');
      if (question.type == QuestionType.geopoint) {
        final parts = value
            .toString()
            .split(RegExp(r'[,\s]+'))
            .map(double.tryParse)
            .toList();
        if (parts.length < 2 ||
            parts[0] == null ||
            parts[1] == null ||
            !parts[0]!.isFinite ||
            !parts[1]!.isFinite ||
            parts[0]!.abs() > 90 ||
            parts[1]!.abs() > 180)
          errors.add('${question.label}: invalid location');
      }
      if (question.type == QuestionType.geoshape ||
          question.type == QuestionType.geotrace) {
        if (!validGeometry(value,
            expectedType: question.type == QuestionType.geoshape
                ? 'Polygon'
                : 'LineString'))
          errors.add('${question.label}: invalid geometry');
      }
      if (question.type == QuestionType.image && photo(value) == null)
        errors.add('${question.label}: photo record is invalid');
      final constraint = SurveyLogic.evaluateConstraint(
          question.constraint, value, question.constraintMessage,
          answers: answers);
      if (constraint != null) errors.add('${question.label}: $constraint');
    }
    return errors;
  }

  static bool _validTime(String value) {
    final match = RegExp(r'^(\d{1,2}):([0-5]\d)(?::[0-5]\d)?(?:\s*([ap]m))?$',
            caseSensitive: false)
        .firstMatch(value);
    if (match == null) return false;
    final hour = int.parse(match[1]!);
    return match[3] == null ? hour <= 23 : hour >= 1 && hour <= 12;
  }

  static bool validGeometry(dynamic value, {String? expectedType}) {
    try {
      final geometry = value is String ? jsonDecode(value) : value;
      if (geometry is! Map ||
          (expectedType != null && geometry['type'] != expectedType))
        return false;
      bool point(dynamic coordinates) =>
          coordinates is List &&
          coordinates.length >= 2 &&
          coordinates[0] is num &&
          coordinates[1] is num &&
          (coordinates[0] as num).isFinite &&
          (coordinates[1] as num).isFinite &&
          (coordinates[0] as num).abs() <= 180 &&
          (coordinates[1] as num).abs() <= 90;
      final coordinates = geometry['coordinates'];
      if (geometry['type'] == 'Point') return point(coordinates);
      if (geometry['type'] == 'GeometryCollection')
        return geometry['geometries'] is List &&
            (geometry['geometries'] as List).isNotEmpty &&
            (geometry['geometries'] as List).every(validGeometry);
      if (geometry['type'] == 'MultiPoint')
        return coordinates is List &&
            coordinates.isNotEmpty &&
            coordinates.every(point);
      if (geometry['type'] == 'MultiLineString')
        return coordinates is List &&
            coordinates.isNotEmpty &&
            coordinates.every((line) =>
                validGeometry({'type': 'LineString', 'coordinates': line}));
      if (geometry['type'] == 'MultiPolygon')
        return coordinates is List &&
            coordinates.isNotEmpty &&
            coordinates.every((polygon) =>
                validGeometry({'type': 'Polygon', 'coordinates': polygon}));
      if (geometry['type'] == 'LineString')
        return coordinates is List &&
            coordinates.length >= 2 &&
            coordinates.every(point) &&
            coordinates.map(jsonEncode).toSet().length >= 2;
      if (geometry['type'] == 'Polygon')
        return coordinates is List &&
            coordinates.isNotEmpty &&
            coordinates.every((ring) =>
                ring is List &&
                ring.length >= 4 &&
                ring.every(point) &&
                jsonEncode(ring.first) == jsonEncode(ring.last) &&
                ring.map(jsonEncode).toSet().length >= 3);
    } catch (_) {}
    return false;
  }

  static Future<List<String>> validateMedia(
      SurveyForm form, Map<String, dynamic> answers) async {
    final errors = <String>[];
    for (final question in form.questions
        .where((question) => question.type == QuestionType.image)) {
      if (!question.isRelevant(answers) ||
          question.groupPath.any(
              (name) => form.groupByName[name]?.isRelevant(answers) == false))
        continue;
      final value = answers[question.name];
      if (empty(value) && !question.required) continue;
      final error = await validatePhoto(photo(value));
      if (error != null) errors.add('${question.label}: $error');
    }
    return errors;
  }

  static PhotoRecord? photo(dynamic value) {
    try {
      final decoded = value is String ? jsonDecode(value) : value;
      if (decoded is Map && decoded['path'] is String)
        return PhotoRecord.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {}
    return null;
  }

  /// Verify image bytes, rather than trusting a sidecar's GPS flag.
  static Future<String?> validatePhoto(PhotoRecord? record) async {
    if (record == null) return 'A geotagged photo is required.';
    try {
      if (!await File(record.path).exists())
        return 'Photo file is missing: ${record.fileName}';
      final embedded =
          GeotagWriter.readGps(await File(record.path).readAsBytes());
      if (embedded == null)
        return 'Photo has no valid GPS EXIF: ${record.fileName}';
      if (record.latitude != null &&
              (embedded.latitude - record.latitude!).abs() > 0.00001 ||
          record.longitude != null &&
              (embedded.longitude - record.longitude!).abs() > 0.00001)
        return 'Photo GPS differs from its stored location: ${record.fileName}';
    } catch (error) {
      return 'Photo cannot be read: ${record.fileName} ($error)';
    }
    return null;
  }

  Future<List<FieldQualityIssue>> inspect(
      {required List<SurveySession> sessions,
      required List<StoredForm> forms,
      required List<StudyAreaSite> sites,
      required double accuracyThresholdM,
      double duplicateDistanceM = 10,
      void Function(int completed, int total, String title)?
          onProgress}) async {
    if (!duplicateDistanceM.isFinite || duplicateDistanceM <= 0)
      throw ArgumentError.value(duplicateDistanceM, 'duplicateDistanceM');
    final issues = <FieldQualityIssue>[];
    final points = <_QualityPoint>[];
    final parsedForms = <String, SurveyForm>{};
    for (final stored in forms) {
      try {
        final form = SurveyForm.fromJson(jsonDecode(stored.json));
        parsedForms[form.id] = form;
      } catch (_) {}
    }
    var completed = 0;
    for (final site in sites) {
      if (site.currentGeometry['type'] == 'Point')
        points.add(_QualityPoint(
            site.latitude, site.longitude, site.displayName,
            siteId: site.id));
    }
    for (final session in sessions) {
      onProgress?.call(completed++, sessions.length, session.title);
      await Future<void>.delayed(Duration.zero);
      Map<String, dynamic> response;
      try {
        response =
            Map<String, dynamic>.from(jsonDecode(session.responses) as Map);
      } catch (_) {
        issues.add(FieldQualityIssue(
            'invalid_data', '${session.title}: response cannot be read',
            sessionId: session.id));
        continue;
      }
      final visit = response['visit'];
      if (visit is Map &&
          visit['site_sync'] == 'pending' &&
          session.status == 'saved')
        issues.add(FieldQualityIssue('map_pending',
            '${session.title}: saved visit has not been applied to the study map',
            sessionId: session.id, siteId: visit['site_id']?.toString()));
      if (session.status == 'draft') {
        issues.add(FieldQualityIssue(
            'draft', '${session.title}: unfinished collection',
            sessionId: session.id));
        continue;
      }
      final answers = response['answers'] is Map
          ? Map<String, dynamic>.from(response['answers'])
          : <String, dynamic>{};
      SurveyForm? form;
      if (response['form_snapshot'] is Map) {
        try {
          form = SurveyForm.fromJson(
              Map<String, dynamic>.from(response['form_snapshot']));
        } catch (_) {
          issues.add(FieldQualityIssue('missing_form',
              '${session.title}: saved form definition cannot be read',
              sessionId: session.id));
        }
      }
      form ??= parsedForms[response['form_id']];
      if (response['form_id'] != null && form == null)
        issues.add(FieldQualityIssue('missing_form',
            '${session.title}: form definition is unavailable, required answers cannot be checked',
            sessionId: session.id));
      if (form != null) {
        for (final error in await validateAnswersInWorker(form, answers))
          issues.add(FieldQualityIssue(
              error.startsWith('Photo:')
                  ? 'photo'
                  : error.contains('time limit')
                      ? 'check_timeout'
                      : 'answer',
              '${session.title}: $error',
              sessionId: session.id));
      }
      final photos = <PhotoRecord>[];
      final topPhoto = photo(response['photo']);
      if (topPhoto != null) photos.add(topPhoto);
      void collectPhotos(dynamic value) {
        final record = photo(value);
        if (record != null) {
          if (!photos.any((item) => item.path == record.path))
            photos.add(record);
        } else if (value is Map) {
          for (final child in value.values) {
            collectPhotos(child);
          }
        } else if (value is List) {
          for (final child in value) {
            collectPhotos(child);
          }
        }
      }

      collectPhotos(answers);
      for (final record in photos) {
        if (record.accuracy != null &&
            (!record.accuracy!.isFinite ||
                record.accuracy! <= 0 ||
                record.accuracy! > accuracyThresholdM))
          issues.add(FieldQualityIssue('gps_accuracy',
              '${session.title}: photo GPS accuracy ${record.accuracy} m exceeds the project review threshold $accuracyThresholdM m',
              sessionId: session.id));
        if (record.gpsFixedAt != null &&
            (record.capturedAt.difference(record.gpsFixedAt!).inSeconds > 30 ||
                record.gpsFixedAt!.difference(record.capturedAt).inSeconds >
                    30))
          issues.add(FieldQualityIssue('gps_stale',
              '${session.title}: photo GPS fix was stale at capture',
              sessionId: session.id));
        final problem = await validatePhoto(record);
        if (problem != null)
          issues.add(FieldQualityIssue('photo', '${session.title}: $problem',
              sessionId: session.id));
      }
      if (photos.isEmpty &&
          ((response['workflow_requirements'] as Map?)?['require_photo'] ==
                  true ||
              (visit is Map && response['workflow_requirements'] == null)))
        issues.add(FieldQualityIssue(
            'photo', '${session.title}: visit evidence photo is missing',
            sessionId: session.id));
      final accuracy = _number(response['accuracy_m'] ?? response['accuracy']);
      if (accuracy != null &&
          (!accuracy.isFinite ||
              accuracy <= 0 ||
              accuracy > accuracyThresholdM))
        issues.add(FieldQualityIssue('gps_accuracy',
            '${session.title}: GPS accuracy ${accuracy.toStringAsFixed(1)} m exceeds the project limit $accuracyThresholdM m',
            sessionId: session.id));
      final fixTime =
          DateTime.tryParse(response['gps_fix_timestamp']?.toString() ?? '');
      final recordedTime =
          DateTime.tryParse(response['recorded_at']?.toString() ?? '') ??
              session.createdAt;
      if (fixTime != null &&
          (recordedTime.difference(fixTime).inSeconds > 30 ||
              fixTime.difference(recordedTime).inSeconds > 5))
        issues.add(FieldQualityIssue(
            'gps_stale', '${session.title}: GPS fix was stale at capture',
            sessionId: session.id));
      final lat = _number(response['latitude']);
      final lon = _number(response['longitude']);
      if (response['feature_type'] == 'point' && lat != null && lon != null)
        points.add(_QualityPoint(lat, lon, session.title,
            sessionId: session.id,
            linkedSiteId: visit is Map ? visit['site_id']?.toString() : null));
      if (form != null) {
        for (final question in form.questions
            .where((item) => item.type == QuestionType.geopoint)) {
          final value = answers[question.name];
          if (value is! String || value.trim().isEmpty) continue;
          final parts =
              value.split(RegExp(r'[,\s]+')).map(double.tryParse).toList();
          if (parts.length < 2 || parts[0] == null || parts[1] == null) {
            issues.add(FieldQualityIssue('geometry',
                '${session.title}: ${question.label} is not a valid location',
                sessionId: session.id));
            continue;
          }
          // MapBanai geopoints are lat,lon,accuracy; ODK space values include altitude before accuracy.
          final fieldAccuracy = parts.length > 3
              ? parts[3]
              : parts.length > 2
                  ? parts[2]
                  : null;
          if (fieldAccuracy != null &&
              (!fieldAccuracy.isFinite ||
                  fieldAccuracy <= 0 ||
                  fieldAccuracy > accuracyThresholdM))
            issues.add(FieldQualityIssue('gps_accuracy',
                '${session.title}: ${question.label} accuracy exceeds $accuracyThresholdM m',
                sessionId: session.id));
          points.add(_QualityPoint(
              parts[0]!, parts[1]!, '${session.title} / ${question.label}',
              sessionId: session.id,
              linkedSiteId:
                  visit is Map ? visit['site_id']?.toString() : null));
        }
      }
    }
    // Spatial buckets bound candidate comparisons for large field datasets.
    final buckets = <String, List<_QualityPoint>>{};
    final latitudeStep = duplicateDistanceM / 111320;
    var comparisons = 0;
    var duplicateCount = 0;
    duplicateScan:
    for (final point in points) {
      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude.abs() > 90 ||
          point.longitude.abs() > 180) continue;
      final row = (point.latitude / latitudeStep).floor();
      // Longitude buckets use the same angular span; inspect enough neighbors at this latitude.
      final column = (point.longitude / latitudeStep).floor();
      final span =
          (1 / math.cos(point.latitude * math.pi / 180).abs().clamp(0.01, 1))
              .ceil();
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -span; dx <= span; dx++) {
          for (final other in buckets['${row + dy}:${column + dx}'] ??
              const <_QualityPoint>[]) {
            if (++comparisons % 1000 == 0)
              await Future<void>.delayed(Duration.zero);
            if (comparisons > 100000 || duplicateCount >= 1000) {
              issues.add(const FieldQualityIssue('duplicate_scan_limit',
                  'Duplicate review reached its limit. Filter by study layer or inspect smaller batches to review the remaining candidates.'));
              break duplicateScan;
            }
            if (point.sessionId != null && point.sessionId == other.sessionId)
              continue;
            if ((point.linkedSiteId != null &&
                    point.linkedSiteId == other.siteId) ||
                (other.linkedSiteId != null &&
                    other.linkedSiteId == point.siteId)) continue;
            if (point.linkedSiteId != null &&
                point.linkedSiteId == other.linkedSiteId) continue;
            final distance = _distance(point, other);
            if (distance <= duplicateDistanceM) {
              duplicateCount++;
              issues.add(FieldQualityIssue('near_duplicate',
                  '${point.label} and ${other.label} are ${distance.toStringAsFixed(1)} m apart. Review whether they are separate features.',
                  sessionId: point.sessionId ?? other.sessionId,
                  siteId: point.siteId ?? other.siteId,
                  relatedSiteId: other.siteId,
                  relatedSessionId: other.sessionId));
            }
          }
        }
      }
      buckets.putIfAbsent('$row:$column', () => []).add(point);
    }
    return issues;
  }

  static double? _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  static double _distance(_QualityPoint a, _QualityPoint b) {
    const rad = math.pi / 180;
    final deltaLat = (b.latitude - a.latitude) * rad;
    final deltaLon = (b.longitude - a.longitude) * rad;
    final h = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(a.latitude * rad) *
            math.cos(b.latitude * rad) *
            math.pow(math.sin(deltaLon / 2), 2);
    return 6371000 *
        2 *
        math.atan2(math.sqrt(h.clamp(0, 1)), math.sqrt((1 - h).clamp(0, 1)));
  }
}

class _QualityPoint {
  final double latitude;
  final double longitude;
  final String label;
  final int? sessionId;
  final String? siteId;
  final String? linkedSiteId;
  const _QualityPoint(this.latitude, this.longitude, this.label,
      {this.sessionId, this.siteId, this.linkedSiteId});
}
