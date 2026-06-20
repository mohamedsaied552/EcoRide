import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class FcmTokenStorage {
  FcmTokenStorage._internal();

  static final FcmTokenStorage _instance = FcmTokenStorage._internal();

  factory FcmTokenStorage() => _instance;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instanceAsync async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getLastSyncedToken() async {
    final prefs = await _instanceAsync;
    return prefs.getString(AppConstants.lastSyncedFcmTokenKey);
  }

  Future<void> saveLastSyncedToken(String token) async {
    final prefs = await _instanceAsync;
    await prefs.setString(AppConstants.lastSyncedFcmTokenKey, token.trim());
  }

  Future<void> clearLastSyncedToken() async {
    final prefs = await _instanceAsync;
    await prefs.remove(AppConstants.lastSyncedFcmTokenKey);
  }
}
