// File: lib/pages/home_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solar_monitor/utils/constants.dart';
import '../models/setup_config.dart';
import '../services/prefs_service.dart';
import '../services/network_service.dart';
import 'setup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? solarIndex;
  double? projectedPower;
  bool isConnected = false;
  bool hasData = false;
  Timer? _timer;

  Future<void> fetchData() async {
    try {
      final uri = Uri.parse('http://${AppConstants.espIp}/solar');
      final response = await http.get(uri);

      isConnected = response.statusCode == 200;

      if (isConnected) {
        final data = json.decode(response.body);
        print('Received: $data');

        if (data['solar_index'] != null) {
          solarIndex = (data['solar_index'] as num).toDouble();

          final config = await PrefsService().loadConfig();
          print('Loaded config: ${config.toJson()}');
          print('Base power: ${config.projectedPowerWatts}');

          projectedPower = config.projectedPowerWatts * solarIndex!;
          hasData = true;
        } else {
          hasData = false;
        }
      } else {
        hasData = false;
      }
    } catch (e) {
      isConnected = false;
      hasData = false;
      print('Error: $e');
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openSetupPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetupPage()),
    );
    fetchData(); // Refresh config on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSetupPage,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: Center(
        child: !isConnected
            ? const Text('❌ Disconnected from ESP')
            : !hasData
            ? const Text('⚠️ Connected, but no data')
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('☀️ Solar Index: ${solarIndex?.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Text('⚡ Projected Power: ${projectedPower?.toStringAsFixed(2)} W'),
          ],
        ),
      ),
    );
  }
}
