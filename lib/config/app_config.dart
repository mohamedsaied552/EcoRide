class AppConfig {
  const AppConfig._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;
}
