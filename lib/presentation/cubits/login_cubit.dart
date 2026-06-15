import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/data/datasources/firebase_auth_service.dart';
import 'package:glider/presentation/utils/phone_utils.dart';

enum LoginStatus { idle, loading, otpSent, failure }

class LoginState {
  const LoginState({
    this.status = LoginStatus.idle,
    this.country = CountryDialCode.egypt,
    this.localPhoneNumber = '',
    this.password = '',
    this.isPasswordObscured = true,
    this.verificationSession,
    this.errorMessage,
  });

  final LoginStatus status;
  final CountryDialCode country;
  final String localPhoneNumber;
  final String password;
  final bool isPasswordObscured;
  final PhoneVerificationSession? verificationSession;
  final String? errorMessage;

  String get internationalPhoneNumber => PhoneUtils.toInternational(
    dialCode: country.dialCode,
    localNumber: localPhoneNumber,
  );

  LoginState copyWith({
    LoginStatus? status,
    CountryDialCode? country,
    String? localPhoneNumber,
    String? password,
    bool? isPasswordObscured,
    PhoneVerificationSession? verificationSession,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      country: country ?? this.country,
      localPhoneNumber: localPhoneNumber ?? this.localPhoneNumber,
      password: password ?? this.password,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      verificationSession: verificationSession ?? this.verificationSession,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({FirebaseAuthService? firebaseAuthService})
    : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService(),
      super(const LoginState());

  final FirebaseAuthService _firebaseAuthService;

  void updateCountry(CountryDialCode country) {
    emit(state.copyWith(country: country, clearError: true));
  }

  void updateLocalPhoneNumber(String value) {
    emit(state.copyWith(localPhoneNumber: value, clearError: true));
  }

  void updatePassword(String value) {
    emit(state.copyWith(password: value, clearError: true));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  void setIdle() {
    emit(state.copyWith(status: LoginStatus.idle, clearError: true));
  }

  String? validateLocalPhone() {
    if (state.country.dialCode == CountryDialCode.egypt.dialCode) {
      return PhoneUtils.validateEgyptLocalNumber(state.localPhoneNumber);
    }
    final digits = PhoneUtils.digitsOnly(state.localPhoneNumber);
    if (digits.length < state.country.localDigits) {
      return 'invalidLength';
    }
    return null;
  }

  Future<bool> sendOtp() async {
    final phoneError = validateLocalPhone();
    if (phoneError != null) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: phoneError,
        ),
      );
      return false;
    }

    if (state.password.length < 6) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'weakPassword',
        ),
      );
      return false;
    }

    emit(state.copyWith(status: LoginStatus.loading, clearError: true));

    try {
      final session = await _firebaseAuthService.verifyPhoneNumber(
        state.internationalPhoneNumber,
      );
      emit(
        state.copyWith(
          status: LoginStatus.otpSent,
          verificationSession: session,
          clearError: true,
        ),
      );
      return true;
    } on FirebaseAuthFailure catch (error) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: error.code.name,
        ),
      );
      return false;
    } catch (error) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }
}
