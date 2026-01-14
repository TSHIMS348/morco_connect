import 'package:hive/hive.dart';

part 'message_status.g.dart';

@HiveType(typeId: 11)
enum MessageStatus {
  @HiveField(0)
  sending,

  @HiveField(1)
  sent,

  // ✅ NOUVEAU — message arrivé chez le destinataire
  @HiveField(2)
  delivered,

  // ✅ NOUVEAU — message lu par le destinataire
  @HiveField(3)
  read,

  // ⚠️ déplacé À LA FIN pour ne rien casser
  @HiveField(4)
  failed,
}
