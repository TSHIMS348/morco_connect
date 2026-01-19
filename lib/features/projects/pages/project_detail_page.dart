import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../auth/services/permission_service.dart';
import '../../users/services/user_directory_service.dart';
import '../../messaging/pages/chat_page.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  Project? _project;

  @override
  void initState() {
    super.initState();
    _reload();
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

  /// ======================================================
  /// 👥 Ouvre le sélecteur visuel des membres (BottomSheet)
  /// ======================================================
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
        ProjectService.addMember(
          projectId: p.id,
          matricule: m,
        );
      } catch (_) {}
    }

    for (final m in current.difference(picked)) {
      try {
        ProjectService.removeMember(
          projectId: p.id,
          matricule: m,
        );
      } catch (_) {}
    }

    _reload();
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

    final bool isAdmin = AuthSession.isAdmin;

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
          ],
        ),
      ),
    );
  }
}

/// ======================================================
/// 👥 BottomSheet — Sélecteur de membres du projet
/// ======================================================
class _UserPickerSheet extends StatefulWidget {
  final Set<String> initiallySelected;
  final String ownerMatricule;

  const _UserPickerSheet({
    required this.initiallySelected,
    required this.ownerMatricule,
  });

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
  }

  @override
  Widget build(BuildContext context) {
    final users = UserDirectoryService.getAll(activeOnly: true);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sélectionner les membres',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ListView(
              children: users.map((u) {
                final bool isOwner = u.matricule == widget.ownerMatricule;
                final bool checked = _selected.contains(u.matricule);

                return CheckboxListTile(
                  value: checked,
                  onChanged: isOwner
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(u.matricule);
                            } else {
                              _selected.remove(u.matricule);
                            }
                          });
                        },
                  title: Text('${u.fullName} (${u.matricule})'),
                  subtitle: Text('${u.site} • ${u.city}'),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Valider'),
            ),
          ),
        ],
      ),
    );
  }
}
