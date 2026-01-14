import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

// =============================
// 🔐 AUTH
// =============================
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/pending_validation_page.dart';
import 'features/auth/otp/otp_page.dart';
import 'features/auth/services/auth_session.dart';

// =============================
// 🏠 CORE PAGES
// =============================
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';

// =============================
// 🛡️ ADMIN
// =============================
import 'features/admin/admin_page.dart';
import 'features/admin/pages/admin_users_page.dart';
import 'features/admin/pages/admin_audit_page.dart';

// 🟣 ADMIN ANNOUNCEMENTS (B11)
import 'features/announcements/pages/admin_announcements_page.dart';
import 'features/announcements/pages/announcement_create_page.dart';

// =============================
// 📊 AUDIT
// =============================
import 'features/audit/services/audit_service.dart';
import 'features/audit/models/audit_action.dart';

class MorcoConnectApp extends StatelessWidget {
  const MorcoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Morco Connect',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',

      // ======================================================
      // 🔁 ROUTING CENTRAL (sécurisé & contrôlé)
      // ======================================================
      onGenerateRoute: (settings) {
        final route = settings.name ?? '/login';

        // 🔁 Mise à jour activité utilisateur (TTL / inactivité)
        AuthSession.touch();

        // ======================================================
        // ⏱️ Expiration globale de session
        // ======================================================
        if (AuthSession.isExpired) {
          AuditService.log(
            AuditAction.sessionExpired,
            description: 'Expiration détectée via navigation',
          );
          AuthSession.logout();
          return _page(const LoginPage());
        }

        // ======================================================
        // 🔒 Routes nécessitant une connexion
        // ======================================================
        const loggedInOnlyRoutes = {
          '/home',
          '/profile',
          '/admin',
          '/admin/users',
          '/admin/audit',
          '/admin/announcements',
          '/admin/announcements/create',
        };

        if (loggedInOnlyRoutes.contains(route) &&
            !AuthSession.isLoggedIn) {
          return _page(const LoginPage());
        }

        // ======================================================
        // 🔒 OTP / Pending uniquement si état pending
        // ======================================================
        if ((route == '/otp' || route == '/pending') &&
            !AuthSession.isPending) {
          return _page(const LoginPage());
        }

        // ======================================================
        // 🔒 ADMIN uniquement (toutes routes /admin/*)
        // ======================================================
        if (route.startsWith('/admin') && !AuthSession.isAdmin) {
          return _page(const HomePage());
        }

        // ======================================================
        // 🔒 Déjà connecté → pas de login/register
        // ======================================================
        if ((route == '/login' || route == '/register') &&
            AuthSession.isLoggedIn) {
          return _page(const HomePage());
        }

        // ======================================================
        // ✅ ROUTING NORMAL
        // ======================================================
        switch (route) {
          case '/login':
            return _page(const LoginPage());

          case '/register':
            return _page(const RegisterPage());

          case '/pending':
            return _page(const PendingValidationPage());

          case '/otp':
            return _page(const OtpPage());

          case '/home':
            return _page(const HomePage());

          case '/profile':
            return _page(const ProfilePage());

          // =============================
          // 🛡️ ADMIN CORE
          // =============================
          case '/admin':
            return _page(const AdminPage());

          case '/admin/users':
            return _page(AdminUsersPage());

          case '/admin/audit':
            return _page(const AdminAuditPage());

          // =============================
          // 🟣 ADMIN ANNOUNCEMENTS (B11)
          // =============================
          case '/admin/announcements':
            return _page(const AdminAnnouncementsPage());

          case '/admin/announcements/create':
            return _page(const AnnouncementCreatePage());

          // =============================
          // ❌ FALLBACK
          // =============================
          default:
            return _page(const LoginPage());
        }
      },
    );
  }

  // ======================================================
  // 📦 Helper de navigation
  // ======================================================
  MaterialPageRoute _page(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
