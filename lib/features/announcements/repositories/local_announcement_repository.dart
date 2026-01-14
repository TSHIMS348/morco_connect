import 'package:hive/hive.dart';
import '../models/announcement.dart';

class LocalAnnouncementRepository {
  static const String _boxName = 'announcements_box';

  static Future<Box<Announcement>> _box() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Announcement>(_boxName);
    }
    return await Hive.openBox<Announcement>(_boxName);
  }

  static Future<List<Announcement>> getAll() async {
    final box = await _box();
    return box.values.toList();
  }

  static Future<void> save(Announcement a) async {
    final box = await _box();
    await box.put(a.id, a);
  }

  static Future<void> update(Announcement a) async {
    final box = await _box();
    await box.put(a.id, a);
  }

  static Future<Announcement?> getById(String id) async {
    final box = await _box();
    return box.get(id);
  }

  static Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }
}
