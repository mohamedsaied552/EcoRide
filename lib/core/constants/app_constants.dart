class AppConstants {
  const AppConstants._();

  static const String baseUrl =
      'https://releasable-unrecessive-adam.ngrok-free.dev/api';

  // Base without /api, used for SignalR hubs
  static const String hubBaseUrl =
      'https://releasable-unrecessive-adam.ngrok-free.dev';

  static const String bearerPrefix = 'Bearer';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String lastSyncedFcmTokenKey = 'last_synced_fcm_token';
}
