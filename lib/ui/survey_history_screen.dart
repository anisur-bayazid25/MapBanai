import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/photo_gallery_screen.dart';
import 'package:mapbanai/ui/survey_session_detail_screen.dart';

class SurveyHistoryScreen extends StatefulWidget {
  const SurveyHistoryScreen({super.key});

  @override
  State<SurveyHistoryScreen> createState() => _SurveyHistoryScreenState();
}

class _SurveyHistoryScreenState extends State<SurveyHistoryScreen> {
  final AppDatabase _database = AppDatabase();
  List<SurveySession> _sessions = [];
  bool _loading = true;
  Map<int, String> _projectNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final projects = await _database.getProjects(includeArchived: true);
    final names = {for (final p in projects) p.id: p.name};
    final sessions = await _database.getSurveySessions();
    if (!mounted) return;
    setState(() {
      _projectNames = names;
      _sessions = sessions;
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
          : _sessions.isEmpty
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
            'No survey responses yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Responses you collect will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrouped(BuildContext context) {
    // Group sessions by project name (sorted), then by date (descending).
    final projects = <String, List<SurveySession>>{};
    for (final session in _sessions) {
      projects
          .putIfAbsent(_projectName(session.projectId), () => [])
          .add(session);
    }
    final sortedProjects = projects.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final projectName in sortedProjects) ...[
          _sectionHeader(
            icon: Icons.folder_outlined,
            title: projectName,
            color: Colors.blue.shade700,
          ),
          ..._buildDates(projects[projectName]!),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<Widget> _buildDates(List<SurveySession> sessions) {
    final byDate = <String, List<SurveySession>>{};
    for (final session in sessions) {
      byDate.putIfAbsent(_dateKey(session.createdAt), () => []).add(session);
    }
    final sortedDates = byDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];
    for (final date in sortedDates) {
      widgets.add(
        _sectionHeader(
          icon: Icons.calendar_today_outlined,
          title: _friendlyDate(date),
          color: Colors.teal.shade700,
        ),
      );
      for (final session in byDate[date]!) {
        widgets.add(_sessionCard(session));
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

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
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
          '${_timeLabel(session.createdAt)}  •  ${session.status}',
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
