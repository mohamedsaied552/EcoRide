import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/data/datasources/firebase_auth_service.dart';
import 'package:glider/data/repositories/backend_service.dart';
import 'package:glider/domain/entities/user.dart';

enum VerifyOtpFlow { registration, login, forgotPassword }

enum VerifyOtpStatus { idle, verifying, syncing, resending, success, failure }

enum VerifyOtpError { none, invalidCode, backendSync, network, unknown }

class VerifyOtpState {
  const VerifyOtpState({
    required this.phoneNumber,
    this.flow = VerifyOtpFlow.registration,
    this.password = '',
    this.verificationId = '',
    this.forceResendingToken,
    this.status = VerifyOtpStatus.idle,
    this.errorType = VerifyOtpError.none,
    this.errorMessage,
    this.firebaseToken,
    this.verifiedUser,
    this.resendCooldownSeconds = 60,
    this.lastResentAt,
  });

  final String phoneNumber;
  final VerifyOtpFlow flow;
  final String password;
  final String verificationId;
  final int? forceResendingToken;
  final VerifyOtpStatus status;
  final VerifyOtpError errorType;
  final String? errorMessage;
  final String? firebaseToken;
  final AppUser? verifiedUser;
  final int resendCooldownSeconds;
  final DateTime? lastResentAt;

  bool get canResend =>
      status != VerifyOtpStatus.resending &&
      status != VerifyOtpStatus.syncing &&
      status != VerifyOtpStatus.verifying &&
      resendCooldownSeconds == 0;

  VerifyOtpState copyWith({
    String? phoneNumber,
    VerifyOtpFlow? flow,
    String? password,
    String? verificationId,
    int? forceResendingToken,
    VerifyOtpStatus? status,
    VerifyOtpError? errorType,
    String? errorMessage,
    String? firebaseToken,
    AppUser? verifiedUser,
    int? resendCooldownSeconds,
    DateTime? lastResentAt,
    bool clearError = false,
    bool clearVerifiedUser = false,
    bool clearForceResendingToken = false,
  }) {
    return VerifyOtpState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      flow: flow ?? this.flow,
      password: password ?? this.password,
      verificationId: verificationId ?? this.verificationId,
      forceResendingToken: clearForceResendingToken
          ? null
          : (forceResendingToken ?? this.forceResendingToken),
      status: status ?? this.status,
      errorType: clearError ? VerifyOtpError.none : (errorType ?? this.errorType),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      firebaseToken: firebaseToken ?? this.firebaseToken,
      verifiedUser:
          clearVerifiedUser ? null : (verifiedUser ?? this.verifiedUser),
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      lastResentAt: lastResentAt ?? this.lastResentAt,
    );
  }
}

class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  VerifyOtpCubit({
    required String phoneNumber,
    required String verificationId,
    VerifyOtpFlow flow = VerifyOtpFlow.registration,
    String password = '',
    int? forceResendingToken,
    FirebaseAuthService? firebaseAuthService,
    BackendService? backendService,
  }) : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService(),
       _backendService = backendService ?? BackendService(),
       super(
         VerifyOtpState(
           phoneNumber: phoneNumber,
           flow: flow,
           password: password,
           verificationId: verificationId,
           forceResendingToken: forceResendingToken,
           resendCooldownSeconds: _initialCooldownSeconds,
         ),
       ) {
    _startInitialCooldown();
  }

  final FirebaseAuthService _firebaseAuthService;
  final BackendService _backendService;
  Timer? _cooldownTimer;

  static const int _initialCooldownSeconds = 60;
  static const int _resendCooldownSeconds = 60;

  void _startInitialCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendCooldownSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        emit(state.copyWith(resendCooldownSeconds: 0));
      } else {
        emit(state.copyWith(resendCooldownSeconds: next));
      }
    });
  }

  Future<void> verifyOtp(String smsCode) async {
    final code = smsCode.trim();
    if (code.length < 4) {
      emit(
        state.copyWith(
          status: VerifyOtpStatus.failure,
          errorType: VerifyOtpError.invalidCode,
          errorMessage: 'invalidCode',
        ),
      );
      return;
    }

    if (state.verificationId.isEmpty) {
      emit(
        state.copyWith(
          status: VerifyOtpStatus.failure,
          errorType: VerifyOtpError.invalidCode,
          errorMessage: 'missingVerificationId',
        ),
      );
      return;
    }

    emit(state.copyWith(status: VerifyOtpStatus.verifying, clearError: true));

    try {
      final idToken = await _firebaseAuthService.signInWithCredential(
        code,
        verificationId: state.verificationId,
      );

      if (state.flow == VerifyOtpFlow.registration ||
          state.flow == VerifyOtpFlow.forgotPassword) {
        emit(
          state.copyWith(
            status: VerifyOtpStatus.success,
            firebaseToken: idToken,
          ),
        );
        return;
      }

      emit(state.copyWith(status: VerifyOtpStatus.syncing, clearError: true));

      final user = await _backendService.loginWithPhone(
        phoneNumber: state.phoneNumber,
        password: state.password,
      );

      emit(
        state.copyWith(
          status: VerifyOtpStatus.success,
          firebaseToken: idToken,
          verifiedUser: user,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: VerifyOtpStatus.failure,
          errorType: VerifyOtpError.backendSync,
          errorMessage: error.message,
        ),
      );
    } on FirebaseAuthFailure catch (error) {
      emit(
        state.copyWith(
          status: VerifyOtpStatus.failure,
          errorType: _classifyFailure(error),
          errorMessage: error.code.name,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: VerifyOtpStatus.failure,
          errorType: VerifyOtpError.unknown,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> resendOtp() async {
    if (!state.canResend) return;

    emit(state.copyWith(status: VerifyOtpStatus.resending, clearError: true));

    try {
      final session = await _firebaseAuthService.verifyPhoneNumber(
        state.phoneNumber,
        forceResendingToken: state.forceResendingToken,
      );
      emit(
        state.copyWith(
          status: VerifyOtpStatus.idle,
          verificationId: session.verificationId,
          forceResendingToken: session.forceResendingToken,
          lastResentAt: DateTime.now(),
          resendCooldownSeconds: _resendCooldownSeconds,
          clearError: true,
        ),
      );
      _startInitialCooldown();
    } on FirebaseAuthFailure catch (error) {
      emit(
        state.copyWith(
          status: VerifyOtpStatus.failure,
          errorType: _classifyFailure(error),
          errorMessage: error.code.name,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: VerifyOtpStatus.failure,
          errorType: VerifyOtpError.unknown,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  VerifyOtpError _classifyFailure(FirebaseAuthFailure error) {
    switch (error.code) {
      case FirebaseAuthErrorCode.network:
        return VerifyOtpError.network;
      case FirebaseAuthErrorCode.invalidVerificationCode:
      case FirebaseAuthErrorCode.sessionExpired:
      case FirebaseAuthErrorCode.missingVerificationId:
        return VerifyOtpError.invalidCode;
      default:
        return VerifyOtpError.unknown;
    }
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
