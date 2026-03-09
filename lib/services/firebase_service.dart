import '../models/ride.dart';
import '../models/scooter.dart';
import '../models/user.dart';

/// Simple in‑memory backend simulator for the demo app.
///
/// This lets different screens share a single source of truth for:
/// - current user & wallet balance
/// - scooters list
/// - ride history
/// - basic ride start/end and charging logic
class FirebaseService {
  FirebaseService._internal() {
    // Seed demo data once.
    _currentUser = const AppUser(
      id: 'u_001',
      name: 'Mohamed Ali',
      email: 'mohamed@example.com',
      phone: '+20 100 123 4567',
      walletBalance: 50.0,
      ridesCount: 12,
      rating: 4.9,
    );

    _scooters = const [
      Scooter(
        id: 's_01',
        code: 'SCT-102',
        lat: 30.045,
        lng: 31.234,
        batteryPercent: 78,
        isAvailable: true,
        locationName: 'Garden City',
      ),
      Scooter(
        id: 's_02',
        code: 'SCT-221',
        lat: 30.046,
        lng: 31.236,
        batteryPercent: 62,
        isAvailable: true,
        locationName: 'Downtown',
      ),
      Scooter(
        id: 's_03',
        code: 'SCT-315',
        lat: 30.042,
        lng: 31.232,
        batteryPercent: 40,
        isAvailable: false,
        locationName: 'Tahrir Square',
      ),
    ];

    final now = DateTime.now();
    _rides = [
      Ride(
        id: 'r_001',
        scooterCode: 'SCT-102',
        startedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        endedAt: now.subtract(const Duration(hours: 2, minutes: 8)),
        distanceKm: 2.4,
        cost: 18.5,
        fromName: 'Garden City',
        toName: 'Downtown',
      ),
      Ride(
        id: 'r_002',
        scooterCode: 'SCT-221',
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        endedAt: now.subtract(const Duration(days: 1, hours: 2, minutes: 35)),
        distanceKm: 3.1,
        cost: 22.0,
        fromName: 'Zamalek',
        toName: 'Opera',
      ),
      Ride(
        id: 'r_003',
        scooterCode: 'SCT-315',
        startedAt: now.subtract(const Duration(days: 3, hours: 1)),
        endedAt: now.subtract(const Duration(days: 3, hours: 0, minutes: 40)),
        distanceKm: 1.6,
        cost: 12.0,
        fromName: 'Tahrir Square',
        toName: 'Kasr El Nil',
      ),
    ];
  }

  static final FirebaseService _instance = FirebaseService._internal();

  /// Factory so every `FirebaseService()` call returns the same instance.
  factory FirebaseService() => _instance;

  late AppUser _currentUser;
  late List<Scooter> _scooters;
  late List<Ride> _rides;

  // Simple pricing and safety configuration for the demo.
  static const double _pricePerMinute = 1.25; // EGP/min
  static const double _minimumWalletToStart = 50.0; // EGP

  /// Returns the current user profile including latest wallet balance.
  Future<AppUser> fetchCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _currentUser;
  }

  /// Returns scooters that are currently in the demo fleet.
  Future<List<Scooter>> fetchNearbyScooters() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<Scooter>.unmodifiable(_scooters);
  }

  /// Returns past rides for the user.
  Future<List<Ride>> fetchRideHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<Ride>.unmodifiable(_rides);
  }

  /// Adds funds to the demo wallet.
  Future<AppUser> topUpWallet(double amount) async {
    if (amount <= 0) return _currentUser;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = _currentUser.copyWith(
      walletBalance: _currentUser.walletBalance + amount,
    );
    return _currentUser;
  }

  /// Charges the user's wallet for a finished ride.
  Future<AppUser> _chargeForRide(double amount) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final newBalance = (_currentUser.walletBalance - amount).clamp(
      0.0,
      1e9.toDouble(),
    );
    _currentUser = _currentUser.copyWith(walletBalance: newBalance);
    return _currentUser;
  }

  /// Starts and immediately completes a short demo ride for a scooter code.
  ///
  /// This simulates:
  /// - wallet balance check
  /// - ride duration & distance
  /// - cost calculation
  /// - wallet deduction
  /// - ride history entry
  ///
  /// It is triggered from the QR scan flow to keep the sample app simple.
  Future<Ride> startAndCompleteDemoRide(String scooterCode) async {
    // 1) Look up the scooter by its QR / code.
    final scooter = _scooters.firstWhere(
      (s) => s.code == scooterCode,
      orElse: () =>
          throw StateError('Scooter with code $scooterCode not found'),
    );

    // 2) Basic wallet safety check.
    if (_currentUser.walletBalance < _minimumWalletToStart) {
      throw StateError(
        'Insufficient balance. Please top up at least '
        '${_minimumWalletToStart.toStringAsFixed(0)} EGP to start a ride.',
      );
    }

    // 3) Simulate a short city ride.
    final startedAt = DateTime.now().subtract(const Duration(minutes: 12));
    final endedAt = DateTime.now();
    final durationMinutes =
        endedAt.difference(startedAt).inSeconds / 60.0; // fractional minutes
    final distanceKm = 1.2; // Demo distance
    final cost = double.parse(
      (durationMinutes * _pricePerMinute).toStringAsFixed(1),
    );

    // 4) Charge wallet and update rides list.
    await _chargeForRide(cost);
    final ride = Ride(
      id: 'r_${_rides.length + 1}',
      scooterCode: scooter.code,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceKm: distanceKm,
      cost: cost,
      fromName: scooter.locationName,
      toName: 'Destination',
    );
    _rides = [ride, ..._rides];

    return ride;
  }
}
