import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/accuracy_filter.dart';

void main() {
  group('AccuracyFilter.isAcceptable', () {
    test('null accuracy is never acceptable', () {
      expect(AccuracyFilter.isAcceptable(null, 10), isFalse);
    });

    test('accuracy at or below threshold is acceptable', () {
      expect(AccuracyFilter.isAcceptable(5.0, 10), isTrue);
      expect(AccuracyFilter.isAcceptable(10.0, 10), isTrue);
      expect(AccuracyFilter.isAcceptable(0.5, 10), isTrue);
    });

    test('accuracy above threshold is not acceptable', () {
      expect(AccuracyFilter.isAcceptable(10.1, 10), isFalse);
      expect(AccuracyFilter.isAcceptable(50.0, 20), isFalse);
    });

    test('threshold of zero requires a perfect fix', () {
      expect(AccuracyFilter.isAcceptable(0.0, 0), isTrue);
      expect(AccuracyFilter.isAcceptable(0.1, 0), isFalse);
    });
  });

  group('AccuracyFilter.qualityLevel', () {
    test('unknown is level 0', () {
      expect(AccuracyFilter.qualityLevel(null, 10), 0);
    });

    test('acceptable is level 1', () {
      expect(AccuracyFilter.qualityLevel(8, 10), 1);
      expect(AccuracyFilter.qualityLevel(10, 10), 1);
    });

    test('within 3x threshold is level 2', () {
      expect(AccuracyFilter.qualityLevel(20, 10), 2);
      expect(AccuracyFilter.qualityLevel(29.9, 10), 2);
    });

    test('far above threshold is level 3', () {
      expect(AccuracyFilter.qualityLevel(31, 10), 3);
    });
  });

  group('AccuracyFilter.format', () {
    test('formats values and unknown', () {
      expect(AccuracyFilter.format(null), '—');
      expect(AccuracyFilter.format(7.25), '7.3 m');
      expect(AccuracyFilter.format(10), '10.0 m');
    });
  });
}