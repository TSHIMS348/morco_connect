import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../../audit/services/audit_service.dart';
import '../../audit/models/audit_action.dart';

enum SessionState {
  loggedOut,
  pending,
  loggedIn,
}

class AuthSession {
  // =============================
  // Storage keys
  // =============================
  static const _keyState = 'session_state';
  static const _keyLastActivity = 'last_activity';
  static const _keyCurrentUser = 'current_user';
  static const _keyPendingUser = 'pending_user';

  /// ⏱️ Durée max d’inactivité
  static const Duration sessionTimeout = Duration(minutes: 30);

  static SessionState _state = SessionState.loggedOut;
  static DateTime? _lastActivity;

  // =============================
  // Profils en mémoire
  // =============================
  static UserProfile? _currentUser;
  static UserProfile? get currentUser => _currentUser;

  static UserProfile? _pendingUser;
  static UserProfile? get pendingUser => _pendingUser;

  // =============================
  // Getters d’état
  // =============================
  static SessionState get state => _state;
  static bool get isLoggedIn => _state == SessionState.loggedIn;
  static bool get isPending => _state == SessionState.pending;

  // =============================
  // Rôles
  // =============================
  static UserRole get role => _currentUser?.role ?? UserRole.user;
  static bool get isAdmin => role == UserRole.admin;

  static DateTime? get lastActivity => _lastActivity;

  static bool get isExpired {
    if (_state == SessionState.loggedOut) return true;
    if (_lastActivity == null) return true;
    return DateTime.now().difference(_lastActivity!) > sessionTimeout;
  }

  // =============================
  // Restauration au démarrage
  // =============================
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final stateString = prefs.getString(_keyState);
    final lastActivityMillis = prefs.getInt(_keyLastActivity);

    final currentUserJson = prefs.getString(_keyCurrentUser);
    final pendingUserJson = prefs.getString(_keyPendingUser);

    if (stateString == null || lastActivityMillis == null) {
      AuditService.log(
        AuditAction.sessionExpired,
        description: 'Session invalide au démarrage (données manquantes)',
      );
      await logout();
      return;
    }

    _state = SessionState.values.firstWhere(
      (e) => e.name == stateString,
      orElse: () => SessionState.loggedOut,
    );

    _lastActivity =
        DateTime.fromMillisecondsSinceEpoch(lastActivityMillis);

    _currentUser = _decodeUser(currentUserJson);
    _pendingUser = _decodeUser(pendingUserJson);

    // Cohérence
    if (_state == SessionState.loggedIn && _currentUser == null) {
      AuditService.log(
        AuditAction.sessionExpired,
        description: 'Session corrompue (user manquant)',
      );
      await logout();
      return;
    }

    if (_state == SessionState.pending && _pendingUser == null) {
      AuditService.log(
        AuditAction.sessionExpired,
        description: 'Session pending corrompue',
      );
      await logout();
      return;
    }

    if (isExpired) {
      AuditService.log(
        AuditAction.sessionExpired,
        description: 'Session expirée au démarrage',
      );
      await logout();
      return;
    }

    await touch();
  }

  // =============================
  // Activité utilisateur
  // =============================
  static Future<void> touch() async {
    if (_state == SessionState.loggedOut) return;

    _lastActivity = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastActivity,
      _lastActivity!.millisecondsSinceEpoch,
    );
  }

  static Future<bool> ensureValidOrLogout() async {
    if (!isExpired) return true;

    AuditService.log(
      AuditAction.sessionExpired,
      description: 'Expiration automatique par inactivité',
    );

    await logout();
    return false;
  }

  // =============================
  // Transitions de session
  // =============================
  static Future<void> setPendingUser(UserProfile user) async {
    _pendingUser = user;
    _currentUser = null;
    _state = SessionState.pending;
    _lastActivity = DateTime.now();

    AuditService.log(
      AuditAction.login,
      description: 'Utilisateur en attente de validation (pending)',
    );

    await _persistAll();
  }

  static Future<void> loginFromPending() async {
    if (_pendingUser != null) {
      _currentUser = _pendingUser;
      _pendingUser = null;
    }

    _state = SessionState.loggedIn;
    _lastActivity = DateTime.now();

    AuditService.log(
      AuditAction.otpValidated,
      description: 'Transition pending → loggedIn',
    );

    await _persistAll();
  }

  static Future<void> loginWithUser(UserProfile user) async {
    _currentUser = user;
    _pendingUser = null;
    _state = SessionState.loggedIn;
    _lastActivity = DateTime.now();

    AuditService.log(
      AuditAction.login,
      description: 'Connexion directe utilisateur',
    );

    await _persistAll();
  }

  static Future<void> logout() async {
    if (_state != SessionState.loggedOut) {
      AuditService.log(
        AuditAction.logout,
        description: 'Déconnexion utilisateur',
      );
    }

    _state = SessionState.loggedOut;
    _lastActivity = null;
    _currentUser = null;
    _pendingUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyState);
    await prefs.remove(_keyLastActivity);
    await prefs.remove(_keyCurrentUser);
    await prefs.remove(_keyPendingUser);
  }

  // =============================
  // Profil
  // =============================
  static Future<void> updateProfile(UserProfile user) async {
    _currentUser = user;
    if (_state == SessionState.loggedIn) {
      await _persistAll();
    }
  }

  // =============================
  // Persistence
  // =============================
  static Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyState, _state.name);
    await prefs.setInt(
      _keyLastActivity,
      (_lastActivity ?? DateTime.now()).millisecondsSinceEpoch,
    );

    if (_currentUser != null) {
      await prefs.setString(
        _keyCurrentUser,
        jsonEncode(_currentUser!.toJson()),
      );
    } else {
      await prefs.remove(_keyCurrentUser);
    }

    if (_pendingUser != null) {
      await prefs.setString(
        _keyPendingUser,
        jsonEncode(_pendingUser!.toJson()),
      );
    } else {
      await prefs.remove(_keyPendingUser);
    }
  }

  static UserProfile? _decodeUser(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
