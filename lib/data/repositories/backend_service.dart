import 'dart:typed_data';

import 'package:glider/core/constants/app_constants.dart';
import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/domain/entities/ride.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/domain/entities/signup_result.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/data/datasources/api_service.dart';
import 'package:glider/data/datasources/auth_service.dart';
import 'package:glider/data/datasources/scooter_api_service.dart';

class BackendService {
  BackendService._internal({
    AuthService? authService,
    ScooterApiService? scooterApiService,
    ApiService? apiService,
  }) : _authService = authService ?? AuthService(),
       _scooterApiService = scooterApiService ?? ScooterApiService(),
       _apiService = apiService ?? ApiService();

  static final BackendService _instance = BackendService._internal();

  factory BackendService() => _instance;

  final AuthService _authService;
  final ScooterApiService _scooterApiService;
  final ApiService _apiService;

  final List<Ride> _rides = <Ride>[];
  AppUser? _currentUser;

  String get activeBaseUrl => AppConstants.baseUrl;

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<AppUser> login(String email, String password) async {
    final user = await _authService.login(email: email, password: password);
    _currentUser = user;
    return user;
  }

  Future<SignupResult> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required Uint8List idFrontPhotoBytes,
    required Uint8List idBackPhotoBytes,
  }) async {
    final result = await _authService.register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      idFrontPhotoBytes: idFrontPhotoBytes,
      idBackPhotoBytes: idBackPhotoBytes,
    );
    // Only treat the user as logged-in if the backend registration flow
    // actually resulted in a saved authentication session (tokens).
    // This avoids auto-login when the server returns tokens during
    // registration but the app still requires email/OTP verification.
    final hasSession = await _authService.hasSavedSession();
    if (!result.requiresEmailVerification && hasSession) {
      _currentUser = result.user;
    }
    return result;
  }

  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    final verifiedUser = await _authService.verifyEmail(
      email: email,
      code: code,
    );
    final user = verifiedUser ?? await _authService.getProfile();
    _currentUser = user;
    return user;
  }

  Future<void> resendOtp(String email) {
    return _authService.resendVerificationCode(email);
  }

  Future<void> forgotPassword(String email) {
    return _authService.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _apiService.post(
      '/Auth/reset-password',
      data: <String, dynamic>{
        'email': email,
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  Future<AppUser> fetchCurrentUser() async {
    final user = await _authService.getProfile();
    _currentUser = user;
    return user;
  }

  Future<AppUser> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    final user = await _authService.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );

    _currentUser = user.copyWith(email: _currentUser?.email ?? email);
    return _currentUser!;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    await _authService.logout();
  }

  Future<List<Scooter>> fetchNearbyScooters() {
    return _scooterApiService.getScooters();
  }

  Future<List<AppUser>> fetchAdminUsers() async {
    throw ApiException(
      'No admin users endpoint is available in the current API specification.',
    );
  }

  Future<List<Scooter>> fetchAdminScooters() {
    return fetchNearbyScooters();
  }

  Future<List<Scooter>> saveAdminScooter({
    String? id,
    required String code,
    required String modelId,
    required String locationName,
    required double lat,
    required double lng,
    required int batteryPercent,
    required bool isAvailable,
  }) async {
    if (id == null) {
      await _apiService.post(
        '/Scooter',
        data: <String, dynamic>{'serialNumber': code, 'modelId': modelId},
      );
      return fetchNearbyScooters();
    }

    await _apiService.put(
      '/Scooter/$id',
      data: <String, dynamic>{'status': isAvailable ? 'Available' : 'Offline'},
    );

    return fetchNearbyScooters();
  }

  Future<List<Scooter>> deleteAdminScooter(String id) async {
    await _apiService.delete('/Scooter/$id');
    return fetchNearbyScooters();
  }

  Future<List<Ride>> fetchRideHistory() async {
    return List<Ride>.unmodifiable(_rides);
  }

  Future<Ride> startRide({
    required String serialNumber,
    required double userLatitude,
    required double userLongitude,
  }) async {
    final data = await _apiService.post(
      '/Ride/start',
      data: <String, dynamic>{
        'serialNumber': serialNumber,
        'userLatitude': userLatitude,
        'userLongitude': userLongitude,
      },
    );

    final ride = Ride.fromJson(data);
    _upsertRide(ride);
    return ride;
  }

  Future<Ride?> fetchActiveRide() async {
    try {
      final data = await _apiService.get('/Ride/active');
      final ride = Ride.fromJson(data);
      _upsertRide(ride);
      return ride;
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<Ride> endActiveRide({
    required double userLatitude,
    required double userLongitude,
    required String endPhotoUrl,
  }) async {
    final data = await _apiService.post(
      '/Ride/active/end',
      data: <String, dynamic>{
        'userLatitude': userLatitude,
        'userLongitude': userLongitude,
        'endPhotoUrl': endPhotoUrl,
      },
    );

    final ride = Ride.fromJson(data);
    _upsertRide(ride);
    _currentUser = await fetchCurrentUser();
    return ride;
  }

  Future<AppUser> topUpWallet(double amount) async {
    _currentUser ??= await fetchCurrentUser();

    if (amount <= 0) {
      return _currentUser!;
    }

    final updatedUser = _currentUser!.copyWith(
      walletBalance: _currentUser!.walletBalance + amount,
    );
    _currentUser = updatedUser;
    return updatedUser;
  }

  Future<AppUser> chargeForRide(double amount) async {
    _currentUser ??= await fetchCurrentUser();

    final updatedUser = _currentUser!.copyWith(
      walletBalance: (_currentUser!.walletBalance - amount).clamp(
        0.0,
        1000000.0,
      ),
    );
    _currentUser = updatedUser;
    return updatedUser;
  }

  Ride createRide({
    required String scooterCode,
    required DateTime startedAt,
    required String fromName,
  }) {
    final ride = Ride(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      scooterCode: scooterCode,
      startedAt: startedAt,
      endedAt: startedAt,
      distanceKm: 0,
      cost: 0,
      fromName: fromName,
      toName: '',
    );
    _rides.insert(0, ride);
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

  void _upsertRide(Ride ride) {
    final index = _rides.indexWhere((item) => item.id == ride.id);
    if (index == -1) {
      _rides.insert(0, ride);
    } else {
      _rides[index] = ride;
    }
  }
}
