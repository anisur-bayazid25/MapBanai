import 'package:mapbanai/ui/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/questionnaire_sync_service.dart';

class QuestionnaireSyncScreen extends StatefulWidget {
  final AppDatabase database;
  final int projectId;
  const QuestionnaireSyncScreen(
      {super.key, required this.database, required this.projectId});
  @override
  State<QuestionnaireSyncScreen> createState() =>
      _QuestionnaireSyncScreenState();
}

class _QuestionnaireSyncScreenState extends State<QuestionnaireSyncScreen> {
  bool _busy = false;
  String? _message;
  QuestionnaireUpdate? _update;
  Future<void> _check() async {
    setState(() {
      _busy = true;
      _message = null;
      _update = null;
    });
    try {
      final update = await QuestionnaireSyncService(widget.database)
          .check(widget.projectId);
      if (mounted)
        setState(() {
          _update = update;
          _message = update.changed
              ? 'A questionnaire update is ready.'
              : 'Your questionnaire is up to date.';
        });
    } catch (error) {
      if (mounted)
        setState(() => _message = 'Cannot sync questionnaire: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      await QuestionnaireSyncService(widget.database).apply(_update!);
      if (mounted)
        setState(() {
          _message =
              'Questionnaire updated. Existing records and drafts are kept.';
          _update = null;
        });
    } catch (error) {
      if (mounted) setState(() => _message = 'Update was not applied: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Sync questionnaire'), actions: [
        IconButton(
            tooltip: 'Help & manager setup',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HelpScreen())))
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text(
            'Fetch the latest XLSForm from your project’s Google Sheet using its Apps Script connection.'),
        const SizedBox(height: 12),
        const Text(
            'Review and apply changes when connected. New surveys use the new version; saved records and drafts keep their original questions.'),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: _busy ? null : _check,
            icon: const Icon(Icons.sync),
            label: const Text('Check Google Sheet')),
        if (_busy)
          const Padding(
              padding: EdgeInsets.all(20), child: LinearProgressIndicator()),
        if (_message != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_message!)),
        if (_update?.changed == true) ...[
          Text('${_update!.form.name} · v${_update!.form.version}',
              style: Theme.of(context).textTheme.titleLarge),
          Text('${_update!.form.questions.length} questions'),
          for (final warning in _update!.form.importWarnings) Text(warning),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: _busy ? null : _apply,
              child: const Text('Apply questionnaire update')),
          for (final question in _update!.form.questions)
            ListTile(
                title: Text(question.label),
                subtitle: Text(
                    '${question.type.name}${question.required ? ' · Required' : ''}'))
        ]
      ]));
}
