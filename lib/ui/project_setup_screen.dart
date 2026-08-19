import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/project_detail_screen.dart';
import 'package:mapbanai/ui/survey_form_builder_screen.dart';
import 'package:mapbanai/ui/survey_screen.dart';
import 'package:provider/provider.dart';

class ProjectSetupScreen extends StatefulWidget {
  const ProjectSetupScreen({super.key, this.database});

  final AppDatabase? database;

  @override
  State<ProjectSetupScreen> createState() => _ProjectSetupScreenState();
}

class _ProjectSetupScreenState extends State<ProjectSetupScreen> {
  final controller = TextEditingController();
  late final AppDatabase database = widget.database ?? AppDatabase();
  List<Project> projects = [];
  List<Project> archivedProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final all = await database.getProjects(includeArchived: true);
    if (!mounted) return;
    setState(() {
      projects = all.where((project) => !project.archived).toList();
      archivedProjects = all.where((project) => project.archived).toList();
    });
  }

  Future<void> _createProject() async {
    final name = controller.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter a project name');
      return;
    }
    if (await database.projectExists(name)) {
      _showSnack('A project named "$name" already exists');
      return;
    }

    await database.createProject(name);
    controller.clear();
    await _loadProjects();

    if (!mounted) return;
    context.read<ProjectState>().setSelectedProject(name);
    _showSnack('Project created: $name');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openProject(Project project) {
    context.read<ProjectState>().setSelectedProject(project.name);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyScreen(projectName: project.name),
      ),
    );
  }

  void _openDetail(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          projectId: project.id,
          database: database,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    if (widget.database == null) {
      database.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project setup'),
        actions: [
          Tooltip(
            message: 'Create custom survey form',
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.assignment_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SurveyFormBuilderScreen(
                        onSave: (form) {
                          _showSnack('Form "${form.name}" saved');
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create or open a project',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Project name',
                hintText: 'e.g. Riverbank survey',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _createProject,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create project'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Saved projects',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: projects.isEmpty && archivedProjects.isEmpty
                  ? const Center(
                      child: Text(
                        'No projects yet. Create one to start collecting data.',
                      ),
                    )
                  : ListView(
                      children: [
                        for (final project in projects)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.folder_open_rounded),
                              title: Text(project.name),
                              subtitle: project.description.isEmpty
                                  ? null
                                  : Text(
                                      project.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              onTap: () => _openProject(project),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Project settings',
                                    icon: const Icon(
                                      Icons.info_outline,
                                      size: 20,
                                    ),
                                    onPressed: () => _openDetail(project),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        if (archivedProjects.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Archived',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final project in archivedProjects)
                            Card(
                              color: Colors.grey.shade100,
                              child: ListTile(
                                leading: const Icon(
                                  Icons.archive_outlined,
                                  color: Colors.grey,
                                ),
                                title: Text(
                                  project.name,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openDetail(project),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}