import 'package:zakzouka/domain/entities/ride.dart';
import 'package:zakzouka/data/repositories/backend_service.dart';
import 'package:zakzouka/data/datasources/api_client.dart';
import 'package:zakzouka/data/mappers/active_ride_mapper.dart';

/// Data source that uses the project's HTTP backend (via BackendService)
/// to check for an active ride for the current user.
abstract class RideRemoteDataSource {
  Future<Ride?> checkActiveRide({required String userId});
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  RideRemoteDataSourceImpl({BackendService? backend, ApiClient? apiClient})
    : _apiClient = apiClient ?? BackendApiClient(backend: backend);
  final ApiClient _apiClient;

  @override
  Future<Ride?> checkActiveRide({required String userId}) async {
    try {
      // Use the adapter to call the REST endpoint and receive the raw DTO map.
      final raw = await _apiClient.get('/api/Ride/active');
      if (raw == null) return null;

      if (raw is Map<String, dynamic>) {
        return mapActiveRideDtoToRide(raw);
      }

      // If adapter returned a Ride serialized map, try to convert.
      if (raw is Ride) return raw;
      if (raw is Map) {
        return mapActiveRideDtoToRide(Map<String, dynamic>.from(raw));
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }
}
