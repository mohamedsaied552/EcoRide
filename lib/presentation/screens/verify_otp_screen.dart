import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:zakzouka/data/services/ride_hub_service.dart';

import 'package:zakzouka/l10n/app_localizations.dart';
import 'package:zakzouka/presentation/cubits/user_cubit.dart';
import 'package:zakzouka/presentation/cubits/verify_otp_cubit.dart';
import 'package:zakzouka/presentation/cubits/wallet_cubit.dart';
import 'package:zakzouka/core/notifications/notification_manager.dart';
import 'package:zakzouka/data/datasources/firebase_auth_service.dart';
import 'package:zakzouka/presentation/utils/firebase_auth_error_utils.dart';
import 'package:zakzouka/presentation/screens/reset_password_screen.dart';
import 'map_screen.dart';

String localizeVerifyOtpError(
  AppLocalizations l10n,
  String message, {
  VerifyOtpError? errorType,
}) {
  if (errorType == VerifyOtpError.backendSync) {
    return message.trim().isNotEmpty ? message : l10n.backendSyncFailed;
  }

  switch (message) {
    case 'invalidCode':
      return l10n.otpInvalidCode;
    case 'network':
      return l10n.networkError;
    default:
      return localizeFirebaseAuthError(
        l10n,
        FirebaseAuthErrorCode.values.asNameMap()[message] ??
            FirebaseAuthErrorCode.unknown,
        fallback: message,
      );
  }
}

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.flow = VerifyOtpFlow.registration,
    this.password = '',
    this.forceResendingToken,
    this.onRegistrationVerified,
  });

  final String phoneNumber;
  final String verificationId;
  final VerifyOtpFlow flow;
  final String password;
  final int? forceResendingToken;
  final void Function(String firebaseToken)? onRegistrationVerified;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerifyOtpCubit(
        phoneNumber: widget.phoneNumber,
        verificationId: widget.verificationId,
        flow: widget.flow,
        password: widget.password,
        forceResendingToken: widget.forceResendingToken,
      ),
      child: _VerifyOtpView(
        otpController: _otpController,
        onRegistrationVerified: widget.onRegistrationVerified,
      ),
    );
  }
}

class _VerifyOtpView extends StatelessWidget {
  const _VerifyOtpView({
    required this.otpController,
    this.onRegistrationVerified,
  });

  final TextEditingController otpController;
  final void Function(String firebaseToken)? onRegistrationVerified;

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyOtpCubit, VerifyOtpState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) async {
        final l10n = AppLocalizations.of(context);

        if (state.status == VerifyOtpStatus.success) {
          if (state.flow == VerifyOtpFlow.registration &&
              state.firebaseToken != null) {
            onRegistrationVerified?.call(state.firebaseToken!);
            return;
          }

          if (state.flow == VerifyOtpFlow.forgotPassword &&
              state.firebaseToken != null) {
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  phoneNumber: state.phoneNumber,
                  firebaseToken: state.firebaseToken!,
                ),
              ),
            );
            return;
          }

          if (state.flow == VerifyOtpFlow.login && state.verifiedUser != null) {
            final user = state.verifiedUser!;
            context.read<UserCubit>().applyAuthenticatedUser(user);
            try {
              await RideHubService().connect();
            } catch (e) {
              debugPrint('SignalR connect failed: $e');
            }
            unawaited(
              // ignore: use_build_context_synchronously
              context.read<WalletCubit>().initialize(
                initialBalance: user.walletBalance,
              ),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.loginSuccessful),
                backgroundColor: const Color(0xFF1FAE6C),
              ),
            );
            unawaited(GetIt.I<NotificationManager>().syncTokenWithServer());
            await RideHubService().connect(); // ← ADD THIS
            debugPrint('SIGNALR CONNECT START → done'); // ← temporary debug log
            // ignore: use_build_context_synchronously
            unawaited(context.read<WalletCubit>().initialize());
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MapScreen()),
              (route) => false,
            );
          }
        } else if (state.status == VerifyOtpStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizeVerifyOtpError(
                  l10n,
                  state.errorMessage!,
                  errorType: state.errorType,
                ),
              ),
              backgroundColor: state.errorType == VerifyOtpError.invalidCode
                  ? Colors.orange
                  : Colors.red,
            ),
          );
        } else if (state.status == VerifyOtpStatus.idle &&
            state.lastResentAt != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.otpResent),
              backgroundColor: const Color(0xFF1FAE6C),
            ),
          );
        }
      },
      child: BlocBuilder<VerifyOtpCubit, VerifyOtpState>(
        builder: (context, state) {
          final cubit = context.read<VerifyOtpCubit>();
          final l10n = AppLocalizations.of(context);
          final isVerifying = state.status == VerifyOtpStatus.verifying;
          final isSyncing = state.status == VerifyOtpStatus.syncing;
          final isBusy = isVerifying || isSyncing;
          final isResending = state.status == VerifyOtpStatus.resending;

          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.verifyOtp),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: const Color(0xFF1F2937),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1FAE6C).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 36,
                        color: Color(0xFF1FAE6C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.confirmYourPhone,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.otpSentTo(state.phoneNumber),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.otpCountdownHint(state.resendCooldownSeconds),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: l10n.enterOtpCode,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isBusy
                            ? null
                            : () => cubit.verifyOtp(otpController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1FAE6C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isBusy
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isSyncing
                                        ? l10n.syncingAccount
                                        : l10n.verifyingOtp,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                l10n.verifyOtpButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResendRow(
                      cooldownSeconds: state.resendCooldownSeconds,
                      isResending: isResending,
                      canResend: state.canResend,
                      onResend: cubit.resendOtp,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.cooldownSeconds,
    required this.isResending,
    required this.canResend,
    required this.onResend,
  });

  final int cooldownSeconds;
  final bool isResending;
  final bool canResend;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.didntGetOtp,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        if (isResending)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TextButton(
            onPressed: canResend ? onResend : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFF1FAE6C),
            ),
            child: Text(
              cooldownSeconds > 0
                  ? l10n.resendIn('$cooldownSeconds')
                  : l10n.resendOtp,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
