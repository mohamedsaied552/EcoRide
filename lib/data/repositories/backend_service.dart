import 'dart:typed_data';

import 'package:glider/core/constants/app_constants.dart';
import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/domain/entities/live_map_bundle.dart';
import 'package:glider/domain/entities/paginated_result.dart';
import 'package:glider/domain/entities/ride.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/domain/entities/scooter_status_info.dart';
import 'package:glider/domain/entities/signup_result.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/domain/entities/zone.dart';
import 'package:glider/data/datasources/api_service.dart';
import 'package:glider/data/datasources/auth_service.dart';
import 'package:glider/data/datasources/scooter_api_service.dart';
import 'package:glider/data/datasources/zone_api_service.dart';

class BackendService {
  BackendService._internal({
    AuthService? authService,
    ScooterApiService? scooterApiService,
    ZoneApiService? zoneApiService,
    ApiService? apiService,
  }) : _authService = authService ?? AuthService(),
       _scooterApiService = scooterApiService ?? ScooterApiService(),
       _zoneApiService = zoneApiService ?? ZoneApiService(),
       _apiService = apiService ?? ApiService();

  static final BackendService _instance = BackendService._internal();

  factory BackendService() => _instance;

  final AuthService _authService;
  final ScooterApiService _scooterApiService;
  final ZoneApiService _zoneApiService;
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
    // actually resulted in a saved authentication session AND verification
    // is not required. Verification gates session establishment.
    if (result.requiresEmailVerification) {
      _currentUser = null;
      return result;
    }
    final hasSession = await _authService.hasSavedSession();
    if (hasSession) {
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
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    final user = await _authService.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarBytes: avatarBytes,
      avatarFileName: avatarFileName,
    );

    _currentUser = user.copyWith(email: _currentUser?.email ?? email);
    return _currentUser!;
  }

  Future<void> updateFcmToken(String token) {
    return _authService.updateFcmToken(token);
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

  Future<LiveMapBundle> fetchLiveMap() {
    return _scooterApiService.getLiveMap();
  }

  Future<ScooterStatusInfo> fetchScooterStatus(String serialNumber) {
    return _scooterApiService.getScooterStatus(serialNumber);
  }

  // ---------------------------------------------------------------------------
  // Scooter Admin CRUD (POST/PUT/DELETE and GET-by-id on /Scooter)
  // ---------------------------------------------------------------------------

  Future<PaginatedResult<Scooter>> fetchScootersPaginated({
    int pageIndex = 1,
    int pageSize = 50,
  }) {
    return _scooterApiService.getScootersPaginated(
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  Future<Scooter> fetchScooterById(String id) {
    return _scooterApiService.getScooterById(id);
  }

  Future<Scooter> createScooter({
    required String serialNumber,
    required String modelId,
  }) {
    return _scooterApiService.createScooter(
      serialNumber: serialNumber,
      modelId: modelId,
    );
  }

  Future<Scooter> updateScooter({required String id, required String status}) {
    return _scooterApiService.updateScooter(id: id, status: status);
  }

  Future<bool> deleteScooter(String id) {
    return _scooterApiService.deleteScooter(id);
  }

  // ---------------------------------------------------------------------------
  // Zone endpoints (/api/Zone)
  // ---------------------------------------------------------------------------

  Future<PaginatedResult<Zone>> fetchZones({
    int pageIndex = 1,
    int pageSize = 50,
    bool? isActive,
  }) {
    return _zoneApiService.getZones(
      pageIndex: pageIndex,
      pageSize: pageSize,
      isActive: isActive,
    );
  }

  Future<Zone> fetchZoneById(String id) {
    return _zoneApiService.getZoneById(id);
  }

  Future<List<Zone>> fetchZonesAtLocation({
    required double latitude,
    required double longitude,
  }) {
    return _zoneApiService.getZonesAtLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<Zone> createZone({
    required String name,
    required String type,
    required double? speedLimitKmH,
    required List<Map<String, double>> boundary,
  }) {
    return _zoneApiService.createZone(
      name: name,
      type: type,
      speedLimitKmH: speedLimitKmH,
      boundary: boundary,
    );
  }

  Future<Zone> updateZone({
    required String id,
    required String name,
    required String type,
    required double? speedLimitKmH,
    required bool isActive,
    required List<Map<String, double>> boundary,
  }) {
    return _zoneApiService.updateZone(
      id: id,
      name: name,
      type: type,
      speedLimitKmH: speedLimitKmH,
      isActive: isActive,
      boundary: boundary,
    );
  }

  Future<bool> deleteZone(String id) {
    return _zoneApiService.deleteZone(id);
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
