import 'package:hive/hive.dart';

part 'announcement_type.g.dart';

/// Type de contenu (backend-ready)
@HiveType(typeId: 30)
enum AnnouncementType {
  @HiveField(0)
  text,

  @HiveField(1)
  image,

  @HiveField(2)
  video,

  @HiveField(3)
  document,

  /// Lettre / note officielle (souvent PDF)
  @HiveField(4)
  letter,
}
