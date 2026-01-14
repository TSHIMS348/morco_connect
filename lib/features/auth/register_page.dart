import 'package:flutter/material.dart';
import 'widgets/register_form.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Text(
  'Demande de création de compte',
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
  ),
),
SizedBox(height: 8),
Text(
  'Soumettez votre demande d’accès à Morco Connect',
  textAlign: TextAlign.center,
  style: TextStyle(color: Colors.grey),
),

                  SizedBox(height: 32),

                  RegisterForm(),

                  SizedBox(height: 16),

                  Text(
                    'Votre demande sera validée par un administrateur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
