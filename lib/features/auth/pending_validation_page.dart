import 'package:flutter/material.dart';

class PendingValidationPage extends StatelessWidget {
  const PendingValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 72,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Demande envoyée',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Votre demande de création de compte a bien été enregistrée.\n\n'
                    'Elle est actuellement en attente de validation par un administrateur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 12),

OutlinedButton.icon(
  onPressed: () {
    Navigator.of(context).pushNamed('/otp');
  },
  icon: const Icon(Icons.verified),
  label: const Text('J’ai reçu un code (OTP)'),
),


                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Retour à la connexion'),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Si le délai est anormalement long,\nveuillez contacter votre responsable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
