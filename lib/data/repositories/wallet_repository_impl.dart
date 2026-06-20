import 'package:glider/data/datasources/wallet_remote_data_source.dart';
import 'package:glider/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({WalletRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? WalletRemoteDataSourceImpl();

  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<String> initiateTopUp({
    required double amount,
    required String walletPhoneNumber,
  }) {
    return _remoteDataSource.initiateTopUp(
      amount: amount,
      walletPhoneNumber: walletPhoneNumber,
    );
  }
}
