import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/ride_service.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final RideService _rideService = RideService();
  GoogleMapController? _mapController;
  StreamSubscription<RideSessionState>? _sub;
  RideSessionState? _state;

  @override
  void initState() {
    super.initState();
    _state = _rideService.latestState;
    _sub = _rideService.stateStream.listen((event) {
      setState(() => _state = event);
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(event.scooterPosition),
        );
      }
      if (!mounted) return;
      if (event.lowBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet balance is low. Ending ride for safety.'),
          ),
        );
      } else if (event.outsideGeofence) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outside operating zone. Please return to the zone.'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final polyline = Polyline(
      polylineId: const PolylineId('ride'),
      color: const Color(0xFF1FAE6C),
      width: 4,
      points: state.route,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Active Ride')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: state.scooterPosition,
              zoom: 16,
            ),
            polylines: {polyline},
            markers: {
              Marker(
                markerId: const MarkerId('scooter'),
                position: state.scooterPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
              Marker(
                markerId: const MarkerId('user'),
                position: state.userPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            },
            myLocationButtonEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ride time',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDuration(state.duration),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Cost',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.cost.toStringAsFixed(1)} EGP',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.route, size: 18),
                            const SizedBox(width: 6),
                            Text('${state.distanceKm.toStringAsFixed(2)} km'),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.battery_full,
                              size: 18,
                              color: state.batteryPercent < 15
                                  ? Colors.red
                                  : const Color(0xFF1FAE6C),
                            ),
                            const SizedBox(width: 6),
                            Text('${state.batteryPercent}%'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final finishedRide = await _rideService.endRide();
                          if (!context.mounted) return;
                          Navigator.pop(context, finishedRide);
                        },
                        child: const Text('End ride'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
