import 'dart:convert';

/// Spatial answers retain their geometry while sharing the same survey record.
class RecordGeometry {
  static List<Map<String, dynamic>> fromResponses(
      Map<String, dynamic> response) {
    final result = <Map<String, dynamic>>[];
    if (response['feature_type'] == 'point' &&
        response['latitude'] is num &&
        response['longitude'] is num) {
      result.add({
        'type': 'Point',
        'coordinates': [response['longitude'], response['latitude']]
      });
    } else if (response['vertices'] is List) {
      final coordinates = <List<dynamic>>[
        for (final vertex in response['vertices'])
          if (vertex is Map &&
              vertex['longitude'] is num &&
              vertex['latitude'] is num)
            [vertex['longitude'], vertex['latitude']]
      ];
      if (response['feature_type'] == 'polygon' && coordinates.length >= 3) {
        if (jsonEncode(coordinates.first) != jsonEncode(coordinates.last))
          coordinates.add(List.from(coordinates.first));
        result.add({
          'type': 'Polygon',
          'coordinates': [coordinates]
        });
      } else if (response['feature_type'] == 'line' &&
          coordinates.length >= 2) {
        result.add({'type': 'LineString', 'coordinates': coordinates});
      }
    }
    final direct = response['geometry'];
    if (direct is Map) result.add(Map<String, dynamic>.from(direct));
    final visit = response['visit'];
    final site = visit is Map ? visit['site_after'] : null;
    if (site is Map) {
      if (site['geometry'] is Map) {
        result.add(Map<String, dynamic>.from(site['geometry']));
      } else if (site['latitude'] is num && site['longitude'] is num) {
        result.add({
          'type': 'Point',
          'coordinates': [site['longitude'], site['latitude']]
        });
      }
    }
    final snapshot = response['form_snapshot'];
    final questions = snapshot is Map ? snapshot['questions'] : null;
    final spatial = <String>{};
    if (questions is List) {
      for (final question in questions) {
        if (question is Map && question['type'] == 'geopoint')
          spatial.add(question['name'].toString());
      }
    }
    final answers = response['answers'];
    if (answers is Map) {
      for (final entry in answers.entries) {
        dynamic value = entry.value;
        if (spatial.contains(entry.key) && value is String) {
          final numbers =
              value.split(RegExp(r'[,\s]+')).map(double.tryParse).toList();
          if (numbers.length >= 2 &&
              numbers[0] != null &&
              numbers[1] != null &&
              numbers[0]!.isFinite &&
              numbers[1]!.isFinite &&
              numbers[0]!.abs() <= 90 &&
              numbers[1]!.abs() <= 180) {
            result.add({
              'type': 'Point',
              'coordinates': [numbers[1], numbers[0]]
            });
          }
        }
        if (value is String) {
          try {
            value = jsonDecode(value);
          } catch (_) {}
        }
        if (value is Map &&
            [
              'Point',
              'LineString',
              'Polygon',
              'MultiPoint',
              'MultiLineString',
              'MultiPolygon'
            ].contains(value['type'])) {
          result.add(Map<String, dynamic>.from(value));
        }
      }
    }
    final seen = <String>{};
    return result.where((geometry) => seen.add(jsonEncode(geometry))).toList();
  }
}
