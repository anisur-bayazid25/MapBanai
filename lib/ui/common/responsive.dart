import 'package:flutter/material.dart';

/// Lightweight responsive helpers shared by screens.
///
/// Content-heavy screens cap their width on tablets/wide screens so lines of
/// text stay readable while mobile phones use the full width.
class ScreenLayout {
  ScreenLayout._();

  /// Maximum content width for tablet/wide screens.
  static const double maxContentWidth = 720;

  /// True on tablets and landscape phones (width >= 600 logical px).
  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  /// Horizontal/window padding that scales with the screen.
  static EdgeInsets contentPadding(BuildContext context) {
    final base = isWide(context) ? 32.0 : 20.0;
    return EdgeInsets.symmetric(horizontal: base, vertical: 16);
  }

  /// Wraps [child] in a centered, width-capped container on wide screens;
  /// on phones it fills the width unchanged.
  static Widget maxWidthAlign(BuildContext context, Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}