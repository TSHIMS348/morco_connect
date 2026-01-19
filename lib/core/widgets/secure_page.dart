import 'package:flutter/material.dart';

/// ======================================================
/// 🔒 SecurePage
/// - Empêche toute navigation arrière
/// - Conforme Flutter moderne (PopScope)
/// ======================================================
class SecurePage extends StatelessWidget {
  final Widget child;

  const SecurePage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ⛔ blocage total du bouton retour
      child: child,
    );
  }
}
