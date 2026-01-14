import 'package:hive/hive.dart';

part 'conversation_type.g.dart';

@HiveType(typeId: 12)
enum ConversationType {
  @HiveField(0)
  global,

  @HiveField(1)
  project,

  @HiveField(2)
  site,

  @HiveField(3)
  city,

  @HiveField(4)
  direct,

  @HiveField(5)
  announcement,
}
