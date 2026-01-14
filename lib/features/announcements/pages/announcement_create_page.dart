import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../auth/services/auth_session.dart';
import '../../users/services/user_directory_service.dart';

import '../models/announcement_type.dart';
import '../models/announcement_priority.dart';
import '../models/announcement_target.dart';
import '../models/announcement_target_type.dart';

import '../services/announcement_service.dart';

class AnnouncementCreatePage extends StatefulWidget {
  const AnnouncementCreatePage({super.key});

  @override
  State<AnnouncementCreatePage> createState() => _AnnouncementCreatePageState();
}

class _AnnouncementCreatePageState extends State<AnnouncementCreatePage> {
  // =============================
  // 📝 Controllers
  // =============================
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  // ⚠️ "info" peut ne pas exister → on prend le premier
  AnnouncementType _type = AnnouncementType.values.first;
  AnnouncementPriority _priority = AnnouncementPriority.normal;

  // =============================
  // 🎯 Ciblage
  // =============================
  AnnouncementTargetType _targetType = AnnouncementTargetType.all;
  String? _targetRefId;

  // Project (saisi manuellement)
  final _projectIdCtrl = TextEditingController();

  // =============================
  // 📎 Média (1 seul)
  // =============================
  String? _mediaPath;
  String? _mediaName;

  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _projectIdCtrl.dispose();
    super.dispose();
  }

  // =============================
  // 📎 Pick media
  // =============================
  Future<void> _pickMedia() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;

    setState(() {
      _mediaPath = f.path ?? f.name; // web fallback
      _mediaName = f.name;
    });
  }

  void _removeMedia() {
    setState(() {
      _mediaPath = null;
      _mediaName = null;
    });
  }

  // =============================
  // 🎯 Build targets
  // =============================
  List<AnnouncementTarget> _buildTargets() {
    // ALL
    if (_targetType == AnnouncementTargetType.all) {
      return [
        AnnouncementTarget(
          type: AnnouncementTargetType.all,
          refId: null,
        ),
      ];
    }

    // SITE / CITY
    if (_targetType == AnnouncementTargetType.site ||
        _targetType == AnnouncementTargetType.city) {
      final ref = _targetRefId?.trim();
      if (ref == null || ref.isEmpty) return [];
      return [
        AnnouncementTarget(type: _targetType, refId: ref),
      ];
    }

    // PROJECT (saisie manuelle)
    if (_targetType == AnnouncementTargetType.project) {
      final pid = _projectIdCtrl.text.trim();
      if (pid.isEmpty) return [];
      return [
        AnnouncementTarget(
          type: AnnouncementTargetType.project,
          refId: pid,
        ),
      ];
    }

    return [];
  }

  // =============================
  // 🚀 Create draft
  // =============================
  Future<void> _submitCreateDraft() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty) {
      _snack('Le titre est obligatoire');
      return;
    }

    final targets = _buildTargets();

    if (_targetType != AnnouncementTargetType.all && targets.isEmpty) {
      _snack('Veuillez sélectionner une cible valide');
      return;
    }

    setState(() => _submitting = true);

    try {
      await AnnouncementService.create(
        title: title,
        body: body.isEmpty ? null : body,
        type: _type,
        priority: _priority,
        mediaPath: _mediaPath,
        targets: targets,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Accès refusé')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle annonce')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TITRE
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // MESSAGE
          TextField(
            controller: _bodyCtrl,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),

          // TYPE
          DropdownButtonFormField<AnnouncementType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: AnnouncementType.values
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 14),

          // PRIORITÉ
          DropdownButtonFormField<AnnouncementPriority>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Priorité',
              border: OutlineInputBorder(),
            ),
            items: AnnouncementPriority.values
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name.toUpperCase()),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? _priority),
          ),
          const SizedBox(height: 18),

          // CIBLAGE
          DropdownButtonFormField<AnnouncementTargetType>(
            value: _targetType,
            decoration: const InputDecoration(
              labelText: 'Ciblage',
              border: OutlineInputBorder(),
            ),
            items: AnnouncementTargetType.values
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _targetType = v;
                _targetRefId = null;
                _projectIdCtrl.clear();
              });
            },
          ),
          const SizedBox(height: 12),

          if (_targetType == AnnouncementTargetType.site ||
              _targetType == AnnouncementTargetType.city)
            _TargetSelectorFromUsers(
              type: _targetType,
              selected: _targetRefId,
              onSelected: (id) => setState(() => _targetRefId = id),
            ),

          if (_targetType == AnnouncementTargetType.project)
            TextField(
              controller: _projectIdCtrl,
              decoration: const InputDecoration(
                labelText: 'ID Projet',
                border: OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 18),

          // MEDIA
          Row(
            children: [
              const Text('Média (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(_mediaPath == null ? 'Ajouter' : 'Remplacer'),
                onPressed: _pickMedia,
              ),
            ],
          ),

          if (_mediaPath != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(_mediaName ?? _mediaPath!),
                subtitle: Text(_mediaPath!),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _removeMedia,
                ),
              ),
            ),

          const SizedBox(height: 28),

          ElevatedButton.icon(
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Créer (Draft)'),
            onPressed: _submitting ? null : _submitCreateDraft,
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 🎯 Target selector (site / ville)
// ======================================================
class _TargetSelectorFromUsers extends StatelessWidget {
  final AnnouncementTargetType type;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _TargetSelectorFromUsers({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final users = UserDirectoryService.getAll(activeOnly: true);

    final values = () {
      switch (type) {
        case AnnouncementTargetType.site:
          return users.map((u) => u.site).where((s) => s.isNotEmpty).toSet().toList()..sort();
        case AnnouncementTargetType.city:
          return users.map((u) => u.city).where((s) => s.isNotEmpty).toSet().toList()..sort();
        default:
          return <String>[];
      }
    }();

    return DropdownButtonFormField<String>(
      value: (selected != null && selected!.isNotEmpty) ? selected : null,
      decoration: const InputDecoration(
        labelText: 'Cible',
        border: OutlineInputBorder(),
      ),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) onSelected(v);
      },
    );
  }
}
