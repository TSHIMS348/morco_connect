import 'package:hive/hive.dart';
import '../models/conversation.dart';

class LocalConversationRepository {
  static const _boxName = 'conversations';

  static Future<Box<Conversation>> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Conversation>(_boxName);
    }
    return Hive.box<Conversation>(_boxName);
  }

  // 🔹 Lire toutes les conversations
  static Future<List<Conversation>> getAll() async {
    final box = await _box();
    return box.values.toList();
  }

  // 🔹 Lire par ID
  static Future<Conversation?> getById(String id) async {
    final box = await _box();
    return box.get(id);
  }

  // 🔹 Sauvegarder / mettre à jour
  static Future<void> save(Conversation conv) async {
    final box = await _box();
    await box.put(conv.id, conv);
  }

  // 🔹 Supprimer
  static Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }
}
