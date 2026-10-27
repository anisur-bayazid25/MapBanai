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

/// Opens at the measured content height; longer panels remain draggable.
class MapSiteSheet extends StatefulWidget {
  const MapSiteSheet({super.key, required this.child});
  final Widget child;
  @override
  State<MapSiteSheet> createState() => _MapSiteSheetState();
}

class _MapSiteSheetState extends State<MapSiteSheet> {
  final _controller = DraggableScrollableController();
  final _contentKey = GlobalKey();
  bool _userDragged = false;
  double? _lastHeight;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitContent(double availableHeight) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _userDragged || !_controller.isAttached) return;
      final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final height = box.size.height;
      if (_lastHeight == height &&
          (_controller.size * availableHeight - height).abs() < 1) return;
      _lastHeight = height;
      final fraction = (height / availableHeight).clamp(.18, .86);
      if ((_controller.size - fraction).abs() > .001) {
        _controller.jumpTo(fraction);
      }
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          _fitContent(constraints.maxHeight);
          return NotificationListener<ScrollStartNotification>(
            onNotification: (event) {
              if (event.dragDetails != null) _userDragged = true;
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: .32,
              minChildSize: .18,
              maxChildSize: .86,
              builder: (context, scroll) => Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(.15),
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28))),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  controller: scroll,
                  child: NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (_) {
                      _fitContent(constraints.maxHeight);
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                        child: Padding(
                      key: _contentKey,
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(context).bottom + 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Center(
                            child: Container(
                                margin:
                                    const EdgeInsets.only(top: 10, bottom: 2),
                                height: 4,
                                width: 36,
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                    borderRadius: BorderRadius.circular(4)))),
                        widget.child,
                      ]),
                    )),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
