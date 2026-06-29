class AppConstants {
  const AppConstants._();

  static const String baseUrl =
      'https://jhfgw7td-5001.uks1.devtunnels.ms/api';

  // Base without /api, used for SignalR hubs
  static const String hubBaseUrl =
      'https://jhfgw7td-5001.uks1.devtunnels.ms';

  static const String bearerPrefix = 'Bearer';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String lastSyncedFcmTokenKey = 'last_synced_fcm_token';
}
