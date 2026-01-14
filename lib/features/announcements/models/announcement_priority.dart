import 'package:hive/hive.dart';

part 'announcement_priority.g.dart';

/// Priorité (pour badge / tri / alerte)
@HiveType(typeId: 31)
enum AnnouncementPriority {
  @HiveField(0)
  normal,

  @HiveField(1)
  important,

  @HiveField(2)
  critical,
}
