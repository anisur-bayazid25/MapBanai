import 'dart:math' as math;

/// Finds the shortest route through line geometries in a project road layer.
/// Road vertices are joined at roughly metre precision; the endpoint is snapped
/// to the nearest vertex and its connector distance is included in the result.
class RoadRoute {
  const RoadRoute(this.coordinates, this.distanceMeters);
  final List<List<double>> coordinates;
  final double distanceMeters;
}

class RoadRoutingService {
  static RoadRoute? shortestRoute({
    required List<Map<String, dynamic>> layers,
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final graph = <String, Map<String, double>>{};
    final coordinates = <String, List<double>>{};
    void addLine(dynamic raw) {
      if (raw is! List || raw.length < 2) return;
      final points = <String>[];
      for (final value in raw) {
        if (value is! List ||
            value.length < 2 ||
            value[0] is! num ||
            value[1] is! num) continue;
        final lon = (value[0] as num).toDouble();
        final lat = (value[1] as num).toDouble();
        if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180)
          continue;
        final key = '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}';
        coordinates[key] = [lon, lat];
        graph.putIfAbsent(key, () => {});
        points.add(key);
      }
      for (var i = 1; i < points.length; i++) {
        final a = points[i - 1], b = points[i];
        if (a == b) continue;
        final aCoord = coordinates[a]!, bCoord = coordinates[b]!;
        final distance = _distance(aCoord[1], aCoord[0], bCoord[1], bCoord[0]);
        graph[a]![b] = distance;
        graph[b]![a] = distance;
      }
    }

    void walk(Map geometry) {
      switch (geometry['type']) {
        case 'LineString':
          addLine(geometry['coordinates']);
          break;
        case 'MultiLineString':
          for (final line in geometry['coordinates'] as List? ?? const [])
            addLine(line);
          break;
        case 'GeometryCollection':
          for (final child in geometry['geometries'] as List? ?? const []) {
            if (child is Map) walk(child);
          }
          break;
      }
    }

    for (final layer in layers) {
      if (layer['visible'] == false || layer['role'] != 'road') continue;
      for (final feature in layer['features'] as List? ?? const []) {
        if (feature is Map && feature['geometry'] is Map)
          walk(feature['geometry'] as Map);
      }
    }
    if (graph.isEmpty) return null;
    String nearest(double lat, double lon) => graph.keys.reduce((a, b) {
          final ca = coordinates[a]!, cb = coordinates[b]!;
          return _distance(lat, lon, ca[1], ca[0]) <=
                  _distance(lat, lon, cb[1], cb[0])
              ? a
              : b;
        });

    final source = nearest(startLatitude, startLongitude);
    final destination = nearest(endLatitude, endLongitude);
    final sourcePoint = coordinates[source]!,
        destinationPoint = coordinates[destination]!;
    final connectorStart = _distance(
        startLatitude, startLongitude, sourcePoint[1], sourcePoint[0]);
    final connectorEnd = _distance(
        endLatitude, endLongitude, destinationPoint[1], destinationPoint[0]);
    // Avoid inventing a route when the nearest roads are clearly unrelated.
    if (connectorStart > 1000 || connectorEnd > 1000) return null;

    final distances = <String, double>{source: 0};
    final previous = <String, String>{};
    final queue = _RoutePriorityQueue()..add(source, 0);
    while (queue.isNotEmpty) {
      final currentEntry = queue.removeFirst();
      final current = currentEntry.node;
      if (currentEntry.distance > distances[current]!) continue;
      if (current == destination) break;
      for (final edge in graph[current]!.entries) {
        final candidate = currentEntry.distance + edge.value;
        if (candidate < (distances[edge.key] ?? double.infinity)) {
          distances[edge.key] = candidate;
          previous[edge.key] = current;
          queue.add(edge.key, candidate);
        }
      }
    }
    if (!distances.containsKey(destination)) return null;
    final path = <String>[destination];
    while (path.last != source) {
      final parent = previous[path.last];
      if (parent == null) return null;
      path.add(parent);
    }
    final ordered = path.reversed.toList();
    return RoadRoute(
      [
        [startLongitude, startLatitude],
        ...ordered.map((key) => coordinates[key]!),
        [endLongitude, endLatitude],
      ],
      connectorStart + distances[destination]! + connectorEnd,
    );
  }

  static double _distance(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371008.8;
    final a = lat1 * math.pi / 180, b = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a) * math.cos(b) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * radius * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }
}

class _RouteQueueEntry {
  const _RouteQueueEntry(this.node, this.distance);
  final String node;
  final double distance;
}

class _RoutePriorityQueue {
  final _items = <_RouteQueueEntry>[];
  bool get isNotEmpty => _items.isNotEmpty;

  void add(String node, double distance) {
    _items.add(_RouteQueueEntry(node, distance));
    var index = _items.length - 1;
    while (index > 0) {
      final parent = (index - 1) >> 1;
      if (_items[parent].distance <= _items[index].distance) break;
      final value = _items[parent];
      _items[parent] = _items[index];
      _items[index] = value;
      index = parent;
    }
  }

  _RouteQueueEntry removeFirst() {
    final result = _items.first;
    final last = _items.removeLast();
    if (_items.isEmpty) return result;
    _items[0] = last;
    var index = 0;
    while (true) {
      final left = index * 2 + 1, right = left + 1;
      if (left >= _items.length) break;
      var smallest = left;
      if (right < _items.length &&
          _items[right].distance < _items[left].distance) {
        smallest = right;
      }
      if (_items[index].distance <= _items[smallest].distance) break;
      final value = _items[index];
      _items[index] = _items[smallest];
      _items[smallest] = value;
      index = smallest;
    }
    return result;
  }
}
