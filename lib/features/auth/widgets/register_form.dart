import 'package:flutter/material.dart';
import '../services/auth_session.dart';
import '../models/user_profile.dart';



class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    // ⏳ Simulation appel API backend
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 🟡 Création utilisateur en attente
    await AuthSession.setPendingUser(
  UserProfile(
    fullName: _nameController.text,
    phone: _phoneController.text,
    email: _emailController.text,
    matricule: _matriculeController.text,
  ),
);


    setState(() => _isLoading = false);

    // ➡️ Redirection vers page pending
    Navigator.of(context).pushReplacementNamed('/pending');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _matriculeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nom complet
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Champ requis' : null,
          ),

          const SizedBox(height: 16),

          // Téléphone
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.length < 6 ? 'Numéro invalide' : null,
          ),

          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Champ requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Matricule
          TextFormField(
            controller: _matriculeController,
            decoration: const InputDecoration(
              labelText: 'Matricule',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Champ requis' : null,
          ),

          const SizedBox(height: 16),

          // Mot de passe
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
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
          ),

          const SizedBox(height: 16),

          // Confirmation mot de passe
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Champ requis';
              if (v != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Bouton créer compte
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer le compte'),
          ),
        ],
      ),
    );
  }
}
