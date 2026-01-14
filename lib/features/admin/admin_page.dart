import 'package:flutter/material.dart';
import 'package:morco_connect/features/auth/services/permission_service.dart';

/// ======================================================
/// 🛡️ ESPACE ADMINISTRATEUR
/// 👉 Hub central pour toutes les actions admin
/// 👉 Sécurisé via PermissionService
/// ======================================================
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔐 Sécurité : accès admin uniquement
    if (!PermissionService.canViewAdminPanel()) {
      return const Scaffold(
        body: Center(
          child: Text('Accès refusé'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Administrateur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =============================
            // 🏷️ TITRE SECTION
            // =============================
            const Text(
              'Actions administrateur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // =============================
            // 👥 GESTION UTILISATEURS
            // =============================
            _AdminActionCard(
              icon: Icons.people,
              title: 'Utilisateurs',
              description: 'Valider les comptes en attente',
              onTap: () {
                Navigator.of(context).pushNamed('/admin/users');
              },
            ),

            // =============================
            // 📢 ANNONCES (B11 – NOUVEAU)
            // =============================
            _AdminActionCard(
              icon: Icons.campaign,
              title: 'Annonces',
              description:
                  'Créer, valider et publier des annonces institutionnelles',
              onTap: () {
                Navigator.of(context).pushNamed('/admin/announcements');
              },
            ),

            // =============================
            // 🧾 AUDIT & SÉCURITÉ
            // =============================
            _AdminActionCard(
              icon: Icons.security,
              title: 'Audit',
              description: 'Consulter le journal de sécurité',
              onTap: () {
                Navigator.of(context).pushNamed('/admin/audit');
              },
            ),

            // =============================
            // ⚙️ PARAMÈTRES (FUTUR)
            // =============================
            _AdminActionCard(
              icon: Icons.settings,
              title: 'Paramètres',
              description: 'Configuration administrateur',
              enabled: false, // réservé
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================================================
/// 🧱 WIDGET : CARTE D’ACTION ADMIN
/// 👉 Réutilisable
/// 👉 Enabled / Disabled
/// ======================================================
class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool enabled;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
