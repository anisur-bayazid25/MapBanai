import 'package:flutter/material.dart';
import 'package:mapbanai/l10n/ui_text.dart';

/// Bulk field-data removal requires deliberate identification of the project.
Future<bool> confirmFieldDataRemoval(
  BuildContext context, {
  required String title,
  required String projectName,
  required String details,
  required int pendingCount,
}) async =>
    await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RemovalDialog(
            title: title,
            projectName: projectName,
            details: details,
            pendingCount: pendingCount)) ??
    false;

class _RemovalDialog extends StatefulWidget {
  final String title, projectName, details;
  final int pendingCount;
  const _RemovalDialog(
      {required this.title,
      required this.projectName,
      required this.details,
      required this.pendingCount});
  @override
  State<_RemovalDialog> createState() => _RemovalDialogState();
}

class _RemovalDialogState extends State<_RemovalDialog> {
  final _name = TextEditingController();
  bool _acknowledgedPending = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(widget.projectName,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(widget.details),
              const SizedBox(height: 12),
              Text(ui(context,
                  'This cannot be undone. Export a backup before continuing.')),
              if (widget.pendingCount > 0)
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(ui(
                        context,
                        'I understand that {v0} unsynced records will be lost.',
                        [widget.pendingCount])),
                    value: _acknowledgedPending,
                    onChanged: (value) =>
                        setState(() => _acknowledgedPending = value ?? false)),
              const SizedBox(height: 16),
              Text(ui(context, 'Type the project name to confirm: {v0}',
                  [widget.projectName])),
              const SizedBox(height: 8),
              TextField(
                  key: const ValueKey('removal-project-name'),
                  controller: _name,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                      labelText: ui(context, 'Project name'),
                      border: const OutlineInputBorder()),
                  onChanged: (_) => setState(() {})),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(ui(context, 'Cancel'))),
          FilledButton(
              key: const ValueKey('confirm-field-data-removal'),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError),
              onPressed: _name.text.trim() == widget.projectName.trim() &&
                      (widget.pendingCount == 0 || _acknowledgedPending)
                  ? () => Navigator.pop(context, true)
                  : null,
              child: Text(ui(context, 'Delete from device'))),
        ],
      );
}
