import 'package:hive/hive.dart';

part 'announcement_status.g.dart';

@HiveType(typeId: 31) // ⚠️ garde ton typeId actuel si déjà utilisé
enum AnnouncementStatus {
  @HiveField(0)
  draft, // créé, pas encore soumis

  @HiveField(1)
  pendingValidation, // soumis à l’admin

  @HiveField(2)
  scheduled, // validé + publication différée (date future)

  @HiveField(3)
  published, // visible users

  @HiveField(4)
  rejected, // refusé par admin
}
