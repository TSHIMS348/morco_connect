import 'package:hive/hive.dart';
import 'conversation_type.dart';

part 'conversation.g.dart';

@HiveType(typeId: 3)
class Conversation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ConversationType type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? refId;

  @HiveField(4)
  final List<String> participants;

  @HiveField(5)
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.type,
    required this.title,
    required this.refId,
    required this.participants,
    required this.createdAt,
  });

  /// Vérifie si un utilisateur est membre
  bool isParticipant(String matricule) =>
      participants.contains(matricule);

  /// Copie immuable (utile pour sync membres projet/site/ville)
  Conversation copyWith({
    List<String>? participants,
  }) {
    return Conversation(
      id: id,
      type: type,
      title: title,
      refId: refId,
      participants: participants ?? this.participants,
      createdAt: createdAt,
    );
  }
}
