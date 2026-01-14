import 'package:hive/hive.dart';

import '../../auth/models/user_role.dart';
import 'announcement_type.dart';
import 'announcement_priority.dart';
import 'announcement_target.dart';
import 'announcement_status.dart';

part 'announcement.g.dart';

@HiveType(typeId: 34) // ⚠️ ON GARDE ABSOLUMENT CE typeId
class Announcement extends HiveObject {
  // =============================
  // 🔑 IDENTITÉ & CONTENU
  // =============================
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  /// Corps texte (optionnel : vidéo / image seule possible)
  @HiveField(2)
  final String? body;

  @HiveField(3)
  final AnnouncementType type;

  @HiveField(4)
  final AnnouncementPriority priority;

  /// Pièce jointe principale (image / vidéo / document)
  /// (support multi-attachments prévu plus tard)
  @HiveField(5)
  final String? mediaPath;

  // =============================
  // 👤 AUTEUR
  // =============================
  @HiveField(6)
  final String authorMatricule;

  @HiveField(7)
  final UserRole authorRole;

  // =============================
  // ⏱️ MÉTADONNÉES
  // =============================
  @HiveField(8)
  final DateTime createdAt;

  /// Ciblage : liste vide => TOUS
  @HiveField(9)
  final List<AnnouncementTarget> targets;

  /// Tracking lecture (matricules ayant lu)
  @HiveField(10)
  final List<String> readBy;

  // =====================================================
  // 🧠 WORKFLOW – B11.3 (AJOUT EN FIN POUR HIVE SAFE)
  // =====================================================

  /// Statut global de l’annonce
  /// ⚠️ valeur par défaut = draft
  @HiveField(50)
  final AnnouncementStatus status;

  /// Date de soumission à validation (draft → pending)
  @HiveField(51)
  final DateTime? submittedAt;

  /// Matricule de celui qui a soumis
  @HiveField(52)
  final String? submittedByMatricule;

  /// Date de validation (par admin)
  @HiveField(53)
  final DateTime? validatedAt;

  /// Matricule de l’admin validateur
  @HiveField(54)
  final String? validatedByMatricule;

  /// Date programmée de publication (si différée)
  @HiveField(55)
  final DateTime? scheduledAt;

  /// Motif de rejet (si refusée)
  @HiveField(56)
  final String? rejectReason;

  // =============================
  // 🧱 CONSTRUCTEUR (SAFE)
  // =============================
  Announcement({
    required this.id,
    required this.title,
    this.body,
    required this.type,
    required this.priority,
    this.mediaPath,
    required this.authorMatricule,
    required this.authorRole,
    required this.createdAt,
    required this.targets,
    required this.readBy,

    // 🔽 WORKFLOW — valeurs par défaut
    this.status = AnnouncementStatus.draft,
    this.submittedAt,
    this.submittedByMatricule,
    this.validatedAt,
    this.validatedByMatricule,
    this.scheduledAt,
    this.rejectReason,
  });

  // =============================
  // 🧠 HELPERS EXISTANTS
  // =============================
  bool get isForAll => targets.isEmpty;

  bool isReadBy(String matricule) => readBy.contains(matricule);

  // =============================
  // 🆕 HELPERS WORKFLOW
  // =============================
  bool get isDraft => status == AnnouncementStatus.draft;

  bool get isPending =>
      status == AnnouncementStatus.pendingValidation;

  bool get isScheduled =>
      status == AnnouncementStatus.scheduled;

  bool get isPublished =>
      status == AnnouncementStatus.published;

  bool get isRejected =>
      status == AnnouncementStatus.rejected;

  // =============================
  // 🔁 copyWith ÉTENDU (SAFE)
  // =============================
  Announcement copyWith({
    String? title,
    String? body,
    AnnouncementType? type,
    AnnouncementPriority? priority,
    String? mediaPath,
    List<AnnouncementTarget>? targets,
    List<String>? readBy,

    // Workflow
    AnnouncementStatus? status,
    DateTime? submittedAt,
    String? submittedByMatricule,
    DateTime? validatedAt,
    String? validatedByMatricule,
    DateTime? scheduledAt,
    String? rejectReason,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      mediaPath: mediaPath ?? this.mediaPath,
      authorMatricule: authorMatricule,
      authorRole: authorRole,
      createdAt: createdAt,
      targets: targets ?? this.targets,
      readBy: readBy ?? this.readBy,

      // Workflow
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedByMatricule:
          submittedByMatricule ?? this.submittedByMatricule,
      validatedAt: validatedAt ?? this.validatedAt,
      validatedByMatricule:
          validatedByMatricule ?? this.validatedByMatricule,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}
