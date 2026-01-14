import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';

import '../models/announcement.dart';
import '../models/announcement_status.dart';
import '../models/announcement_priority.dart';

// ✅ IMPORT UNIQUE ET CORRECT
import '../services/announcement_service.dart';

import 'announcement_detail_page.dart';


class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // =============================
  // 🔎 Recherche + filtres (B11.4)
  // =============================
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Filtre priorité : null = toutes
  AnnouncementPriority? _priorityFilter;

  // Tri : true = plus récents d’abord
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: AnnouncementStatus.values.length,
      vsync: this,
    );

    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Accès réservé administrateur')),
      );
    }

    final all = AnnouncementService.getAllCached();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces – Administration'),
        actions: [
          IconButton(
            tooltip: 'Créer une annonce',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context)
                  .pushNamed('/admin/announcements/create');
              setState(() {});
            },
          ),
        ],

        // 🔎 Recherche + filtres + tabs
        bottom: PreferredSize(
          // ✅ 112 était trop petit (Search + filtres + TabBar)
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onClear: () => _searchCtrl.clear(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _PriorityFilter(
                        value: _priorityFilter,
                        onChanged: (v) =>
                            setState(() => _priorityFilter = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: _sortNewestFirst
                          ? 'Tri : plus récent'
                          : 'Tri : plus ancien',
                      icon: Icon(_sortNewestFirst
                          ? Icons.arrow_downward
                          : Icons.arrow_upward),
                      onPressed: () =>
                          setState(() => _sortNewestFirst = !_sortNewestFirst),
                    ),
                    IconButton(
                      tooltip: 'Réinitialiser',
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _priorityFilter = null;
                          _sortNewestFirst = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: AnnouncementStatus.values.map(_statusTab).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: AnnouncementStatus.values.map((status) {
          var list = all.where((a) => a.status == status).toList();

          // Recherche
          if (_query.isNotEmpty) {
            list = list.where((a) {
              final t = a.title.toLowerCase();
              final b = (a.body ?? '').toLowerCase();
              final author = a.authorMatricule.toLowerCase();
              return t.contains(_query) ||
                  b.contains(_query) ||
                  author.contains(_query);
            }).toList();
          }

          // Filtre priorité
          if (_priorityFilter != null) {
            list = list.where((a) => a.priority == _priorityFilter).toList();
          }

          // Tri
          list.sort((a, b) => _sortNewestFirst
              ? b.createdAt.compareTo(a.createdAt)
              : a.createdAt.compareTo(b.createdAt));

          if (list.isEmpty) {
            return const Center(child: Text('Aucune annonce'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final ann = list[i];

              return _AdminAnnouncementTile(
                announcement: ann,
                onRefresh: () => setState(() {}),

                // B11.4 : planification
                onSchedule: () async {
                  final when = await _pickDateTime(context);
                  if (when == null) return;

                  await AnnouncementService.schedulePublish(
                    id: ann.id,
                    when: when,
                  );

                  setState(() {});
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Tab _statusTab(AnnouncementStatus s) => Tab(text: _labelForStatus(s));

  String _labelForStatus(AnnouncementStatus s) {
    switch (s) {
      case AnnouncementStatus.draft:
        return 'Brouillons';
      case AnnouncementStatus.pendingValidation:
        return 'À valider';
      case AnnouncementStatus.scheduled:
        return 'Programmées';
      case AnnouncementStatus.published:
        return 'Publiées';
      case AnnouncementStatus.rejected:
        return 'Rejetées';
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
    );
    if (time == null) return null;

    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (when.isBefore(now)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date/heure invalide (dans le passé).')),
        );
      }
      return null;
    }

    return when;
  }
}

// ======================================================
// 🔎 Search bar
// ======================================================
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Rechercher (titre, auteur, contenu)…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        isDense: true,
      ),
    );
  }
}

// ======================================================
// 🎯 Filtre priorité (aligné sur ton enum: normal/important/critical)
// ======================================================
class _PriorityFilter extends StatelessWidget {
  final AnnouncementPriority? value;
  final ValueChanged<AnnouncementPriority?> onChanged;

  const _PriorityFilter({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AnnouncementPriority?>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Priorité',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Toutes')),
        DropdownMenuItem(value: AnnouncementPriority.normal, child: Text('Normal')),
        DropdownMenuItem(value: AnnouncementPriority.important, child: Text('Important')),
        DropdownMenuItem(value: AnnouncementPriority.critical, child: Text('Critique')),
      ],
      onChanged: onChanged,
    );
  }
}

// ======================================================
// 🧩 Tuile Admin (Badges + actions workflow)
// ======================================================
class _AdminAnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onRefresh;
  final Future<void> Function()? onSchedule;

  const _AdminAnnouncementTile({
    required this.announcement,
    required this.onRefresh,
    this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: _leadingIcon(),
        title: Text(
          announcement.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusBadge(status: announcement.status),
            _PriorityBadge(priority: announcement.priority),
            if (announcement.status == AnnouncementStatus.scheduled &&
                announcement.scheduledAt != null)
              _SmallInfo(text: _formatDate(announcement.scheduledAt!)),
            _SmallInfo(text: announcement.authorMatricule),
          ],
        ),
        trailing: _actions(context),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnnouncementDetailPage(
                announcementId: announcement.id,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _leadingIcon() {
    switch (announcement.status) {
      case AnnouncementStatus.draft:
        return const Icon(Icons.edit_note);
      case AnnouncementStatus.pendingValidation:
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      case AnnouncementStatus.scheduled:
        return const Icon(Icons.schedule, color: Colors.blue);
      case AnnouncementStatus.published:
        return const Icon(Icons.check_circle, color: Colors.green);
      case AnnouncementStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }

  Widget _actions(BuildContext context) {
    switch (announcement.status) {
      case AnnouncementStatus.draft:
        return IconButton(
          tooltip: 'Soumettre',
          icon: const Icon(Icons.send),
          onPressed: () async {
            await AnnouncementService.submitForValidation(announcement.id);
            onRefresh();
          },
        );

      case AnnouncementStatus.pendingValidation:
        return PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'publish') {
              final ok = await _confirmWithAudience(
                context,
                actionLabel: 'Publier',
              );
              if (!ok) return;

              await AnnouncementService.publishNow(announcement.id);
              onRefresh();
              return;
            }

            if (v == 'schedule') {
              final ok = await _confirmWithAudience(
                context,
                actionLabel: 'Programmer',
              );
              if (!ok) return;

              if (onSchedule != null) {
                await onSchedule!();
              }
              return;
            }

            if (v == 'reject') {
              final reason = await _askRejectReason(context);
              if (reason == null) return;

              await AnnouncementService.reject(
                id: announcement.id,
                reason: reason,
              );
              onRefresh();
              return;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'publish', child: Text('Publier maintenant')),
            PopupMenuItem(value: 'schedule', child: Text('Programmer…')),
            PopupMenuItem(value: 'reject', child: Text('Rejeter…')),
          ],
        );

      default:
        return const Icon(Icons.chevron_right);
    }
  }

  Future<String?> _askRejectReason(BuildContext context) async {
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejeter cette annonce ?'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motif du rejet (obligatoire)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (ok != true) return null;

    final reason = ctrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Motif obligatoire.')),
      );
      return null;
    }

    return reason;
  }

  Future<bool> _confirmWithAudience(
    BuildContext context, {
    required String actionLabel,
  }) async {
    // ✅ IMPORTANT : ta méthode service est getTargetMatricules(a)
    final targets = AnnouncementService.getTargetMatricules(announcement);

    if (targets.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Audience vide'),
          content: const Text(
            'Cette annonce ne cible aucun agent.\n'
            'Veuillez vérifier le ciblage (Tous/Site/Ville/Projet).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$actionLabel cette annonce ?'),
        content: Text('Cette annonce sera visible par ${targets.length} agent(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    return ok == true;
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$mi';
  }
}

// ======================================================
// 🏷️ Badges UI (statut)
// ======================================================
class _StatusBadge extends StatelessWidget {
  final AnnouncementStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case AnnouncementStatus.draft:
        label = 'DRAFT';
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey.shade800;
        break;
      case AnnouncementStatus.pendingValidation:
        label = 'PENDING';
        bg = Colors.orange.withOpacity(0.14);
        fg = Colors.orange.shade900;
        break;
      case AnnouncementStatus.scheduled:
        label = 'SCHEDULED';
        bg = Colors.blue.withOpacity(0.14);
        fg = Colors.blue.shade800;
        break;
      case AnnouncementStatus.published:
        label = 'PUBLISHED';
        bg = Colors.green.withOpacity(0.14);
        fg = Colors.green.shade800;
        break;
      case AnnouncementStatus.rejected:
        label = 'REJECTED';
        bg = Colors.red.withOpacity(0.14);
        fg = Colors.red.shade800;
        break;
    }

    return _Badge(label: label, bg: bg, fg: fg);
  }
}

// ======================================================
// 🏷️ Badges UI (priorité)
// ======================================================
class _PriorityBadge extends StatelessWidget {
  final AnnouncementPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (priority) {
      case AnnouncementPriority.normal:
        label = 'NORMAL';
        bg = Colors.grey.withOpacity(0.10);
        fg = Colors.grey.shade800;
        break;

      case AnnouncementPriority.important:
        label = 'IMPORTANT';
        bg = Colors.blueGrey.withOpacity(0.10);
        fg = Colors.blueGrey.shade800;
        break;

      case AnnouncementPriority.critical:
        label = 'CRITICAL';
        bg = Colors.red.withOpacity(0.12);
        fg = Colors.red.shade900;
        break;
    }

    return _Badge(label: label, bg: bg, fg: fg);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final String text;
  const _SmallInfo({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.black54),
    );
  }
}
