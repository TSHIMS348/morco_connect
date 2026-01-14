import 'package:flutter/material.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/pending_validation_page.dart';
import '../features/home/home_page.dart';
import '../features/auth/otp/otp_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (_) => const LoginPage(),
    '/register': (_) => const RegisterPage(),
    '/pending': (_) => const PendingValidationPage(),
    '/home': (_) => const HomePage(),
    '/otp': (_) => const OtpPage(),

  };
}
