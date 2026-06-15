import 'package:glider/data/datasources/firebase_auth_service.dart';
import 'package:glider/l10n/app_localizations.dart';

String localizeFirebaseAuthError(
  AppLocalizations l10n,
  FirebaseAuthErrorCode code, {
  String? fallback,
}) {
  switch (code) {
    case FirebaseAuthErrorCode.weakPassword:
      return l10n.firebaseWeakPassword;
    case FirebaseAuthErrorCode.emailAlreadyInUse:
      return l10n.firebaseEmailAlreadyInUse;
    case FirebaseAuthErrorCode.invalidEmail:
      return l10n.firebaseInvalidEmail;
    case FirebaseAuthErrorCode.invalidPhoneNumber:
      return l10n.firebaseInvalidPhoneNumber;
    case FirebaseAuthErrorCode.invalidVerificationCode:
    case FirebaseAuthErrorCode.sessionExpired:
      return l10n.otpInvalidCode;
    case FirebaseAuthErrorCode.missingVerificationId:
    case FirebaseAuthErrorCode.smsTimeout:
      return l10n.otpSessionExpired;
    case FirebaseAuthErrorCode.operationNotAllowed:
      return l10n.firebaseOperationNotAllowed;
    case FirebaseAuthErrorCode.network:
      return l10n.networkError;
    case FirebaseAuthErrorCode.tooManyRequests:
      return l10n.firebaseTooManyRequests;
    case FirebaseAuthErrorCode.emailNotVerified:
      return l10n.firebaseEmailNotVerified;
    case FirebaseAuthErrorCode.userNotFound:
    case FirebaseAuthErrorCode.wrongPassword:
      return l10n.firebaseInvalidCredentials;
    case FirebaseAuthErrorCode.userDisabled:
      return l10n.firebaseUserDisabled;
    case FirebaseAuthErrorCode.unknown:
      return fallback?.isNotEmpty == true ? fallback! : l10n.loginFailed;
  }
}
