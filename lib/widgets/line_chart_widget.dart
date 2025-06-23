import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PowerLineChart extends StatelessWidget {
  final List<FlSpot> data;

  const PowerLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No Data"));

    final minX = data.first.x;
    final maxX = data.last.x;
    final yValues = data.map((e) => e.y);
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 22),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.cyan,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              spots: data,
            )
          ],
        ),
      ),
    );
  }
}
