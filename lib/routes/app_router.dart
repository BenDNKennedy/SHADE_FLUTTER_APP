// File: lib/routes/app_router.dart

import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/setup_page.dart';
import '../pages/test_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/setup':
        return MaterialPageRoute(builder: (_) => const SetupPage());
      case '/test':
        return MaterialPageRoute(builder: (_) => const TestPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(child: Text('404 - Page not found')),
          ),
        );
    }
  }
}
