import 'package:flutter/material.dart';
import 'widgets/otp_form.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation du compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Icon(Icons.verified_user, size: 64, color: Colors.green),
                  SizedBox(height: 16),

                  Text(
                    'Code de validation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Un code de validation vous a été envoyé.\n'
                    'Veuillez le saisir pour activer votre compte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: 32),

                  OtpForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
