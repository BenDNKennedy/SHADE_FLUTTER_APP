// File: lib/services/prefs_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/setup_config.dart';

class PrefsService {
  static const _roofAreaKey = 'roof_area';
  static const _efficiencyKey = 'efficiency';
  static const _wattageKey = 'wattage';
  static const _mpptKey = 'mppt_enabled';

  Future<void> saveConfig(SetupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_roofAreaKey, config.roofArea);
    await prefs.setDouble(_efficiencyKey, config.panelEfficiency);
    await prefs.setDouble(_wattageKey, config.panelWattage);
    await prefs.setBool(_mpptKey, config.mpptEnabled);
  }

  Future<void> saveEspIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('espIp', ip);
  }

  Future<String?> loadEspIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('espIp');
  }


  Future<SetupConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final roofArea = prefs.getDouble(_roofAreaKey) ?? 0.0;
    final efficiency = prefs.getDouble(_efficiencyKey) ?? 0.2;
    final wattage = prefs.getDouble(_wattageKey) ?? 370.0;
    final mppt = prefs.getBool(_mpptKey) ?? false;

    return SetupConfig(
      roofArea: roofArea,
      panelEfficiency: efficiency,
      panelWattage: wattage,
      mpptEnabled: mppt,
    );
  }
}
