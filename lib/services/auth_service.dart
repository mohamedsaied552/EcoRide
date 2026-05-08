import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/storage/token_storage.dart';
import '../models/auth_result.dart';
import '../models/user.dart';
import 'api_service.dart';

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

  Future<AppUser> register({
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

    final result = AuthResult.fromJson(data);
    await _tokenStorage.saveTokens(
      accessToken: result.token.accessToken,
      refreshToken: result.token.refreshToken,
    );
    return result.user;
  }

  Future<AppUser> getProfile() async {
    final data = await _apiService.get('/Auth/profile');
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    final data = await _apiService.put(
      '/Auth/profile',
      data: <String, dynamic>{
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
      },
    );
    return AppUser.fromJson(data);
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
