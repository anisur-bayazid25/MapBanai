import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/update_checker.dart';

void main() {
  group('UpdateChecker.compareVersions', () {
    test('equal versions', () {
      expect(UpdateChecker.compareVersions('2.1.0', '2.1.0'), 0);
      expect(UpdateChecker.compareVersions('1.0.0+5', '1.0.0+99'), 0);
    });

    test('newer patch/major/minor', () {
      expect(UpdateChecker.compareVersions('2.1.0', '2.1.1'), -1);
      expect(UpdateChecker.compareVersions('2.0.9', '2.1.0'), -1);
      expect(UpdateChecker.compareVersions('1.9.9', '2.0.0'), -1);
    });

    test('older versions', () {
      expect(UpdateChecker.compareVersions('2.1.1', '2.1.0'), 1);
      expect(UpdateChecker.compareVersions('3.0.0', '1.0.0'), 1);
    });

    test('missing segments count as zero', () {
      expect(UpdateChecker.compareVersions('2.1', '2.1.0'), 0);
      expect(UpdateChecker.compareVersions('2.1', '2.1.1'), -1);
    });

    test('pre-release suffix is ignored', () {
      expect(UpdateChecker.compareVersions('2.1.0-beta', '2.1.0'), 0);
      expect(UpdateChecker.compareVersions('2.0.1-test', '2.1.0'), -1);
    });
  });
}