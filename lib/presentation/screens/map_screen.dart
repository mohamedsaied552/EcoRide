import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:glider/config/app_config.dart';
import 'package:glider/presentation/cubits/map_cubit.dart';
import 'package:glider/presentation/cubits/ride_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/presentation/widgets/app_user_drawer.dart';
import 'package:glider/presentation/widgets/loading_spinner.dart';
import 'package:glider/presentation/widgets/map_marker.dart';
import 'package:glider/presentation/widgets/map_unavailable_card.dart';
import 'qr_scan_screen.dart';
import 'wallet_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const LatLng _center = LatLng(30.0444, 31.2357);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapCubit()..load(),
      child: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          return BlocBuilder<MapCubit, MapState>(
            builder: (context, mapState) {
              final scooters = mapState.scooters;
              final availableScooters = scooters
                  .where((scooter) => scooter.isAvailable)
                  .toList(growable: false);

              final markers = scooters
                  .where((scooter) => scooter.isAvailable)
                  .map(
                    (scooter) => Marker(
                      markerId: MarkerId(scooter.id),
                      position: LatLng(scooter.lat, scooter.lng),
                      infoWindow: InfoWindow(title: scooter.code),
                    ),
                  )
                  .toSet();

              final Widget mapWidget;
              if (kIsWeb) {
                mapWidget = const MapUnavailableCard(
                  message: 'Map preview is not available on Web.',
                );
              } else if (AppConfig.hasGoogleMapsApiKey) {
                mapWidget = GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _center,
                    zoom: 14.0,
                  ),
                  markers: markers,
                  myLocationButtonEnabled: false,
                );
              } else {
                mapWidget = const MapUnavailableCard(
                  message:
                      'Map is temporarily unavailable because the Google Maps API key is not configured yet.',
                );
              }

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Nearby Scooters'),
                  actions: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ],
                ),
                drawer: userState.user != null
                    ? AppUserDrawer(user: userState.user!)
                    : null,
                body: Stack(
                  children: [
                    mapWidget,
                    if (mapState.status == MapStatus.loading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0xAAFFFFFF),
                          child: LoadingSpinner(
                            message: 'Finding nearby scooters...',
                          ),
                        ),
                      ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Available scooters',
                                      style:
                                          Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.read<MapCubit>().load(),
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (mapState.status == MapStatus.failure)
                                Text(
                                  mapState.errorMessage ??
                                      'Unable to load scooters.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.red),
                                )
                              else if (availableScooters.isEmpty &&
                                  mapState.status != MapStatus.loading)
                                Text(
                                  'No scooters nearby. Try a different area.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                ...availableScooters.take(3).map(
                                      (scooter) => _ScooterRow(scooter: scooter),
                                    ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.qr_code),
                                  label: const Text('Scan to unlock'),
                                  onPressed: () {
                                    context.read<RideCubit>().reset();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const QRScanScreen(),
                                      ),
                                    );
                                  },
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
            },
          );
        },
      ),
    );
  }
}

class _ScooterRow extends StatelessWidget {
  const _ScooterRow({required this.scooter});

  final Scooter scooter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1FAE6C).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.electric_scooter,
              color: Color(0xFF1FAE6C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scooter.code,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  scooter.locationName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ScooterStatusChip(
            batteryPercent: scooter.batteryPercent,
            available: scooter.isAvailable,
          ),
        ],
      ),
    );
  }
}
