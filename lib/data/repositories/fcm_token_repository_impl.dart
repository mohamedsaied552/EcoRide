import 'package:glider/data/datasources/fcm_token_remote_data_source.dart';
import 'package:glider/domain/repositories/fcm_token_repository.dart';

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  FcmTokenRepositoryImpl({FcmTokenRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? FcmTokenRemoteDataSourceImpl();

  final FcmTokenRemoteDataSource _remoteDataSource;

  @override
  Future<void> updateFcmToken({required String userId, required String token}) {
    return _remoteDataSource.updateFcmToken(userId: userId, token: token);
  }
}
