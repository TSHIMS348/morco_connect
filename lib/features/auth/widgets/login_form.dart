import 'package:flutter/material.dart';
import 'package:morco_connect/features/auth/services/auth_service.dart';
import 'package:morco_connect/features/auth/models/user_status.dart';
import 'package:morco_connect/features/audit/services/audit_service.dart';
import 'package:morco_connect/features/audit/models/audit_action.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final loginValue = _loginController.text.trim();

    final result = await _authService.login(
      login: loginValue,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!context.mounted) return;

    // ❌ ÉCHEC LOGIN
    if (!result.success) {
      AuditService.log(
        AuditAction.login,
        description:
            'Échec connexion utilisateur ($loginValue) : ${result.message}',
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      return;
    }

    // ✅ SUCCÈS — ROUTAGE UNIQUEMENT
    switch (result.status) {
      case UserStatus.active:
        AuditService.log(
          AuditAction.login,
          description: 'Connexion réussie (utilisateur actif)',
        );

        Navigator.of(context).pushReplacementNamed('/home');
        break;

      case UserStatus.pending:
        AuditService.log(
          AuditAction.login,
          description:
              'Connexion réussie (compte en attente de validation)',
        );

        Navigator.of(context).pushReplacementNamed('/pending');
        break;

      case UserStatus.blocked:
        AuditService.log(
          AuditAction.permissionDenied,
          description:
              'Tentative connexion compte bloqué ($loginValue)',
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content:
                  Text('Compte bloqué. Contactez un administrateur.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        break;
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginController,
            decoration: const InputDecoration(
              labelText: 'Matricule ou téléphone',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                v == null || v.length < 4
                    ? 'Mot de passe trop court'
                    : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
