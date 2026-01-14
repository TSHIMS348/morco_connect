import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_session.dart';
import 'package:morco_connect/features/audit/services/audit_service.dart';
import 'package:morco_connect/features/audit/models/audit_action.dart';

class OtpForm extends StatefulWidget {
  const OtpForm({super.key});

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  static const int _otpDuration = 120;
  Timer? _timer;
  int _remainingSeconds = _otpDuration;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

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

  Future<void> _submit() async {
    if (_isLoading) return;

    /// ⛔ OTP expiré → logout + audit + redirection forcée
    if (_remainingSeconds == 0) {
      AuditService.log(
        AuditAction.sessionExpired,
        description: 'OTP expiré — session invalidée',
      );

      AuthSession.logout();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
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

    // ✅ TRANSITION pending → loggedIn
    await AuthSession.loginFromPending();

    AuditService.log(
      AuditAction.otpValidated,
      description: 'OTP validé, compte utilisateur activé',
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Compte activé avec succès')),
      );

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  void _showError(String message) {
    AuditService.log(
      AuditAction.otpFailed,
      description: message,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // ⛔ blocage bouton retour
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
