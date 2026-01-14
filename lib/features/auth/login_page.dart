import 'package:flutter/material.dart';
import 'widgets/login_form.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / titre
                      Column(
                        children: const [
                          Icon(Icons.lock_outline, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Morco Connect',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Connexion sécurisée',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const LoginForm(),

                      const SizedBox(height: 12),

                      TextButton(
  onPressed: () {
    Navigator.of(context).pushNamed('/register');

  },
  child: const Text('Première connexion ? Créer un compte'),
),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
