// File: lib/utils/constants.dart
import '../../services/prefs_service.dart';

class AppConstants {
  static const defaultPanelArea = 1.7; // in m²
  static const defaultPackingFactor = 0.85;
  static const defaultEfficiency = 0.20;
  static const defaultPanelWattage = 370.0;
  static const defaultMpptBoost = 1.05;

  // static const espIp = '192.168.1.144'; // Default for testing

  static const panelOptions = [
    300.0,
    370.0,
    450.0,
  ];

  static Future<String> get espIp async {
    final ip = await PrefsService.instance.loadEspIp();
    return ip ?? '172.20.10.6'; // fallback default
  }


}
