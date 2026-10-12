import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbanai/services/study_area_store.dart';

/// Requires a choice for each divergent feature before any import is committed.
class StudyAreaMergeReviewDialog extends StatefulWidget {
  final StudyAreaMergePreview preview;
  const StudyAreaMergeReviewDialog({super.key, required this.preview});

  @override
  State<StudyAreaMergeReviewDialog> createState() =>
      _StudyAreaMergeReviewDialogState();
}

class _StudyAreaMergeReviewDialogState
    extends State<StudyAreaMergeReviewDialog> {
  final Map<String, StudyAreaMergeChoice> _choices = {};

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Review team import'),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    '${widget.preview.additions} new features, ${widget.preview.updates} incoming revisions, ${widget.preview.unchanged} unchanged or older versions.'),
                const SizedBox(height: 12),
                if (widget.preview.conflicts.isEmpty)
                  const Text(
                      'No conflicts. Imported revisions include their original data and change history.'),
                for (final conflict in widget.preview.conflicts)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${conflict.current.displayName} (${conflict.current.id})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    'Local revision ${conflict.current.revision}; incoming revision ${conflict.incoming.revision}'),
                                if (conflict.incoming.history.isNotEmpty)
                                  Text(
                                      'Incoming: ${conflict.incoming.history.last.author}, ${conflict.incoming.history.last.timestamp.toLocal()}'),
                                ExpansionTile(
                                    title: const Text('Compare both versions'),
                                    children: [
                                      const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('On this device',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      SelectableText(
                                          const JsonEncoder.withIndent('  ')
                                              .convert(conflict.current
                                                  .stateSnapshot())),
                                      const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('Incoming file',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      SelectableText(
                                          const JsonEncoder.withIndent('  ')
                                              .convert(conflict.incoming
                                                  .stateSnapshot())),
                                    ]),
                                DropdownButtonFormField<StudyAreaMergeChoice>(
                                    value: _choices[conflict.incoming.id],
                                    decoration: const InputDecoration(
                                        labelText: 'Choose a resolution'),
                                    items: const [
                                      DropdownMenuItem(
                                          value: StudyAreaMergeChoice.keepLocal,
                                          child: Text('Keep local version')),
                                      DropdownMenuItem(
                                          value:
                                              StudyAreaMergeChoice.useIncoming,
                                          child: Text('Use incoming version')),
                                      DropdownMenuItem(
                                          value: StudyAreaMergeChoice
                                              .preserveAsNew,
                                          child: Text(
                                              'Keep both as separate features')),
                                    ],
                                    onChanged: (choice) {
                                      if (choice != null)
                                        setState(() =>
                                            _choices[conflict.incoming.id] =
                                                choice);
                                    }),
                              ]))),
              ],
            ))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _choices.length == widget.preview.conflicts.length
                  ? () => Navigator.pop(context, _choices)
                  : null,
              child: const Text('Apply import'))
        ],
      );
}
