import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/data/repositories/backend_service.dart';
import 'iot_service.dart';

enum ScooterStatus {
  available,
  reserved,
  inUse,
  offline,
  charging,
}

class ScooterService {
  ScooterService._internal();

  static final ScooterService _instance = ScooterService._internal();

  factory ScooterService() => _instance;

  final BackendService _backend = BackendService();
  final IoTService _iot = IoTService();

  final Map<String, ScooterStatus> _status = <String, ScooterStatus>{};

  ScooterStatus getStatus(String scooterId) {
    return _status[scooterId] ?? ScooterStatus.available;
  }

  Future<List<Scooter>> fetchNearbyScooters() async {
    final scooters = await _backend.fetchNearbyScooters();
    return scooters;
  }

  Future<void> unlockScooter(String scooterId) async {
    _status[scooterId] = ScooterStatus.inUse;
    await _iot.sendUnlockCommand(scooterId);
  }

  Future<void> lockScooter(String scooterId) async {
    _status[scooterId] = ScooterStatus.available;
    await _iot.sendLockCommand(scooterId);
  }

  Future<int> getScooterBattery(String scooterId, {int initial = 80}) async {
    return _iot.receiveBatteryLevel(scooterId, initial: initial);
  }

  Future<LatLng> getScooterLocation(
    String scooterId, {
    required LatLng fallback,
  }) async {
    return _iot.receiveGPSLocation(scooterId, fallback);
  }

  Future<ScooterStatus> getScooterStatus(String scooterId) async {
    return getStatus(scooterId);
  }
}

