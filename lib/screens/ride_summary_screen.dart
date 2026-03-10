import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ride.dart';

class RideSummaryScreen extends StatelessWidget {
  const RideSummaryScreen({
    super.key,
    required this.ride,
    required this.route,
    this.remainingBalance,
  });

  final Ride ride;
  final List<LatLng> route;
  final double? remainingBalance;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final polyline = Polyline(
      polylineId: const PolylineId('summary_route'),
      color: const Color(0xFF1FAE6C),
      width: 4,
      points: route,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Summary")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: route.isEmpty
                    ? const Center(child: Text('No route data'))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: route.first,
                          zoom: 15,
                        ),
                        polylines: {polyline},
                        markers: {
                          if (route.isNotEmpty)
                            Marker(
                              markerId: const MarkerId('start'),
                              position: route.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ),
                            ),
                          if (route.length > 1)
                            Marker(
                              markerId: const MarkerId('end'),
                              position: route.last,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        liteModeEnabled: true,
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
                      "Your ride is complete",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Scooter"),
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
                        const Text("Time"),
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
                        const Text("Distance"),
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
                        const Text("Cost"),
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
                          const Text("Wallet after ride"),
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
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
