import 'package:hive/hive.dart';

import '../../auth/models/user_role.dart';
import 'attachment.dart';
import 'message_status.dart';

part 'message.g.dart';

@HiveType(typeId: 2)
class Message {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String conversationId;

  /// Identité de l’expéditeur
  @HiveField(2)
  final String senderMatricule;

  /// ⭐ Rôle de l’expéditeur au moment de l’envoi
  @HiveField(3)
  final UserRole senderRole;

  /// Contenu texte (optionnel)
  @HiveField(4)
  final String? content;

  /// Pièces jointes
  @HiveField(5)
  final List<Attachment> attachments;

  /// Date/heure d’envoi
  @HiveField(6)
  final DateTime sentAt;

  /// Statut réseau
  @HiveField(7)
  final MessageStatus status;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderMatricule,
    required this.senderRole,
    required this.content,
    required this.attachments,
    required this.sentAt,
    required this.status,
  });

  /// Helpers UX
  bool get hasText => content != null && content!.trim().isNotEmpty;

  /// ⭐ Détection propre Admin / User
  bool get isFromAdmin => senderRole == UserRole.admin;

  /// Copie immuable (retry, update status)
  Message copyWith({
    MessageStatus? status,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderMatricule: senderMatricule,
      senderRole: senderRole,
      content: content,
      attachments: attachments,
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }
}
