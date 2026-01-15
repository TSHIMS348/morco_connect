import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../../users/services/user_directory_service.dart';

import '../models/announcement.dart';
import '../models/announcement_status.dart';
import '../models/announcement_target_type.dart';
import '../services/announcement_service.dart';

/// =====================================================
/// 📢 PAGE DÉTAIL ANNONCE
/// =====================================================
class AnnouncementDetailPage extends StatefulWidget {
  final String announcementId;

  const AnnouncementDetailPage({
    super.key,
    required this.announcementId,
  });

  @override
  State<AnnouncementDetailPage> createState() =>
      _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage> {
  Announcement? _announcement;

  @override
  void initState() {
    super.initState();
    _load();

    // 🔁 publication différée
    AnnouncementService.processScheduled().then((_) {
      if (!mounted) return;
      _load();
    });
  }

  void _load() {
    final all = AnnouncementService.getAllCached();

    final a = all.firstWhere(
      (x) => x.id == widget.announcementId,
      orElse: () => throw Exception('Annonce introuvable'),
    );

    setState(() => _announcement = a);

    // 👁️ marquer comme lu
    final me = AuthSession.currentUser;
    if (me != null && a.status == AnnouncementStatus.published) {
      AnnouncementService.markAsRead(
        announcementId: a.id,
        readerMatricule: me.matricule,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _announcement;

    if (a == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonce'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🏷️ HEADER
          Text(
            a.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusChip(status: a.status),
              _InfoChip(text: 'Auteur : ${a.authorMatricule}'),
              _InfoChip(
                text:
                    'Créée le ${a.createdAt.day.toString().padLeft(2, '0')}/'
                    '${a.createdAt.month.toString().padLeft(2, '0')}/'
                    '${a.createdAt.year}',
              ),
            ],
          ),

          const Divider(height: 32),

          // 📝 CONTENU
          if ((a.body ?? '').trim().isNotEmpty)
            Text(
              a.body!.trim(),
              style: const TextStyle(fontSize: 15, height: 1.5),
            )
          else
            const Text('—'),

          const SizedBox(height: 24),

          // 📊 IMPACT (ADMIN)
          _ImpactBlock(announcement: a),
        ],
      ),
    );
  }
}

// ======================================================
// 📊 Impact post-publication
// ======================================================
class _ImpactBlock extends StatelessWidget {
  final Announcement announcement;

  const _ImpactBlock({required this.announcement});

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isAdmin) return const SizedBox.shrink();

    if (announcement.status != AnnouncementStatus.published) {
      return _infoBox(
        '📊 Impact indisponible : annonce non publiée.',
        Colors.orange,
      );
    }

    final users = UserDirectoryService.getAll(activeOnly: true);

    final targeted = users.where((u) {
      if (announcement.isForAll) return true;

      return announcement.targets.any((t) {
        switch (t.type) {
          case AnnouncementTargetType.all:
            return true;
          case AnnouncementTargetType.site:
            return u.site == t.refId;
          case AnnouncementTargetType.city:
            return u.city == t.refId;
          case AnnouncementTargetType.project:
            return false;
        }
      });
    }).toList();

    final total = targeted.length;
    final read =
        targeted.where((u) => announcement.readBy.contains(u.matricule)).length;
    final unread = total - read;
    final rate = total == 0 ? 0.0 : read / total;
    final percent = (rate * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.green.withOpacity(0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Impact post-publication',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Kpi(label: 'Ciblés', value: '$total'),
              _Kpi(label: 'Lus', value: '$read'),
              _Kpi(label: 'Non lus', value: '$unread'),
              _Kpi(label: 'Taux', value: '$percent%'),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: rate.clamp(0, 1),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.08),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ======================================================
// 🧩 UI helpers
// ======================================================
class _StatusChip extends StatelessWidget {
  final AnnouncementStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return _Chip(label: status.name.toUpperCase());
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return _Chip(label: text);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;

  const _Kpi({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.04),
      ),
      child: Text(
        '$label : $value',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
