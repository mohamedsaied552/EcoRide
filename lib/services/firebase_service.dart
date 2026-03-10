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
  Future<AppUser> chargeForRide(double amount) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final newBalance = (_currentUser.walletBalance - amount).clamp(
      0.0,
      1e9.toDouble(),
    );
    _currentUser = _currentUser.copyWith(walletBalance: newBalance);
    return _currentUser;
  }

  /// Creates a new ride entry when a ride starts.
  Ride createRide({
    required String scooterCode,
    required DateTime startedAt,
    required String fromName,
  }) {
    final ride = Ride(
      id: 'r_${_rides.length + 1}',
      scooterCode: scooterCode,
      startedAt: startedAt,
      endedAt: startedAt,
      distanceKm: 0,
      cost: 0,
      fromName: fromName,
      toName: '',
    );
    _rides = [ride, ..._rides];
    return ride;
  }

  /// Completes an existing ride with final stats.
  Ride completeRide({
    required String id,
    required DateTime endedAt,
    required double distanceKm,
    required double cost,
    required String toName,
  }) {
    final index = _rides.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw StateError('Ride with id $id not found');
    }
    final existing = _rides[index];
    final updated = Ride(
      id: existing.id,
      scooterCode: existing.scooterCode,
      startedAt: existing.startedAt,
      endedAt: endedAt,
      distanceKm: distanceKm,
      cost: cost,
      fromName: existing.fromName,
      toName: toName,
    );
    _rides[index] = updated;
    return updated;
  }
}
