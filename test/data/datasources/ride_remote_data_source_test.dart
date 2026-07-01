import 'package:flutter_test/flutter_test.dart';
import 'package:zakzouka/data/datasources/ride_remote_data_source.dart';
import 'package:zakzouka/data/datasources/api_client.dart';

class FakeApiClient implements ApiClient {
  FakeApiClient({this.raw});

  final dynamic raw;

  String? lastGetPath;
  @override
  Future<dynamic> get(String path) async {
    lastGetPath = path;
    return raw;
  }

  String? lastPutPath;
  Map<String, dynamic>? lastPutBody;
  @override
  Future put(String path, Map<String, dynamic> body) async {
    lastPutPath = path;
    lastPutBody = body;
    return null;
  }
}

void main() {
  test('checkActiveRide maps ActiveRideResponseDto to Ride', () async {
    final startedAt = DateTime.now().toIso8601String();
    final dto = {
      'rideId': '1111-2222',
      'scooterSerialNumber': 'SC-123',
      'startTime': startedAt,
      'currentDurationMinutes': 5.5,
      'currentCost': 12.34,
    };

    final fake = FakeApiClient(raw: dto);
    final ds = RideRemoteDataSourceImpl(apiClient: fake);

    final ride = await ds.checkActiveRide(userId: 'user-1');

    expect(fake.lastGetPath, '/api/Ride/active');
    expect(ride, isNotNull);
    expect(ride!.scooterCode, 'SC-123');
    expect(ride.cost, 12.34);
    expect(ride.startedAt.toIso8601String(), startedAt);
  });
}
