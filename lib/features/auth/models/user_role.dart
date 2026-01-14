import 'package:hive/hive.dart';

part 'user_role.g.dart';

@HiveType(typeId: 13)
enum UserRole {
  @HiveField(0)
  user,

  @HiveField(1)
  supervisor,

  @HiveField(2)
  projectManager,

  @HiveField(3)
  admin,
}
