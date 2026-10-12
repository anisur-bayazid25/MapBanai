import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/field_quality_service.dart';
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
  List<FieldQualityIssue> _issues = [];
  List<SurveySession> _sessions = [];
  bool _loading = true;
  String? _error;
  String _projectName = '';
  String? _projectExternalId;
  double _distance = 10;
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
      final issues = await FieldQualityService().inspect(
          sessions: sessions,
          forms: forms,
          sites: sites,
          accuracyThresholdM: project.gpsThresholdM,
          duplicateDistanceM: _distance);
      if (!mounted) return;
      setState(() {
        _issues = issues;
        _sessions = sessions;
        _projectName = project.name;
        _projectExternalId = project.externalId;
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  Future<void> _review(FieldQualityIssue issue) async {
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

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              'Field quality${_projectName.isEmpty ? '' : ' — $_projectName'}'),
          actions: [
            IconButton(
                tooltip: 'Refresh quality checks',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh))
          ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                  'Review missing answers, photo evidence, recorded GPS quality and nearby features. GPS accuracy findings are advisory.'),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                  value: _distance,
                  decoration: const InputDecoration(
                      labelText: 'Nearby feature review distance'),
                  items: [5.0, 10.0, 25.0, 50.0]
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text('${value.toInt()} m')))
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (value) {
                          setState(() => _distance = value!);
                          _load();
                        }),
              const SizedBox(height: 8),
              const Text(
                  'Includes this project and baseline features not yet assigned to a project. A nearby pair may be two valid features. GPS age is checked only where capture timestamps were recorded.')
            ])),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Cannot check data: $_error'))
                    : _issues.isEmpty
                        ? const Center(
                            child: Text('No issues found by these checks.'))
                        : ListView.builder(
                            itemCount: _issues.length,
                            itemBuilder: (context, index) {
                              final issue = _issues[index];
                              return ListTile(
                                  leading: Icon(issue.code == 'near_duplicate'
                                      ? Icons.place_outlined
                                      : issue.code.startsWith('gps')
                                          ? Icons.gps_fixed
                                          : Icons.fact_check_outlined),
                                  title: Text(issue.message),
                                  subtitle:
                                      Text(issue.code.replaceAll('_', ' ')),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _review(issue));
                            })),
      ]));
}
