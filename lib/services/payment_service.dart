import 'backend_service.dart';

class PaymentService {
  /// Simulates a successful payment, then updates the demo wallet balance.
  Future<bool> topUp({required double amount, required String method}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await BackendService().topUpWallet(amount);
    return true;
  }

  /// In a real app this would call a backend; here it is a no-op.
  Future<bool> chargeRide({required double amount}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
