import 'package:hive/hive.dart';
import 'attachment_type.dart';

part 'attachment.g.dart';

@HiveType(typeId: 1)
class Attachment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final AttachmentType type;

  /// Chemin local (offline). Plus tard : URL cloud (Firebase / S3 / etc.)
  @HiveField(2)
  final String path;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final int sizeBytes;

  Attachment({
    required this.id,
    required this.type,
    required this.path,
    required this.name,
    required this.sizeBytes,
  });
}
