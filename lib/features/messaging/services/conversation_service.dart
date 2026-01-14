import 'dart:math';

import '../../auth/services/auth_session.dart';
import '../../users/services/user_directory_service.dart';
import '../../projects/services/project_service.dart';

import '../models/conversation.dart';
import '../models/conversation_type.dart';

// ✅ Stockage Hive
import '../repositories/local_conversation_repository.dart';

class ConversationService {
  /// 🧠 Cache mémoire (SOURCE POUR L’UI)
  static final List<Conversation> _conversations = [];

  static bool _initialized = false;

  // =============================
  // 🚀 INITIALISATION CENTRALE
  // =============================
  static Future<void> init() async {
    if (_initialized) return;

    await ensureSystemConversations();

    final all = await LocalConversationRepository.getAll();
    _conversations
      ..clear()
      ..addAll(all);

    _initialized = true;
  }

  // =============================
  // 🔐 LECTURE — VERSION UI (SYNC)
  // =============================

  /// 👤 Utilisateur courant
  static List<Conversation> getForCurrentUser() {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) return [];

    return _conversations
        .where((c) => c.isParticipant(me))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 🛡️ Admin → tout
  static List<Conversation> getAll() {
    return [..._conversations]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 🔍 Par ID (utilisé partout dans l’UI)
  static Conversation? getById(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // =============================
  // 🧱 INITIALISATION SYSTÈME (ASYNC)
  // =============================
  static Future<void> ensureSystemConversations() async {
    await _ensureGlobal();
    await _ensureProjectConversations();
    await ensureSiteAndCityConversations();
  }

  // =============================
  // 🌍 GLOBAL
  // =============================
  static Future<void> _ensureGlobal() async {
    final existing =
        await LocalConversationRepository.getById('GLOBAL');

    if (existing != null) {
      _upsertCache(existing);
      return;
    }

    final participants = UserDirectoryService.getAll(activeOnly: true)
        .map((u) => u.matricule)
        .toList();

    final conv = Conversation(
      id: 'GLOBAL',
      type: ConversationType.global,
      title: 'Global',
      refId: null,
      participants: participants,
      createdAt: DateTime.now(),
    );

    await LocalConversationRepository.save(conv);
    _upsertCache(conv);
  }

  // =============================
  // 🧩 PROJETS
  // =============================
  static Future<void> _ensureProjectConversations() async {
    final isAdmin = AuthSession.isAdmin;

    final projects = isAdmin
        ? ProjectService.getAll()
        : ProjectService.getForCurrentUser();

    for (final p in projects) {
      final convId = 'PRJ:${p.id}';
      final existing =
          await LocalConversationRepository.getById(convId);

      if (existing == null) {
        final conv = Conversation(
          id: convId,
          type: ConversationType.project,
          title: 'Projet: ${p.name}',
          refId: p.id,
          participants: [...p.members],
          createdAt: DateTime.now(),
        );

        await LocalConversationRepository.save(conv);
        _upsertCache(conv);
      } else {
        final updated =
            existing.copyWith(participants: [...p.members]);

        await LocalConversationRepository.save(updated);
        _upsertCache(updated);
      }
    }
  }

  /// 🔁 Appelé depuis ProjectService
  static Future<void> syncProjectConversation({
    required String projectId,
    required String projectName,
    required List<String> members,
  }) async {
    final convId = 'PRJ:$projectId';

    final existing =
        await LocalConversationRepository.getById(convId);

    if (existing == null) {
      final conv = Conversation(
        id: convId,
        type: ConversationType.project,
        title: 'Projet: $projectName',
        refId: projectId,
        participants: [...members],
        createdAt: DateTime.now(),
      );

      await LocalConversationRepository.save(conv);
      _upsertCache(conv);
    } else {
      final updated =
          existing.copyWith(participants: [...members]);

      await LocalConversationRepository.save(updated);
      _upsertCache(updated);
    }
  }

  // =============================
  // 🏭 SITE / 🏙️ VILLE
  // =============================
  static Future<void> ensureSiteAndCityConversations() async {
    final users = UserDirectoryService.getAll(activeOnly: true);

    final sites = users.map((u) => u.site).toSet();
    final cities = users.map((u) => u.city).toSet();

    for (final site in sites) {
      await _ensureChannel(
        id: 'SITE:$site',
        type: ConversationType.site,
        title: 'Site: $site',
        refId: site,
        participants: users
            .where((u) => u.site == site)
            .map((u) => u.matricule)
            .toList(),
      );
    }

    for (final city in cities) {
      await _ensureChannel(
        id: 'CITY:$city',
        type: ConversationType.city,
        title: 'Ville: $city',
        refId: city,
        participants: users
            .where((u) => u.city == city)
            .map((u) => u.matricule)
            .toList(),
      );
    }
  }

  static Future<void> _ensureChannel({
    required String id,
    required ConversationType type,
    required String title,
    required String refId,
    required List<String> participants,
  }) async {
    final existing =
        await LocalConversationRepository.getById(id);

    if (existing == null) {
      final conv = Conversation(
        id: id,
        type: type,
        title: title,
        refId: refId,
        participants: participants,
        createdAt: DateTime.now(),
      );

      await LocalConversationRepository.save(conv);
      _upsertCache(conv);
    } else {
      final updated =
          existing.copyWith(participants: participants);

      await LocalConversationRepository.save(updated);
      _upsertCache(updated);
    }
  }

  // =============================
  // 👤 DIRECT (1-to-1)
  // =============================
  static Future<Conversation> createDirect({
    required String otherMatricule,
    required String otherName,
  }) async {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) throw Exception('Utilisateur non connecté');

    final participants = {me, otherMatricule}.toList()..sort();
    final key = participants.join('|');

    final all = await LocalConversationRepository.getAll();
    final existing = all.where((c) =>
        c.type == ConversationType.direct &&
        c.refId == key);

    if (existing.isNotEmpty) {
      final conv = existing.first;
      _upsertCache(conv);
      return conv;
    }

    final conv = Conversation(
      id: _generateId(prefix: 'DIR'),
      type: ConversationType.direct,
      title: otherName,
      refId: key,
      participants: participants,
      createdAt: DateTime.now(),
    );

    await LocalConversationRepository.save(conv);
    _upsertCache(conv);
    return conv;
  }

  // =============================
  // 🆔 ID
  // =============================
  static String _generateId({required String prefix}) {
    final r = Random();
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(999)}';
  }

  // =============================
  // 🧠 CACHE
  // =============================
  static void _upsertCache(Conversation conv) {
    final i = _conversations.indexWhere((c) => c.id == conv.id);
    if (i == -1) {
      _conversations.add(conv);
    } else {
      _conversations[i] = conv;
    }
  }
}
