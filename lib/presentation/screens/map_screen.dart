// ignore: unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

// --- Google Maps imports (kept for reference, replaced by OpenStreetMap) ---
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// --------------------------------------------------------------------------
import 'package:get_it/get_it.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:glider/config/app_config.dart';
import 'package:glider/core/events/app_event_bus.dart';
import 'package:glider/presentation/cubits/map_cubit.dart';
import 'package:glider/presentation/cubits/ride_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/presentation/widgets/app_user_drawer.dart';
import 'package:glider/presentation/widgets/loading_spinner.dart';
// ignore: unused_import
import 'package:glider/presentation/widgets/map_unavailable_card.dart';
import 'package:geolocator/geolocator.dart';
import 'qr_scan_screen.dart';
import 'wallet_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static final LatLng _center = LatLng(30.0444, 31.2357);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapCubit _mapCubit;
  late final StreamSubscription<MapRefreshRequestedEvent> _eventSubscription;
  final MapController _mapController = MapController();

  // 1. متغير لحفظ موقع المستخدم الحالي ورسم الدائرة الزرقاء بناءً عليه
  LatLng? _userPosition;

  @override
  void initState() {
    super.initState();
    _mapCubit = MapCubit()..load();

    final eventBus = GetIt.I<AppEventBus>();
    _eventSubscription = eventBus.on<MapRefreshRequestedEvent>().listen((_) {
      debugPrint('Map screen received a global refresh_map event.');
      _mapCubit.refreshLiveMap();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToMyLocation();
    });
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable GPS.'),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Enable it from settings.',
            ),
          ),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          // 2. حفظ الموقع في المتغير لتحديث الشاشة ورسم الدائرة الزرقاء
          _userPosition = LatLng(position.latitude, position.longitude);
        });

        _mapController.move(_userPosition!, 15.0);
      }
    } catch (e) {
      debugPrint('Error fetching user location: $e');
    }
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _mapCubit.close();
    _mapController.dispose();
    super.dispose();
  }

  Color _zoneFillColor(String type) {
    switch (type.toLowerCase()) {
      case 'noride':
      case 'no-ride':
      case 'restricted':
        return Colors.red.withValues(alpha: 0.18);
      case 'slow':
      case 'slowzone':
        return Colors.orange.withValues(alpha: 0.18);
      case 'noparking':
      case 'no-parking':
        return const Color.fromARGB(255, 244, 67, 54).withValues(alpha: 0.15);
      default:
        return const Color(0xFF1FAE6C).withValues(alpha: 0.12);
    }
  }

  Color _zoneBorderColor(String type) {
    switch (type.toLowerCase()) {
      case 'noride':
      case 'no-ride':
      case 'restricted':
        return Colors.red;
      case 'slow':
      case 'slowzone':
        return Colors.orange;
      case 'noparking':
      case 'no-parking':
        return Colors.red;
      default:
        return const Color(0xFF1FAE6C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _mapCubit,
      child: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          return BlocBuilder<MapCubit, MapState>(
            builder: (context, mapState) {
              final scooters = mapState.scooters;
              final availableScooters = scooters
                  .where(
                    (scooter) => scooter.isAvailable && scooter.hasCoordinates,
                  )
                  .toList(growable: false);

              final List<Polygon> zonePolygons = mapState.zones
                  .where((zone) => zone.boundary.length >= 3)
                  .map(
                    (zone) => Polygon(
                      points: zone.boundary
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(growable: false),
                      color: _zoneFillColor(zone.type),
                      borderColor: _zoneBorderColor(zone.type),
                      borderStrokeWidth: 2,
                    ),
                  )
                  .toList(growable: false);

              // بناء الماركرز للسكوترز المتاحة
              final List<Marker> osmMarkers = availableScooters
                  .map(
                    (scooter) => Marker(
                      point: LatLng(scooter.lat, scooter.lng),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          final priceLabel =
                              scooter.unlockFee != null &&
                                  scooter.feePerMinute != null
                              ? ' • Unlock ${scooter.unlockFee!.toStringAsFixed(2)} + ${scooter.feePerMinute!.toStringAsFixed(2)}/min'
                              : '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${scooter.code} • Battery: ${scooter.batteryPercent}%$priceLabel',
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.location_on,
                          size: 40.0,
                          color: Color(0xFF1FAE6C),
                        ),
                      ),
                    ),
                  )
                  .toList(); // شيلنا الـ growable: false عشان هنضيف عليه ماركر المستخدم

              // 3. إضافة الدائرة الزرقاء (موقع المستخدم الحالي) إلى قائمة الماركرز لو كان موجوداً
              if (_userPosition != null) {
                osmMarkers.add(
                  Marker(
                    point: _userPosition!,
                    width: 25,
                    height: 25,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(
                          alpha: 0.25,
                        ), // الدائرة الشفافة الخارجية
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color:
                                Colors.blue, // النقطة الزرقاء المصمتة في السنتر
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final LatLng centerPosition = availableScooters.isNotEmpty
                  ? LatLng(
                      availableScooters.first.lat,
                      availableScooters.first.lng,
                    )
                  : MapScreen._center;

              final Widget mapWidget;
              // ignore: unused_local_variable
              final bool hasGoogleMapsApiKey = AppConfig.hasGoogleMapsApiKey;

              mapWidget = FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _userPosition ??
                      centerPosition, // لو موقع المستخدم جاهز نفتح عليه فوراً
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.glider',
                  ),
                  if (zonePolygons.isNotEmpty)
                    PolygonLayer(polygons: zonePolygons),
                  MarkerLayer(markers: osmMarkers),
                ],
              );

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Nearby Scooters'),
                  actions: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WalletScreen(),
                          ),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // The "My location" button sits directly above the
                          // bottom panel, so it tracks the panel's actual
                          // height (which changes with 0-3 scooter rows /
                          // failure / empty states) instead of using a fixed
                          // pixel offset that would overlap the panel.
                          FloatingActionButton(
                            heroTag: 'my_location_btn',
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: _goToMyLocation,
                            child: const Icon(
                              Icons.my_location,
                              color: Color(0xFF1FAE6C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
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
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    )
                                  else
                                    ...availableScooters
                                        .take(3)
                                        .map(
                                          (scooter) =>
                                              _ScooterRow(scooter: scooter),
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
                                            builder: (_) =>
                                                const QRScanScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
            child: const Icon(Icons.electric_scooter, color: Color(0xFF1FAE6C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scooter.code,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Battery: ${scooter.batteryPercent}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Handle scooter selection
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
