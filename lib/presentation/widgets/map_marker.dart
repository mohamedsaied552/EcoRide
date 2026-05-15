import 'package:flutter/material.dart';

class ScooterStatusChip extends StatelessWidget {
  const ScooterStatusChip({
    super.key,
    required this.batteryPercent,
    required this.available,
  });

  final int batteryPercent;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_full, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$batteryPercent%',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
