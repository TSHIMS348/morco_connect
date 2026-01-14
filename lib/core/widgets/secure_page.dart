import 'package:flutter/material.dart';

class SecurePage extends StatelessWidget {
  final Widget child;

  const SecurePage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // ⛔ empêche le bouton retour
      child: child,
    );
  }
}
