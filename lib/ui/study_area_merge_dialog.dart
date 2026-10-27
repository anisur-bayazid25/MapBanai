import 'package:mapbanai/l10n/ui_text.dart';
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
        title: Text(ui(context, 'Review team import')),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ui(
                    context,
                    '{v0} new features, {v1} incoming revisions, {v2} unchanged or older versions.',
                    [
                      widget.preview.additions,
                      widget.preview.updates,
                      widget.preview.unchanged
                    ])),
                const SizedBox(height: 12),
                if (widget.preview.conflicts.isEmpty)
                  Text(ui(context,
                      'No conflicts. Imported revisions include their original data and change history.')),
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
                                Text(ui(
                                    context,
                                    'Local revision {v0}; incoming revision {v1}',
                                    [
                                      conflict.current.revision,
                                      conflict.incoming.revision
                                    ])),
                                if (conflict.incoming.history.isNotEmpty)
                                  Text(ui(context, 'Incoming: {v0}, {v1}', [
                                    conflict.incoming.history.last.author,
                                    conflict.incoming.history.last.timestamp
                                        .toLocal()
                                  ])),
                                ExpansionTile(
                                    title: Text(
                                        ui(context, 'Compare both versions')),
                                    children: [
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              ui(context, 'On this device'),
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      SelectableText(
                                          const JsonEncoder.withIndent('  ')
                                              .convert(conflict.current
                                                  .stateSnapshot())),
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              ui(context, 'Incoming file'),
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      SelectableText(
                                          const JsonEncoder.withIndent('  ')
                                              .convert(conflict.incoming
                                                  .stateSnapshot())),
                                    ]),
                                DropdownButtonFormField<StudyAreaMergeChoice>(
                                    itemHeight: null,
                                    isExpanded: true,
                                    value: _choices[conflict.incoming.id],
                                    decoration: InputDecoration(
                                        labelText:
                                            ui(context, 'Choose a resolution')),
                                    items: [
                                      DropdownMenuItem(
                                          value: StudyAreaMergeChoice.keepLocal,
                                          child: Text(ui(
                                              context, 'Keep local version'))),
                                      DropdownMenuItem(
                                          value:
                                              StudyAreaMergeChoice.useIncoming,
                                          child: Text(ui(context,
                                              'Use incoming version'))),
                                      DropdownMenuItem(
                                          value: StudyAreaMergeChoice
                                              .preserveAsNew,
                                          child: Text(ui(context,
                                              'Keep both as separate features'))),
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
              child: Text(ui(context, 'Cancel'))),
          FilledButton(
              onPressed: _choices.length == widget.preview.conflicts.length
                  ? () => Navigator.pop(context, _choices)
                  : null,
              child: Text(ui(context, 'Apply import')))
        ],
      );
}
