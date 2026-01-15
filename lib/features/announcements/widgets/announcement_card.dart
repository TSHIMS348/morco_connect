import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../auth/services/auth_session.dart';

import '../models/announcement.dart';
import '../models/announcement_target.dart';

/// ======================================================
/// 📢 Announcement Card (B11.x compatible)
/// ======================================================
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onOpen;
  final VoidCallback? onMarkRead;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onOpen,
    this.onMarkRead,
  });

  bool get _isReadByMe {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) return false;
    return announcement.readBy.contains(me);
  }

  @override
  Widget build(BuildContext context) {
    final tag = _inferTag(announcement);
    final theme = _tagTheme(tag);
    final isRead = _isReadByMe;

    final String? mediaPath = announcement.mediaPath;
    final bool hasMedia =
        mediaPath != null && mediaPath.trim().isNotEmpty;

    return Opacity(
      opacity: isRead ? 0.92 : 1.0,
      child: Card(
        elevation: isRead ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            onMarkRead?.call();
            onOpen?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============================
                // HEADER
                // =============================
                Row(
                  children: [
                    _TagChip(
                      label: tag.label,
                      background: theme.bg,
                      foreground: theme.fg,
                      icon: tag.icon,
                    ),
                    const SizedBox(width: 8),
                    _TargetsChip(targets: announcement.targets),
                    const Spacer(),
                    Text(
                      _formatDateTime(announcement.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // =============================
                // TITRE
                // =============================
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_isCritical(announcement, tag))
                      const Icon(Icons.priority_high, color: Colors.red),
                  ],
                ),

                const SizedBox(height: 6),

                // =============================
                // AUTEUR
                // =============================
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Par ${announcement.authorMatricule}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                    if (announcement.authorRole.name == 'admin')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: _AdminBadge(),
                      ),
                  ],
                ),

                // =============================
                // BODY
                // =============================
                if ((announcement.body ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    announcement.body ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // =============================
                // MEDIA
                // =============================
                if (hasMedia) ...[
                  const SizedBox(height: 12),
                  _MediaPreview(path: mediaPath),
                ],

                const SizedBox(height: 10),

                // =============================
                // FOOTER
                // =============================
                Row(
                  children: [
                    Icon(
                      isRead
                          ? Icons.visibility
                          : Icons.visibility_outlined,
                      size: 16,
                      color: isRead ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRead ? 'Vu' : 'Non lu',
                      style: TextStyle(
                        color: isRead
                            ? Colors.green
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Ouvrir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================
  // Helpers
  // =============================
  _AnnTag _inferTag(Announcement a) {
    final t = a.title.toLowerCase();
    final b = (a.body ?? '').toLowerCase();

    if (t.contains('hse') || b.contains('sécurité')) {
      return _AnnTag.hse();
    }
    if (t.contains('direction') || t.contains('dg')) {
      return _AnnTag.direction();
    }
    return _AnnTag.info();
  }

  bool _isCritical(Announcement a, _AnnTag tag) {
    final t = a.title.toLowerCase();
    return tag.key == 'hse' || t.contains('urgent');
  }

  _TagColors _tagTheme(_AnnTag tag) {
    switch (tag.key) {
      case 'hse':
        return _TagColors(
          bg: Colors.orange.withValues(alpha: 0.15),
          fg: Colors.deepOrange,
        );
      case 'direction':
        return _TagColors(
          bg: Colors.blue.withValues(alpha: 0.12),
          fg: Colors.blue.shade700,
        );
      default:
        return _TagColors(
          bg: Colors.grey.withValues(alpha: 0.15),
          fg: Colors.grey.shade800,
        );
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ======================================================
// 🎯 Targets chip
// ======================================================
class _TargetsChip extends StatelessWidget {
  final List<AnnouncementTarget> targets;

  const _TargetsChip({required this.targets});

  @override
  Widget build(BuildContext context) {
    final label = targets.isEmpty
        ? 'Tous'
        : targets.map((t) => t.type.name).join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ======================================================
// 📎 Media preview
// ======================================================
class _MediaPreview extends StatelessWidget {
  final String path;

  const _MediaPreview({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return const Text('Fichier introuvable');
    }

    final lower = path.toLowerCase();
    final isImage = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(file, fit: BoxFit.cover),
      );
    }

    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(path.split('/').last),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => OpenFilex.open(path),
    );
  }
}

// ======================================================
// 🧩 UI parts
// ======================================================
class _TagChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'ADMIN',
        style: TextStyle(
          fontSize: 10,
          color: Colors.red,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TagColors {
  final Color bg;
  final Color fg;
  const _TagColors({required this.bg, required this.fg});
}

class _AnnTag {
  final String key;
  final String label;
  final IconData icon;
  const _AnnTag(this.key, this.label, this.icon);

  factory _AnnTag.hse() =>
      const _AnnTag('hse', 'HSE', Icons.health_and_safety);
  factory _AnnTag.direction() =>
      const _AnnTag('direction', 'Direction', Icons.corporate_fare);
  factory _AnnTag.info() =>
      const _AnnTag('info', 'Info', Icons.info_outline);
}
