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
import 'network_page.dart'; // ← ✅ Must be present
import 'package:fl_chart/fl_chart.dart';
import '../widgets/line_chart_widget.dart';
import '../enums/time_range.dart';
import '../models/solar_data.dart';
import '../services/db_service.dart';
import '../widgets/historical_chart.dart';
import '../models/averaged_data.dart';
import 'package:shared_preferences/shared_preferences.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<AveragedData>> averagedDataFuture;
  double? solarIndex;
  double? projectedPower;
  double maxSystemPower = 0;
  bool isConnected = false;
  bool hasData = false;
  Timer? _timer;
  final List<FlSpot> powerHistory = [];
  int timeStep = 0;
  double totalEnergyWh = 0.0;

  TimeRange selectedRange = TimeRange.daily;
  List<SolarData> historicalData = [];


  Future<void> fetchData() async {
    try {
      // final uri = Uri.parse('http://${AppConstants.espIp}/solar');
      final ip = await PrefsService.instance.loadEspIp() ?? '172.20.10.6';
      final uri = Uri.parse('http://$ip/solar');
      print("🌐 Trying ESP at $ip");
      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      isConnected = response.statusCode == 200;

      if (isConnected) {
        final data = json.decode(response.body);
        print('Received: $data');


        if (data['solar_index'] != null) {
          solarIndex = (data['solar_index'] as num).toDouble();

          final config = await PrefsService.instance.loadConfig();
          print('Loaded config: ${config.toJson()}');
          print('Base power: ${config.projectedPowerWatts}');

          maxSystemPower = config.projectedPowerWatts;
          projectedPower = config.projectedPowerWatts * solarIndex!;
          hasData = true;

          if (projectedPower != null) {
            final addedWh = projectedPower! * (5.0 / 3600.0);
            totalEnergyWh += addedWh;
            print('⏱️ Added ${projectedPower! * (5.0 / 3600.0)} Wh, total: $totalEnergyWh');
          }

          powerHistory.add(FlSpot(timeStep.toDouble(), projectedPower ?? 0));
          if (powerHistory.length > 30) {
            powerHistory.removeAt(0);
          }
          timeStep++;
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

  Future<void> saveEspIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('espIp', ip);
    print("💾 Saved new ESP IP: $ip");  // ✅ debug
  }


  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchData());
    averagedDataFuture = DBService().getPrecomputedData(selectedRange);
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Live'),
            Tab(text: 'History'),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSetupPage,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchData,
            ),
            IconButton(
              icon: const Icon(Icons.wifi_tethering),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NetworkPage()),
                );
                await fetchData();
              },
            ),
          ], // your existing buttons
        ),
        body: TabBarView(
          children: [
            // Tab 1: Live view (unchanged)
            Center(
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
                  const SizedBox(height: 20),
                  Text('💰 Money Saved: \$${(totalEnergyWh / 1000 * 0.12).toStringAsFixed(4)}'),       // 0.12 is the bc hydro price per kwh
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PowerLineChart(
                      data: powerHistory,
                      maxSystemPower: maxSystemPower,
                    ),
                  )
                ],
              ),
            ),

            // Tab 2: Historical graph view
            Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: TimeRange.values.map((range) {
                    return ChoiceChip(
                      label: Text(range.label),
                      selected: selectedRange == range,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedRange = range;
                            averagedDataFuture = DBService().getPrecomputedData(range);
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder(
                    future: averagedDataFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data!;
                      final totalSaved = data.fold(0.0, (sum, d) => sum + (d.moneySaved ?? 0));

                      return Column(
                        children: [
                          Text(
                            '💰 Money Saved: \$${totalSaved.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Expanded(child: HistoricalChart(data: data, range: selectedRange)),
                        ],
                      );
                    },
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );

    // old code
    /*
      Scaffold(
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
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NetworkPage()),
              );
            },
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
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PowerLineChart(
                data: powerHistory,
                maxSystemPower: maxSystemPower,
              ),
            )
          ],
        ),
      ),
    );

     */
  }
}
