// # ✅ Data class for each row: timestamp, solar_index, etc.

// File: lib/models/solar_data.dart

class SolarData {
  final int timestamp;       // milliseconds since epoch
  final double solarIndex;   // 0.0 – 1.0 normalized

  SolarData({
    required this.timestamp,
    required this.solarIndex,
  });

  // For SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'solar_index': solarIndex,
    };
  }

  // For SQLite query result
  factory SolarData.fromMap(Map<String, dynamic> map) {
    return SolarData(
      timestamp: map['timestamp'] as int,
      solarIndex: (map['solar_index'] as num).toDouble(),
    );
  }
}
