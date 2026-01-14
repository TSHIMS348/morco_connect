import '../models/user_role.dart';
import 'auth_session.dart';

class PermissionService {
  // =============================
  // États généraux
  // =============================
  static bool get isLoggedIn => AuthSession.isLoggedIn;

  static bool get isAdmin {
    final user = AuthSession.currentUser;
    return user != null && user.role == UserRole.admin;
  }

  // =============================
  // Admin / Back-office
  // =============================
  static bool canViewAdminPanel() {
    return isLoggedIn && isAdmin;
  }

  static bool canValidateUsers() {
    return isLoggedIn && isAdmin;
  }

  static bool canViewPendingUsers() {
    return isLoggedIn && isAdmin;
  }

  // =============================
  // Profil utilisateur
  // =============================
  static bool canEditProfile() {
    return isLoggedIn;
  }

  // =============================
  // Projets (RÈGLES MÉTIER CLÉS)
  // =============================

  /// Création de projet :
  /// - Admin
  /// - Chef de projet
  /// - Superviseur site
  static bool canCreateProject() {
    if (!isLoggedIn) return false;

    final role = AuthSession.role;
    return role == UserRole.admin ||
        role == UserRole.projectManager ||
        role == UserRole.supervisor;
  }

  /// Gestion des membres d’un projet :
  /// - Admin
  /// - Propriétaire du projet
  static bool canManageProjectMembers({
    required String projectOwnerMatricule,
  }) {
    if (!isLoggedIn) return false;

    final me = AuthSession.currentUser?.matricule;
    if (me == null) return false;

    return AuthSession.role == UserRole.admin ||
        me == projectOwnerMatricule;
  }
}
