/// User-selectable distance unit, persisted in settings.
enum DistanceUnit {
  auto,
  m,
  km,
  ft,
  mi;

  static DistanceUnit fromSetting(String? value) {
    return values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => auto,
    );
  }

  String get label => switch (this) {
        auto => 'Automatic',
        m => 'Meters (m)',
        km => 'Kilometers (km)',
        ft => 'Feet (ft)',
        mi => 'Miles (mi)',
      };
}

/// User-selectable area unit, persisted in settings.
enum AreaUnit {
  auto,
  m2,
  ha,
  ac,
  sqft;

  static AreaUnit fromSetting(String? value) {
    return values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => auto,
    );
  }

  String get label => switch (this) {
        auto => 'Automatic',
        m2 => 'Square meters (m²)',
        ha => 'Hectares (ha)',
        ac => 'Acres (ac)',
        sqft => 'Square feet (ft²)',
      };
}

/// Formats measured distances and areas into the user-chosen unit.
class MeasureUnits {
  static const double _metersPerFt = 0.3048;
  static const double _metersPerMi = 1609.344;
  static const double _m2PerHa = 10000;
  static const double _m2PerAc = 4046.8564224;
  static const double _m2PerSqFt = 0.09290304;

  static String formatDistance(
    double meters, [
    DistanceUnit unit = DistanceUnit.auto,
  ]) {
    switch (unit) {
      case DistanceUnit.m:
        return '${meters.toStringAsFixed(1)} m';
      case DistanceUnit.km:
        return '${(meters / 1000).toStringAsFixed(2)} km';
      case DistanceUnit.ft:
        return '${(meters / _metersPerFt).toStringAsFixed(0)} ft';
      case DistanceUnit.mi:
        return '${(meters / _metersPerMi).toStringAsFixed(2)} mi';
      case DistanceUnit.auto:
        if (meters >= 1000) {
          return '${(meters / 1000).toStringAsFixed(2)} km';
        }
        return '${meters.toStringAsFixed(1)} m';
    }
  }

  static String formatArea(
    double squareMeters, [
    AreaUnit unit = AreaUnit.auto,
  ]) {
    switch (unit) {
      case AreaUnit.m2:
        return '${squareMeters.toStringAsFixed(1)} m²';
      case AreaUnit.ha:
        return '${(squareMeters / _m2PerHa).toStringAsFixed(2)} ha';
      case AreaUnit.ac:
        return '${(squareMeters / _m2PerAc).toStringAsFixed(2)} ac';
      case AreaUnit.sqft:
        return '${(squareMeters / _m2PerSqFt).toStringAsFixed(0)} ft²';
      case AreaUnit.auto:
        if (squareMeters >= 10000) {
          return '${(squareMeters / _m2PerHa).toStringAsFixed(2)} ha';
        }
        if (squareMeters >= 4046.8564224) {
          return '${(squareMeters / _m2PerAc).toStringAsFixed(2)} ac';
        }
        return '${squareMeters.toStringAsFixed(1)} m²';
    }
  }
}