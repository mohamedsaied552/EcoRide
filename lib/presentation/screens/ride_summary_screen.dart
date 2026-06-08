import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:glider/domain/entities/ride.dart';

class RideSummaryScreen extends StatelessWidget {
  const RideSummaryScreen({
    super.key,
    required this.ride,
    required this.route,
    this.remainingBalance,
  });

  final Ride ride;
  final List<dynamic> route;
  final double? remainingBalance;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  LatLng _toMapLatLng(dynamic position) {
    return LatLng(position.latitude as double, position.longitude as double);
  }

  bool _isValidLatLng(LatLng position) {
    return position.latitude.abs() <= 90 &&
        position.longitude.abs() <= 180 &&
        !(position.latitude == 0 && position.longitude == 0);
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = route
        .map(_toMapLatLng)
        .where(_isValidLatLng)
        .toList(growable: false);
    final centerPosition = routePoints.isNotEmpty
        ? routePoints.first
        : LatLng(30.0444, 31.2357);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Summary')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: routePoints.isEmpty
                    ? const Center(child: Text('No route data'))
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: centerPosition,
                          initialZoom: 16,
                          initialCameraFit: routePoints.length > 1
                              ? CameraFit.coordinates(
                                  coordinates: routePoints,
                                  padding: const EdgeInsets.all(28),
                                  maxZoom: 17,
                                )
                              : null,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.glider',
                          ),
                          if (routePoints.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routePoints,
                                  color: const Color(0xFF1FAE6C),
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: routePoints.first,
                                width: 34,
                                height: 34,
                                child: const Icon(
                                  Icons.trip_origin,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              if (routePoints.length > 1)
                                Marker(
                                  point: routePoints.last,
                                  width: 38,
                                  height: 38,
                                  child: const Icon(
                                    Icons.flag,
                                    color: Color(0xFF1FAE6C),
                                    size: 32,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your ride is complete',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Scooter'),
                        Text(
                          ride.scooterCode,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Time'),
                        Text(
                          _formatDuration(ride.duration),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Distance'),
                        Text(
                          '${ride.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cost'),
                        Text(
                          '${ride.cost.toStringAsFixed(1)} EGP',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (remainingBalance != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Wallet after ride'),
                          Text(
                            '${remainingBalance!.toStringAsFixed(1)} EGP',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/map',
                    (route) => false,
                  );
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
