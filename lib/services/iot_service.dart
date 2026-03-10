import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Simulated IoT layer for communicating with ESP32 scooters.
///
/// In a real system this would use MQTT or HTTP to talk to the hardware.
/// Here we generate predictable demo data so the app can behave like a
/// production scooter rental app without physical devices.
class IoTService {
  IoTService._internal();

  static final IoTService _instance = IoTService._internal();

  factory IoTService() => _instance;

  final Map<String, LatLng> _scooterPositions = <String, LatLng>{};
  final Map<String, int> _batteryLevels = <String, int>{};
  final Map<String, double> _speeds = <String, double>{};

  final Random _random = Random();

  Future<void> sendUnlockCommand(String scooterId) async {
    // In real life this would send an MQTT "unlock" command.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> sendLockCommand(String scooterId) async {
    // In real life this would send an MQTT "lock" command.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  /// Returns the latest GPS position of the scooter.
  ///
  /// For the demo, we slightly move the position each call to simulate motion.
  Future<LatLng> receiveGPSLocation(String scooterId, LatLng fallback) async {
    final current = _scooterPositions[scooterId] ?? fallback;

    // Tiny random walk around the current point.
    final deltaLat = (_random.nextDouble() - 0.5) / 5000;
    final deltaLng = (_random.nextDouble() - 0.5) / 5000;

    final updated = LatLng(
      current.latitude + deltaLat,
      current.longitude + deltaLng,
    );

    _scooterPositions[scooterId] = updated;
    return updated;
  }

  /// Returns simulated battery percentage for the scooter.
  Future<int> receiveBatteryLevel(String scooterId, {int initial = 80}) async {
    final current = _batteryLevels.putIfAbsent(scooterId, () => initial);
    // Drain a tiny bit of battery each call, but never below 5%.
    final drained = max(5, current - _random.nextInt(2));
    _batteryLevels[scooterId] = drained;
    return drained;
  }

  /// Returns simulated current speed in km/h.
  Future<double> receiveSpeed(String scooterId) async {
    final speed =
        _speeds[scooterId] ?? _random.nextDouble() * 18; // up to 18 km/h
    // Slightly vary speed over time.
    final variation = (_random.nextDouble() - 0.5) * 2;
    final updated = max(0.0, speed + variation);
    _speeds[scooterId] = updated;
    return updated;
  }
}
