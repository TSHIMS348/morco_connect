import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../auth/services/permission_service.dart';
import '../../users/models/system_user.dart';
import '../../users/services/user_directory_service.dart';
import '../../messaging/pages/chat_page.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  Project? _project;

  final _csvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _csvCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _project = ProjectService.getById(widget.projectId);
    });
  }

  bool get _canManage {
    final p = _project;
    if (p == null) return false;
    return PermissionService.canManageProjectMembers(
      projectOwnerMatricule: p.createdBy,
    );
  }

  List<String> _parseCsv(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _addFromCsv() {
    final p = _project;
    if (p == null) return;

    final items = _parseCsv(_csvCtrl.text);
    if (items.isEmpty) return;

    final invalid = <String>[];
    for (final m in items) {
      if (!UserDirectoryService.exists(m)) {
        invalid.add(m);
      }
    }

    if (invalid.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Matricules introuvables: ${invalid.join(", ")}',
          ),
        ),
      );
      return;
    }

    for (final m in items) {
      try {
        ProjectService.addMember(
          projectId: p.id,
          matricule: m,
        );
      } catch (_) {}
    }

    _csvCtrl.clear();
    _reload();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membres ajoutés')),
    );

    Navigator.of(context).pop(true);
  }

  Future<void> _openPicker() async {
    final p = _project;
    if (p == null) return;

    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserPickerSheet(
        initiallySelected: p.members.toSet(),
        ownerMatricule: p.createdBy,
      ),
    );

    if (!mounted || picked == null) return;

    final current = p.members.toSet();

    for (final m in picked.difference(current)) {
      try {
        ProjectService.addMember(projectId: p.id, matricule: m);
      } catch (_) {}
    }

    for (final m in current.difference(picked)) {
      try {
        ProjectService.removeMember(projectId: p.id, matricule: m);
      } catch (_) {}
    }

    _reload();

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = _project;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails projet')),
        body: const Center(child: Text('Projet introuvable')),
      );
    }

    final users = p.members
        .map((m) => UserDirectoryService.findByMatricule(m))
        .whereType<SystemUser>()
        .toList();

    final isAdmin = AuthSession.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Discuter',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    conversationId: 'PRJ:${p.id}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: _openPicker,
              icon: const Icon(Icons.people),
              label: const Text('Gérer membres'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(p.description),
                    const SizedBox(height: 12),
                    Text('Créé par : ${p.createdBy}'),
                    Text('Membres : ${p.members.length}'),
                    if (isAdmin)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'ADMIN — accès complet au projet',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Membres',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: users.map((u) {
                  final isOwner = u.matricule == p.createdBy;
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('${u.fullName} (${u.matricule})'),
                    subtitle: Text('${u.site} • ${u.city} • ${u.role.name}'),
                    trailing: (_canManage && !isOwner)
                        ? IconButton(
                            icon:
                                const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              ProjectService.removeMember(
                                projectId: p.id,
                                matricule: u.matricule,
                              );
                              _reload();
                              if (!mounted) return;
                              Navigator.of(context).pop(true);
                            },
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
            if (_canManage) ...[
              const SizedBox(height: 20),
              TextFormField(
                controller: _csvCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ajouter via matricules (CSV)',
                  hintText: 'Ex: MRC014, MRC107',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addFromCsv,
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter depuis le champ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
