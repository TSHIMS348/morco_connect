import '../models/audit_event.dart';
import '../models/audit_action.dart';
import '../../auth/services/auth_session.dart';

class AuditService {
  static final List<AuditEvent> _events = [];

  /// ➕ Enregistrement d’un événement audit
  static void log(
    AuditAction action, {
    required String description,
  }) {
    final event = AuditEvent(
      action: action,
      timestamp: DateTime.now(),
      userMatricule: AuthSession.currentUser?.matricule,
      description: description,
    );

    _events.add(event);

    // 🔜 FUTUR : envoyer au backend
    // ApiService.sendAudit(event.toJson());
  }

  /// 📋 Tous les événements (lecture seule)
  static List<AuditEvent> get events => List.unmodifiable(_events);

  /// 🔍 FILTRAGE AVANCÉ (A4.5)
  static List<AuditEvent> filter({
    AuditAction? action,
    String? userMatricule,
    DateTime? from,
    DateTime? to,
  }) {
    return _events.where((e) {
      if (action != null && e.action != action) return false;

      if (userMatricule != null &&
          userMatricule.isNotEmpty &&
          e.userMatricule != userMatricule) {
        return false;
      }

      if (from != null && e.timestamp.isBefore(from)) return false;

      if (to != null && e.timestamp.isAfter(to)) return false;

      return true;
    }).toList();
  }
}
