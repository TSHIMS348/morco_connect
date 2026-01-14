import 'dart:math';

import '../../auth/services/auth_session.dart';
import '../models/message.dart';
import '../models/message_status.dart';
import '../models/attachment.dart';
import '../models/attachment_type.dart';
import '../services/conversation_service.dart';
import '../repositories/local_message_repository.dart';

class MessageService {
  // =============================
  // 🧠 Cache mémoire (pour UI synchro)
  // =============================
  static final Map<String, List<Message>> _cache = {};

  // =============================
  // 📖 Lecture
  // =============================
  static List<Message> getMessages(String conversationId) {
    final list = _cache[conversationId] ?? [];
    final copy = [...list]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return copy;
  }

  static Future<void> loadConversation(String conversationId) async {
    final list =
        await LocalMessageRepository.getByConversation(conversationId);
    _cache[conversationId] = list;
  }

  // =============================
  // 🔐 Sécurité d’accès
  // =============================
  static void _checkCanSend(String conversationId) {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) {
      throw Exception('Utilisateur non connecté');
    }

    final conv = ConversationService.getById(conversationId);
    if (conv == null) {
      throw Exception('Conversation introuvable');
    }

    final isAdmin = AuthSession.isAdmin;

    if (!isAdmin && !conv.participants.contains(me)) {
      throw Exception('Accès refusé à cette conversation');
    }
  }

  // =============================
  // ✉️ Envoi TEXTE
  // =============================
  static Message sendText({
    required String conversationId,
    required String content,
  }) {
    _checkCanSend(conversationId);

    final me = AuthSession.currentUser!;
    final role = me.role;

    final text = content.trim();
    if (text.isEmpty) throw Exception('Message vide');

    final msg = Message(
      id: _id('MSG'),
      conversationId: conversationId,
      senderMatricule: me.matricule,
      senderRole: role,
      content: text,
      attachments: const [],
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    _addAndPersist(msg);
    _simulateNetworkSend(msg);

    return msg;
  }

  // =============================
  // 📎 Envoi AVEC PIÈCES JOINTES
  // =============================
  static Message sendWithAttachments({
    required String conversationId,
    String? content,
    required List<Attachment> attachments,
  }) {
    _checkCanSend(conversationId);

    final me = AuthSession.currentUser!;
    final role = me.role;

    if ((content == null || content.trim().isEmpty) &&
        attachments.isEmpty) {
      throw Exception('Message vide');
    }

    final msg = Message(
      id: _id('MSG'),
      conversationId: conversationId,
      senderMatricule: me.matricule,
      senderRole: role,
      content: content?.trim(),
      attachments: attachments,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    _addAndPersist(msg);
    _simulateNetworkSend(msg);

    return msg;
  }

  // =============================
  // 🔁 RETRY MESSAGE ÉCHOUÉ
  // =============================
  static void retry(Message msg) {
    final updated = msg.copyWith(status: MessageStatus.sending);
    _replaceAndPersist(updated);
    _simulateNetworkSend(updated);
  }

  // =============================
  // 🔁 RETRY GLOBAL
  // =============================
  static Future<void> retryAllFailed() async {
    for (final entry in _cache.entries) {
      for (final msg in entry.value) {
        if (msg.status == MessageStatus.failed) {
          retry(msg);
        }
      }
    }
  }

  // =============================
  // 🧹 Nettoyage cache
  // =============================
  static void clearCacheFor(String conversationId) {
    _cache.remove(conversationId);
  }

  // ============================================================
  // ⭐ NOUVEAU — STATUT DELIVERED / READ (DIRECT ONLY)
  // ============================================================
  static void markDirectConversationAsRead({
    required String conversationId,
    required String readerMatricule,
  }) {
    final list = _cache[conversationId];
    if (list == null) return;

    bool changed = false;

    for (int i = 0; i < list.length; i++) {
      final msg = list[i];

      // seulement les messages reçus
      if (msg.senderMatricule == readerMatricule) continue;

      if (msg.status == MessageStatus.sent) {
        list[i] = msg.copyWith(status: MessageStatus.delivered);
        LocalMessageRepository.update(list[i]);
        changed = true;
      } else if (msg.status == MessageStatus.delivered) {
        list[i] = msg.copyWith(status: MessageStatus.read);
        LocalMessageRepository.update(list[i]);
        changed = true;
      }
    }

    if (changed) {
      _cache[conversationId] = list;
    }
  }

  // =============================
  // 📡 Simulation réseau
  // =============================
  static void _simulateNetworkSend(Message msg) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final success = Random().nextInt(100) >= 20;

    final updated = msg.copyWith(
      status: success ? MessageStatus.sent : MessageStatus.failed,
    );

    _replaceAndPersist(updated);
  }

  // =============================
  // 🧠 Cache + Hive
  // =============================
  static void _addAndPersist(Message msg) {
    _cache.putIfAbsent(msg.conversationId, () => []);
    _cache[msg.conversationId]!.add(msg);
    LocalMessageRepository.save(msg);
  }

  static void _replaceAndPersist(Message msg) {
    final list = _cache[msg.conversationId];
    if (list == null) return;

    final index = list.indexWhere((m) => m.id == msg.id);
    if (index == -1) return;

    list[index] = msg;
    LocalMessageRepository.update(msg);
  }

  // =============================
  // 🧱 Pièces jointes
  // =============================
  static Attachment makeAttachment({
    required AttachmentType type,
    required String path,
    required String name,
    required int sizeBytes,
  }) {
    return Attachment(
      id: _id('ATT'),
      type: type,
      path: path,
      name: name,
      sizeBytes: sizeBytes,
    );
  }

  // =============================
  // 🆔 ID
  // =============================
  static String _id(String prefix) {
    final r = Random();
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(999)}';
  }
}
