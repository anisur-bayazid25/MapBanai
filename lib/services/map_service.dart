import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/data/app_database.dart';

class Basemap {
  final String id;
  final String name;
  final String url;
  final String attribution;

  const Basemap({
    required this.id,
    required this.name,
    required this.url,
    required this.attribution,
  });

  static const List<Basemap> defaults = [
    Basemap(
      id: 'osm',
      name: 'OpenStreetMap',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap contributors',
    ),
    Basemap(
      id: 'carto_light',
      name: 'CartoDB Light',
      url: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap contributors, © CARTO',
    ),
    Basemap(
      id: 'carto_dark',
      name: 'CartoDB Dark',
      url: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap contributors, © CARTO',
    ),
    Basemap(
      id: 'satellite',
      name: 'Satellite (Esri)',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/'
          'World_Imagery/MapServer/tile/{z}/{y}/{x}',
      attribution: 'Tiles © Esri — Source: Esri, Maxar, Earthstar Geographics',
    ),
  ];
}

class MapLayer {
  final String id;
  final String name;
  final String sourceId;
  final bool visible;
  final double opacity;
  final Map<String, dynamic> paint;

  MapLayer({
    required this.id,
    required this.name,
    required this.sourceId,
    this.visible = true,
    this.opacity = 1.0,
    this.paint = const {},
  });

  MapLayer copyWith({
    String? id,
    String? name,
    String? sourceId,
    bool? visible,
    double? opacity,
    Map<String, dynamic>? paint,
  }) {
    return MapLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceId: sourceId ?? this.sourceId,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      paint: paint ?? this.paint,
    );
  }
}

class MapState {
  final LatLng? center;
  final double zoom;
  final double bearing;
  final double pitch;

  const MapState({
    this.center,
    this.zoom = 14.0,
    this.bearing = 0.0,
    this.pitch = 0.0,
  });

  MapState copyWith({
    LatLng? center,
    double? zoom,
    double? bearing,
    double? pitch,
  }) {
    return MapState(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      bearing: bearing ?? this.bearing,
      pitch: pitch ?? this.pitch,
    );
  }
}

class FeatureData {
  final int sessionId;
  final String geometryType;
  final Map<String, dynamic> geometry;
  final Map<String, dynamic> properties;

  FeatureData({
    required this.sessionId,
    required this.geometryType,
    required this.geometry,
    required this.properties,
  });

  factory FeatureData.fromSession(SurveySession session) {
    return FeatureData(
      sessionId: session.id,
      geometryType: 'Point',
      geometry: {},
      properties: {},
    );
  }
}