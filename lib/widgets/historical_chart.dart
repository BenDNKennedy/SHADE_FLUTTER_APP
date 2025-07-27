//  # ✅ New graph widget for historical view

// File: lib/widgets/historical_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/solar_data.dart';
import '../enums/time_range.dart';
import 'package:intl/intl.dart';
import '../models/averaged_data.dart';


List<SolarData> downsample(List<SolarData> input, int maxPoints) {
  if (input.length <= maxPoints) return input;

  final step = input.length ~/ maxPoints;
  return List.generate(maxPoints, (i) => input[i * step]);
}


class HistoricalChart extends StatelessWidget {
  final List<AveragedData> data;
  final TimeRange range;

  const HistoricalChart({
    Key? key,
    required this.data,
    required this.range,
  }) : super(key: key);

  String formatLabel(int x) {
    switch (range) {
      case TimeRange.daily: return '$x:00';             // 0–23h
      case TimeRange.weekly: return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][x - 1];
      case TimeRange.monthly: return 'Week ${x + 1}';
      case TimeRange.yearly: return ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][x - 1];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data available'));

    final spots = data.map((e) => FlSpot(e.x.toDouble(), e.solarIndex)).toList();

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) =>
                  Text(formatLabel(value.toInt()), style: const TextStyle(fontSize: 10)),
              interval: 1,
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) =>
                  Text('${(value * 100).toInt()}%'),
              reservedSize: 40,
            ),
          ),
        ),
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            color: Colors.orangeAccent,
            barWidth: 2,
          ),
        ],
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}