import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ride.dart';
import '../models/scooter.dart';
import '../models/user.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackendService {
  BackendService._internal() {
    _seedLocalData();
  }

  static final BackendService _instance = BackendService._internal();

  factory BackendService() => _instance;

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000'
        : 'http://localhost:5000';
  }

  final http.Client _client = http.Client();

  String? _accessToken;
  AppUser? _currentUser;
  late List<Scooter> _scooters;
  late List<Ride> _rides;

  bool get isLoggedIn => _accessToken != null;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool authenticated = false}) {
    return {
      'Content-Type': 'application/json',
      if (authenticated && _accessToken != null)
        'Authorization': 'Bearer $_accessToken',
    };
  }

  String _readError(http.Response response) {
    if (response.body.isEmpty) {
      return 'Request failed with status ${response.statusCode}.';
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'] ?? body['title'] ?? body['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      return response.body;
    }

    return response.body;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    bool authenticated = false,
  }) async {
    final response = await _sendRequest(
      () => _client.post(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_readError(response));
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> payload, {
    bool authenticated = false,
  }) async {
    final response = await _sendRequest(
      () => _client.put(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_readError(response));
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool authenticated = false,
  }) async {
    final response = await _sendRequest(
      () => _client.get(
        _uri(path),
        headers: _headers(authenticated: authenticated),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_readError(response));
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on Exception catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('failed host lookup') ||
          message.contains('connection refused') ||
          message.contains('failed to fetch') ||
          message.contains('clientexception')) {
        throw ApiException(
          'Could not reach the server at $baseUrl. Check your API base URL and make sure the backend is running.',
        );
      }
      throw ApiException('Unexpected network error: $error');
    }
  }

  void _seedLocalData() {
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
    ];
  }

  AppUser _mapApiUser(Map<String, dynamic> json) {
    return AppUser.fromJson(json).copyWith(
      ridesCount: _rides.length,
      rating: _currentUser?.rating ?? 4.9,
      walletBalance: _currentUser?.walletBalance ?? 0,
    );
  }

  void _storeAuthResult(Map<String, dynamic> data) {
    final userJson = data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final tokenJson =
        data['token'] as Map<String, dynamic>? ?? <String, dynamic>{};

    _accessToken = tokenJson['accessToken'] as String?;
    _currentUser = _mapApiUser(userJson);
  }

  Future<bool> login(String email, String password) async {
    final data = await _post('/api/Auth/login', {
      'email': email,
      'password': password,
    });
    _storeAuthResult(data);
    return true;
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String idPhotoUrl,
  }) async {
    final data = await _post('/api/Auth/register', {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'idPhotoUrl': idPhotoUrl,
    });
    _storeAuthResult(data);
    return true;
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _post(
      '/api/Auth/verify-email',
      {
        'email': email,
        'code': code,
      },
      authenticated: true,
    );
  }

  Future<void> resendOtp(String email) async {
    await _post('/api/Auth/resend-otp', {'email': email}, authenticated: true);
  }

  Future<void> forgotPassword(String email) async {
    await _post('/api/Auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _post('/api/Auth/reset-password', {
      'email': email,
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<AppUser> fetchCurrentUser() async {
    if (_accessToken == null) {
      if (_currentUser != null) {
        return _currentUser!;
      }
      throw ApiException('Please log in first.');
    }

    final data = await _get('/api/Auth/profile', authenticated: true);
    _currentUser = _mapApiUser(data).copyWith(
      walletBalance: _currentUser?.walletBalance ?? 0,
    );
    return _currentUser!;
  }

  Future<AppUser> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    final data = await _put(
      '/api/Auth/profile',
      {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
      },
      authenticated: true,
    );
    _currentUser = _mapApiUser(data).copyWith(
      walletBalance: _currentUser?.walletBalance ?? 0,
    );
    return _currentUser!;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _post(
      '/api/Auth/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      authenticated: true,
    );
  }

  Future<void> logout() async {
    _accessToken = null;
    _currentUser = null;
  }

  Future<List<Scooter>> fetchNearbyScooters() async {
    return List<Scooter>.unmodifiable(_scooters);
  }

  Future<List<Ride>> fetchRideHistory() async {
    return List<Ride>.unmodifiable(_rides);
  }

  Future<AppUser> topUpWallet(double amount) async {
    if (amount <= 0) {
      return fetchCurrentUser();
    }

    final user = await fetchCurrentUser();
    _currentUser = user.copyWith(walletBalance: user.walletBalance + amount);
    return _currentUser!;
  }

  Future<AppUser> chargeForRide(double amount) async {
    final user = await fetchCurrentUser();
    final newBalance = (user.walletBalance - amount).clamp(0.0, 1000000.0);
    _currentUser = user.copyWith(walletBalance: newBalance);
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
    _rides = [ride, ..._rides];
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
}
