import 'package:flutter/material.dart';

/// A shared surface for map controls, kept separate from the platform map so
/// controls can animate without recreating the map or reloading its tiles.
class MapControlSurface extends StatelessWidget {
  const MapControlSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(12),
      this.radius = 24});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(.14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      );
}

/// A real draggable, scrollable site sheet rather than a fixed map overlay.
/// Large fonts and landscape get more initial space; every action still scrolls.
class MapSiteSheet extends StatelessWidget {
  const MapSiteSheet({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final large = MediaQuery.textScalerOf(context).scale(14) > 20;
    final initial = large || size.width > size.height ? .46 : .32;
    return DraggableScrollableSheet(
      initialChildSize: initial,
      minChildSize: .18,
      maxChildSize: .86,
      snap: true,
      snapSizes: [initial, .65],
      builder: (context, scroll) => Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(.15),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        clipBehavior: Clip.antiAlias,
        child: ListView(
            controller: scroll,
            padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 12),
            children: [
              Center(
                  child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 2),
                      height: 4,
                      width: 36,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4)))),
              child,
            ]),
      ),
    );
  }
}
