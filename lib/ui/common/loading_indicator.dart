import 'package:flutter/material.dart';

/// Centered loading indicator for full-body async loads, or a compact
/// inline spinner (e.g. inside buttons) when [dense] is true.
class AppLoadingIndicator extends StatelessWidget {
  final bool dense;
  final double? size;

  const AppLoadingIndicator({
    this.dense = false,
    this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return SizedBox(
        width: size ?? 18,
        height: size ?? 18,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          width: size ?? 36,
          height: size ?? 36,
          child: const CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}