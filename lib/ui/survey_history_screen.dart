import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/gis_mode_screen.dart';
import 'package:mapbanai/ui/photo_gallery_screen.dart';
import 'package:mapbanai/ui/survey_form_renderer.dart';
import 'package:mapbanai/ui/survey_session_detail_screen.dart';

class SurveyHistoryScreen extends StatefulWidget {
  const SurveyHistoryScreen({super.key});

  @override
  State<SurveyHistoryScreen> createState() => _SurveyHistoryScreenState();
}

class _SurveyHistoryScreenState extends State<SurveyHistoryScreen> {
  final AppDatabase _database = AppDatabase();
  List<SurveySession> _sessions = [];
  List<SurveySession> _drafts = [];
  bool _loading = true;
  Map<int, String> _projectNames = {};
  final Set<String> _collapsedProjects = {};
  final Set<String> _collapsedDates = {};
  bool _draftsCollapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final projects = await _database.getProjects(includeArchived: true);
    final names = {for (final p in projects) p.id: p.name};
    final sessions = await _database.getSurveySessions();
    final drafts = await _database.getDraftSurveySessions();
    if (!mounted) return;
    setState(() {
      _projectNames = names;
      _sessions = sessions;
      _drafts = drafts;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  String _projectName(int? projectId) {
    final name = projectId != null ? _projectNames[projectId] : null;
    return name ?? 'Unknown project';
  }

  String _dateKey(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openDetail(SurveySession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveySessionDetailScreen(
          session: session,
          projectName: _projectName(session.projectId),
        ),
      ),
    );
    await _load();
  }

  // ── draft actions ────────────────────────────────────────────

  bool _isGisDraft(SurveySession draft) {
    try {
      final responses =
          jsonDecode(draft.responses) as Map<String, dynamic>;
      return responses['feature_type'] != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openDraft(SurveySession draft) async {
    if (_isGisDraft(draft)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GisModeScreen(
            projectName: _projectName(draft.projectId),
            resumeDraftId: draft.id,
          ),
        ),
      );
    } else {
      await _resumeSurveyDraft(draft);
    }
    await _load();
  }

  Future<void> _resumeSurveyDraft(SurveySession draft) async {
    Map<String, dynamic> responses;
    try {
      responses = jsonDecode(draft.responses) as Map<String, dynamic>;
    } catch (_) {
      _showSnack('Could not read this draft');
      return;
    }
    final answers =
        (responses['answers'] as Map?)?.cast<String, dynamic>() ?? {};

    final project = await _database.getProjectById(draft.projectId);
    if (project == null || !mounted) {
      _showSnack('Project not found for this draft');
      return;
    }

    final forms = await _database.getStoredFormsForProject(project.id);
    StoredForm? stored;
    final formId = int.tryParse('${responses['form_id'] ?? ''}');
    if (formId != null) {
      for (final f in forms) {
        if (f.id == formId) {
          stored = f;
          break;
        }
      }
    }
    if (stored == null) {
      final formName = responses['form_name']?.toString();
      if (formName != null) {
        for (final f in forms) {
          if (f.name == formName) {
            stored = f;
            break;
          }
        }
      }
    }
    if (stored == null || !mounted) {
      _showSnack('Survey form not found for this draft');
      return;
    }

    final form = SurveyForm.fromJson(
      jsonDecode(stored.json) as Map<String, dynamic>,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Resume survey draft')),
          body: SurveyFormRenderer(
            form: form,
            initialAnswers: answers,
            onSave: (answers) async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final title = answers['site_name']?.toString() ?? form.name;
              final updated = <String, dynamic>{
                'form_id': form.id,
                'form_name': form.name,
                'user_name': await _database.getSetting('user_name'),
                'answers': answers,
              };
              await _database.updateSurveySession(
                draft.id,
                title: title,
                status: 'saved',
                responses: jsonEncode(updated),
              );
              if (messenger.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Saved response for ${project.name}')),
                );
              }
              if (navigator.mounted) navigator.pop();
            },
            onSaveDraft: (answers) async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final updated = <String, dynamic>{
                'form_id': form.id,
                'form_name': form.name,
                'user_name': await _database.getSetting('user_name'),
                'answers': answers,
              };
              await _database.updateSurveySession(
                draft.id,
                title: answers['site_name']?.toString() ??
                    'Draft survey — ${form.name}',
                status: 'draft',
                responses: jsonEncode(updated),
              );
              if (messenger.mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('Draft updated')));
              }
              if (navigator.mounted) navigator.pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDraft(SurveySession draft) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete draft',
      message: 'Delete this draft? The unfinished data will be lost.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await _database.deleteSurveySession(draft.id);
    await _load();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey History'),
        actions: [
          IconButton(
            tooltip: 'Photo gallery',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhotoGalleryScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingIndicator()
          : _sessions.isEmpty && _drafts.isEmpty
              ? _buildEmpty(context)
              : _buildGrouped(context),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No saved responses or drafts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved responses appear here; unfinished work is kept as drafts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrouped(BuildContext context) {
    final saved = _sessions
        .where((session) => session.status != 'draft')
        .toList();

    // Group sessions by project name (sorted), then by date (descending).
    final projects = <String, List<SurveySession>>{};
    for (final session in saved) {
      projects
          .putIfAbsent(_projectName(session.projectId), () => [])
          .add(session);
    }
    final sortedProjects = projects.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_drafts.isNotEmpty) ...[
          _collapsibleHeader(
            icon: Icons.edit_note,
            title: 'Drafts',
            count: _drafts.length,
            color: Colors.orange.shade800,
            collapsed: _draftsCollapsed,
            onTap: () => setState(() => _draftsCollapsed = !_draftsCollapsed),
          ),
          if (!_draftsCollapsed) for (final draft in _drafts) _draftCard(draft),
          const SizedBox(height: 12),
        ],
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: Text(
                'No saved responses yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          for (final projectName in sortedProjects) ...[
            _collapsibleHeader(
              icon: Icons.folder_outlined,
              title: projectName,
              count: projects[projectName]!.length,
              color: Colors.blue.shade700,
              collapsed: _collapsedProjects.contains(projectName),
              onTap: () => setState(() {
                if (_collapsedProjects.contains(projectName)) {
                  _collapsedProjects.remove(projectName);
                } else {
                  _collapsedProjects.add(projectName);
                }
              }),
            ),
            if (!_collapsedProjects.contains(projectName))
              ..._buildDates(projectName, projects[projectName]!),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  List<Widget> _buildDates(String projectName, List<SurveySession> sessions) {
    final byDate = <String, List<SurveySession>>{};
    for (final session in sessions) {
      byDate.putIfAbsent(_dateKey(session.createdAt), () => []).add(session);
    }
    final sortedDates = byDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];
    for (final date in sortedDates) {
      final dateKey = '$projectName|$date';
      final collapsed = _collapsedDates.contains(dateKey);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _collapsibleHeader(
            icon: Icons.calendar_today_outlined,
            title: _friendlyDate(date),
            count: byDate[date]!.length,
            color: Colors.teal.shade700,
            collapsed: collapsed,
            dense: true,
            onTap: () => setState(() {
              if (collapsed) {
                _collapsedDates.remove(dateKey);
              } else {
                _collapsedDates.add(dateKey);
              }
            }),
          ),
        ),
      );
      if (!collapsed) {
        for (final session in byDate[date]!) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _sessionCard(session),
            ),
          );
        }
      }
    }
    return widgets;
  }

  String _friendlyDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final y = parts[0];
    final m = int.tryParse(parts[1]) ?? 0;
    final d = int.tryParse(parts[2]) ?? 0;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = (m >= 1 && m <= 12) ? months[m - 1] : parts[1];
    return '$d $month $y';
  }

  Widget _collapsibleHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required bool collapsed,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, dense ? 8 : 12, 4, dense ? 4 : 6),
        child: Row(
          children: [
            Icon(icon, size: dense ? 16 : 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title ($count)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: dense ? 13 : 15,
                ),
              ),
            ),
            AnimatedRotation(
              turns: collapsed ? -0.25 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(Icons.expand_more, size: dense ? 18 : 20, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _draftCard(SurveySession draft) {
    final isGis = _isGisDraft(draft);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDark ? const Color(0xFF4E342E) : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? Colors.orange.shade800 : Colors.orange.shade200),
      ),
      child: ListTile(
        leading: Icon(
          isGis ? Icons.edit_location_alt_outlined : Icons.assignment_outlined,
          color: Colors.orange.shade800,
        ),
        title: Text(
          draft.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${_projectName(draft.projectId)}  •  ${_timeLabel(draft.createdAt)}  •  draft',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _openDraft(draft),
              child: const Text('Resume'),
            ),
            IconButton(
              tooltip: 'Delete draft',
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () => _deleteDraft(draft),
            ),
          ],
        ),
        onTap: () => _openDraft(draft),
      ),
    );
  }

  Widget _sessionCard(SurveySession session) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          session.responses.contains('feature_type')
              ? Icons.edit_location_alt_outlined
              : Icons.assignment_outlined,
          color: Colors.indigo.shade400,
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          _timeLabel(session.createdAt),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _openDetail(session),
      ),
    );
  }

  String _timeLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}