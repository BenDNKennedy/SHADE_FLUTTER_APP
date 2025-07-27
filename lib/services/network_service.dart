// File: lib/services/network_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:solar_monitor/services/db_service.dart';
import 'package:solar_monitor/models/solar_data.dart';

const Duration kInsertInterval = Duration(minutes: 5); // or make configurable


class NetworkService {
  static final Duration kInsertInterval = Duration(minutes: 5);
  DateTime? _lastInsert;

  Future<Map<String, dynamic>?> fetchSolarData() async {
    try {
      final url = Uri.parse('http://${AppConstants.espIp}/solar');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // return json.decode(response.body) as Map<String, dynamic>;

        final jsonMap = json.decode(response.body) as Map<String, dynamic>;


        final solarIndex = (jsonMap['solar_index'] as num).toDouble();
        final now = DateTime.now();

        // Insert to DB if enough time has passed
        if (_lastInsert == null || now.difference(_lastInsert!) >= kInsertInterval) {
          final data = SolarData(timestamp: now.millisecondsSinceEpoch, solarIndex: solarIndex);
          await DBService.instance.insertSolarData(data);
          _lastInsert = now;
        }

        return jsonMap;
      } else {
        return null;
      }

    } catch (e) {
      return null;
    }
  }
}
