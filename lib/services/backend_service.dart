import 'dart:async';

import '../models/ride.dart';
import '../models/scooter.dart';
import '../models/user.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _StoredUser {
  _StoredUser({
    required this.user,
    required this.password,
    required this.idFrontPhotoUrl,
    required this.idBackPhotoUrl,
  });

  AppUser user;
  String password;
  String idFrontPhotoUrl;
  String idBackPhotoUrl;
}

class BackendService {
  BackendService._internal() {
    _seedData();
  }

  static final BackendService _instance = BackendService._internal();

  factory BackendService() => _instance;

  final Map<String, _StoredUser> _usersByEmail = <String, _StoredUser>{};
  final List<Scooter> _scooters = <Scooter>[];
  late List<Ride> _rides;

  AppUser? _currentUser;

  String get activeBaseUrl => 'Local demo mode';

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<void> _pause([int milliseconds = 220]) {
    return Future<void>.delayed(Duration(milliseconds: milliseconds));
  }

  void _seedData() {
    _rides = _seedRideHistory();
    _scooters
      ..clear()
      ..addAll(_seedScooters());
    _usersByEmail
      ..clear()
      ..addAll(_seedUsers());
  }

  List<Ride> _seedRideHistory() {
    final now = DateTime.now();
    return <Ride>[
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
    ];
  }

  List<Scooter> _seedScooters() {
    return const <Scooter>[
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
  }

  Map<String, _StoredUser> _seedUsers() {
    final admin = AppUser(
      id: 'admin_001',
      name: 'Fleet Admin',
      email: 'admin@glider.com',
      phone: '01000000000',
      walletBalance: 0,
      ridesCount: 0,
      rating: 5,
      accountStatus: 'Active',
      idVerificationStatus: 'Verified',
      phoneVerified: true,
      role: UserRole.admin,
    );

    final demoUser = AppUser(
      id: 'user_001',
      name: 'Mohamed Said',
      email: 'mohamed@example.com',
      phone: '01004832172',
      walletBalance: 120,
      ridesCount: _rides.length,
      rating: 4.9,
      accountStatus: 'Active',
      idVerificationStatus: 'Pending',
      phoneVerified: true,
      role: UserRole.user,
    );

    return <String, _StoredUser>{
      admin.email.toLowerCase(): _StoredUser(
        user: admin,
        password: 'admin123',
        idFrontPhotoUrl: '',
        idBackPhotoUrl: '',
      ),
      demoUser.email.toLowerCase(): _StoredUser(
        user: demoUser,
        password: '12345678',
        idFrontPhotoUrl: '',
        idBackPhotoUrl: '',
      ),
    };
  }

  Future<AppUser> login(String email, String password) async {
    await _pause(350);
    final storedUser = _usersByEmail[email.trim().toLowerCase()];
    if (storedUser == null || storedUser.password != password) {
      throw ApiException('Invalid email or password');
    }

    _currentUser = storedUser.user.copyWith(
      ridesCount: storedUser.user.isAdmin ? 0 : _rides.length,
    );
    return _currentUser!;
  }

  Future<AppUser> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String idFrontPhotoUrl,
    required String idBackPhotoUrl,
  }) async {
    await _pause(450);
    final normalizedEmail = email.trim().toLowerCase();
    if (_usersByEmail.containsKey(normalizedEmail)) {
      throw ApiException('An account with this email already exists');
    }

    final user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: fullName.trim(),
      email: normalizedEmail,
      phone: phoneNumber.trim(),
      walletBalance: 0,
      ridesCount: _rides.length,
      rating: 5,
      accountStatus: 'Active',
      idVerificationStatus: 'Pending',
      phoneVerified: false,
      role: UserRole.user,
    );

    _usersByEmail[normalizedEmail] = _StoredUser(
      user: user,
      password: password,
      idFrontPhotoUrl: idFrontPhotoUrl,
      idBackPhotoUrl: idBackPhotoUrl,
    );
    _currentUser = user;
    return _currentUser!;
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _pause();
  }

  Future<void> resendOtp(String email) async {
    await _pause();
  }

  Future<void> forgotPassword(String email) async {
    await _pause(280);
    if (!_usersByEmail.containsKey(email.trim().toLowerCase())) {
      throw ApiException('No account found for this email');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _pause();
    final storedUser = _usersByEmail[email.trim().toLowerCase()];
    if (storedUser == null) {
      throw ApiException('No account found for this email');
    }
    storedUser.password = newPassword;
  }

  Future<AppUser> fetchCurrentUser() async {
    await _pause(180);
    if (_currentUser == null) {
      throw ApiException('Please log in first.');
    }
    return _currentUser!;
  }

  Future<AppUser> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    await _pause(300);
    if (_currentUser == null) {
      throw ApiException('Please log in first.');
    }

    final currentEmail = _currentUser!.email.toLowerCase();
    final newEmail = email.trim().toLowerCase();
    final existing = _usersByEmail[newEmail];
    if (newEmail != currentEmail && existing != null) {
      throw ApiException('Email is already in use');
    }

    final stored = _usersByEmail.remove(currentEmail);
    if (stored == null) {
      throw ApiException('Unable to update profile right now.');
    }

    final updatedUser = stored.user.copyWith(
      name: fullName.trim(),
      email: newEmail,
      phone: phoneNumber.trim(),
      avatarUrl: avatarUrl,
    );
    stored.user = updatedUser;
    _usersByEmail[newEmail] = stored;
    _currentUser = updatedUser;
    return _currentUser!;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _pause(260);
    if (_currentUser == null) {
      throw ApiException('Please log in first.');
    }

    final stored = _usersByEmail[_currentUser!.email.toLowerCase()];
    if (stored == null) {
      throw ApiException('Unable to update password right now.');
    }
    if (stored.password != currentPassword) {
      throw ApiException('Current password is incorrect');
    }
    stored.password = newPassword;
  }

  Future<void> logout() async {
    await _pause(120);
    _currentUser = null;
  }

  Future<List<Scooter>> fetchNearbyScooters() async {
    await _pause(220);
    return List<Scooter>.unmodifiable(_scooters);
  }

  Future<List<AppUser>> fetchAdminUsers() async {
    await _pause(220);
    _ensureAdmin();
    return _usersByEmail.values
        .map((entry) => entry.user)
        .toList(growable: false);
  }

  Future<List<Scooter>> fetchAdminScooters() async {
    await _pause(220);
    _ensureAdmin();
    return List<Scooter>.unmodifiable(_scooters);
  }

  Future<List<Scooter>> saveAdminScooter({
    String? id,
    required String code,
    required String locationName,
    required double lat,
    required double lng,
    required int batteryPercent,
    required bool isAvailable,
  }) async {
    await _pause(280);
    _ensureAdmin();

    if (id == null) {
      _scooters.add(
        Scooter(
          id: 's_${DateTime.now().millisecondsSinceEpoch}',
          code: code,
          lat: lat,
          lng: lng,
          batteryPercent: batteryPercent,
          isAvailable: isAvailable,
          locationName: locationName,
        ),
      );
    } else {
      final index = _scooters.indexWhere((scooter) => scooter.id == id);
      if (index == -1) {
        throw ApiException('Scooter not found');
      }
      _scooters[index] = _scooters[index].copyWith(
        code: code,
        locationName: locationName,
        lat: lat,
        lng: lng,
        batteryPercent: batteryPercent,
        isAvailable: isAvailable,
      );
    }

    return List<Scooter>.unmodifiable(_scooters);
  }

  Future<List<Scooter>> deleteAdminScooter(String id) async {
    await _pause(220);
    _ensureAdmin();
    _scooters.removeWhere((scooter) => scooter.id == id);
    return List<Scooter>.unmodifiable(_scooters);
  }

  Future<List<Ride>> fetchRideHistory() async {
    await _pause(180);
    return List<Ride>.unmodifiable(_rides);
  }

  Future<AppUser> topUpWallet(double amount) async {
    await _pause(180);
    if (_currentUser == null) {
      throw ApiException('Please log in first.');
    }

    if (amount <= 0) {
      return _currentUser!;
    }

    final updatedUser = _currentUser!.copyWith(
      walletBalance: _currentUser!.walletBalance + amount,
    );
    _replaceCurrentUser(updatedUser);
    return _currentUser!;
  }

  Future<AppUser> chargeForRide(double amount) async {
    await _pause(150);
    if (_currentUser == null) {
      throw ApiException('Please log in first.');
    }

    final newBalance =
        (_currentUser!.walletBalance - amount).clamp(0.0, 1000000.0);
    final updatedUser = _currentUser!.copyWith(walletBalance: newBalance);
    _replaceCurrentUser(updatedUser);
    return _currentUser!;
  }

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
    _rides = <Ride>[ride, ..._rides];
    return ride;
  }

  Ride completeRide({
    required String id,
    required DateTime endedAt,
    required double distanceKm,
    required double cost,
    required String toName,
  }) {
    final index = _rides.indexWhere((ride) => ride.id == id);
    if (index == -1) {
      throw ApiException('Ride with id $id not found.');
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

  void _replaceCurrentUser(AppUser user) {
    final stored = _usersByEmail[user.email.toLowerCase()];
    if (stored != null) {
      stored.user = user;
    }
    _currentUser = user;
  }

  void _ensureAdmin() {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      throw ApiException('Admin access required');
    }
  }
}
