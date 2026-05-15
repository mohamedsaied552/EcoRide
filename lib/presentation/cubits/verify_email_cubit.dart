
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/domain/entities/user.dart';
import '../../data/repositories/backend_service.dart';

enum VerifyEmailStatus { idle, verifying, resending, success, failure }

enum VerifyEmailError { none, invalidCode, expiredCode, network, unknown }

class VerifyEmailState {
  const VerifyEmailState({
    required this.email,
    this.code = '',
    this.status = VerifyEmailStatus.idle,
    this.errorType = VerifyEmailError.none,
    this.errorMessage,
    this.verifiedUser,
    this.resendCooldownSeconds = 0,
    this.lastResentAt,
  });

  final String email;
  final String code;
  final VerifyEmailStatus status;
  final VerifyEmailError errorType;
  final String? errorMessage;
  final AppUser? verifiedUser;
  final int resendCooldownSeconds;
  final DateTime? lastResentAt;

  bool get canResend =>
      status != VerifyEmailStatus.resending && resendCooldownSeconds == 0;

  VerifyEmailState copyWith({
    String? email,
    String? code,
    VerifyEmailStatus? status,
    VerifyEmailError? errorType,
    String? errorMessage,
    AppUser? verifiedUser,
    int? resendCooldownSeconds,
    DateTime? lastResentAt,
    bool clearError = false,
    bool clearVerifiedUser = false,
  }) {
    return VerifyEmailState(
      email: email ?? this.email,
      code: code ?? this.code,
      status: status ?? this.status,
      errorType: clearError ? VerifyEmailError.none : (errorType ?? this.errorType),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      verifiedUser:
          clearVerifiedUser ? null : (verifiedUser ?? this.verifiedUser),
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      lastResentAt: lastResentAt ?? this.lastResentAt,
    );
  }
}

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit({
    required String email,
    BackendService? backendService,
  })  : _backendService = backendService ?? BackendService(),
        super(VerifyEmailState(email: email));

  final BackendService _backendService;
  Timer? _cooldownTimer;

  static const int _resendCooldownSeconds = 45;

  void updateCode(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9]'), '');
    emit(state.copyWith(code: sanitized, clearError: true));
  }

  Future<void> submit() async {
    final trimmed = state.code.trim();
    if (trimmed.length != 4 && trimmed.length != 6) {
      emit(
        state.copyWith(
          status: VerifyEmailStatus.failure,
          errorType: VerifyEmailError.invalidCode,
          errorMessage: 'Enter the 6-digit code sent to your email.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: VerifyEmailStatus.verifying, clearError: true));

    try {
      final user = await _backendService.verifyEmail(
        email: state.email,
        code: trimmed,
      );
      emit(state.copyWith(status: VerifyEmailStatus.success, verifiedUser: user));
    } on ApiException catch (error) {
      final classified = _classifyError(error);
      emit(
        state.copyWith(
          status: VerifyEmailStatus.failure,
          errorType: classified,
          errorMessage: _messageFor(classified, fallback: error.message),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: VerifyEmailStatus.failure,
          errorType: VerifyEmailError.unknown,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> resendCode() async {
    if (!state.canResend) return;

    emit(state.copyWith(status: VerifyEmailStatus.resending, clearError: true));

    try {
      await _backendService.resendOtp(state.email);
      emit(
        state.copyWith(
          status: VerifyEmailStatus.idle,
          lastResentAt: DateTime.now(),
          resendCooldownSeconds: _resendCooldownSeconds,
          clearError: true,
        ),
      );
      _startCooldown();
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: VerifyEmailStatus.failure,
          errorType: VerifyEmailError.network,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: VerifyEmailStatus.failure,
          errorType: VerifyEmailError.unknown,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _startCooldown() {
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

  VerifyEmailError _classifyError(ApiException error) {
    final message = error.message.toLowerCase();
    if (message.contains('expire')) {
      return VerifyEmailError.expiredCode;
    }
    if (message.contains('invalid') ||
        message.contains('incorrect') ||
        message.contains('wrong') ||
        error.statusCode == 400 ||
        error.statusCode == 422) {
      return VerifyEmailError.invalidCode;
    }
    if (error.statusCode == null) {
      return VerifyEmailError.network;
    }
    return VerifyEmailError.unknown;
  }

  String _messageFor(VerifyEmailError type, {required String fallback}) {
    switch (type) {
      case VerifyEmailError.invalidCode:
        return 'That code is invalid. Please check and try again.';
      case VerifyEmailError.expiredCode:
        return 'This code has expired. Tap "Resend code" to get a new one.';
      case VerifyEmailError.network:
        return 'Network error. Check your connection and try again.';
      case VerifyEmailError.unknown:
      case VerifyEmailError.none:
        return fallback;
    }
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}

