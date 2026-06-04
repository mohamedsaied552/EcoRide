import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:glider/core/storage/token_storage.dart';
import 'package:glider/domain/entities/auth_result.dart';
import 'package:glider/domain/entities/signup_result.dart';
import 'package:glider/domain/entities/token.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/data/datasources/api_service.dart';

class AuthService {
  AuthService({ApiService? apiService, TokenStorage? tokenStorage})
    : _apiService = apiService ?? ApiService(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiService.post(
      '/Auth/login',
      data: <String, dynamic>{'email': email, 'password': password},
    );

    final result = AuthResult.fromJson(data);
    await _tokenStorage.saveTokens(
      accessToken: result.token.accessToken,
      refreshToken: result.token.refreshToken,
    );
    return result.user;
  }

  Future<SignupResult> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required Uint8List idFrontPhotoBytes,
    required Uint8List idBackPhotoBytes,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'IdFrontPhoto': MultipartFile.fromBytes(
        idFrontPhotoBytes,
        filename: 'id_front.jpg',
        contentType: DioMediaType.parse('image/jpeg'),
      ),
      'IdBackPhoto': MultipartFile.fromBytes(
        idBackPhotoBytes,
        filename: 'id_back.jpg',
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    });

    final data = await _apiService.multipartPost(
      '/Auth/register',
      data: formData,
    );

    final userJson = data['user'];

    final user = userJson is Map
        ? AppUser.fromJson(Map<String, dynamic>.from(userJson))
        : AppUser.fromJson(data);

    // The OpenAPI spec returns AuthResultDto { user, token } with no explicit
    // verification flag, but the API exposes a mandatory /Auth/verify-email
    // step. Default to requiring verification unless the server explicitly
    // opts out via `emailVerified: true` (or a future `requiresEmailVerification`
    // flag), or the user's accountStatus is unambiguously verified/active.
    final explicitFlag = data['requiresEmailVerification'];
    final emailVerifiedFlag = data['emailVerified'];
    final accountStatus = (user.accountStatus ?? '').toLowerCase();
    final idVerificationStatus = (user.idVerificationStatus ?? '')
        .toLowerCase();

    final bool requiresVerification;
    if (explicitFlag is bool) {
      requiresVerification = explicitFlag;
    } else if (emailVerifiedFlag is bool) {
      requiresVerification = !emailVerifiedFlag;
    } else if (_isVerifiedAccountStatus(accountStatus) &&
        _isVerifiedIdStatus(idVerificationStatus)) {
      requiresVerification = false;
    } else {
      requiresVerification = true;
    }

    // Do not persist tokens as part of the registration flow. Token
    // persistence and establishing an authenticated session should only
    // happen after an explicit verification (verifyEmail) or login.

    return SignupResult(
      user: user,
      requiresEmailVerification: requiresVerification,
    );
  }

  static bool _isVerifiedAccountStatus(String status) {
    if (status.isEmpty) return false;
    return status == 'active' || status == 'verified' || status == 'enabled';
  }

  static bool _isVerifiedIdStatus(String status) {
    if (status.isEmpty) return true;
    return status == 'verified' || status == 'approved';
  }

  Future<AppUser?> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _apiService.post(
      '/Auth/verify-email',
      data: <String, dynamic>{'email': email, 'code': code},
    );

    final tokenJson = data['token'];
    if (tokenJson is Map) {
      final token = AuthToken.fromJson(Map<String, dynamic>.from(tokenJson));
      await _tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
    }

    final userJson = data['user'];
    if (userJson is Map) {
      return AppUser.fromJson(Map<String, dynamic>.from(userJson));
    }
    return null;
  }

  Future<void> resendVerificationCode(String email) async {
    await _apiService.post(
      '/Auth/resend-otp',
      data: <String, dynamic>{'email': email},
    );
  }

  Future<AppUser> getProfile() async {
    final data = await _apiService.get('/Auth/profile');
    try {
      return AppUser.fromJson(data);
    } catch (error, stackTrace) {
      debugPrint('PARSING ERROR: AppUser.fromJson failed in getProfile');
      debugPrint('Error: $error');
      debugPrint('Response payload: $data');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<AppUser> updateProfile({
    required String fullName,
    required String phoneNumber,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    final formMap = <String, dynamic>{
      'FullName': fullName,
      'PhoneNumber': phoneNumber,
    };

    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      formMap['AvatarPhoto'] = MultipartFile.fromBytes(
        avatarBytes,
        filename: avatarFileName?.isNotEmpty == true
            ? avatarFileName!
            : 'avatar.jpg',
        contentType: DioMediaType.parse(_guessImageMimeType(avatarFileName)),
      );
    }

    final formData = FormData.fromMap(formMap);
    final data = await _apiService.multipartPut(
      '/Auth/profile',
      data: formData,
    );
    return AppUser.fromJson(data);
  }

  Future<void> updateFcmToken(String token) async {
    await _apiService.put(
      '/Auth/fcm-token',
      data: <String, dynamic>{'token': token},
    );
  }

  String _guessImageMimeType(String? fileName) {
    final lower = (fileName ?? '').toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> forgotPassword(String email) async {
    await _apiService.post(
      '/Auth/forgot-password',
      data: <String, dynamic>{'email': email},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiService.post(
      '/Auth/change-password',
      data: <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<bool> hasSavedSession() {
    return _tokenStorage.hasToken();
  }
}
