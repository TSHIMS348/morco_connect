import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';

import '../models/conversation.dart';
import '../models/conversation_type.dart';
import '../models/conversation_filter.dart';
import '../services/conversation_service.dart';

import 'chat_page.dart';
import 'start_chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<Conversation> _convs = const [];

  // =========================
  // 🎛️ ÉTAT DU FILTRE
  // =========================
  ConversationFilter _filter = ConversationFilter.all;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // =========================
  // 🔄 RECHARGEMENT DES CONVERSATIONS
  // - admin → toutes les conversations
  // - user  → conversations autorisées
  // ⚠️ async car Hive
  // =========================
  Future<void> _reload() async {
    final isAdmin = AuthSession.isAdmin;

    final list = isAdmin
        ? ConversationService.getAll()
        : ConversationService.getForCurrentUser();

    if (!mounted) return;

    setState(() {
      _convs = list;
    });
  }

  // =========================
  // 🔍 APPLICATION DU FILTRE
  // =========================
  List<Conversation> _filtered(List<Conversation> list) {
    switch (_filter) {
      case ConversationFilter.project:
        return list
            .where((c) => c.type == ConversationType.project)
            .toList();

      case ConversationFilter.site:
        return list
            .where((c) => c.type == ConversationType.site)
            .toList();

      case ConversationFilter.city:
        return list
            .where((c) => c.type == ConversationType.city)
            .toList();

      case ConversationFilter.global:
        return list
            .where((c) => c.type == ConversationType.global)
            .toList();

      case ConversationFilter.all:
      default:
        return list;
    }
  }

  // =========================
  // 🎨 ICÔNE PAR TYPE
  // (announcement géré)
  // =========================
  IconData _iconForType(ConversationType t) {
    switch (t) {
      case ConversationType.global:
        return Icons.public;

      case ConversationType.project:
        return Icons.work;

      case ConversationType.site:
        return Icons.factory;

      case ConversationType.city:
        return Icons.location_city;

      case ConversationType.direct:
        return Icons.person;

      case ConversationType.announcement:
        return Icons.campaign; // ✅ NOUVEAU
    }
  }

  // =========================
  // 📝 SOUS-TITRE
  // =========================
  String _subtitle(Conversation c) {
    switch (c.type) {
      case ConversationType.global:
        return 'Tout le monde';

      case ConversationType.project:
        return 'Canal projet • ${c.participants.length} membres';

      case ConversationType.site:
        return 'Canal site • ${c.participants.length} membres';

      case ConversationType.city:
        return 'Canal ville • ${c.participants.length} membres';

      case ConversationType.direct:
        return 'Discussion privée';

      case ConversationType.announcement:
        return 'Annonce officielle'; // ✅
    }
  }

  // =========================
  // ➕ DÉMARRER UNE DISCUSSION DIRECTE
  // =========================
  Future<void> _openStartChat() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const StartChatPage()),
    );

    if (created == true) {
      _reload();
    }
  }

  // =========================
  // 💬 OUVRIR UNE CONVERSATION
  // =========================
  Future<void> _openChat(Conversation c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(conversationId: c.id),
      ),
    );

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final visibleConversations = _filtered(_convs);
    final isAdmin = AuthSession.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: _openStartChat,
            icon: const Icon(Icons.edit_square),
            tooltip: 'Nouveau message',
          ),
        ],
      ),
      body: Column(
        children: [
          // =========================
          // 🎛️ FILTRES (Projet / Site / Ville / Global)
          // =========================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: ConversationFilter.values.map((f) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f.name.toUpperCase()),
                    selected: _filter == f,
                    onSelected: (_) {
                      setState(() => _filter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // =========================
          // 📜 LISTE DES CONVERSATIONS
          // =========================
          Expanded(
            child: visibleConversations.isEmpty
                ? const Center(child: Text('Aucune conversation'))
                : ListView.separated(
                    itemCount: visibleConversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = visibleConversations[i];

                      return ListTile(
                        leading: Icon(_iconForType(c.type)),

                        // =========================
                        // 🛡️ BADGE ADMIN (VISIBLE SI ADMIN)
                        // =========================
                        title: Row(
                          children: [
                            Expanded(child: Text(c.title)),
                            if (isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        subtitle: Text(_subtitle(c)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openChat(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
