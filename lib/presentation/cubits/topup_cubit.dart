import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakzouka/data/repositories/wallet_repository_impl.dart';
import 'package:zakzouka/domain/usecases/initiate_top_up_use_case.dart';

enum TopUpStatus { idle, loading, success, failure }

class TopUpState {
  const TopUpState({
    this.status = TopUpStatus.idle,
    this.errorMessage,
    this.redirectUrl,
  });

  final TopUpStatus status;
  final String? errorMessage;
  final String? redirectUrl;

  TopUpState copyWith({
    TopUpStatus? status,
    String? errorMessage,
    String? redirectUrl,
    bool clearError = false,
    bool clearRedirectUrl = false,
  }) {
    return TopUpState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      redirectUrl: clearRedirectUrl ? null : (redirectUrl ?? this.redirectUrl),
    );
  }
}

class TopUpCubit extends Cubit<TopUpState> {
  TopUpCubit({InitiateTopUpUseCase? initiateTopUpUseCase})
    : _initiateTopUpUseCase =
          initiateTopUpUseCase ??
          InitiateTopUpUseCase(repository: WalletRepositoryImpl()),
      super(const TopUpState());

  final InitiateTopUpUseCase _initiateTopUpUseCase;

  Future<void> pay({
    required double amount,
    required String walletPhoneNumber,
  }) async {
    emit(
      state.copyWith(
        status: TopUpStatus.loading,
        clearError: true,
        clearRedirectUrl: true,
      ),
    );

    try {
      final redirectUrl = await _initiateTopUpUseCase.execute(
        amount: amount,
        walletPhoneNumber: walletPhoneNumber,
      );

      if (redirectUrl.isEmpty) {
        throw StateError('Payment gateway returned an empty redirect URL.');
      }
      final uri = Uri.tryParse(redirectUrl);
      if (uri == null ||
          !uri.hasScheme ||
          !(uri.scheme == 'http' || uri.scheme == 'https')) {
        throw StateError(
          'Payment gateway returned an invalid redirect URL: $redirectUrl',
        );
      }

      emit(
        state.copyWith(
          status: TopUpStatus.success,
          redirectUrl: redirectUrl,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TopUpStatus.failure,
          errorMessage: error.toString(),
          clearRedirectUrl: true,
        ),
      );
    }
  }
}
