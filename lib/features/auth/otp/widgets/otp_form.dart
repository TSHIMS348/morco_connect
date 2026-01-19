import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/auth_session.dart';
import 'package:morco_connect/features/audit/services/audit_service.dart';
import 'package:morco_connect/features/audit/models/audit_action.dart';

/// ======================================================
/// 🔐 OTP FORM
/// - Validation OTP avec expiration
/// - Sécurité async (mounted)
/// - Audit systématique
/// ======================================================
class OtpForm extends StatefulWidget {
  const OtpForm({super.key});

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  static const int _otpDuration = 120; // secondes
  Timer? _timer;
  int _remainingSeconds = _otpDuration;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  /// ======================================================
  /// ⏱️ Timer OTP
  /// ======================================================
  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _otpDuration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        setState(() => _remainingSeconds = 0);
        timer.cancel();
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// ======================================================
  /// ✅ Validation OTP
  /// ======================================================
  Future<void> _submit() async {
    if (_isLoading) return;

    /// ⛔ OTP expiré → logout + audit + redirection
    if (_remainingSeconds == 0) {
      AuditService.log(
        AuditAction.sessionExpired,
        description: 'OTP expiré — session invalidée',
      );

      AuthSession.logout();

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Code expiré. Veuillez vous reconnecter.'),
          ),
        );

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    // ⏳ Simulation vérification OTP
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isLoading = false);

    // ✅ Transition pending → loggedIn
    await AuthSession.loginFromPending();
    if (!mounted) return;

    AuditService.log(
      AuditAction.otpValidated,
      description: 'OTP validé, compte utilisateur activé',
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Compte activé avec succès')),
      );

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  /// ======================================================
  /// 🧱 UI
  /// ======================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ⛔ Blocage retour (remplace WillPopScope)
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code OTP',
                prefixIcon: Icon(Icons.lock_outline),
                counterText: '',
              ),
              validator: (v) =>
                  v == null || v.length != 6 ? 'Code invalide' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Code valide pendant $_formattedTime',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _remainingSeconds > 0 ? Colors.grey : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Valider le code'),
            ),
          ],
        ),
      ),
    );
  }
}
