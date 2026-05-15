import 'package:flutter_bloc/flutter_bloc.dart';

enum LoginStatus { idle, loading, failure }

class LoginState {
  const LoginState({
    this.status = LoginStatus.idle,
    this.isPasswordObscured = true,
    this.errorMessage,
  });

  final LoginStatus status;
  final bool isPasswordObscured;
  final String? errorMessage;

  LoginState copyWith({
    LoginStatus? status,
    bool? isPasswordObscured,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  void togglePasswordVisibility() {
    emit(
      state.copyWith(isPasswordObscured: !state.isPasswordObscured),
    );
  }

  void setLoading() {
    emit(state.copyWith(status: LoginStatus.loading, clearError: true));
  }

  void setIdle() {
    emit(state.copyWith(status: LoginStatus.idle, clearError: true));
  }

  void setFailure(String message) {
    emit(
      state.copyWith(
        status: LoginStatus.failure,
        errorMessage: message,
      ),
    );
  }
}
