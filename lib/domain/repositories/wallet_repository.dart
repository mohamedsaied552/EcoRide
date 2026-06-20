abstract class WalletRepository {
  /// Initiates a top-up request and returns the Paymob redirect URL.
  Future<String> initiateTopUp({
    required double amount,
    required String walletPhoneNumber,
  });
}
