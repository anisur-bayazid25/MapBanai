import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/data_export_screen.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'package:mapbanai/ui/gis_mode_screen.dart';
import 'package:mapbanai/ui/gps_mode_screen.dart';
import 'package:mapbanai/ui/project_setup_screen.dart';
import 'package:mapbanai/ui/settings_screen.dart';
import 'package:mapbanai/ui/survey_history_screen.dart';
import 'package:mapbanai/ui/survey_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AppDatabase _database;
  List<Project> _projects = [];
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _loadProjects();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptUserNameOnce());
  }

  Future<void> _loadProjects() async {
    final projects = await _database.getProjects();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _refreshTick++;
    });
  }

  Future<void> _promptUserNameOnce() async {
    final stored = await _database.getSetting('user_name');
    if (stored != null && stored.trim().isNotEmpty) return;
    if (!mounted) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to MapBanai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your name — it will be attached to every survey '
              'response, GPS log entry and export. You can change it later '
              'in Settings.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'User name',
                hintText: 'e.g., John Doe',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    final name = result?.trim();
    if (name != null && name.isNotEmpty) {
      await _database.setSetting('user_name', name);
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectState>();
    final selected = projectState.selectedProject;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ScreenLayout.maxWidthAlign(
            context,
            Padding(
              padding: ScreenLayout.contentPadding(context),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'MapBanai',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C3E50),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Offline field data collection',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                _buildProjectSelector(context, projectState, selected),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'Survey Mode',
                  subtitle: 'Simple form-based field capture',
                  color: const Color(0xFF2E7D32),
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SurveyScreen(projectName: selected),
                      ),
                    );
                    _loadProjects();
                  },
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'GIS Mode',
                  subtitle: 'Map-based spatial editing and layers',
                  color: const Color(0xFF1565C0),
                  icon: Icons.map_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GisModeScreen(projectName: selected),
                      ),
                    );
                    _loadProjects();
                  },
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'GPS Mode',
                  subtitle: 'Live GPS readings and coordinate logging',
                  color: const Color(0xFF00695C),
                  icon: Icons.my_location_outlined,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GpsModeScreen()),
                    );
                    _loadProjects();
                  },
                ),
                const SizedBox(height: 24),
                _buildCollectedData(projectState, selected),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProjectSetupScreen()),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Open'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SurveyHistoryScreen()),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.history_outlined),
                        label: const Text('History'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DataExportScreen(projectName: selected),
                            ),
                          );
                          _loadProjects();
                        },
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('Export'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(database: _database),
                      ),
                    );
                    _loadProjects();
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectSelector(
    BuildContext context,
    ProjectState projectState,
    String selected,
  ) {
    return Material(
      color: Colors.blue.shade50,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickProject(context, projectState),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                color: selected.isEmpty ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.isEmpty
                      ? 'No project selected — tap to choose one'
                      : 'Current project: $selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProject(
    BuildContext context,
    ProjectState projectState,
  ) async {
    if (_projects.isEmpty) {
      _showSnack('Create a project first (Home → Open → New project)');
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select project'),
        children: [
          for (final project in _projects)
            RadioListTile<String>(
              title: Text(project.name),
              subtitle: Text(
                project.description.trim().isEmpty
                    ? 'No description'
                    : project.description.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: project.name,
              groupValue: projectState.selectedProject.isEmpty
                  ? null
                  : projectState.selectedProject,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
            ),
        ],
      ),
    );
    if (selected == null) return;
    projectState.setSelectedProject(selected);
  }

  Widget _buildCollectedData(ProjectState projectState, String selected) {
    if (selected.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Text(
          'Select a project above to see its collected data.',
          style: TextStyle(color: Colors.green),
        ),
      );
    }

    int? projectId;
    for (final project in _projects) {
      if (project.name == selected) {
        projectId = project.id;
        break;
      }
    }
    return FutureBuilder<({int survey, int gis})>(
      key: ValueKey('$_refreshTick|$selected'),
      future: _database.responseCountsForProject(projectId ?? 0),
      builder: (context, snapshot) {
        final counts = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Collected data — $selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      label: 'Survey Responses',
                      value: counts?.survey.toString() ?? '…',
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statTile(
                      label: 'GIS Features',
                      value: counts?.gis.toString() ?? '…',
                      icon: Icons.edit_location_alt_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
