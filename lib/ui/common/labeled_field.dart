import 'package:flutter/material.dart';

/// A persistent caption outside a filled selector, so its label cannot be
/// clipped by the selector or overlap the selected value at large text sizes.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const LabeledField({super.key, required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(height: 8),
          Semantics(label: label, child: child),
        ],
      );
}
