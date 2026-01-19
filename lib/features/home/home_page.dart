import 'package:flutter/material.dart';

import 'package:morco_connect/core/widgets/secure_page.dart';
import 'package:morco_connect/features/auth/services/auth_session.dart';
import 'package:morco_connect/features/auth/models/user_profile.dart';

import 'package:morco_connect/features/projects/pages/projects_page.dart';
import 'package:morco_connect/features/messaging/pages/conversations_page.dart';
import 'package:morco_connect/features/announcements/pages/announcements_page.dart';
import 'package:morco_connect/features/profile/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser;

    return SecurePage(
      child: user == null
          ? const Scaffold(
              body: Center(child: Text('Utilisateur non connecté')),
            )
          : Scaffold(
              appBar: _HomeHeader(user: user),
              body: RefreshIndicator(
                onRefresh: () async {},
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    _SectionHeader(
                      title: 'Actualités & Annonces',
                      onSeeAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnnouncementsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const _AnnouncementsPreview(),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Mes projets',
                      onSeeAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProjectsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const _ProjectsPreview(),
                    const SizedBox(height: 24),
                    _quickActions(context),
                  ],
                ),
              ),
              bottomNavigationBar: const _BottomNav(currentIndex: 0),
            ),
    );
  }
}

// ======================================================
// 🔝 EN-TÊTE
// ======================================================
class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final UserProfile user;

  const _HomeHeader({required this.user});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          const CircleAvatar(radius: 20, child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${user.site} • ${user.city}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Messages',
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ConversationsPage(),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ======================================================
// 📰 APERÇU ANNONCES
// ======================================================
class _AnnouncementsPreview extends StatelessWidget {
  const _AnnouncementsPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.blue.withValues(alpha: 15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernières communications',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Annonces de la direction, HSE et management.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 🏗️ APERÇU PROJETS
// ======================================================
class _ProjectsPreview extends StatelessWidget {
  const _ProjectsPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.green.withValues(alpha: 15),
      ),
      child: const Text(
        'Accédez rapidement à vos projets actifs.',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ======================================================
// ⚡ RACCOURCIS
// ======================================================
Widget _quickActions(BuildContext context) {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    children: [
      _ActionTile(
        icon: Icons.campaign,
        label: 'Annonces',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnnouncementsPage()),
        ),
      ),
      _ActionTile(
        icon: Icons.chat,
        label: 'Messages',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConversationsPage()),
        ),
      ),
      _ActionTile(
        icon: Icons.work,
        label: 'Projets',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProjectsPage()),
        ),
      ),
      _ActionTile(
        icon: Icons.person,
        label: 'Profil',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        ),
      ),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// ⬇️ BOTTOM NAV
// ======================================================
class _BottomNav extends StatelessWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 1:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProjectsPage()),
            );
            break;
          case 2:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnouncementsPage()),
            );
            break;
          case 3:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Projets'),
        BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Annonces'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}

// ======================================================
// 🧩 HEADER SECTION
// ======================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('Voir tout'),
        ),
      ],
    );
  }
}
