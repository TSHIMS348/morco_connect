import 'user_role.dart';

class UserProfile {
  final String fullName;
  final String phone;
  final String email;
  final String matricule;
  final UserRole role;

  // 🆕 Localisation / rattachement
  final String site;
  final String city;

  const UserProfile({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.matricule,
    this.role = UserRole.user, // ✅ rôle par défaut
    this.site = 'Non défini',
    this.city = 'Non défini',
  });

  // 🔁 JSON → Object
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      matricule: (json['matricule'] ?? '').toString(),
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.user,
      ),

      // 🆕 rétrocompatibilité
      site: (json['site'] ?? 'Non défini').toString(),
      city: (json['city'] ?? 'Non défini').toString(),
    );
  }

  // 🔁 Object → JSON
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'matricule': matricule,
      'role': role.name, // ✅ sérialisation rôle
      'site': site,
      'city': city,
    };
  }
}
