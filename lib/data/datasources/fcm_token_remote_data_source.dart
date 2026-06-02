import 'package:glider/data/repositories/backend_service.dart';
import 'package:glider/data/datasources/api_client.dart';

abstract class FcmTokenRemoteDataSource {
  Future<void> updateFcmToken({required String userId, required String token});
}

class FcmTokenRemoteDataSourceImpl implements FcmTokenRemoteDataSource {
  FcmTokenRemoteDataSourceImpl({BackendService? backend, ApiClient? apiClient})
    : _apiClient = apiClient ?? BackendApiClient(backend: backend);
  final ApiClient _apiClient;

  @override
  Future<void> updateFcmToken({
    required String userId,
    required String token,
  }) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('FCM token must not be empty');
    }

    // Use the ApiClient to perform PUT /api/Auth/fcm-token with body { token }
    await _apiClient.put('/api/Auth/fcm-token', <String, dynamic>{
      'token': token,
    });
  }
}
