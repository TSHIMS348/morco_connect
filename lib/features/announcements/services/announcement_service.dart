import 'dart:math';

import '../../auth/services/auth_session.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/models/user_role.dart';

import '../../users/services/user_directory_service.dart';
import '../../projects/services/project_service.dart';

// 🧾 AUDIT
import '../../audit/services/audit_service.dart';
import '../../audit/models/audit_action.dart';

import '../models/announcement.dart';
import '../models/announcement_target.dart';
import '../models/announcement_target_type.dart';
import '../models/announcement_type.dart';
import '../models/announcement_priority.dart';
import '../models/announcement_status.dart';

import '../repositories/local_announcement_repository.dart';

class AnnouncementService {
  // ======================================================
  // 🧠 CACHE MÉMOIRE
  // ======================================================
  static List<Announcement> _cache = [];

  // ======================================================
  // 🔐 DROITS
  // ======================================================
  static bool canCreate(UserRole role) => role == UserRole.admin;
  static bool canValidatePublish(UserRole role) => role == UserRole.admin;

  // ======================================================
  // 📥 LOAD
  // ======================================================
  static Future<void> loadAll() async {
    final list = await LocalAnnouncementRepository.getAll();
    _cache = list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Announcement> getAllCached() => [..._cache];

  // ======================================================
  // 👀 VISIBILITÉ UTILISATEUR
  // ======================================================
  static List<Announcement> getCachedVisibleForCurrentUser() {
    final me = AuthSession.currentUser;
    if (me == null) return [];

    if (AuthSession.isAdmin) {
      return [..._cache]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return _cache
        .where((a) => a.status == AnnouncementStatus.published)
        .where((a) => _isVisibleToUser(a, me))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ======================================================
  // 🧠 LOGIQUE DE CIBLAGE
  // ======================================================
  static bool _isVisibleToUser(Announcement a, UserProfile u) {
    if (a.isForAll) return true;

    for (final t in a.targets) {
      switch (t.type) {
        case AnnouncementTargetType.all:
          return true;

        case AnnouncementTargetType.site:
          if (t.refId != null && t.refId == u.site) return true;
          break;

        case AnnouncementTargetType.city:
          if (t.refId != null && t.refId == u.city) return true;
          break;

        case AnnouncementTargetType.project:
          if (t.refId == null) break;
          final p = ProjectService.getById(t.refId!);
          if (p != null && p.members.contains(u.matricule)) return true;
          break;
      }
    }
    return false;
  }

  // ======================================================
  // 👥 PREVIEW AUDIENCE
  // ======================================================
  static List<String> computeAudienceMatricules({
    required AnnouncementTargetType targetType,
    String? targetRefId,
  }) {
    final users = UserDirectoryService.getAll(activeOnly: true);

    switch (targetType) {
      case AnnouncementTargetType.all:
        return users.map((u) => u.matricule).toList();

      case AnnouncementTargetType.site:
        if (targetRefId == null) return [];
        return users
            .where((u) => u.site == targetRefId)
            .map((u) => u.matricule)
            .toList();

      case AnnouncementTargetType.city:
        if (targetRefId == null) return [];
        return users
            .where((u) => u.city == targetRefId)
            .map((u) => u.matricule)
            .toList();

      case AnnouncementTargetType.project:
        if (targetRefId == null) return [];
        final p = ProjectService.getById(targetRefId);
        return p?.members ?? [];
    }
  }

  // ======================================================
  // 👥 CIBLES EFFECTIVES (ADMIN)
  // ======================================================
  static List<String> getTargetMatricules(Announcement a) {
    final result = <String>{};

    if (a.isForAll) {
      return UserDirectoryService.getAll(activeOnly: true)
          .map((u) => u.matricule)
          .toList();
    }

    for (final t in a.targets) {
      switch (t.type) {
        case AnnouncementTargetType.all:
          result.addAll(
            UserDirectoryService.getAll(activeOnly: true)
                .map((u) => u.matricule),
          );
          break;

        case AnnouncementTargetType.site:
          if (t.refId == null) break;
          result.addAll(
            UserDirectoryService.getAll(activeOnly: true)
                .where((u) => u.site == t.refId)
                .map((u) => u.matricule),
          );
          break;

        case AnnouncementTargetType.city:
          if (t.refId == null) break;
          result.addAll(
            UserDirectoryService.getAll(activeOnly: true)
                .where((u) => u.city == t.refId)
                .map((u) => u.matricule),
          );
          break;

        case AnnouncementTargetType.project:
          if (t.refId == null) break;
          final p = ProjectService.getById(t.refId!);
          if (p != null) result.addAll(p.members);
          break;
      }
    }

    return result.toList();
  }

  // ======================================================
  // 📝 CREATE (DRAFT)
  // ======================================================
  static Future<Announcement> create({
    required String title,
    String? body,
    required AnnouncementType type,
    AnnouncementPriority priority = AnnouncementPriority.normal,
    String? mediaPath,
    List<AnnouncementTarget>? targets,
  }) async {
    final me = AuthSession.currentUser;
    if (me == null) throw Exception('Utilisateur non connecté');
    if (!canCreate(me.role)) throw Exception('Droit insuffisant');

    final a = Announcement(
      id: _id('ANN'),
      title: title.trim(),
      body: body?.trim().isEmpty == true ? null : body?.trim(),
      type: type,
      priority: priority,
      mediaPath: mediaPath,
      authorMatricule: me.matricule,
      authorRole: me.role,
      createdAt: DateTime.now(),
      targets: targets ?? [],
      readBy: const [],
      status: AnnouncementStatus.draft,
      submittedAt: null,
      submittedByMatricule: null,
      validatedAt: null,
      validatedByMatricule: null,
      scheduledAt: null,
      rejectReason: null,
    );

    _cache.insert(0, a);
    await LocalAnnouncementRepository.save(a);
    return a;
  }

  // ======================================================
  // 📩 DRAFT → PENDING
  // ======================================================
  static Future<void> submitForValidation(String id) async {
    final me = AuthSession.currentUser;
    if (me == null) return;

    final i = _cache.indexWhere((a) => a.id == id);
    if (i == -1) return;

    final updated = _cache[i].copyWith(
      status: AnnouncementStatus.pendingValidation,
      submittedAt: DateTime.now(),
      submittedByMatricule: me.matricule,
      rejectReason: null,
    );

    _cache[i] = updated;
    await LocalAnnouncementRepository.update(updated);

    AuditService.log(
      AuditAction.announcementSubmitted,
      description: 'Annonce ${updated.id} soumise par ${me.matricule}',
    );
  }

  // ======================================================
  // ✅ PUBLICATION
  // ======================================================
  static Future<void> publishNow(String id) async {
    final me = AuthSession.currentUser;
    if (me == null || !canValidatePublish(me.role)) {
      throw Exception('Admin uniquement');
    }

    final i = _cache.indexWhere((a) => a.id == id);
    if (i == -1) return;

    final updated = _cache[i].copyWith(
      status: AnnouncementStatus.published,
      validatedAt: DateTime.now(),
      validatedByMatricule: me.matricule,
      scheduledAt: null,
      rejectReason: null,
    );

    _cache[i] = updated;
    await LocalAnnouncementRepository.update(updated);

    AuditService.log(
      AuditAction.announcementPublished,
      description: 'Annonce ${updated.id} publiée par admin ${me.matricule}',
    );
  }

  // ======================================================
  // ⏳ PROGRAMMATION AUTO
  // ======================================================
  static Future<void> processScheduled() async {
    final now = DateTime.now();

    for (var i = 0; i < _cache.length; i++) {
      final a = _cache[i];

      if (a.status == AnnouncementStatus.scheduled &&
          a.scheduledAt != null &&
          !a.scheduledAt!.isAfter(now)) {
        final updated = a.copyWith(
          status: AnnouncementStatus.published,
          scheduledAt: null,
        );

        _cache[i] = updated;
        await LocalAnnouncementRepository.update(updated);

        AuditService.log(
          AuditAction.announcementPublished,
          description:
              'Annonce ${updated.id} publiée automatiquement (programmation)',
        );
      }
    }
  }

  // ======================================================
  // 👁️ MARQUER COMME LU
  // ======================================================
  static Future<void> markAsRead({
    required String announcementId,
    required String readerMatricule,
  }) async {
    final i = _cache.indexWhere((x) => x.id == announcementId);
    if (i == -1) return;

    final a = _cache[i];
    if (a.readBy.contains(readerMatricule)) return;

    final updated = a.copyWith(readBy: [...a.readBy, readerMatricule]);
    _cache[i] = updated;
    await LocalAnnouncementRepository.update(updated);
  }

  // ======================================================
  // 🆔 ID
  // ======================================================
  static String _id(String prefix) {
    final r = Random();
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(999)}';
  }
  // ======================================================
// ⏳ PROGRAMMER UNE PUBLICATION
// ======================================================
static Future<void> schedulePublish({
  required String id,
  required DateTime when,
}) async {
  final me = AuthSession.currentUser;
  if (me == null || !canValidatePublish(me.role)) {
    throw Exception('Admin uniquement');
  }

  final i = _cache.indexWhere((a) => a.id == id);
  if (i == -1) return;

  final updated = _cache[i].copyWith(
    status: AnnouncementStatus.scheduled,
    scheduledAt: when,
    validatedAt: DateTime.now(),
    validatedByMatricule: me.matricule,
    rejectReason: null,
  );

  _cache[i] = updated;
  await LocalAnnouncementRepository.update(updated);
}

// ======================================================
// ❌ REJET
// ======================================================
static Future<void> reject({
  required String id,
  String? reason,
}) async {
  final me = AuthSession.currentUser;
  if (me == null || !canValidatePublish(me.role)) {
    throw Exception('Admin uniquement');
  }

  final i = _cache.indexWhere((a) => a.id == id);
  if (i == -1) return;

  final updated = _cache[i].copyWith(
    status: AnnouncementStatus.rejected,
    validatedAt: DateTime.now(),
    validatedByMatricule: me.matricule,
    rejectReason: reason?.trim(),
    scheduledAt: null,
  );

  _cache[i] = updated;
  await LocalAnnouncementRepository.update(updated);
}

}
