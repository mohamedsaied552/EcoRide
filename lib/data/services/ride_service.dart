import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:glider/domain/entities/ride.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/data/repositories/backend_service.dart';
import 'geofence_service.dart';
import 'iot_service.dart';
import 'package:glider/data/services/scooter_service.dart';

class RideSessionState {
  const RideSessionState({
    required this.isActive,
    required this.duration,
    required this.distanceKm,
    required this.cost,
    required this.batteryPercent,
    required this.scooterPosition,
    required this.userPosition,
    required this.route,
    required this.lowBalance,
    required this.outsideGeofence,
  });

  final bool isActive;
  final Duration duration;
  final double distanceKm;
  final double cost;
  final int batteryPercent;
  final LatLng scooterPosition;
  final LatLng userPosition;
  final List<LatLng> route;
  final bool lowBalance;
  final bool outsideGeofence;

  RideSessionState copyWith({
    bool? isActive,
    Duration? duration,
    double? distanceKm,
    double? cost,
    int? batteryPercent,
    LatLng? scooterPosition,
    LatLng? userPosition,
    List<LatLng>? route,
    bool? lowBalance,
    bool? outsideGeofence,
  }) {
    return RideSessionState(
      isActive: isActive ?? this.isActive,
      duration: duration ?? this.duration,
      distanceKm: distanceKm ?? this.distanceKm,
      cost: cost ?? this.cost,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      scooterPosition: scooterPosition ?? this.scooterPosition,
      userPosition: userPosition ?? this.userPosition,
      route: route ?? this.route,
      lowBalance: lowBalance ?? this.lowBalance,
      outsideGeofence: outsideGeofence ?? this.outsideGeofence,
    );
  }
}

class RideService {
  RideService._internal();

  static final RideService _instance = RideService._internal();

  factory RideService() => _instance;

  final BackendService _backend = BackendService();
  final ScooterService _scooterService = ScooterService();
  final IoTService _iot = IoTService();
  final GeofenceService _geofence = GeofenceService();

  static const double pricePerMinute = 1.0; // EGP per minute
  static const double minimumWalletToStart = 10.0; // EGP

  Ride? _currentRide;
  AppUser? _userSnapshot;
  Timer? _tickTimer;
  Duration _duration = Duration.zero;
  double _distanceKm = 0;
  int _batteryPercent = 80;
  late LatLng _scooterPosition;
  late LatLng _userPosition;
  final List<LatLng> _route = <LatLng>[];
  bool _lowBalance = false;
  bool _outsideGeofence = false;
  int _secondsOutsideGeofence = 0;

  final StreamController<RideSessionState> _stateController =
      StreamController<RideSessionState>.broadcast();

  Stream<RideSessionState> get stateStream => _stateController.stream;

  RideSessionState? _latestState;

  RideSessionState? get latestState => _latestState;

  bool get hasActiveRide => _currentRide != null;

  Ride? get currentRide => _currentRide;

  List<LatLng> get route => List<LatLng>.unmodifiable(_route);

  Future<Ride> startRide(
    String scooterCode, {
    required double userLatitude,
    required double userLongitude,
  }) async {
    if (_currentRide != null) {
      return _currentRide!;
    }

    final user = await _backend.fetchCurrentUser();
    _userSnapshot = user;
    if (user.walletBalance < minimumWalletToStart) {
      throw StateError(
        'Insufficient balance. Minimum $minimumWalletToStart EGP required to start a ride.',
      );
    }

    final scooters = await _backend.fetchNearbyScooters();
    final scooter = scooters.firstWhere(
      (s) => s.code == scooterCode,
      orElse: () => throw StateError('Scooter with code $scooterCode not found'),
    );

    if (!scooter.isAvailable) {
      throw StateError('Scooter is not available right now.');
    }

    final initialPosition = LatLng(scooter.lat, scooter.lng);
    final ride = await _backend.startRide(
      serialNumber: scooter.code,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );

    await _scooterService.unlockScooter(scooter.id);
    _currentRide = ride;

    _scooterPosition = initialPosition;
    _userPosition = _scooterPosition;
    _route
      ..clear()
      ..add(_scooterPosition);
    _batteryPercent =
        await _iot.receiveBatteryLevel(scooter.id, initial: scooter.batteryPercent);
    _duration = DateTime.now().difference(ride.startedAt);
    _distanceKm = 0;
    _lowBalance = false;
    _outsideGeofence = false;
    _secondsOutsideGeofence = 0;

    _emitState(isActive: true);

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick(scooter);
    });

    return ride;
  }

  void _onTick(Scooter scooter) async {
    if (_currentRide == null) return;

    _duration = DateTime.now().difference(_currentRide!.startedAt);

    // Update scooter position & route.
    final newPos =
        await _scooterService.getScooterLocation(scooter.id, fallback: _scooterPosition);
    _distanceKm += _incrementalDistance(_scooterPosition, newPos);
    _scooterPosition = newPos;
    _route.add(newPos);

    // Keep user close to scooter for the demo.
    _userPosition = LatLng(
      _scooterPosition.latitude + 0.0001,
      _scooterPosition.longitude + 0.0001,
    );

    _batteryPercent =
        await _scooterService.getScooterBattery(scooter.id, initial: scooter.batteryPercent);

    // Wallet safety – compute current cost against starting wallet snapshot.
    final cost = calculateRideCost();
    final startingBalance = _userSnapshot?.walletBalance ?? 0;
    final remaining = startingBalance - cost;
    _lowBalance = remaining <= 0;

    // Geofence – detect if we are outside allowed area.
    final inside = _geofence.isInside(_scooterPosition);
    if (!inside) {
      _secondsOutsideGeofence += 1;
      _outsideGeofence = true;
    } else {
      _secondsOutsideGeofence = 0;
      _outsideGeofence = false;
    }

    // If outside geofence for too long or balance depleted, end ride automatically.
    if (_secondsOutsideGeofence >= 20 || _lowBalance) {
      unawaited(endRide());
      return;
    }

    _emitState(isActive: true);
  }

  double _incrementalDistance(LatLng from, LatLng to) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(to.latitude - from.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final a = sinDLat * sinDLat +
        sinDLon * sinDLon * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthRadius * c) / 1000.0; // km
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  double calculateRideCost() {
    final minutes = _duration.inSeconds / 60.0;
    return minutes * pricePerMinute;
  }

  void _emitState({required bool isActive}) {
    final cost = calculateRideCost();
    final state = RideSessionState(
      isActive: isActive,
      duration: _duration,
      distanceKm: _distanceKm,
      cost: cost,
      batteryPercent: _batteryPercent,
      scooterPosition: _scooterPosition,
      userPosition: _userPosition,
      route: List<LatLng>.unmodifiable(_route),
      lowBalance: _lowBalance,
      outsideGeofence: _outsideGeofence,
    );
    _latestState = state;
    _stateController.add(state);
  }

  Future<Ride> endRide() async {
    final ride = _currentRide;
    if (ride == null) {
      throw StateError('No active ride to end.');
    }

    _tickTimer?.cancel();
    _tickTimer = null;

    final completedRide = await _backend.endActiveRide(
      userLatitude: _userPosition.latitude,
      userLongitude: _userPosition.longitude,
      endPhotoUrl: '',
    );
    _userSnapshot = await _backend.fetchCurrentUser();

    final scooters = await _backend.fetchNearbyScooters();
    final scooter = scooters.where((item) => item.code == ride.scooterCode).firstOrNull;
    await _scooterService.lockScooter(scooter?.id ?? ride.scooterCode);

    _currentRide = null;
    _emitState(isActive: false);

    return completedRide;
  }

  void pauseRide() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void dispose() {
    _tickTimer?.cancel();
    _stateController.close();
  }
}

