import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/payment_service.dart';

enum TopUpStatus { idle, loading, success, failure }

class TopUpState {
  const TopUpState({
    this.status = TopUpStatus.idle,
    this.errorMessage,
    this.successMessage,
  });

  final TopUpStatus status;
  final String? errorMessage;
  final String? successMessage;

  TopUpState copyWith({
    TopUpStatus? status,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TopUpState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class TopUpCubit extends Cubit<TopUpState> {
  TopUpCubit({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService(),
        super(const TopUpState());

  final PaymentService _paymentService;

  Future<void> pay({
    required double amount,
    required String method,
  }) async {
    emit(
      state.copyWith(
        status: TopUpStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await _paymentService.topUp(amount: amount, method: method);
      emit(
        state.copyWith(
          status: TopUpStatus.success,
          successMessage: 'Top up successful via $method',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TopUpStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
