class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.isActive,
  });

  final int id;
  final String name;
  final DateTime createdAt;
  final bool isActive;

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: (map['isActive'] as int) == 1,
    );
  }
}
