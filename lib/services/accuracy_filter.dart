/// Pure logic for GPS accuracy filtering used by recording screens.
class AccuracyFilter {
  /// A fix is only acceptable when its accuracy is known and at or
  /// below the configured threshold.
  static bool isAcceptable(double? accuracy, double thresholdMeters) {
    if (accuracy == null) return false;
    return accuracy <= thresholdMeters;
  }

  /// Relative quality of the current fix against the threshold.
  /// Returns 0 when unknown, 1 when acceptable, 2 when within 3x the
  /// threshold (usable but poor), 3 when far above the threshold.
  static int qualityLevel(double? accuracy, double thresholdMeters) {
    if (accuracy == null) return 0;
    if (accuracy <= thresholdMeters) return 1;
    if (accuracy <= thresholdMeters * 3) return 2;
    return 3;
  }

  static String format(double? accuracy) {
    if (accuracy == null) return '—';
    return '${accuracy.toStringAsFixed(1)} m';
  }
}