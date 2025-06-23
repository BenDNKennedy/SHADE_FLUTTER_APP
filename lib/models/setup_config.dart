// File: lib/models/setup_config.dart

class SetupConfig {
  final double roofArea;
  final double panelEfficiency;
  final double panelWattage;
  final bool mpptEnabled;

  static const double defaultPanelArea = 1.7; // m² per panel
  static const double defaultPackingFactor = 0.85;

  SetupConfig({
    required this.roofArea,
    required this.panelEfficiency,
    required this.panelWattage,
    required this.mpptEnabled,
  });

  int get panelCount =>
      ((roofArea * defaultPackingFactor) / defaultPanelArea).floor();

  double get projectedPowerWatts {
    final mpptFactor = mpptEnabled ? 1.05 : 1.0;
    return panelCount * panelWattage * panelEfficiency * mpptFactor;
  }

  Map<String, dynamic> toJson() => {
    'roofArea': roofArea,
    'panelEfficiency': panelEfficiency,
    'panelWattage': panelWattage,
    'mpptEnabled': mpptEnabled,
  };

  factory SetupConfig.fromJson(Map<String, dynamic> json) => SetupConfig(
    roofArea: (json['roofArea'] ?? 0).toDouble(),
    panelEfficiency: (json['panelEfficiency'] ?? 0.2).toDouble(),
    panelWattage: (json['panelWattage'] ?? 370).toDouble(),
    mpptEnabled: json['mpptEnabled'] ?? false,
  );

  factory SetupConfig.empty() => SetupConfig(
    roofArea: 30.0,
    panelEfficiency: 0.2,
    panelWattage: 370.0,
    mpptEnabled: false,
  );
}
