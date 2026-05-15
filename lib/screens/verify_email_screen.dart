
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/user_cubit.dart';
import '../cubits/verify_email_cubit.dart';
import 'admin_screen.dart';
import 'map_screen.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerifyEmailCubit(email: email),
      child: const _VerifyEmailView(),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  const _VerifyEmailView();

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyEmailCubit, VerifyEmailState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == VerifyEmailStatus.success &&
            state.verifiedUser != null) {
          final user = state.verifiedUser!;
          context.read<UserCubit>().applyAuthenticatedUser(user);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully'),
              backgroundColor: Color(0xFF1FAE6C),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  user.isAdmin ? const AdminScreen() : const MapScreen(),
            ),
            (route) => false,
          );
        } else if (state.status == VerifyEmailStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: state.errorType == VerifyEmailError.expiredCode
                  ? Colors.orange
                  : Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<VerifyEmailCubit, VerifyEmailState>(
        builder: (context, state) {
          final cubit = context.read<VerifyEmailCubit>();
          final isVerifying = state.status == VerifyEmailStatus.verifying;
          final isResending = state.status == VerifyEmailStatus.resending;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Verify your email'),
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
                        Icons.mark_email_unread_outlined,
                        size: 36,
                        color: Color(0xFF1FAE6C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Confirm your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a verification code to\n${state.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _CodeField(
                      controller: _codeController,
                      enabled: !isVerifying,
                      onChanged: cubit.updateCode,
                      onSubmitted: (_) => cubit.submit(),
                      hasError: state.errorType == VerifyEmailError.invalidCode ||
                          state.errorType == VerifyEmailError.expiredCode,
                    ),
                    if (state.errorMessage != null &&
                        state.status == VerifyEmailStatus.failure) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: state.errorType == VerifyEmailError.expiredCode
                              ? Colors.orange.shade800
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isVerifying ? null : cubit.submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1FAE6C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
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
                      onResend: cubit.resendCode,
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

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
    required this.hasError,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 12,
        color: Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '••••••',
        hintStyle: TextStyle(
          color: Colors.grey.shade300,
          letterSpacing: 12,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? Colors.red : const Color(0xFF1FAE6C),
            width: 1.6,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: hasError
              ? const BorderSide(color: Colors.red, width: 1.2)
              : BorderSide.none,
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Didn't get a code? ",
          style: TextStyle(color: Color(0xFF6B7280)),
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
                  ? 'Resend in ${cooldownSeconds}s'
                  : 'Resend code',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

