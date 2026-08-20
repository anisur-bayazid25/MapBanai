import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/measure_units.dart';

void main() {
  group('MeasureUnits.formatDistance', () {
    test('auto picks metres below 1 km', () {
      expect(MeasureUnits.formatDistance(999), '999.0 m');
      expect(MeasureUnits.formatDistance(0), '0.0 m');
    });

    test('auto picks kilometres at and above 1 km', () {
      expect(MeasureUnits.formatDistance(1000), '1.00 km');
      expect(MeasureUnits.formatDistance(25000), '25.00 km');
    });

    test('explicit units convert correctly', () {
      expect(MeasureUnits.formatDistance(1, DistanceUnit.ft), '3 ft');
      expect(MeasureUnits.formatDistance(100, DistanceUnit.ft), '328 ft');
      expect(MeasureUnits.formatDistance(1609.344, DistanceUnit.mi), '1.00 mi');
      expect(MeasureUnits.formatDistance(25000, DistanceUnit.km), '25.00 km');
      expect(MeasureUnits.formatDistance(1234.5, DistanceUnit.m), '1234.5 m');
    });

    test('parsing from settings falls back to auto', () {
      expect(DistanceUnit.fromSetting('km'), DistanceUnit.km);
      expect(DistanceUnit.fromSetting('bogus'), DistanceUnit.auto);
      expect(DistanceUnit.fromSetting(null), DistanceUnit.auto);
    });
  });

  group('MeasureUnits.formatArea', () {
    test('auto formats square metres, acres, hectares', () {
      expect(MeasureUnits.formatArea(5000), '1.24 ac');
      expect(MeasureUnits.formatArea(5000, AreaUnit.ac), '1.24 ac');
      expect(MeasureUnits.formatArea(20000), '2.00 ha');
      expect(MeasureUnits.formatArea(2000), '2000.0 m²');
      expect(MeasureUnits.formatArea(2, AreaUnit.sqft), '22 ft²');
    });

    test('parsing from settings falls back to auto', () {
      expect(AreaUnit.fromSetting('ha'), AreaUnit.ha);
      expect(AreaUnit.fromSetting('nope'), AreaUnit.auto);
    });
  });
}