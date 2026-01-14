class Project {
  final String id;

  String name;
  String description;

  /// Matricule du créateur
  final String createdBy;

  /// Membres du projet (matricules)
  final List<String> members;

  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.members,
    required this.createdAt,
  });

  // =============================
  // JSON serialization
  // =============================
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdBy': createdBy,
        'members': members,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['createdBy'],
      members: List<String>.from(json['members'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // =============================
  // Helpers métier
  // =============================
  bool isMember(String matricule) {
    return members.contains(matricule);
  }

  bool isOwner(String matricule) {
    return createdBy == matricule;
  }
}
