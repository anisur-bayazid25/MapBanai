import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/field_accuracy_review_service.dart';
import 'package:mapbanai/services/study_area_store.dart';
import 'package:mapbanai/ui/guided_visit_screen.dart';
import 'package:mapbanai/services/guided_visit_service.dart';
import 'package:mapbanai/ui/study_area_mode_screen.dart';
import 'package:mapbanai/ui/survey_session_detail_screen.dart';

class FieldQualityScreen extends StatefulWidget {
  const FieldQualityScreen(
      {super.key, required this.projectId, this.database, this.studyAreaStore});
  final int projectId;
  final AppDatabase? database;
  final StudyAreaStore? studyAreaStore;
  @override
  State<FieldQualityScreen> createState() => _FieldQualityScreenState();
}

class _FieldQualityScreenState extends State<FieldQualityScreen> {
  late final AppDatabase _db = widget.database ?? AppDatabase();
  late final StudyAreaStore _store = widget.studyAreaStore ?? StudyAreaStore();
  List<AccuracyFinding> _issues = [];
  List<SurveySession> _sessions = [];
  bool _loading = true;
  String? _error;
  String _projectName = '';
  String? _projectExternalId;
  double? _accuracyLimit;
  final String _progress = 'Checking recorded GPS accuracy…';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.database == null) _db.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final project = await _db.getProjectById(widget.projectId);
      if (project == null) throw StateError('Project no longer exists.');
      final sessions = await _db.getSurveySessionsByProject(project.id);
      final forms = await _db.getStoredFormsForProject(project.id);
      final sites = (await _store.loadSites())
          .where((site) => GuidedVisitService.belongsToProject(site, project))
          .toList();
      final identity = project.externalId ?? 'local:${project.id}';
      _accuracyLimit ??= double.tryParse(
              await _db.getSetting('accuracy_review_limit:$identity') ?? '') ??
          project.gpsThresholdM;
      final accepted = await FieldAccuracyReviewService(_db).accepted(identity);
      final issues = FieldAccuracyReviewService.scan(
          sessions: sessions,
          forms: forms,
          sites: sites,
          limitM: _accuracyLimit!,
          acceptedKeys: accepted.keys.toSet());
      if (!mounted) return;
      setState(() {
        _issues = issues;
        _sessions = sessions;
        _projectName = project.name;
        _projectExternalId = project.externalId;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _review(AccuracyFinding issue) async {
    final session =
        _sessions.where((row) => row.id == issue.sessionId).firstOrNull;
    if (session != null) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GuidedVisitService.isVisit(session)
              ? GuidedVisitScreen(
                  projectId: widget.projectId,
                  resumeSessionId: session.id,
                  database: _db,
                  studyAreaStore: _store)
              : SurveySessionDetailScreen(
                  session: session, projectName: _projectName)));
    } else if (issue.siteId != null) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StudyAreaModeScreen(
              projectExternalId: _projectExternalId,
              store: _store,
              projectId: widget.projectId,
              initialSelectedSiteId: issue.siteId)));
    }
    if (mounted) await _load();
  }

  String get _identity => _projectExternalId ?? 'local:${widget.projectId}';
  Future<void> _accept(AccuracyFinding finding) async {
    try {
      await FieldAccuracyReviewService(_db).accept(_identity, finding);
      if (!mounted) return;
      setState(() => _issues.removeWhere((item) => item.key == finding.key));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              const Text('Accuracy accepted. Your data and photo are kept.'),
          action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await FieldAccuracyReviewService(_db)
                    .undo(_identity, finding.key);
                if (mounted) await _load();
              })));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save acceptance: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final limits = {
      5.0,
      10.0,
      20.0,
      25.0,
      50.0,
      100.0,
      200.0,
      if (_accuracyLimit != null) _accuracyLimit!
    }.toList()
      ..sort();
    return Scaffold(
        appBar: AppBar(
            title: Text(
                'Field quality${_projectName.isEmpty ? '' : ' — $_projectName'}'),
            actions: [
              IconButton(
                  tooltip: 'Refresh accuracy review',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh))
            ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Review GPS accuracy above your limit. Accept a reading if it is suitable for your fieldwork.'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<double>(
                        value: _accuracyLimit,
                        decoration: const InputDecoration(
                            labelText: 'GPS accuracy review limit',
                            border: OutlineInputBorder()),
                        items: limits
                            .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text('${value.toInt()} m')))
                            .toList(),
                        onChanged: _loading
                            ? null
                            : (value) async {
                                if (value == null) return;
                                setState(() => _accuracyLimit = value);
                                await _db.setSetting(
                                    'accuracy_review_limit:$_identity',
                                    value.toString());
                                if (mounted) await _load();
                              }),
                    const SizedBox(height: 8),
                    const Text(
                        'Only readings above this limit appear. Accepted readings stay hidden; photos and records remain saved.'),
                  ])),
          Expanded(
              child: _loading
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_progress)
                    ]))
                  : _error != null
                      ? Center(child: Text('Cannot review accuracy: $_error'))
                      : _issues.isEmpty
                          ? const Center(
                              child: Text(
                                  'No GPS readings above the limit need review.',
                                  textAlign: TextAlign.center))
                          : ListView.builder(
                              itemCount: _issues.length,
                              itemBuilder: (context, index) {
                                final issue = _issues[index];
                                return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(issue.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium),
                                              const SizedBox(height: 4),
                                              Text(issue.source),
                                              const SizedBox(height: 8),
                                              Text(
                                                  'GPS accuracy: ±${issue.accuracyM.toStringAsFixed(1)} m · Limit: ${_accuracyLimit!.toInt()} m'),
                                              const SizedBox(height: 8),
                                              Wrap(spacing: 12, children: [
                                                OutlinedButton.icon(
                                                    onPressed: () =>
                                                        _review(issue),
                                                    icon: const Icon(
                                                        Icons.open_in_new),
                                                    label: const Text(
                                                        'View record')),
                                                FilledButton.icon(
                                                    onPressed: () =>
                                                        _accept(issue),
                                                    icon:
                                                        const Icon(Icons.check),
                                                    label: const Text(
                                                        'Accept accuracy')),
                                              ]),
                                            ])));
                              })),
        ]));
  }
}
