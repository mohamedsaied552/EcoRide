import 'package:flutter_test/flutter_test.dart';
import 'package:glider/data/datasources/fcm_token_remote_data_source.dart';
import 'package:glider/data/datasources/api_client.dart';

class FakeApiClient implements ApiClient {
  String? lastPutPath;
  Map<String, dynamic>? lastPutBody;

  @override
  Future get(String path) async => null;

  @override
  Future put(String path, Map<String, dynamic> body) async {
    lastPutPath = path;
    lastPutBody = body;
    return null;
  }
}

void main() {
  test('updateFcmToken calls backend PUT with token', () async {
    final fake = FakeApiClient();
    final ds = FcmTokenRemoteDataSourceImpl(apiClient: fake);

    await ds.updateFcmToken(userId: 'u1', token: 'tok-123');

    expect(fake.lastPutPath, '/api/Auth/fcm-token');
    expect(fake.lastPutBody, isNotNull);
    expect(fake.lastPutBody!['token'], 'tok-123');
  });
}
