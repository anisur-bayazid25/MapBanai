/// Circular low-pass filtering preserves the shortest rotation across north.
class CompassHeadingFilter {
  double? value;
  double? update(double heading, {double smoothing = .45}) {
    if (!heading.isFinite || heading < 0) return value;
    final normalized = heading % 360;
    final previous = value;
    if (previous == null) return value = normalized;
    final delta = ((normalized - previous + 540) % 360) - 180;
    return value = previous + delta * smoothing.clamp(0, 1);
  }
}
