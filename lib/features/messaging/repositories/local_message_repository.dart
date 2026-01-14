import 'package:hive/hive.dart';
import '../models/message.dart';

class LocalMessageRepository {
  static const _boxName = 'messages';

  static Future<Box<Message>> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Message>(_boxName);
    }
    return Hive.box<Message>(_boxName);
  }

  // 🔹 Messages d’une conversation
  static Future<List<Message>> getByConversation(String conversationId) async {
    final box = await _box();
    final list = box.values
        .where((m) => m.conversationId == conversationId)
        .toList();

    list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return list;
  }

  // 🔹 Sauvegarder un message
  static Future<void> save(Message msg) async {
    final box = await _box();
    await box.put(msg.id, msg);
  }

  // 🔹 Mise à jour (status, retry…)
  static Future<void> update(Message msg) async {
    final box = await _box();
    await box.put(msg.id, msg);
  }

  // 🔹 Supprimer
  static Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }
}
