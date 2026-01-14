import '../models/auth_result.dart';
import '../models/user_status.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_session.dart';

class AuthService {
  Future<AuthResult> login({
    required String login,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // =============================
    // Validation basique
    // =============================
    if (login.isEmpty || password.isEmpty) {
      return AuthResult(
        success: false,
        status: UserStatus.pending,
        message: 'Identifiants invalides',
      );
    }

    // =============================
    // Cas PENDING
    // =============================
    if (login == 'pending') {
      return AuthResult(
        success: true,
        status: UserStatus.pending,
        message: 'Compte en attente de validation',
      );
    }

    // =============================
    // Cas BLOQUÉ
    // =============================
    if (login == 'blocked') {
      return AuthResult(
        success: true,
        status: UserStatus.blocked,
        message: 'Compte bloqué',
      );
    }

    // =============================
    // ✅ CAS ADMIN (MOCK)
    // =============================
    if (login == 'admin' && password == 'admin') {
      final adminUser = UserProfile(
        matricule: 'ADMIN001',
        fullName: 'Administrateur',
        role: UserRole.admin,
        site: 'Siège',
        city: 'Kinshasa',
        email: 'admin@morco.com',
        phone: '+243000000000',
      );

      await AuthSession.loginWithUser(adminUser);

      return AuthResult(
        success: true,
        status: UserStatus.active,
        message: 'Connexion admin réussie',
      );
    }

    // =============================
    // ✅ CAS UTILISATEUR NORMAL (MOCK)
    // =============================
    final user = UserProfile(
      matricule: 'USR001',
      fullName: 'Utilisateur Test',
      role: UserRole.user,
      site: 'Site A',
      city: 'Lubumbashi',
      email: 'user@morco.com',
      phone: '+243999999999',
    );

    await AuthSession.loginWithUser(user);

    return AuthResult(
      success: true,
      status: UserStatus.active,
      message: 'Connexion réussie',
    );
  }
}
