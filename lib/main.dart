// File: lib/main.dart

import 'package:flutter/material.dart';
import 'pages/test_page.dart';
import 'pages/setup_page.dart';
import 'pages/home_page.dart';
import 'services/db_service.dart'; // ← Add this


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed historical DB with dummy data
  final db = DBService.instance;
  final existing = await db.getDataBetween(
    DateTime.now().subtract(const Duration(days: 365)),
    DateTime.now(),
  );

  if (existing.isEmpty) {
    print("⏳ No historical data found. Seeding now...");
    await db.insertDummyYearlyData();
    print("✅ Seeding complete.");
  } else {
    print("📊 Historical data already exists: ${existing.length} entries.");
  }


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
