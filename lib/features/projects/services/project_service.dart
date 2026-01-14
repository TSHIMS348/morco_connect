import 'dart:math';

import '../../auth/services/auth_session.dart';
import '../../auth/services/permission_service.dart';
import '../../users/services/user_directory_service.dart';
import '../../messaging/services/conversation_service.dart';
import '../models/project.dart';
import '../../audit/services/audit_service.dart';
import '../../audit/models/audit_action.dart';

class ProjectService {
  static final List<Project> _projects = [];

  // =============================
  // Lecture
  // =============================

  /// Tous les projets (admin uniquement)
  static List<Project> getAll() {
    if (!AuthSession.isAdmin) {
      throw Exception('Accès refusé');
    }
    return List.unmodifiable(_projects);
  }

  /// Projets visibles par l'utilisateur courant
  static List<Project> getForCurrentUser() {
    final user = AuthSession.currentUser;
    if (user == null) return [];

    if (AuthSession.isAdmin) {
      return List.unmodifiable(_projects);
    }

    return _projects.where((p) => p.isMember(user.matricule)).toList();
  }

  static Project? getById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // =============================
  // Création
  // =============================
  static Project create({
    required String name,
    required String description,
    required List<String> members,
  }) {
    final user = AuthSession.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // 🔐 RÈGLE MÉTIER
    if (!PermissionService.canCreateProject()) {
      throw Exception(
        'Droits insuffisants (admin / chef de projet / superviseur requis)',
      );
    }

    final creatorMatricule = user.matricule;

    // 🔎 Validation créateur
    if (!UserDirectoryService.exists(creatorMatricule)) {
      throw Exception(
        'Créateur introuvable dans l’annuaire : $creatorMatricule',
      );
    }

    // 🔎 Nettoyage + validation membres
    final cleanedMembers = members
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    for (final m in cleanedMembers) {
      if (!UserDirectoryService.exists(m)) {
        throw Exception('Matricule introuvable : $m');
      }
    }

    // 🔒 Le créateur est toujours membre
    if (!cleanedMembers.contains(creatorMatricule)) {
      cleanedMembers.insert(0, creatorMatricule);
    }

    final project = Project(
      id: _generateId(),
      name: name,
      description: description,
      createdBy: creatorMatricule,
      members: cleanedMembers,
      createdAt: DateTime.now(),
    );

    _projects.add(project);

    // 🔗 SYNC conversation projet (création)
    ConversationService.syncProjectConversation(
      projectId: project.id,
      projectName: project.name,
      members: project.members,
    );

    AuditService.log(
      AuditAction.projectCreated,
      description: 'Création du projet ${project.name}',
    );

    return project;
  }

  // =============================
  // Gestion des membres
  // =============================

  static void addMember({
    required String projectId,
    required String matricule,
  }) {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) throw Exception('Utilisateur non connecté');

    final p = getById(projectId);
    if (p == null) throw Exception('Projet introuvable');

    if (!PermissionService.canManageProjectMembers(
      projectOwnerMatricule: p.createdBy,
    )) {
      throw Exception('Droits insuffisants');
    }

    final m = matricule.trim();
    if (m.isEmpty) throw Exception('Matricule invalide');

    if (!UserDirectoryService.exists(m)) {
      throw Exception('Matricule introuvable : $m');
    }

    if (!p.members.contains(m)) {
      p.members.add(m);

      // 🔗 SYNC conversation projet (ajout)
      ConversationService.syncProjectConversation(
        projectId: p.id,
        projectName: p.name,
        members: p.members,
      );

      AuditService.log(
        AuditAction.projectMemberAdded,
        description: 'Ajout membre $m au projet ${p.name}',
      );
    }
  }

  static void removeMember({
    required String projectId,
    required String matricule,
  }) {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) throw Exception('Utilisateur non connecté');

    final p = getById(projectId);
    if (p == null) throw Exception('Projet introuvable');

    if (!PermissionService.canManageProjectMembers(
      projectOwnerMatricule: p.createdBy,
    )) {
      throw Exception('Droits insuffisants');
    }

    final m = matricule.trim();
    if (m.isEmpty) throw Exception('Matricule invalide');

    if (m == p.createdBy) {
      throw Exception('Impossible de retirer le créateur du projet');
    }

    if (p.members.remove(m)) {
      // 🔗 SYNC conversation projet (retrait)
      ConversationService.syncProjectConversation(
        projectId: p.id,
        projectName: p.name,
        members: p.members,
      );

      AuditService.log(
        AuditAction.projectMemberRemoved,
        description: 'Retrait membre $m du projet ${p.name}',
      );
    }
  }

  // =============================
  // Utilitaires
  // =============================
  static String _generateId() {
    final rand = Random();
    return 'PRJ-${DateTime.now().millisecondsSinceEpoch}-${rand.nextInt(999)}';
  }
}
