import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class TokenStorage {
  TokenStorage._internal();

  static final TokenStorage _instance = TokenStorage._internal();

  factory TokenStorage() => _instance;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instanceAsync async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await _instanceAsync;
    await prefs.setString(AppConstants.accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await _instanceAsync;
    return prefs.getString(AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _instanceAsync;
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> clear() async {
    final prefs = await _instanceAsync;
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
  }
}
