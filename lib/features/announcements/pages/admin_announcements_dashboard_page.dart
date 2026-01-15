import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../users/services/user_directory_service.dart';

import '../models/announcement_status.dart';
import '../services/announcement_service.dart';

class AdminAnnouncementsDashboardPage extends StatelessWidget {
  const AdminAnnouncementsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔐 Sécurité
    if (!AuthSession.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Accès réservé administrateur')),
      );
    }

    final users = UserDirectoryService.getAll(activeOnly: true);
    final all = AnnouncementService.getAllCached();

    // =============================
    // 📊 Agrégations ÉTAT
    // =============================
    final int total = all.length;
    final int drafts =
        all.where((a) => a.status == AnnouncementStatus.draft).length;
    final int pending =
        all.where((a) => a.status == AnnouncementStatus.pendingValidation).length;
    final int scheduled =
        all.where((a) => a.status == AnnouncementStatus.scheduled).length;
    final int published =
        all.where((a) => a.status == AnnouncementStatus.published).length;

    // =============================
    // 📊 Impact global (publiées)
    // =============================
    int totalTargets = 0;
    int totalRead = 0;

    final publishedAnnouncements =
        all.where((a) => a.status == AnnouncementStatus.published);

    for (final a in publishedAnnouncements) {
      final targets =
          AnnouncementService.getTargetMatricules(a).toSet();
      final readers = a.readBy.toSet();

      for (final u in users) {
        if (!targets.contains(u.matricule)) continue;
        totalTargets++;
        if (readers.contains(u.matricule)) {
          totalRead++;
        }
      }
    }

    final int unread = totalTargets - totalRead;
    final int rate = totalTargets == 0
        ? 0
        : ((totalRead / totalTargets) * 100).round();

    // =============================
    // ⚠️ Annonces à faible impact
    // =============================
    final lowImpact = publishedAnnouncements.where((a) {
      int t = 0;
      int r = 0;

      final targets =
          AnnouncementService.getTargetMatricules(a).toSet();
      final readers = a.readBy.toSet();

      for (final u in users) {
        if (!targets.contains(u.matricule)) continue;
        t++;
        if (readers.contains(u.matricule)) {
          r++;
        }
      }

      return t > 0 && (r / t) < 0.5;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard – Annonces'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =============================
          // KPI — ÉTAT
          // =============================
          const _Section(title: 'État des annonces'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiCard(label: 'Total', value: '$total'),
              _KpiCard(label: 'Publiées', value: '$published'),
              _KpiCard(label: 'À valider', value: '$pending'),
              _KpiCard(label: 'Programmées', value: '$scheduled'),
              _KpiCard(label: 'Brouillons', value: '$drafts'),
            ],
          ),

          const SizedBox(height: 24),

          // =============================
          // KPI — IMPACT
          // =============================
          const _Section(title: 'Impact global'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiCard(label: 'Agents ciblés', value: '$totalTargets'),
              _KpiCard(label: 'Lus', value: '$totalRead'),
              _KpiCard(label: 'Non lus', value: '$unread'),
              _KpiCard(
                label: 'Taux lecture',
                value: '$rate%',
                highlight: rate < 50,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // =============================
          // ⚠️ À SURVEILLER
          // =============================
          const _Section(title: 'Annonces à faible impact'),
          if (lowImpact.isEmpty)
            const Text('✅ Toutes les annonces ont un bon taux de lecture.')
          else
            ...lowImpact.map((a) {
              int t = 0;
              int r = 0;

              final targets =
                  AnnouncementService.getTargetMatricules(a).toSet();
              final readers = a.readBy.toSet();

              for (final u in users) {
                if (!targets.contains(u.matricule)) continue;
                t++;
                if (readers.contains(u.matricule)) {
                  r++;
                }
              }

              final int p = t == 0 ? 0 : ((r / t) * 100).round();

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(a.title),
                subtitle: Text('Lecture : $p% ($r/$t)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/admin/announcements/detail',
                    arguments: a.id,
                  );
                },
              );
            }),
        ],
      ),
    );
  }
}

// ======================================================
// 🧩 UI Helpers
// ======================================================
class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _KpiCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlight
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
