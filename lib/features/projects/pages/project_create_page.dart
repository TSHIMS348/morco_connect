import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../auth/services/permission_service.dart';
import '../../users/models/system_user.dart';
import '../../users/services/user_directory_service.dart';
import '../services/project_service.dart';

class ProjectCreatePage extends StatefulWidget {
  const ProjectCreatePage({super.key});

  @override
  State<ProjectCreatePage> createState() => _ProjectCreatePageState();
}

class _ProjectCreatePageState extends State<ProjectCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _membersInputCtrl = TextEditingController();

  bool _isSaving = false;

  // Matricules sélectionnés
  final Set<String> _selectedMembers = {};

  @override
  void initState() {
    super.initState();

    // Ajoute automatiquement le créateur
    final me = AuthSession.currentUser?.matricule;
    if (me != null && me.isNotEmpty && UserDirectoryService.exists(me)) {
      _selectedMembers.add(me);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _membersInputCtrl.dispose();
    super.dispose();
  }

  List<String> _parseCsvMatricules(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _addFromInput() {
    final items = _parseCsvMatricules(_membersInputCtrl.text);
    if (items.isEmpty) return;

    final invalid = <String>[];
    for (final m in items) {
      if (!UserDirectoryService.exists(m)) {
        invalid.add(m);
      }
    }

    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Matricules introuvables: ${invalid.join(", ")}'),
        ),
      );
      return;
    }

    setState(() {
      _selectedMembers.addAll(items);
      _membersInputCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membres ajoutés')),
    );
  }

  Future<void> _openPicker() async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserPickerSheet(
        initiallySelected: _selectedMembers,
      ),
    );

    if (picked == null) return;
    setState(() {
      _selectedMembers
        ..clear()
        ..addAll(picked);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final user = AuthSession.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session invalide. Veuillez vous reconnecter.')),
      );
      return;
    }

    if (!PermissionService.canCreateProject()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Droits insuffisants (admin / chef projet / superviseur requis).')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Validation finale membres (sécurité)
    final members = _selectedMembers.toList();
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un membre')),
      );
      return;
    }

    final invalid = members.where((m) => !UserDirectoryService.exists(m)).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membres invalides: ${invalid.join(", ")}')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final project = ProjectService.create(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        members: members,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Projet créé : ${project.name}')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = _selectedMembers
        .map((m) => UserDirectoryService.findByMatricule(m))
        .whereType<SystemUser>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un projet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du projet',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Le nom est obligatoire';
                  if (value.length < 3) return 'Nom trop court';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'La description est obligatoire';
                  if (value.length < 10) return 'Description trop courte';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openPicker,
                      icon: const Icon(Icons.people),
                      label: const Text('Sélectionner des membres'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedUsers.map((u) {
                  final isOwner = u.matricule == AuthSession.currentUser?.matricule;
                  return Chip(
                    label: Text('${u.fullName} (${u.matricule})'),
                    deleteIcon: isOwner ? null : const Icon(Icons.close),
                    onDeleted: isOwner
                        ? null
                        : () {
                            setState(() => _selectedMembers.remove(u.matricule));
                          },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _membersInputCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ajouter via matricules (CSV)',
                  hintText: 'Ex: MRC014, MRC107',
                  helperText: 'Les matricules doivent exister dans l’annuaire.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addFromInput,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter depuis le champ'),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Enregistrement...' : 'Créer le projet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserPickerSheet extends StatefulWidget {
  final Set<String> initiallySelected;

  const _UserPickerSheet({
    required this.initiallySelected,
  });

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final _searchCtrl = TextEditingController();
  late Set<String> _selected;
  List<SystemUser> _results = const [];

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
    _results = UserDirectoryService.getAll(activeOnly: true);
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _results = UserDirectoryService.search(_searchCtrl.text, activeOnly: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottom + 16,
      ),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélection des membres',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher (nom, matricule, site, ville)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = _results[i];
                  final checked = _selected.contains(u.matricule);

                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(u.matricule);
                        } else {
                          // ne pas retirer le créateur
                          final me = AuthSession.currentUser?.matricule;
                          if (u.matricule == me) return;
                          _selected.remove(u.matricule);
                        }
                      });
                    },
                    title: Text('${u.fullName} (${u.matricule})'),
                    subtitle: Text('${u.site} • ${u.city} • ${u.role.name}'),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: Text('Valider (${_selected.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
