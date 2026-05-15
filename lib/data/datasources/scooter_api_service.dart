import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/data/datasources/api_service.dart';

class ScooterApiService {
  ScooterApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<Scooter>> getScooters({
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

    final items = List<Map<String, dynamic>>.from(
      (data['data'] as List<dynamic>? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    return items.map(Scooter.fromJson).toList(growable: false);
  }
}
