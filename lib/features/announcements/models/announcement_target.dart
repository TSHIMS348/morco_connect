import 'package:hive/hive.dart';
import 'announcement_target_type.dart';

part 'announcement_target.g.dart';

/// Une cible unique (site/city/project). On peut en mettre plusieurs.
@HiveType(typeId: 33)
class AnnouncementTarget extends HiveObject {
  @HiveField(0)
  final AnnouncementTargetType type;

  /// Pour site/city: refId = nom (String)
  /// Pour project: refId = projectId (String)
  /// Pour all: refId peut être null
  @HiveField(1)
  final String? refId;

  AnnouncementTarget({
    required this.type,
    this.refId,
  });
}
