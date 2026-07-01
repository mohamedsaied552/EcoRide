import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:zakzouka/config/app_config.dart';
import 'package:zakzouka/core/location/location_accuracy_validator.dart';
import 'package:zakzouka/data/services/ride_service.dart';
import 'package:zakzouka/l10n/app_localizations.dart';
import 'package:zakzouka/presentation/widgets/map_unavailable_card.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final RideService _rideService = RideService();
  final UniqueKey _googleMapKey = UniqueKey();
  GoogleMapController? _mapController;
  StreamSubscription<RideSessionState>? _sub;
  RideSessionState? _state;
  LatLng? _liveUserPosition;

  @override
  void initState() {
    super.initState();
    _state = _rideService.latestState;
    _resolveInitialLocation();
    _sub = _rideService.stateStream.listen((event) {
      if (!mounted) return;
      setState(() => _state = event);
      if (_mapController != null && _isValidLatLng(event.scooterPosition)) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(event.scooterPosition),
        );
      }
      final l10n = AppLocalizations.of(context);
      if (event.lowBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.walletBalanceLow)),
        );
      } else if (event.outsideGeofence) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.outsideOperatingZone)),
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

  bool _isValidLatLng(LatLng position) {
    return position.latitude.abs() <= 90 &&
        position.longitude.abs() <= 180 &&
        !(position.latitude == 0 && position.longitude == 0);
  }

  Future<void> _resolveInitialLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      LocationAccuracyValidator.validate(position);
      if (!mounted) return;
      setState(() {
        _liveUserPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (error) {
      debugPrint('Active ride initial location failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    final scooterMarkerPosition = _isValidLatLng(state.scooterPosition)
        ? state.scooterPosition
        : null;
    final userMarkerPosition = _isValidLatLng(state.userPosition)
        ? state.userPosition
        : null;
    final LatLng centerPosition =
        _liveUserPosition ??
        scooterMarkerPosition ??
        userMarkerPosition ??
        const LatLng(30.0444, 31.2357);

    final markers = <Marker>{};
    if (scooterMarkerPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('scooter'),
          position: scooterMarkerPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (userMarkerPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userMarkerPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activeRide)),
      body: Stack(
        children: [
          AppConfig.hasGoogleMapsApiKey
              ? GoogleMap(
                  key: _googleMapKey,
                  initialCameraPosition: CameraPosition(
                    target: centerPosition,
                    zoom: 16,
                  ),
                  polylines: {polyline},
                  markers: markers,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                )
              : MapUnavailableCard(message: l10n.mapUnavailable),
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
                            Text(
                              l10n.rideTime,
                              style: const TextStyle(color: Colors.grey),
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
                            Text(
                              l10n.cost,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.costEgp(state.cost.toStringAsFixed(1)),
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
                            Text(
                              l10n.distanceKm(
                                state.distanceKm.toStringAsFixed(2),
                              ),
                            ),
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
                            Text(
                              l10n.percentSuffix('${state.batteryPercent}'),
                            ),
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
                          try {
                            final currentPosition =
                                await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.medium,
                                  ),
                                );
                            final finishedRide = await _rideService.endRide(
                              userLatitude: currentPosition.latitude,
                              userLongitude: currentPosition.longitude,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context, finishedRide);
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.errorEndingRide('$error'),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(l10n.endRide),
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
