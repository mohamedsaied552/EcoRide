//import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  // static String get baseUrl =>
  //     kIsWeb ? 'http://localhost:5001/api' : 'http://10.0.2.2:5001/api';
  static const String baseUrl =
      'https://releasable-unrecessive-adam.ngrok-free.dev/api';
  static const String bearerPrefix = 'Bearer';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String lastSyncedFcmTokenKey = 'last_synced_fcm_token';
}
