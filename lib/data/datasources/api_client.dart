import 'package:zakzouka/data/repositories/backend_service.dart';

/// Minimal API client abstraction for data sources to allow easy mocking
/// in tests without depending on BackendService's concrete implementation.
abstract class ApiClient {
  Future<dynamic> get(String path);
  Future<dynamic> put(String path, Map<String, dynamic> body);
}

class BackendApiClient implements ApiClient {
  BackendApiClient({BackendService? backend})
    : _backend = backend ?? BackendService();

  final BackendService _backend;

  @override
  Future<dynamic> get(String path) async {
    // Normalize path variants
    final normalized = path.startsWith('/api')
        ? path.replaceFirst('/api', '')
        : path;
    if (normalized.endsWith('/Ride/active') ||
        normalized.endsWith('/Ride/active')) {
      final ride = await _backend.fetchActiveRide();
      return ride?.toJson();
    }

    throw UnsupportedError('GET $path is not supported by BackendApiClient');
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final normalized = path.startsWith('/api')
        ? path.replaceFirst('/api', '')
        : path;
    if (normalized.endsWith('/Auth/fcm-token')) {
      final token = body['token'] as String? ?? '';
      return _backend.updateFcmToken(token);
    }

    throw UnsupportedError('PUT $path is not supported by BackendApiClient');
  }
}
