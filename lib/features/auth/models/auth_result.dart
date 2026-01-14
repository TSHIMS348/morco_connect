import 'package:morco_connect/features/auth/models/user_status.dart';

class AuthResult {
  final bool success;
  final UserStatus status;
  final String message;

  AuthResult({
    required this.success,
    required this.status,
    required this.message,
  });
}
