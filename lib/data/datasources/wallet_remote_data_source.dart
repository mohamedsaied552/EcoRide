import 'package:glider/data/datasources/api_service.dart';

abstract class WalletRemoteDataSource {
  Future<String> initiateTopUp({
    required double amount,
    required String walletPhoneNumber,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  @override
  Future<String> initiateTopUp({
    required double amount,
    required String walletPhoneNumber,
  }) async {
    final response = await _apiService.post(
      '/Wallet/top-up',
      data: <String, dynamic>{
        'amount': amount,
        'walletPhoneNumber': walletPhoneNumber,
      },
    );

    final redirectUrl = _extractRedirectUrl(response);
    if (redirectUrl.isEmpty) {
      throw StateError('Payment gateway returned an empty redirect URL.');
    }
    if (!_isAbsoluteUrl(redirectUrl)) {
      throw StateError(
        'Payment gateway returned a non-absolute redirect URL: $redirectUrl',
      );
    }

    return redirectUrl;
  }

  String _extractRedirectUrl(Map<String, dynamic> response) {
    final rawRedirect =
        response['redirectUrl'] ??
        response['redirect_url'] ??
        (response['data'] is Map<String, dynamic>
            ? response['data']['redirectUrl'] ??
                  response['data']['redirect_url']
            : null);
    return rawRedirect?.toString().trim() ?? '';
  }

  bool _isAbsoluteUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
