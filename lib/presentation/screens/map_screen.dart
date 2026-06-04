import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:glider/core/events/app_event_bus.dart';
import 'package:glider/presentation/cubits/map_cubit.dart';
import 'package:glider/presentation/cubits/ride_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/presentation/widgets/app_user_drawer.dart';
import 'package:glider/presentation/widgets/loading_spinner.dart';

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

  LocationPermission? _cachedPermission;

  Future<bool> _ensureLocationPermission() async {
    if (_cachedPermission == LocationPermission.always ||
        _cachedPermission == LocationPermission.whileInUse) {
      return true;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _cachedPermission = permission;
      return true;
    }

    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      _cachedPermission = requested;
      return requested == LocationPermission.always ||
          requested == LocationPermission.whileInUse;
    }

    _cachedPermission = permission;
    return false;
  }

  Future<void> _goToMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) {
      if (_cachedPermission == LocationPermission.deniedForever && mounted) {
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
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && mounted) {
        final instantPosition = LatLng(
          lastPosition.latitude,
          lastPosition.longitude,
        );
        setState(() {
          _userPosition = instantPosition;
        });
        _mapController.move(instantPosition, 15.0);
      }

      unawaited(_fetchAndMoveToCurrentPosition());
    } catch (e) {
      debugPrint('Error fetching user location: $e');
    }
  }

  Future<void> _fetchAndMoveToCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;

      final currentPosition = LatLng(position.latitude, position.longitude);
      setState(() {
        _userPosition = currentPosition;
      });
      _mapController.move(currentPosition, _mapController.camera.zoom);
    } catch (e) {
      debugPrint('Error fetching fresh user location: $e');
    }
  }

  void _zoomIn() {
    // Access the current zoom and center through the 'camera' property
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom + 1.0).clamp(1.0, 18.0);

    _mapController.move(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom - 1.0).clamp(1.0, 18.0);

    _mapController.move(_mapController.camera.center, newZoom);
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _mapCubit.close();
    _mapController.dispose();
    super.dispose();
  }

  void _showScooterDetailsBottomSheet(BuildContext context, Scooter scooter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return _buildScooterDetailsSheet(context, scooter, _userPosition);
      },
    );
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
                          _showScooterDetailsBottomSheet(context, scooter);
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
                          alpha: 0.15,
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

              final Widget mapWidget = FlutterMap(
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
                          FloatingActionButton(
                            heroTag: 'zoom_in_btn',
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: _zoomIn,
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF1FAE6C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            heroTag: 'zoom_out_btn',
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: _zoomOut,
                            child: const Icon(
                              Icons.remove,
                              color: Color(0xFF1FAE6C),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                children: [
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

Widget _buildDetailRow({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String value,
}) {
  return Row(
    children: [
      Icon(icon, color: iconColor, size: 28),
      const SizedBox(width: 16),
      Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

Widget _buildScooterDetailsSheet(
  BuildContext context,
  Scooter scooter,
  LatLng? userPosition,
) {
  final double? distanceInMeters = userPosition != null
      ? const Distance().as(
          LengthUnit.Meter,
          userPosition,
          LatLng(scooter.lat, scooter.lng),
        )
      : null;
  final String distanceLabel = distanceInMeters != null
      ? (distanceInMeters >= 1000
            ? '${(distanceInMeters / 1000).toStringAsFixed(1)} km'
            : '${distanceInMeters.toStringAsFixed(0)} m')
      : 'Unknown';
  final double? feePerMinute = scooter.feePerMinute;
  final double? unlockFee = scooter.unlockFee;
  final String scooterModel = scooter.modelName ?? scooter.code;

  return Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scooter Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(scooterModel, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        _buildDetailRow(
          icon: Icons.battery_charging_full,
          iconColor: Colors.green,
          title: 'Battery',
          value: '${scooter.batteryPercent}%',
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          icon: Icons.location_on,
          iconColor: Colors.redAccent,
          title: 'Distance',
          value: distanceLabel,
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          icon: Icons.timer,
          iconColor: Colors.blue,
          title: 'Rate',
          value: feePerMinute != null
              ? '${feePerMinute.toStringAsFixed(2)} / min'
              : 'TBD',
        ),
        if (unlockFee != null) ...[
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.lock_open,
            iconColor: Colors.orange,
            title: 'Unlock Fee',
            value: unlockFee.toStringAsFixed(2),
          ),
        ],
      ],
    ),
  );
}

// ignore: unused_element
class _ScooterRow extends StatelessWidget {
  // ignore: unused_element_parameter
  const _ScooterRow({required this.scooter, this.userPosition});

  final Scooter scooter;
  final LatLng? userPosition;

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
              _showScooterDetailsBottomSheet(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _showScooterDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return _buildScooterDetailsSheet(context, scooter, userPosition);
      },
    );
  }
}
