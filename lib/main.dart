// File: lib/main.dart

import 'package:flutter/material.dart';
import 'pages/test_page.dart';
import 'pages/setup_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const SolarMonitorApp());
}

class SolarMonitorApp extends StatelessWidget {
  const SolarMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Monitor',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/setup': (context) => const SetupPage(),
        '/test': (context) => const TestPage(),
      },
    );
  }
}
