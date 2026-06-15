import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:glider/core/storage/token_storage.dart';
import 'package:glider/domain/entities/auth_result.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/data/datasources/api_service.dart';

class AuthService {
  AuthService({ApiService? apiService, TokenStorage? tokenStorage})
    : _apiService = apiService ?? ApiService(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  /// POST /api/Auth/login — LoginDto { phoneNumber, password }
  Future<AppUser> loginWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    final data = await _apiService.post(
      '/Auth/login',
      data: <String, dynamic>{
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );

    final result = AuthResult.fromJson(data);
    await _tokenStorage.saveTokens(
      accessToken: result.token.accessToken,
      refreshToken: result.token.refreshToken,
    );
    return result.user;
  }

  /// POST /api/Auth/register — multipart fields per OpenAPI spec.
  Future<AppUser> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String firebaseToken,
    required Uint8List idFrontPhotoBytes,
    required Uint8List idBackPhotoBytes,
    required Uint8List selfiePhotoBytes,
    String email = '',
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'FullName': fullName,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'Password': password,
      'FirebaseToken': firebaseToken,
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
      'SelfiePhoto': MultipartFile.fromBytes(
        selfiePhotoBytes,
        filename: 'selfie.jpg',
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    });

    final data = await _apiService.multipartPost(
      '/Auth/register',
      data: formData,
    );

    final result = AuthResult.fromJson(data);
    await _tokenStorage.saveTokens(
      accessToken: result.token.accessToken,
      refreshToken: result.token.refreshToken,
    );
    return result.user;
  }

  /// POST /api/Auth/reset-password — ResetPasswordDto
  Future<void> resetPassword({
    required String phoneNumber,
    required String firebaseToken,
    required String newPassword,
  }) async {
    await _apiService.post(
      '/Auth/reset-password',
      data: <String, dynamic>{
        'phoneNumber': phoneNumber,
        'firebaseToken': firebaseToken,
        'newPassword': newPassword,
      },
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
