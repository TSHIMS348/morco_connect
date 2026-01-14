import 'package:hive/hive.dart';

part 'announcement_target_type.g.dart';

/// Ciblage de diffusion
@HiveType(typeId: 32)
enum AnnouncementTargetType {
  /// Tout le monde
  @HiveField(0)
  all,

  /// Par site (ex: "KCC")
  @HiveField(1)
  site,

  /// Par ville (ex: "Kolwezi")
  @HiveField(2)
  city,

  /// Par projet (refId = projectId)
  @HiveField(3)
  project,
}
