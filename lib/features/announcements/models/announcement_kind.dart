import 'package:hive/hive.dart';
part 'announcement_kind.g.dart';

@HiveType(typeId: 41)
enum AnnouncementKind {
  @HiveField(0)
  announcement, // officiel

  @HiveField(1)
  story, // statut
}
