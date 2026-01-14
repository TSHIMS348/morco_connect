import 'audit_action.dart';

class AuditEvent {
  final AuditAction action;
  final DateTime timestamp;
  final String? userMatricule;
  final String description;

  AuditEvent({
    required this.action,
    required this.timestamp,
    required this.description,
    this.userMatricule,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'timestamp': timestamp.toIso8601String(),
      'userMatricule': userMatricule,
      'description': description,
    };
  }
}
