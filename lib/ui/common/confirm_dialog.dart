import 'package:flutter/material.dart';

/// Standard confirm dialog. Returns true when the user confirms.
/// When [destructive] is true the confirm button is styled as a danger action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelText),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor:
                      Theme.of(dialogContext).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Confirm dialog that requires typing [typeToConfirm] exactly before the
/// destructive action can be triggered. Returns true when the user typed the
/// exact string and confirmed.
Future<bool> showTypeToConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String typeToConfirm,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  final controller = TextEditingController();
  var matches = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Type: $typeToConfirm',
              ),
              onChanged: (value) {
                setDialogState(() => matches = value == typeToConfirm);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelText),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: matches
                ? () => Navigator.pop(dialogContext, true)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result ?? false;
}