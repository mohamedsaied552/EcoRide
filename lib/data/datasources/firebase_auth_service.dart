import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:glider/domain/entities/user.dart';

enum FirebaseAuthErrorCode {
  weakPassword,
  emailAlreadyInUse,
  invalidEmail,
  invalidPhoneNumber,
  invalidVerificationCode,
  sessionExpired,
  operationNotAllowed,
  network,
  tooManyRequests,
  emailNotVerified,
  userNotFound,
  wrongPassword,
  userDisabled,
  missingVerificationId,
  smsTimeout,
  unknown,
}

class FirebaseAuthFailure implements Exception {
  const FirebaseAuthFailure({
    required this.code,
    this.rawMessage,
  });

  final FirebaseAuthErrorCode code;
  final String? rawMessage;

  factory FirebaseAuthFailure.fromException(FirebaseAuthException exception) {
    final code = switch (exception.code) {
      'weak-password' => FirebaseAuthErrorCode.weakPassword,
      'email-already-in-use' => FirebaseAuthErrorCode.emailAlreadyInUse,
      'invalid-email' => FirebaseAuthErrorCode.invalidEmail,
      'invalid-phone-number' => FirebaseAuthErrorCode.invalidPhoneNumber,
      'invalid-verification-code' => FirebaseAuthErrorCode.invalidVerificationCode,
      'session-expired' => FirebaseAuthErrorCode.sessionExpired,
      'operation-not-allowed' => FirebaseAuthErrorCode.operationNotAllowed,
      'network-request-failed' => FirebaseAuthErrorCode.network,
      'too-many-requests' => FirebaseAuthErrorCode.tooManyRequests,
      'user-not-found' => FirebaseAuthErrorCode.userNotFound,
      'wrong-password' => FirebaseAuthErrorCode.wrongPassword,
      'user-disabled' => FirebaseAuthErrorCode.userDisabled,
      _ => FirebaseAuthErrorCode.unknown,
    };

    return FirebaseAuthFailure(
      code: code,
      rawMessage: exception.message,
    );
  }

  static const noCurrentUser = FirebaseAuthFailure(
    code: FirebaseAuthErrorCode.unknown,
    rawMessage: 'No signed-in user found.',
  );

  static const missingVerificationId = FirebaseAuthFailure(
    code: FirebaseAuthErrorCode.missingVerificationId,
    rawMessage: 'Phone verification has not been started.',
  );
}

class PhoneVerificationSession {
  const PhoneVerificationSession({
    required this.verificationId,
    this.forceResendingToken,
  });

  final String verificationId;
  final int? forceResendingToken;
}

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  bool get hasSession => _firebaseAuth.currentUser != null;

  /// Starts Firebase Phone Auth and sends an SMS OTP to [phoneNumber].
  Future<PhoneVerificationSession> verifyPhoneNumber(
    String phoneNumber, {
    int? forceResendingToken,
  }) async {
    final normalizedPhone = phoneNumber.trim();
    if (normalizedPhone.isEmpty) {
      throw const FirebaseAuthFailure(
        code: FirebaseAuthErrorCode.invalidPhoneNumber,
        rawMessage: 'Phone number is required.',
      );
    }

    final completer = Completer<PhoneVerificationSession>();
    PhoneVerificationSession? session;

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _firebaseAuth.signInWithCredential(credential);
            session ??= PhoneVerificationSession(
              verificationId: credential.verificationId ?? '',
              forceResendingToken: forceResendingToken,
            );
            if (!completer.isCompleted && session!.verificationId.isNotEmpty) {
              completer.complete(session!);
            }
          } catch (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          if (!completer.isCompleted) {
            completer.completeError(FirebaseAuthFailure.fromException(error));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          session = PhoneVerificationSession(
            verificationId: verificationId,
            forceResendingToken: resendToken,
          );
          if (!completer.isCompleted) {
            completer.complete(session!);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Preserve verificationId so manual OTP entry still works after
          // [SmsRetrieverHelper] auto-retrieval timeout on Android.
          session = PhoneVerificationSession(
            verificationId: verificationId,
            forceResendingToken: session?.forceResendingToken ?? forceResendingToken,
          );
          if (!completer.isCompleted) {
            completer.complete(session!);
          }
        },
      );
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailure.fromException(error);
    }

    return completer.future;
  }

  /// Completes phone sign-in using the SMS [smsCode] and returns a Firebase ID token.
  Future<String> signInWithCredential(
    String smsCode, {
    required String verificationId,
  }) async {
    if (verificationId.trim().isEmpty) {
      throw FirebaseAuthFailure.missingVerificationId;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const FirebaseAuthFailure(code: FirebaseAuthErrorCode.unknown);
      }

      return getIdToken(forceRefresh: true);
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailure.fromException(error);
    }
  }

  Future<String> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthFailure.noCurrentUser;
    }

    try {
      final token = await user.getIdToken(forceRefresh);
      if (token == null || token.trim().isEmpty) {
        throw const FirebaseAuthFailure(code: FirebaseAuthErrorCode.unknown);
      }
      return token;
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailure.fromException(error);
    }
  }

  AppUser? getCurrentAppUser({
    String? fullName,
    String? phone,
  }) {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      name: fullName?.isNotEmpty == true
          ? fullName!
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'Rider'),
      email: user.email ?? '',
      phone: phone ?? user.phoneNumber ?? '',
      walletBalance: 0,
      ridesCount: 0,
      rating: 0,
      accountStatus: 'active',
      idVerificationStatus: 'pending',
      phoneVerified: user.phoneNumber?.isNotEmpty == true,
    );
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}
