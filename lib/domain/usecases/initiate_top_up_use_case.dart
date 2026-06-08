import 'package:glider/domain/repositories/wallet_repository.dart';

class InitiateTopUpUseCase {
  InitiateTopUpUseCase({required WalletRepository repository})
      : _repository = repository;

  final WalletRepository _repository;

  Future<String> execute({
    required double amount,
    required String walletPhoneNumber,
  }) {
    return _repository.initiateTopUp(
      amount: amount,
      walletPhoneNumber: walletPhoneNumber,
    );
  }
}
