import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/data/datasources/firebase_auth_service.dart';
import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/register_cubit.dart';
import 'package:glider/presentation/cubits/verify_otp_cubit.dart';
import 'package:glider/presentation/screens/register_documents_screen.dart';
import 'package:glider/presentation/screens/verify_otp_screen.dart';
import 'package:glider/presentation/utils/firebase_auth_error_utils.dart';

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

void handleRegisterSubmission(
  BuildContext context,
  RegisterState state,
) {
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

  if (state.submissionStatus == RegisterSubmissionStatus.failure &&
      state.errorMessage != null) {
    final phoneError = localizePhoneValidationError(l10n, state.errorMessage);
    final errorCode = FirebaseAuthErrorCode.values.asNameMap()[
      state.errorMessage!];
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
