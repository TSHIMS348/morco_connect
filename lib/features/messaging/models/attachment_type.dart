import 'package:hive/hive.dart';

part 'attachment_type.g.dart';

@HiveType(typeId: 10)
enum AttachmentType {
  @HiveField(0)
  image,

  @HiveField(1)
  file,

  @HiveField(2)
  audio,
}
