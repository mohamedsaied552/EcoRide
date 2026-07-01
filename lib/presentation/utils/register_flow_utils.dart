import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakzouka/data/datasources/firebase_auth_service.dart';
import 'package:zakzouka/l10n/app_localizations.dart';
import 'package:zakzouka/presentation/cubits/register_cubit.dart';
import 'package:zakzouka/presentation/cubits/verify_otp_cubit.dart';
import 'package:zakzouka/presentation/screens/register_documents_screen.dart';
import 'package:zakzouka/presentation/screens/verify_otp_screen.dart';
import 'package:zakzouka/presentation/utils/firebase_auth_error_utils.dart';

String localizeRegisterImageError(AppLocalizations l10n, String? error) {
  switch (error) {
    case RegisterImageError.noImageSelected:
      return l10n.noImageSelected;
    case RegisterImageError.uploadBothId:
      return l10n.uploadBothIdImages;
    case RegisterImageError.selfieRequired:
      return l10n.selfieRequired;
    default:
      return error ?? '';
  }
}

String localizePhoneValidationError(AppLocalizations l10n, String? code) {
  switch (code) {
    case 'invalidLength':
      return l10n.phoneInvalidLength;
    case 'invalidFormat':
      return l10n.phoneInvalidFormat;
    case 'empty':
      return l10n.pleaseEnterPhoneNumber;
    default:
      return code ?? l10n.phoneTooShort;
  }
}

void handleRegisterSubmission(BuildContext context, RegisterState state) {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<RegisterCubit>();

  if (state.submissionStatus == RegisterSubmissionStatus.otpSent &&
      state.verificationSession != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: VerifyOtpScreen(
            phoneNumber: state.internationalPhoneNumber,
            flow: VerifyOtpFlow.registration,
            verificationId: state.verificationSession!.verificationId,
            forceResendingToken: state.verificationSession!.forceResendingToken,
            onRegistrationVerified: (firebaseToken) {
              cubit.setFirebaseToken(firebaseToken);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const RegisterDocumentsScreen(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    return;
  }

  if (state.submissionStatus == RegisterSubmissionStatus.success &&
      state.registeredUser != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.accountCreatedSuccess),
        backgroundColor: const Color(0xFF1FAE6C),
      ),
    );
    return;
  }

  if (state.submissionStatus == RegisterSubmissionStatus.requiresManualId) {
    _showManualNationalIdDialog(context, cubit);
    return;
  }

  if (state.submissionStatus == RegisterSubmissionStatus.failure) {
    final String displayMessage =
        state.errorMessage ?? 'An unknown error occurred';
    final phoneError = localizePhoneValidationError(l10n, displayMessage);
    final errorCode = FirebaseAuthErrorCode.values.asNameMap()[displayMessage];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorCode != null
              ? localizeFirebaseAuthError(l10n, errorCode)
              : phoneError,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _showManualNationalIdDialog(BuildContext context, RegisterCubit cubit) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  String? localError;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(l10n.manualNationalIdTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.manualNationalIdSubtitle),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 14,
                  decoration: InputDecoration(
                    hintText: l10n.manualNationalIdHint,
                    errorText: localError,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.length != 14 || int.tryParse(value) == null) {
                    setState(() {
                      localError = l10n.manualNationalIdInvalid;
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  cubit.submitRegistration(manualNationalId: value);
                },
                child: Text(l10n.confirm),
              ),
            ],
          );
        },
      );
    },
  );
}
