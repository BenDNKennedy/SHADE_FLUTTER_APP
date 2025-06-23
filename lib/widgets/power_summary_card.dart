// File: lib/widgets/power_summary_card.dart

import 'package:flutter/material.dart';

class PowerSummaryCard extends StatelessWidget {
  final double solarPercentage;
  final double computedWatts;
  final String status;

  const PowerSummaryCard({
    super.key,
    required this.solarPercentage,
    required this.computedWatts,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Solar Input: ${solarPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Output: ${computedWatts.toStringAsFixed(2)} W',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}
