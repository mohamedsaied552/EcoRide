// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Scooter';

  @override
  String get moveFaster => 'Move faster, move smarter';

  @override
  String get profile => 'Profile';

  @override
  String get wallet => 'Wallet';

  @override
  String get rideHistory => 'Ride history';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get helpUnableOpenWhatsApp => 'Unable to open WhatsApp.';

  @override
  String get helpErrorOpeningWhatsApp => 'Error opening WhatsApp.';

  @override
  String get helpUnablePlaceCall => 'Unable to place a call.';

  @override
  String get helpErrorPlacingCall => 'Error placing call.';

  @override
  String get helpContactSupport => 'Contact Support';

  @override
  String get helpChatWhatsApp => 'Chat on WhatsApp';

  @override
  String get helpCallSupport => 'Call Support';

  @override
  String get helpFaqUnlockQuestion => 'How do I unlock a scooter?';

  @override
  String get helpFaqUnlockAnswer =>
      'Open the app, tap a scooter, then scan the QR code or enter the scooter code to unlock.';

  @override
  String get helpFaqBatteryQuestion => 'What if the battery is low?';

  @override
  String get helpFaqBatteryAnswer =>
      'Scooters show battery percentage in the details. Only select scooters with sufficient charge for your trip.';

  @override
  String get helpFaqSidewalkQuestion => 'Can I ride on sidewalks?';

  @override
  String get helpFaqSidewalkAnswer =>
      'Please follow local regulations. Generally, use bike lanes and roads where allowed.';

  @override
  String get helpFaqFeesQuestion => 'How are fees calculated?';

  @override
  String get helpFaqFeesAnswer =>
      'Fees are charged per-minute. Unlock fees may apply depending on the scooter model.';

  @override
  String get helpFaqReportQuestion => 'How to report a damaged scooter?';

  @override
  String get helpFaqReportAnswer =>
      'Use the \"Report\" option in the scooter details or contact support via chat or call below.';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInSubtitle => 'Sign in to ride or manage your fleet.';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMin6 => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get or => 'OR';

  @override
  String get signInWithGoogle => 'Sign-In with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign Up';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String get googleSignInUnavailable => 'Google sign-in is not available';

  @override
  String get loginFailed => 'Login failed.';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get enterAccountEmail => 'Enter your account email';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get resetInstructionsSent => 'Reset instructions sent successfully.';

  @override
  String get nearbyScooters => 'Nearby Scooters';

  @override
  String get findingNearbyScooters => 'Finding nearby scooters...';

  @override
  String get couldNotOpenMaps => 'Could not open Google Maps on this device.';

  @override
  String get errorOpeningNavigation => 'Error opening navigation.';

  @override
  String get locationDisabled =>
      'Location services are disabled. Please enable GPS.';

  @override
  String get locationPermanentlyDenied =>
      'Location permissions are permanently denied. Enable it from settings.';

  @override
  String get unableOpenNavigation => 'Unable to open navigation.';

  @override
  String get scanToUnlock => 'Scan to unlock';

  @override
  String get scooterDetails => 'Scooter Details';

  @override
  String get battery => 'Battery';

  @override
  String get distance => 'Distance';

  @override
  String get rate => 'Rate';

  @override
  String get unlockFee => 'Unlock Fee';

  @override
  String get directMe => 'Direct Me';

  @override
  String get unknown => 'Unknown';

  @override
  String get tbd => 'TBD';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String distanceM(String distance) {
    return '$distance m';
  }

  @override
  String feePerMin(String fee) {
    return '$fee / min';
  }

  @override
  String get skip => 'Skip';

  @override
  String get onboardingTitle => 'Easy & Smart E‑Scooter Sharing';

  @override
  String get onboardingSubtitle =>
      'Find nearby scooters, unlock with a QR scan, and ride in seconds. Pay securely and track every ride in one place.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get preferences => 'Preferences';

  @override
  String get accountInformation => 'Account Information';

  @override
  String get security => 'Security';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get pleaseEnterName => 'Please enter your name.';

  @override
  String get pleaseEnterPhone => 'Please enter your phone number.';

  @override
  String get enterCurrentPassword => 'Enter your current password.';

  @override
  String get newPasswordMin8 => 'New password must be at least 8 characters.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get updatePassword => 'Update password';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get invalidQrCode => 'Invalid QR code';

  @override
  String get scanQrInstruction =>
      'Scan the scooter QR to load its status, wallet check, and proximity confirmation.';

  @override
  String get status => 'Status';

  @override
  String get notCheckedYet => 'Not checked yet';

  @override
  String walletBalanceMin(String balance, String min) {
    return '$balance EGP / $min EGP min';
  }

  @override
  String distanceRadius(String distance, String radius) {
    return '$distance m / $radius m';
  }

  @override
  String batteryPercent(String percent) {
    return '$percent% battery';
  }

  @override
  String get balanceTooLow =>
      'Your balance is below the minimum required to unlock this scooter.';

  @override
  String get moveCloser =>
      'Move closer to the scooter and try the proximity check again.';

  @override
  String get addMoney => 'Add Money';

  @override
  String get startRide => 'Start Ride';

  @override
  String get checkDistance => 'Check Distance';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get scanAnotherScooter => 'Scan another scooter';

  @override
  String get available => 'Available';

  @override
  String get offline => 'Offline';

  @override
  String get loadingRides => 'Loading rides...';

  @override
  String scooterCode(String code) {
    return 'Scooter $code';
  }

  @override
  String routeSeparator(String from, String to) {
    return '$from → $to';
  }

  @override
  String costEgp(String cost) {
    return '$cost EGP';
  }

  @override
  String durationMinSec(String minutes, String seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String get activeRide => 'Active Ride';

  @override
  String get walletBalanceLow =>
      'Wallet balance is low. Ending ride for safety.';

  @override
  String get outsideOperatingZone =>
      'Outside operating zone. Please return to the zone.';

  @override
  String errorEndingRide(String error) {
    return 'Error ending ride: $error';
  }

  @override
  String get mapUnavailable =>
      'Live map is unavailable until a Google Maps API key is configured.';

  @override
  String get rideTime => 'Ride time';

  @override
  String get cost => 'Cost';

  @override
  String get endRide => 'End ride';

  @override
  String get ongoingRide => 'Ongoing Ride';

  @override
  String scooterId(String code) {
    return 'Scooter ID: $code';
  }

  @override
  String get active => 'Active';

  @override
  String get rideDuration => 'RIDE DURATION';

  @override
  String get currentCost => 'CURRENT COST';

  @override
  String get endRideUpper => 'END RIDE';

  @override
  String get rideSummary => 'Ride Summary';

  @override
  String get noRouteData => 'No route data';

  @override
  String get rideComplete => 'Your ride is complete';

  @override
  String get scooter => 'Scooter';

  @override
  String get time => 'Time';

  @override
  String get walletAfterRide => 'Wallet after ride';

  @override
  String get done => 'Done';

  @override
  String get createAccount => 'Create Account';

  @override
  String get createRiderProfile => 'Create your rider profile';

  @override
  String get createAccountSubtitle =>
      'We will use these details to create your account and keep your rides secure.';

  @override
  String get uploadIdTitle => 'Upload both sides of your ID';

  @override
  String get uploadIdSubtitle =>
      'Make sure both images are sharp, readable, and fully visible.';

  @override
  String get accountCreatedVerifyEmail =>
      'Account created. Please verify your email to continue.';

  @override
  String get accountCreatedSuccess => 'Account created successfully';

  @override
  String get continueToVerification => 'Continue to Verification';

  @override
  String get back => 'Back';

  @override
  String get termsAgreement =>
      'By signing up, you agree to our Terms of Service and Privacy Policy.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get enterFullLegalName => 'Enter your full legal name';

  @override
  String get enterEmailAddress => 'Enter your email address';

  @override
  String get enterMobileNumber => 'Enter your mobile number';

  @override
  String get createStrongPassword => 'Create a strong password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reenterPassword => 'Re-enter your password';

  @override
  String get pleaseEnterFullName => 'Please enter your full name.';

  @override
  String get nameMin3 => 'Name must be at least 3 characters.';

  @override
  String get pleaseEnterEmailAddress => 'Please enter your email.';

  @override
  String get pleaseEnterValidEmailAddress =>
      'Please enter a valid email address.';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter your phone number.';

  @override
  String get phoneTooShort => 'Phone number looks too short.';

  @override
  String get pleaseEnterPasswordField => 'Please enter a password.';

  @override
  String get passwordMin8 => 'Password must be at least 8 characters.';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password.';

  @override
  String get uploadIdInstruction =>
      'Upload both the front and back of your national ID before submitting your registration.';

  @override
  String get frontSide => 'Front side';

  @override
  String get backSide => 'Back side';

  @override
  String get noImageSelected => 'No image selected.';

  @override
  String get uploadBothIdImages =>
      'Please upload both front and back images of your ID.';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get idVerification => 'ID Verification';

  @override
  String get selfieVerification => 'Selfie Verification';

  @override
  String get continueToSelfie => 'Continue to Selfie';

  @override
  String get uploadNationalId => 'Upload your national ID';

  @override
  String get uploadIdHint =>
      'Use a sharp, well-lit image and keep the full ID visible.';

  @override
  String get removeAndReupload => 'Remove and re-upload';

  @override
  String get unablePreviewImage => 'Unable to preview image';

  @override
  String get tryDifferentPhoto => 'Try selecting a different photo.';

  @override
  String get selfieVerificationTitle => 'Selfie Verification';

  @override
  String get selfieLookAtCamera => 'Please look directly at the camera';

  @override
  String get selfieInstruction =>
      'Position your face inside the circle and ensure good lighting.';

  @override
  String get retake => 'Retake';

  @override
  String get confirm => 'Confirm';

  @override
  String get captureSelfie => 'Capture Selfie';

  @override
  String get selfieRequired => 'Please capture a selfie to continue.';

  @override
  String get selfieCaptureError =>
      'Failed to capture selfie. Please try again.';

  @override
  String get verifyEmail => 'Verify your email';

  @override
  String get confirmYourEmail => 'Confirm your email';

  @override
  String verificationLinkSent(String email) {
    return 'We sent a verification link to\n$email';
  }

  @override
  String get checkYourInbox =>
      'Open your email and tap the verification link to activate your account.';

  @override
  String get emailVerifiedSuccess => 'Email verified successfully';

  @override
  String get iHaveVerified => 'I have verified';

  @override
  String get checkingVerification => 'Checking...';

  @override
  String get syncingAccount => 'Syncing account...';

  @override
  String get backendSyncFailed =>
      'Could not connect your account to the server. Please try again.';

  @override
  String get didntGetLink => 'Didn\'t get the email? ';

  @override
  String resendIn(String seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resendLink => 'Resend link';

  @override
  String get verificationLinkResent => 'Verification link sent again.';

  @override
  String get emailNotVerifiedYet =>
      'Your email is not verified yet. Please check your inbox and try again.';

  @override
  String get networkError =>
      'Network error. Check your connection and try again.';

  @override
  String get firebaseWeakPassword =>
      'Password is too weak. Use at least 8 characters with letters and numbers.';

  @override
  String get firebaseEmailAlreadyInUse =>
      'This email is already registered. Try signing in instead.';

  @override
  String get firebaseInvalidEmail => 'Please enter a valid email address.';

  @override
  String get firebaseOperationNotAllowed =>
      'Email sign-up is not enabled. Contact support.';

  @override
  String get firebaseTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get firebaseEmailNotVerified =>
      'Please verify your email before signing in.';

  @override
  String get firebaseInvalidCredentials => 'Invalid email or password.';

  @override
  String get firebaseUserDisabled =>
      'This account has been disabled. Contact support.';

  @override
  String get completePayment => 'Complete Payment';

  @override
  String get addBalance => 'Add Balance';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get choosePaymentMethod => 'Choose payment method';

  @override
  String get walletPhoneNumber => 'Wallet phone number';

  @override
  String get egpPrefix => 'EGP ';

  @override
  String get phoneHint => '010XXXXXXXX';

  @override
  String get mobileWallet => 'Mobile Wallet';

  @override
  String get visaMastercard => 'Visa / MasterCard';

  @override
  String get vodafoneCash => 'Vodafone Cash';

  @override
  String get orangeCash => 'Orange Cash';

  @override
  String get etisalatCash => 'Etisalat Cash';

  @override
  String get instapay => 'Instapay';

  @override
  String get enterValidAmount => 'Please enter a valid amount.';

  @override
  String get enterWalletPhone => 'Please enter your wallet phone number.';

  @override
  String get unableOpenPayment => 'Unable to open payment gateway.';

  @override
  String get paymentCompleted => 'Payment completed — refreshing balance.';

  @override
  String get paymentCancelled => 'Payment was cancelled or failed.';

  @override
  String get topUpPay => 'Top-up / Pay';

  @override
  String get loadingBalance => 'Loading balance...';

  @override
  String get pleaseLoginFirst => 'Please log in first.';

  @override
  String get currentBalance => 'Current balance';

  @override
  String linkedAccount(String email) {
    return 'Linked account: $email';
  }

  @override
  String get addBalanceButton => 'Add balance';

  @override
  String get qrNotSupportedWeb => 'QR scanning is not supported on Web.';

  @override
  String percentSuffix(String value) {
    return '$value%';
  }

  @override
  String get signInWithPhoneSubtitle =>
      'Enter your phone number to receive a one-time code.';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get confirmYourPhone => 'Confirm your phone number';

  @override
  String otpSentTo(String phone) {
    return 'We sent a verification code to\n$phone';
  }

  @override
  String get enterOtpCode => 'Enter OTP code';

  @override
  String get verifyOtpButton => 'Verify & Continue';

  @override
  String get verifyingOtp => 'Verifying...';

  @override
  String get didntGetOtp => 'Didn\'t get the code? ';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get otpResent => 'Verification code sent again.';

  @override
  String get otpVerifiedSuccess => 'Phone verified successfully';

  @override
  String get accountCreatedVerifyOtp =>
      'Account created. Enter the OTP sent to your phone to continue.';

  @override
  String get otpInvalidCode => 'Invalid or expired verification code.';

  @override
  String get otpSessionExpired =>
      'Verification session expired. Request a new code.';

  @override
  String get firebaseInvalidPhoneNumber => 'Please enter a valid phone number.';

  @override
  String get endRidePhotoRequired =>
      'Please capture a parking photo before ending your ride.';

  @override
  String get endRidePhotoTitle => 'Parking verification';

  @override
  String get captureParkingPhoto => 'Capture parking photo';

  @override
  String get phoneHintLocal => '1004832172';

  @override
  String get phoneInvalidLength => 'Enter exactly 10 digits for Egypt numbers.';

  @override
  String get phoneInvalidFormat =>
      'Enter a valid Egyptian mobile number starting with 1.';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your phone number and we\'ll send a verification code.';

  @override
  String get resetPasswordSubtitle => 'Choose a new password for your account.';

  @override
  String get passwordResetSuccess =>
      'Password updated successfully. You can sign in now.';

  @override
  String otpCountdownHint(int seconds) {
    return 'Resend available in ${seconds}s';
  }
}
