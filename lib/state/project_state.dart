import 'package:flutter/foundation.dart';

class ProjectState extends ChangeNotifier {
  String _selectedProject = '';

  String get selectedProject => _selectedProject;

  void setSelectedProject(String projectName) {
    if (projectName.trim().isEmpty) return;
    _selectedProject = projectName;
    notifyListeners();
  }

  void clearSelectedProject() {
    if (_selectedProject.isEmpty) return;
    _selectedProject = '';
    notifyListeners();
  }
}
