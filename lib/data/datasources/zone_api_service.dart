import 'package:glider/data/datasources/api_service.dart';
import 'package:glider/domain/entities/paginated_result.dart';
import 'package:glider/domain/entities/zone.dart';

/// Data source for the `/api/Zone` endpoints described in `v1.json`.
class ZoneApiService {
  ZoneApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResult<Zone>> getZones({
    int pageIndex = 1,
    int pageSize = 50,
    bool? isActive,
  }) async {
    final query = <String, dynamic>{
      'PageIndex': pageIndex,
      'PageSize': pageSize,
    };
    if (isActive != null) {
      query['IsActive'] = isActive;
    }

    final data = await _apiService.get('/Zone', queryParameters: query);
    return PaginatedResult.fromJson(data, Zone.fromJson);
  }

  Future<Zone> getZoneById(String id) async {
    final data = await _apiService.get('/Zone/$id');
    return Zone.fromJson(data);
  }

  Future<List<Zone>> getZonesAtLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiService.getList(
      '/Zone/location',
      queryParameters: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return response
        .map((item) => Zone.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<Zone> createZone({
    required String name,
    required String type,
    required double? speedLimitKmH,
    required List<Map<String, double>> boundary,
  }) async {
    final data = await _apiService.post(
      '/Zone',
      data: <String, dynamic>{
        'name': name,
        'type': type,
        'speedLimitKmH': speedLimitKmH,
        'boundary': boundary,
      },
    );
    return Zone.fromJson(data);
  }

  Future<Zone> updateZone({
    required String id,
    required String name,
    required String type,
    required double? speedLimitKmH,
    required bool isActive,
    required List<Map<String, double>> boundary,
  }) async {
    final data = await _apiService.put(
      '/Zone/$id',
      data: <String, dynamic>{
        'name': name,
        'type': type,
        'speedLimitKmH': speedLimitKmH,
        'isActive': isActive,
        'boundary': boundary,
      },
    );
    return Zone.fromJson(data);
  }

  Future<bool> deleteZone(String id) async {
    final response = await _apiService.delete('/Zone/$id');
    if (response is bool) return response;
    if (response is Map && response['success'] is bool) {
      return response['success'] as bool;
    }
    // The API spec returns a bare boolean; treat any 200 as success.
    return true;
  }
}
