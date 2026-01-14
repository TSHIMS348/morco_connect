import 'package:morco_connect/features/auth/models/user_profile.dart';
import 'package:morco_connect/features/auth/services/permission_service.dart';
import 'package:morco_connect/features/audit/services/audit_service.dart';
import 'package:morco_connect/features/audit/models/audit_action.dart';


class AdminUserService {
  /// 🔁 Mock : utilisateurs en attente
  static final List<UserProfile> _pendingUsers = [
    const UserProfile(
      fullName: 'Jean Mukendi',
      phone: '099000111',
      email: 'jean@morco.com',
      matricule: 'EMP001',
    ),
    const UserProfile(
      fullName: 'Marie Kabila',
      phone: '081222333',
      email: 'marie@morco.com',
      matricule: 'EMP002',
    ),
  ];

  static List<UserProfile> getPendingUsers() {
    return List.unmodifiable(_pendingUsers);
  }

  static Future<void> validateUser(UserProfile user) async {
    if (!PermissionService.canValidateUsers()) {
      AuditService.log(
        AuditAction.permissionDenied,
        description: 'Tentative validation non autorisée',
      );
      throw Exception('Permission refusée');
    }

    // ⏳ Simulation backend
    await Future.delayed(const Duration(seconds: 1));

    _pendingUsers.remove(user);

    AuditService.log(
      AuditAction.userValidated,
      description: 'Utilisateur validé : ${user.matricule}',
    );
  }
}
