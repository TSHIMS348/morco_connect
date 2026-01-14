import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../users/services/user_directory_service.dart';

import '../models/announcement_status.dart';
import '../services/announcement_service.dart';

class AdminAnnouncementImpactByTargetPage extends StatefulWidget {
  const AdminAnnouncementImpactByTargetPage({super.key});

  @override
  State<AdminAnnouncementImpactByTargetPage> createState() =>
      _AdminAnnouncementImpactByTargetPageState();
}

class _AdminAnnouncementImpactByTargetPageState
    extends State<AdminAnnouncementImpactByTargetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Accès réservé administrateur')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact lecture — Annonces'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sites'),
            Tab(text: 'Villes'),
            Tab(text: 'Projets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ImpactByTarget(type: _TargetType.site),
          _ImpactByTarget(type: _TargetType.city),
          _ImpactByTarget(type: _TargetType.project),
        ],
      ),
    );
  }
}

enum _TargetType { site, city, project }

// ======================================================
// 🔎 Calcul + affichage impact par cible
// ======================================================
class _ImpactByTarget extends StatelessWidget {
  final _TargetType type;
  const _ImpactByTarget({required this.type});

  @override
  Widget build(BuildContext context) {
    final users = UserDirectoryService.getAll(activeOnly: true);

    // Annonces publiées uniquement
    final published = AnnouncementService.getAllCached()
        .where((a) => a.status == AnnouncementStatus.published)
        .toList();

    // Map: target -> {total, read}
    final Map<String, _ImpactStats> map = {};

    for (final a in published) {
      final stats = AnnouncementService.getReadStats(a);
      final targets = AnnouncementService.getTargetMatricules(a).toSet();
      final readers = a.readBy.toSet();

      for (final u in users) {
        final key = _keyForUser(u);

        if (!targets.contains(u.matricule)) continue;

        map.putIfAbsent(key, () => _ImpactStats());
        map[key]!.total++;

        if (readers.contains(u.matricule)) {
          map[key]!.read++;
        }
      }
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = entries[i];
        final rate = e.value.total == 0
            ? 0
            : (e.value.read / e.value.total * 100).round();

        Color color;
        if (rate < 30) {
          color = Colors.red;
        } else if (rate < 50) {
          color = Colors.orange;
        } else {
          color = Colors.green;
        }

        return ListTile(
          title: Text(e.key),
          subtitle: Text(
            'Lus ${e.value.read} / ${e.value.total}  •  $rate%',
          ),
          trailing: Icon(Icons.circle, color: color, size: 14),
        );
      },
    );
  }

  String _keyForUser(user) {
    switch (type) {
      case _TargetType.site:
        return user.site ?? '—';
      case _TargetType.city:
        return user.city ?? '—';
      case _TargetType.project:
        return user.projects.isEmpty ? '—' : user.projects.first;
    }
  }
}

// ======================================================
// 📊 Stats internes
// ======================================================
class _ImpactStats {
  int total = 0;
  int read = 0;
}
