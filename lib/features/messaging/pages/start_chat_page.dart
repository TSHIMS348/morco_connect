import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../users/models/system_user.dart';
import '../../users/services/user_directory_service.dart';
import '../services/conversation_service.dart';
import 'chat_page.dart';

class StartChatPage extends StatefulWidget {
  const StartChatPage({super.key});

  @override
  State<StartChatPage> createState() => _StartChatPageState();
}

class _StartChatPageState extends State<StartChatPage> {
  final _searchCtrl = TextEditingController();
  List<SystemUser> _results = const [];

  @override
  void initState() {
    super.initState();
    _results = UserDirectoryService.getAll(activeOnly: true);
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  // =============================
  // 🔍 Recherche utilisateur
  // =============================
  void _onSearch() {
    setState(() {
      _results = UserDirectoryService.search(_searchCtrl.text);
    });
  }

  // =============================
  // 💬 Démarrer une discussion directe
  // =============================
  Future<void> _start(SystemUser other) async {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) return;

    // 🔐 Sécurité : pas de chat avec soi-même
    if (other.matricule == me) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas vous écrire à vous-même'),
        ),
      );
      return;
    }

    // ✅ CORRECTION CLÉ : await obligatoire
    final conv = await ConversationService.createDirect(
      otherMatricule: other.matricule,
      otherName: other.fullName,
    );

    if (!mounted) return;

    // 🔁 Ouvre directement la page de chat
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatPage(conversationId: conv.id),
      ),
    );

    // 🔙 Informe la page précédente qu’une conversation a été créée
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau message')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =============================
            // 🔍 Champ de recherche
            // =============================
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un agent',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // =============================
            // 👥 Liste des utilisateurs
            // =============================
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = _results[i];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('${u.fullName} (${u.matricule})'),
                    subtitle: Text('${u.site} • ${u.city}'),
                    onTap: () => _start(u),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
