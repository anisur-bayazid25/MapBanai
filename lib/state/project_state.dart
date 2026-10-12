import 'package:flutter/foundation.dart';

class ProjectState extends ChangeNotifier {
  String _selectedProject = '';
  int? _selectedProjectId;
  int? get selectedProjectId => _selectedProjectId;

  String get selectedProject => _selectedProject;

  void setSelectedProject(String projectName, {int? projectId}) {
    if (projectName.trim().isEmpty) return;
    _selectedProject = projectName;
    _selectedProjectId = projectId;
    notifyListeners();
  }

  void clearSelectedProject() {
    if (_selectedProject.isEmpty) return;
    _selectedProject = '';
    _selectedProjectId = null;
    notifyListeners();
  }
}
