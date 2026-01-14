import '../../auth/models/user_role.dart';

class SystemUser {
  final String matricule;
  final String fullName;
  final UserRole role;
  final String site;
  final String city;
  final String phone;
  final bool active;

  const SystemUser({
    required this.matricule,
    required this.fullName,
    required this.role,
    required this.site,
    required this.city,
    required this.phone,
    required this.active,
  });

  bool matchesQuery(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return true;
    return matricule.toLowerCase().contains(query) ||
        fullName.toLowerCase().contains(query) ||
        site.toLowerCase().contains(query) ||
        city.toLowerCase().contains(query);
  }
}
