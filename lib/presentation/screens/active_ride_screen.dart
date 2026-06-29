import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:glider/data/repositories/backend_service.dart';
import 'package:glider/data/services/ride_service.dart';
import 'package:glider/domain/entities/map_zone.dart';
import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/ride_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/presentation/cubits/wallet_cubit.dart';
import 'package:glider/presentation/screens/ride_summary_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({
    super.key,
    required this.scooterCode,
    this.ratePerMinute = RideService.pricePerMinute,
  });

  final String scooterCode;
  final double ratePerMinute;

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  static final LatLng _fallbackCenter = LatLng(30.0444, 31.2357);

  final RideService _rideService = RideService();
  final BackendService _backendService = BackendService();
  final MapController _mapController = MapController();

  StreamSubscription<RideSessionState>? _rideSubscription;
  StreamSubscription<Position>? _positionSubscription;
  RideSessionState? _rideState;
  List<MapZone> _zones = const [];
  LatLng? _userPosition;
  LatLng? _scooterPosition;
  double _heading = 0;
  bool _isEndingRide = false;
  LocationPermission? _cachedPermission;

  @override
  void initState() {
    super.initState();
    _rideState = _rideService.latestState;
    _syncFromRideState(_rideState, notify: false);

    _rideSubscription = _rideService.stateStream.listen((state) {
      if (!mounted) return;
      _syncFromRideState(state);
      _followRideCamera();
      _showRideAlerts(state);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followRideCamera();
      _startLocationTracking();
      _loadOperationalZones();
    });
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _syncFromRideState(RideSessionState? state, {bool notify = true}) {
    if (state == null) return;

    final scooterPosition = _toMapLatLng(state.scooterPosition);
    final userPositionFromRide = _toMapLatLng(state.userPosition);

    if (notify) {
      setState(() {
        _rideState = state;
        _scooterPosition = scooterPosition;
        _userPosition ??= userPositionFromRide;
      });
    } else {
      _scooterPosition = scooterPosition;
      _userPosition ??= userPositionFromRide;
    }
  }

  LatLng _toMapLatLng(dynamic position) {
    return LatLng(position.latitude as double, position.longitude as double);
  }

  LatLng _zonePointToLatLng(GeoPoint point) {
    return LatLng(point.latitude, point.longitude);
  }

  bool _isValidLatLng(LatLng? position) {
    return position != null &&
        position.latitude.abs() <= 90 &&
        position.longitude.abs() <= 180 &&
        !(position.latitude == 0 && position.longitude == 0);
  }

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

  Future<void> _startLocationTracking() async {
    final l10n = AppLocalizations.of(context);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationDisabled)));
      }
      return;
    }

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) {
      if (_cachedPermission == LocationPermission.deniedForever && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationPermanentlyDenied)));
      }
      return;
    }

    try {
      if (!kIsWeb) {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          _applyPosition(lastPosition);
        }
      }

      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _applyPosition(currentPosition);

      _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 1,
            ),
          ).listen(
            _applyPosition,
            onError: (error) {
              debugPrint('Active ride location stream failed: $error');
            },
          );
    } catch (error) {
      debugPrint('Error starting active ride location tracking: $error');
    }
  }

  void _applyPosition(Position position) {
    if (!mounted) return;

    final currentPosition = LatLng(position.latitude, position.longitude);
    final currentHeading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : _bearingBetween(_userPosition, currentPosition) ?? _heading;

    setState(() {
      _userPosition = currentPosition;
      _heading = currentHeading;
    });
    _followRideCamera();
  }

  double? _bearingBetween(LatLng? from, LatLng to) {
    if (from == null) return null;

    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);
    final deltaLng = _degreesToRadians(to.longitude - from.longitude);
    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    return (_radiansToDegrees(math.atan2(y, x)) + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  double _radiansToDegrees(double radians) => radians * 180 / math.pi;

  void _followRideCamera() {
    final targetPosition = _isValidLatLng(_userPosition)
        ? _userPosition
        : _scooterPosition;
    if (!_isValidLatLng(targetPosition)) {
      return;
    }

    _mapController.moveAndRotate(targetPosition!, 17, _heading);
  }

  Future<void> _loadOperationalZones() async {
    try {
      final bundle = await _backendService.fetchLiveMap();
      if (!mounted) return;
      setState(() {
        _zones = bundle.zones;
      });
    } catch (error) {
      debugPrint('Error loading operational zones for active ride: $error');
    }
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

  void _showRideAlerts(RideSessionState state) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (state.lowBalance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.walletBalanceLow)));
    } else if (state.outsideGeofence) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.outsideOperatingZone)));
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom + 1.0).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom - 1.0).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _onEndRide() async {
    if (_isEndingRide) return;

    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (!mounted) return;
    if (photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.endRidePhotoRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final photoBytes = await photo.readAsBytes();

    setState(() {
      _isEndingRide = true;
    });

    try {
      final ride = await context.read<RideCubit>().endActiveRide(
        endPhotoBytes: photoBytes,
      );
      if (!mounted) return;

      final user = _backendService.currentUser ??
          await _backendService.fetchCurrentUser(forceRefresh: true);
      if (!mounted) return;

      final remainingBalance = user.walletBalance;
      context.read<UserCubit>().applyAuthenticatedUser(user);
      context.read<WalletCubit>().updateBalance(remainingBalance);

      final route = _rideService.latestState?.route ?? [];
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RideSummaryScreen(
            ride: ride,
            route: route,
            remainingBalance: remainingBalance,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEndingRide = false;
      });

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorEndingRide('$e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rideState = _rideState;
    final duration = rideState?.duration ?? Duration.zero;
    final currentCost =
        rideState?.cost ?? duration.inSeconds / 60 * widget.ratePerMinute;
    final batteryPercent = rideState?.batteryPercent;
    final routePoints = rideState?.route
        .map(_toMapLatLng)
        .where(_isValidLatLng)
        .toList(growable: false);
    final centerPosition = _userPosition ?? _scooterPosition ?? _fallbackCenter;
    final zonePolygons = _zones
        .where((zone) => zone.boundary.length >= 3)
        .map(
          (zone) => Polygon(
            points: zone.boundary
                .map(_zonePointToLatLng)
                .toList(growable: false),
            color: _zoneFillColor(zone.type),
            borderColor: _zoneBorderColor(zone.type),
            borderStrokeWidth: 2,
          ),
        )
        .toList(growable: false);
    final markers = <Marker>[
      if (_isValidLatLng(_scooterPosition))
        Marker(
          point: _scooterPosition!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1FAE6C).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.electric_scooter,
              color: Color(0xFF1FAE6C),
              size: 32,
            ),
          ),
        ),
      if (_isValidLatLng(_userPosition))
        Marker(
          point: _userPosition!,
          width: 42,
          height: 42,
          child: Transform.rotate(
            angle: _degreesToRadians(_heading),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.navigation, color: Colors.blue, size: 24),
            ),
          ),
        ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerPosition,
                initialZoom: 17.0,
                initialRotation: _heading,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.glider',
                ),
                if (zonePolygons.isNotEmpty)
                  PolygonLayer(polygons: zonePolygons),
                if (routePoints != null && routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: const Color(0xFF1FAE6C),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.electric_scooter,
                          color: Color(0xFF1FAE6C),
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.ongoingRide,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                l10n.scooterId(widget.scooterCode),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.active,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    heroTag: 'active_zoom_in_btn',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add, color: Color(0xFF1FAE6C)),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'active_zoom_out_btn',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove, color: Color(0xFF1FAE6C)),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'active_my_location_btn',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _startLocationTracking,
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF1FAE6C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RIDE DURATION',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.costEgp(currentCost.toStringAsFixed(2)),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1FAE6C),
                            ),
                          ),
                          if (batteryPercent != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.battery_full,
                                  size: 18,
                                  color: batteryPercent < 15
                                      ? Colors.red
                                      : const Color(0xFF1FAE6C),
                                ),
                                const SizedBox(width: 6),
                                Text(l10n.percentSuffix('$batteryPercent')),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            l10n.currentCost,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _isEndingRide ? null : _onEndRide,
                              child: _isEndingRide
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.stop, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.endRideUpper,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
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
      ),
    );
  }
}
