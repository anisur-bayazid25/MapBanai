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

  /// Map overlays scroll independently instead of hiding controls below the
  /// viewport on short landscape screens or at large accessibility text sizes.
  static Widget mapPanel(BuildContext context, Widget child) {
    return LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (MediaQuery.sizeOf(context).height * 0.45)
                    .clamp(0.0, constraints.maxHeight),
              ),
              child: SingleChildScrollView(child: child),
            ));
  }
}

/// Equal-width controls that reflow using their local available width and the
/// user's text size. Children keep their natural height; no labels are clipped
/// to make a row fit. Use inside a vertically scrollable screen or sheet.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minChildWidth = 180,
    this.maxColumns = 3,
    this.spacing = 8,
    this.runSpacing = 8,
  })  : assert(minChildWidth > 0),
        assert(maxColumns > 0);

  final List<Widget> children;
  final double minChildWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
        .clamp(1.0, double.infinity);
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.hasBoundedWidth
          ? ((constraints.maxWidth + spacing) /
                  (minChildWidth * textScale + spacing))
              .floor()
              .clamp(1, maxColumns)
          : 1;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) SizedBox(height: runSpacing),
            // IntrinsicHeight equalizes only this small row of controls, while
            // allowing text to determine its height at every font scale.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = start;
                      index < children.length && index < start + columns;
                      index++) ...[
                    if (index > start) SizedBox(width: spacing),
                    Expanded(child: children[index]),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// A single-choice control whose options wrap instead of squeezing segments.
class ResponsiveChoice<T> extends StatelessWidget {
  const ResponsiveChoice({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final segment in segments)
            ChoiceChip(
              label: segment.label ?? const SizedBox.shrink(),
              avatar: segment.icon,
              tooltip: segment.tooltip,
              selected: selected.contains(segment.value),
              onSelected: onSelectionChanged == null || !segment.enabled
                  ? null
                  : (_) => onSelectionChanged!({segment.value}),
            ),
        ],
      );
}
