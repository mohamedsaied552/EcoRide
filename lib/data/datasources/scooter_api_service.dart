import 'package:zakzouka/data/datasources/api_service.dart';
import 'package:zakzouka/domain/entities/live_map_bundle.dart';
import 'package:zakzouka/domain/entities/paginated_result.dart';
import 'package:zakzouka/domain/entities/scooter.dart';
import 'package:zakzouka/domain/entities/scooter_status_info.dart';

class ScooterApiService {
  ScooterApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<Scooter>> getScooters({
    int pageIndex = 1,
    int pageSize = 50,
  }) async {
    final page = await getScootersPaginated(
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return page.data;
  }

  Future<PaginatedResult<Scooter>> getScootersPaginated({
    int pageIndex = 1,
    int pageSize = 50,
  }) async {
    final data = await _apiService.get(
      '/Scooter',
      queryParameters: <String, dynamic>{
        'PageIndex': pageIndex,
        'PageSize': pageSize,
      },
    );
    return PaginatedResult.fromJson(data, Scooter.fromJson);
  }

  Future<LiveMapBundle> getLiveMap() async {
    final data = await _apiService.get('/Scooter/live-map');
    return LiveMapBundle.fromJson(data);
  }

  Future<ScooterStatusInfo> getScooterStatus(String serialNumber) async {
    final data = await _apiService.get('/Scooter/$serialNumber/status');
    return ScooterStatusInfo.fromJson(data);
  }

  Future<Scooter> getScooterById(String id) async {
    final data = await _apiService.get('/Scooter/$id');
    return Scooter.fromJson(data);
  }

  Future<Scooter> createScooter({
    required String serialNumber,
    required String modelId,
  }) async {
    final data = await _apiService.post(
      '/Scooter',
      data: <String, dynamic>{'serialNumber': serialNumber, 'modelId': modelId},
    );
    return Scooter.fromJson(data);
  }

  Future<Scooter> updateScooter({
    required String id,
    required String status,
  }) async {
    final data = await _apiService.put(
      '/Scooter/$id',
      data: <String, dynamic>{'status': status},
    );
    return Scooter.fromJson(data);
  }

  Future<bool> deleteScooter(String id) async {
    final response = await _apiService.delete('/Scooter/$id');
    if (response is bool) return response;
    if (response is Map && response['success'] is bool) {
      return response['success'] as bool;
    }
    return true;
  }
}
