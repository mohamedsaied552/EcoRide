import 'package:flutter/material.dart';

class MapUnavailableCard extends StatelessWidget {
  const MapUnavailableCard({
    super.key,
    required this.message,
    this.height,
  });

  final String message;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      color: const Color(0xFFEFF4F1),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map_outlined,
            size: 48,
            color: Color(0xFF1FAE6C),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );

    if (height == null) {
      return body;
    }

    return SizedBox(height: height, child: body);
  }
}
