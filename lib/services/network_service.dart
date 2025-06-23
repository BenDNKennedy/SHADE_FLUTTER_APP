// File: lib/services/network_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NetworkService {
  Future<Map<String, dynamic>?> fetchSolarData() async {
    try {
      final url = Uri.parse('http://${AppConstants.espIp}/solar');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
