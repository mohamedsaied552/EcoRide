
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:glider/core/constants/app_constants.dart';
import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/domain/entities/live_map_bundle.dart';
import 'package:glider/domain/entities/paginated_result.dart';
import 'package:glider/domain/entities/ride.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/domain/entities/scooter_status_info.dart';
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

  Future<AppUser> loginWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    final user = await _authService.loginWithPhone(
      phoneNumber: phoneNumber,
      password: password,
    );
    _currentUser = user;
    return user;
  }

  Future<AppUser> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String firebaseToken,
    required Uint8List idFrontPhotoBytes,
    required Uint8List idBackPhotoBytes,
    required Uint8List selfiePhotoBytes,
  }) async {
    final user = await _authService.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      password: password,
      firebaseToken: firebaseToken,
      idFrontPhotoBytes: idFrontPhotoBytes,
      idBackPhotoBytes: idBackPhotoBytes,
      selfiePhotoBytes: selfiePhotoBytes,
    );
    _currentUser = user;
    return user;
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String firebaseToken,
    required String newPassword,
  }) {
    return _authService.resetPassword(
      phoneNumber: phoneNumber,
      firebaseToken: firebaseToken,
      newPassword: newPassword,
    );
  }

  Future<AppUser> fetchCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUser != null) return _currentUser!;
    final user = await _authService.getProfile();
    _currentUser = user;
    return user;
  }

  Future<bool> hasSavedSession() {
    return _authService.hasSavedSession();
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

  Future<List<Scooter>> fetchNearbyScooters() async {
    // Rider map uses GET /Scooter/live-map (authorized for app users).
    // GET /Scooter (paginated admin list) returns 403 for non-admin riders.
    final bundle = await fetchLiveMap();
    return bundle.scooters;
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
    Uint8List? endPhotoBytes,
    String? endPhotoPath,
  }) async {
    MultipartFile? endPhoto;

    // 💡 طباعة سريعة للتأكد من البيانات قبل التجهيز
    debugPrint(
      '📸 DEBUG END RIDE -> Path: $endPhotoPath | Bytes length: ${endPhotoBytes?.length}',
    );

    if (endPhotoPath != null && endPhotoPath.isNotEmpty) {
      endPhoto = await MultipartFile.fromFile(
        endPhotoPath,
        filename: 'end_ride.jpg',
        contentType: DioMediaType.parse('image/jpeg'),
      );
    }

    // 💡 لو الـ Path مجابش نتيجة أو فاضي، بنجرب البايتس فوراً كخطة بديلة
    if (endPhoto == null && endPhotoBytes != null && endPhotoBytes.isNotEmpty) {
      endPhoto = MultipartFile.fromBytes(
        endPhotoBytes,
        filename: 'end_ride.jpg',
        contentType: DioMediaType.parse('image/jpeg'),
      );
    }

    // تأكيد أخير: لو الـ endPhoto لسه بـ null، بنرمي خطأ محلي يفهمنا إن المشكلة من الـ UI
    if (endPhoto == null) {
      throw ApiException(
        '⚠️ فلاتر: لم يتم التقاط الصورة بنجاح، الـ Path والـ Bytes كلاهما فارغ!',
      );
    }

    // تجهيز الـ FormData بالمسميات الدقيقة
    final formData = FormData.fromMap(<String, dynamic>{
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'EndPhoto': endPhoto, // 👈 شيلنا الـ if عشان نضمن إن الـ Key يتبعت حتماً
    });

    final data = await _apiService.multipartPost(
      '/Ride/active/end',
      data: formData,
    );

    final ride = Ride.fromJson(data);
    _upsertRide(ride);
    _currentUser = await fetchCurrentUser(forceRefresh: true);
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
