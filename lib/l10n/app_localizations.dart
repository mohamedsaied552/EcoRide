import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Scooter'**
  String get appTitle;

  /// No description provided for @moveFaster.
  ///
  /// In en, this message translates to:
  /// **'Move faster, move smarter'**
  String get moveFaster;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @rideHistory.
  ///
  /// In en, this message translates to:
  /// **'Ride history'**
  String get rideHistory;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @helpUnableOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Unable to open WhatsApp.'**
  String get helpUnableOpenWhatsApp;

  /// No description provided for @helpErrorOpeningWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Error opening WhatsApp.'**
  String get helpErrorOpeningWhatsApp;

  /// No description provided for @helpUnablePlaceCall.
  ///
  /// In en, this message translates to:
  /// **'Unable to place a call.'**
  String get helpUnablePlaceCall;

  /// No description provided for @helpErrorPlacingCall.
  ///
  /// In en, this message translates to:
  /// **'Error placing call.'**
  String get helpErrorPlacingCall;

  /// No description provided for @helpContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get helpContactSupport;

  /// No description provided for @helpChatWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Chat on WhatsApp'**
  String get helpChatWhatsApp;

  /// No description provided for @helpCallSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get helpCallSupport;

  /// No description provided for @helpFaqUnlockQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I unlock a scooter?'**
  String get helpFaqUnlockQuestion;

  /// No description provided for @helpFaqUnlockAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open the app, tap a scooter, then scan the QR code or enter the scooter code to unlock.'**
  String get helpFaqUnlockAnswer;

  /// No description provided for @helpFaqBatteryQuestion.
  ///
  /// In en, this message translates to:
  /// **'What if the battery is low?'**
  String get helpFaqBatteryQuestion;

  /// No description provided for @helpFaqBatteryAnswer.
  ///
  /// In en, this message translates to:
  /// **'Scooters show battery percentage in the details. Only select scooters with sufficient charge for your trip.'**
  String get helpFaqBatteryAnswer;

  /// No description provided for @helpFaqSidewalkQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I ride on sidewalks?'**
  String get helpFaqSidewalkQuestion;

  /// No description provided for @helpFaqSidewalkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please follow local regulations. Generally, use bike lanes and roads where allowed.'**
  String get helpFaqSidewalkAnswer;

  /// No description provided for @helpFaqFeesQuestion.
  ///
  /// In en, this message translates to:
  /// **'How are fees calculated?'**
  String get helpFaqFeesQuestion;

  /// No description provided for @helpFaqFeesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Fees are charged per-minute. Unlock fees may apply depending on the scooter model.'**
  String get helpFaqFeesAnswer;

  /// No description provided for @helpFaqReportQuestion.
  ///
  /// In en, this message translates to:
  /// **'How to report a damaged scooter?'**
  String get helpFaqReportQuestion;

  /// No description provided for @helpFaqReportAnswer.
  ///
  /// In en, this message translates to:
  /// **'Use the \"Report\" option in the scooter details or contact support via chat or call below.'**
  String get helpFaqReportAnswer;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to ride or manage your fleet.'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMin6;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign-In with Google'**
  String get signInWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @googleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available'**
  String get googleSignInUnavailable;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get loginFailed;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @enterAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email'**
  String get enterAccountEmail;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @resetInstructionsSent.
  ///
  /// In en, this message translates to:
  /// **'Reset instructions sent successfully.'**
  String get resetInstructionsSent;

  /// No description provided for @nearbyScooters.
  ///
  /// In en, this message translates to:
  /// **'Nearby Scooters'**
  String get nearbyScooters;

  /// No description provided for @findingNearbyScooters.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby scooters...'**
  String get findingNearbyScooters;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps on this device.'**
  String get couldNotOpenMaps;

  /// No description provided for @errorOpeningNavigation.
  ///
  /// In en, this message translates to:
  /// **'Error opening navigation.'**
  String get errorOpeningNavigation;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable GPS.'**
  String get locationDisabled;

  /// No description provided for @locationPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Enable it from settings.'**
  String get locationPermanentlyDenied;

  /// No description provided for @unableOpenNavigation.
  ///
  /// In en, this message translates to:
  /// **'Unable to open navigation.'**
  String get unableOpenNavigation;

  /// No description provided for @scanToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Scan to unlock'**
  String get scanToUnlock;

  /// No description provided for @scooterDetails.
  ///
  /// In en, this message translates to:
  /// **'Scooter Details'**
  String get scooterDetails;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @unlockFee.
  ///
  /// In en, this message translates to:
  /// **'Unlock Fee'**
  String get unlockFee;

  /// No description provided for @directMe.
  ///
  /// In en, this message translates to:
  /// **'Direct Me'**
  String get directMe;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @tbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get tbd;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKm(String distance);

  /// No description provided for @distanceM.
  ///
  /// In en, this message translates to:
  /// **'{distance} m'**
  String distanceM(String distance);

  /// No description provided for @feePerMin.
  ///
  /// In en, this message translates to:
  /// **'{fee} / min'**
  String feePerMin(String fee);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Easy & Smart E‑Scooter Sharing'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find nearby scooters, unlock with a QR scan, and ride in seconds. Pay securely and track every ride in one place.'**
  String get onboardingSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number.'**
  String get pleaseEnterPhone;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get enterCurrentPassword;

  /// No description provided for @newPasswordMin8.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters.'**
  String get newPasswordMin8;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get invalidQrCode;

  /// No description provided for @scanQrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan the scooter QR to load its status, wallet check, and proximity confirmation.'**
  String get scanQrInstruction;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @notCheckedYet.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get notCheckedYet;

  /// No description provided for @walletBalanceMin.
  ///
  /// In en, this message translates to:
  /// **'{balance} EGP / {min} EGP min'**
  String walletBalanceMin(String balance, String min);

  /// No description provided for @distanceRadius.
  ///
  /// In en, this message translates to:
  /// **'{distance} m / {radius} m'**
  String distanceRadius(String distance, String radius);

  /// No description provided for @batteryPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% battery'**
  String batteryPercent(String percent);

  /// No description provided for @balanceTooLow.
  ///
  /// In en, this message translates to:
  /// **'Your balance is below the minimum required to unlock this scooter.'**
  String get balanceTooLow;

  /// No description provided for @moveCloser.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the scooter and try the proximity check again.'**
  String get moveCloser;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @startRide.
  ///
  /// In en, this message translates to:
  /// **'Start Ride'**
  String get startRide;

  /// No description provided for @checkDistance.
  ///
  /// In en, this message translates to:
  /// **'Check Distance'**
  String get checkDistance;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @scanAnotherScooter.
  ///
  /// In en, this message translates to:
  /// **'Scan another scooter'**
  String get scanAnotherScooter;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @loadingRides.
  ///
  /// In en, this message translates to:
  /// **'Loading rides...'**
  String get loadingRides;

  /// No description provided for @scooterCode.
  ///
  /// In en, this message translates to:
  /// **'Scooter {code}'**
  String scooterCode(String code);

  /// No description provided for @routeSeparator.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String routeSeparator(String from, String to);

  /// No description provided for @costEgp.
  ///
  /// In en, this message translates to:
  /// **'{cost} EGP'**
  String costEgp(String cost);

  /// No description provided for @durationMinSec.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String durationMinSec(String minutes, String seconds);

  /// No description provided for @activeRide.
  ///
  /// In en, this message translates to:
  /// **'Active Ride'**
  String get activeRide;

  /// No description provided for @walletBalanceLow.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance is low. Ending ride for safety.'**
  String get walletBalanceLow;

  /// No description provided for @outsideOperatingZone.
  ///
  /// In en, this message translates to:
  /// **'Outside operating zone. Please return to the zone.'**
  String get outsideOperatingZone;

  /// No description provided for @errorEndingRide.
  ///
  /// In en, this message translates to:
  /// **'Error ending ride: {error}'**
  String errorEndingRide(String error);

  /// No description provided for @mapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live map is unavailable until a Google Maps API key is configured.'**
  String get mapUnavailable;

  /// No description provided for @rideTime.
  ///
  /// In en, this message translates to:
  /// **'Ride time'**
  String get rideTime;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @endRide.
  ///
  /// In en, this message translates to:
  /// **'End ride'**
  String get endRide;

  /// No description provided for @ongoingRide.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Ride'**
  String get ongoingRide;

  /// No description provided for @scooterId.
  ///
  /// In en, this message translates to:
  /// **'Scooter ID: {code}'**
  String scooterId(String code);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @rideDuration.
  ///
  /// In en, this message translates to:
  /// **'RIDE DURATION'**
  String get rideDuration;

  /// No description provided for @currentCost.
  ///
  /// In en, this message translates to:
  /// **'CURRENT COST'**
  String get currentCost;

  /// No description provided for @endRideUpper.
  ///
  /// In en, this message translates to:
  /// **'END RIDE'**
  String get endRideUpper;

  /// No description provided for @rideSummary.
  ///
  /// In en, this message translates to:
  /// **'Ride Summary'**
  String get rideSummary;

  /// No description provided for @noRouteData.
  ///
  /// In en, this message translates to:
  /// **'No route data'**
  String get noRouteData;

  /// No description provided for @rideComplete.
  ///
  /// In en, this message translates to:
  /// **'Your ride is complete'**
  String get rideComplete;

  /// No description provided for @scooter.
  ///
  /// In en, this message translates to:
  /// **'Scooter'**
  String get scooter;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @walletAfterRide.
  ///
  /// In en, this message translates to:
  /// **'Wallet after ride'**
  String get walletAfterRide;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createRiderProfile.
  ///
  /// In en, this message translates to:
  /// **'Create your rider profile'**
  String get createRiderProfile;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will use these details to create your account and keep your rides secure.'**
  String get createAccountSubtitle;

  /// No description provided for @uploadIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload both sides of your ID'**
  String get uploadIdTitle;

  /// No description provided for @uploadIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make sure both images are sharp, readable, and fully visible.'**
  String get uploadIdSubtitle;

  /// No description provided for @accountCreatedVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created. Please verify your email to continue.'**
  String get accountCreatedVerifyEmail;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccess;

  /// No description provided for @continueToVerification.
  ///
  /// In en, this message translates to:
  /// **'Continue to Verification'**
  String get continueToVerification;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms of Service and Privacy Policy.'**
  String get termsAgreement;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @enterFullLegalName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full legal name'**
  String get enterFullLegalName;

  /// No description provided for @enterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmailAddress;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enterMobileNumber;

  /// No description provided for @createStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get createStrongPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterPassword;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name.'**
  String get pleaseEnterFullName;

  /// No description provided for @nameMin3.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters.'**
  String get nameMin3;

  /// No description provided for @pleaseEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get pleaseEnterEmailAddress;

  /// No description provided for @pleaseEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get pleaseEnterValidEmailAddress;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number.'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @phoneTooShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number looks too short.'**
  String get phoneTooShort;

  /// No description provided for @pleaseEnterPasswordField.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password.'**
  String get pleaseEnterPasswordField;

  /// No description provided for @passwordMin8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMin8;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get pleaseConfirmPassword;

  /// No description provided for @uploadIdInstruction.
  ///
  /// In en, this message translates to:
  /// **'Upload both the front and back of your national ID before submitting your registration.'**
  String get uploadIdInstruction;

  /// No description provided for @frontSide.
  ///
  /// In en, this message translates to:
  /// **'Front side'**
  String get frontSide;

  /// No description provided for @backSide.
  ///
  /// In en, this message translates to:
  /// **'Back side'**
  String get backSide;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected.'**
  String get noImageSelected;

  /// No description provided for @uploadBothIdImages.
  ///
  /// In en, this message translates to:
  /// **'Please upload both front and back images of your ID.'**
  String get uploadBothIdImages;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @idVerification.
  ///
  /// In en, this message translates to:
  /// **'ID Verification'**
  String get idVerification;

  /// No description provided for @selfieVerification.
  ///
  /// In en, this message translates to:
  /// **'Selfie Verification'**
  String get selfieVerification;

  /// No description provided for @continueToSelfie.
  ///
  /// In en, this message translates to:
  /// **'Continue to Selfie'**
  String get continueToSelfie;

  /// No description provided for @uploadNationalId.
  ///
  /// In en, this message translates to:
  /// **'Upload your national ID'**
  String get uploadNationalId;

  /// No description provided for @uploadIdHint.
  ///
  /// In en, this message translates to:
  /// **'Use a sharp, well-lit image and keep the full ID visible.'**
  String get uploadIdHint;

  /// No description provided for @removeAndReupload.
  ///
  /// In en, this message translates to:
  /// **'Remove and re-upload'**
  String get removeAndReupload;

  /// No description provided for @unablePreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to preview image'**
  String get unablePreviewImage;

  /// No description provided for @tryDifferentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different photo.'**
  String get tryDifferentPhoto;

  /// No description provided for @selfieVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Selfie Verification'**
  String get selfieVerificationTitle;

  /// No description provided for @selfieLookAtCamera.
  ///
  /// In en, this message translates to:
  /// **'Please look directly at the camera'**
  String get selfieLookAtCamera;

  /// No description provided for @selfieInstruction.
  ///
  /// In en, this message translates to:
  /// **'Position your face inside the circle and ensure good lighting.'**
  String get selfieInstruction;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @captureSelfie.
  ///
  /// In en, this message translates to:
  /// **'Capture Selfie'**
  String get captureSelfie;

  /// No description provided for @selfieRequired.
  ///
  /// In en, this message translates to:
  /// **'Please capture a selfie to continue.'**
  String get selfieRequired;

  /// No description provided for @selfieCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture selfie. Please try again.'**
  String get selfieCaptureError;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmail;

  /// No description provided for @confirmYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get confirmYourEmail;

  /// No description provided for @verificationLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to\n{email}'**
  String verificationLinkSent(String email);

  /// No description provided for @checkYourInbox.
  ///
  /// In en, this message translates to:
  /// **'Open your email and tap the verification link to activate your account.'**
  String get checkYourInbox;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully'**
  String get emailVerifiedSuccess;

  /// No description provided for @iHaveVerified.
  ///
  /// In en, this message translates to:
  /// **'I have verified'**
  String get iHaveVerified;

  /// No description provided for @checkingVerification.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingVerification;

  /// No description provided for @syncingAccount.
  ///
  /// In en, this message translates to:
  /// **'Syncing account...'**
  String get syncingAccount;

  /// No description provided for @backendSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect your account to the server. Please try again.'**
  String get backendSyncFailed;

  /// No description provided for @didntGetLink.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the email? '**
  String get didntGetLink;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(String seconds);

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resendLink;

  /// No description provided for @verificationLinkResent.
  ///
  /// In en, this message translates to:
  /// **'Verification link sent again.'**
  String get verificationLinkResent;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Your email is not verified yet. Please check your inbox and try again.'**
  String get emailNotVerifiedYet;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @firebaseWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 8 characters with letters and numbers.'**
  String get firebaseWeakPassword;

  /// No description provided for @firebaseEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in instead.'**
  String get firebaseEmailAlreadyInUse;

  /// No description provided for @firebaseInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get firebaseInvalidEmail;

  /// No description provided for @firebaseOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email sign-up is not enabled. Contact support.'**
  String get firebaseOperationNotAllowed;

  /// No description provided for @firebaseTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get firebaseTooManyRequests;

  /// No description provided for @firebaseEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before signing in.'**
  String get firebaseEmailNotVerified;

  /// No description provided for @firebaseInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get firebaseInvalidCredentials;

  /// No description provided for @firebaseUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support.'**
  String get firebaseUserDisabled;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @addBalance.
  ///
  /// In en, this message translates to:
  /// **'Add Balance'**
  String get addBalance;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get choosePaymentMethod;

  /// No description provided for @walletPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Wallet phone number'**
  String get walletPhoneNumber;

  /// No description provided for @egpPrefix.
  ///
  /// In en, this message translates to:
  /// **'EGP '**
  String get egpPrefix;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'010XXXXXXXX'**
  String get phoneHint;

  /// No description provided for @mobileWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get mobileWallet;

  /// No description provided for @visaMastercard.
  ///
  /// In en, this message translates to:
  /// **'Visa / MasterCard'**
  String get visaMastercard;

  /// No description provided for @vodafoneCash.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash'**
  String get vodafoneCash;

  /// No description provided for @orangeCash.
  ///
  /// In en, this message translates to:
  /// **'Orange Cash'**
  String get orangeCash;

  /// No description provided for @etisalatCash.
  ///
  /// In en, this message translates to:
  /// **'Etisalat Cash'**
  String get etisalatCash;

  /// No description provided for @instapay.
  ///
  /// In en, this message translates to:
  /// **'Instapay'**
  String get instapay;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @enterWalletPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your wallet phone number.'**
  String get enterWalletPhone;

  /// No description provided for @unableOpenPayment.
  ///
  /// In en, this message translates to:
  /// **'Unable to open payment gateway.'**
  String get unableOpenPayment;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment completed — refreshing balance.'**
  String get paymentCompleted;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment was cancelled or failed.'**
  String get paymentCancelled;

  /// No description provided for @topUpPay.
  ///
  /// In en, this message translates to:
  /// **'Top-up / Pay'**
  String get topUpPay;

  /// No description provided for @loadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Loading balance...'**
  String get loadingBalance;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please log in first.'**
  String get pleaseLoginFirst;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @linkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Linked account: {email}'**
  String linkedAccount(String email);

  /// No description provided for @addBalanceButton.
  ///
  /// In en, this message translates to:
  /// **'Add balance'**
  String get addBalanceButton;

  /// No description provided for @qrNotSupportedWeb.
  ///
  /// In en, this message translates to:
  /// **'QR scanning is not supported on Web.'**
  String get qrNotSupportedWeb;

  /// No description provided for @percentSuffix.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentSuffix(String value);

  /// No description provided for @signInWithPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a one-time code.'**
  String get signInWithPhoneSubtitle;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @confirmYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Confirm your phone number'**
  String get confirmYourPhone;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to\n{phone}'**
  String otpSentTo(String phone);

  /// No description provided for @enterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP code'**
  String get enterOtpCode;

  /// No description provided for @verifyOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyOtpButton;

  /// No description provided for @verifyingOtp.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifyingOtp;

  /// No description provided for @didntGetOtp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code? '**
  String get didntGetOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent again.'**
  String get otpResent;

  /// No description provided for @otpVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully'**
  String get otpVerifiedSuccess;

  /// No description provided for @accountCreatedVerifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Account created. Enter the OTP sent to your phone to continue.'**
  String get accountCreatedVerifyOtp;

  /// No description provided for @otpInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired verification code.'**
  String get otpInvalidCode;

  /// No description provided for @otpSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification session expired. Request a new code.'**
  String get otpSessionExpired;

  /// No description provided for @firebaseInvalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get firebaseInvalidPhoneNumber;

  /// No description provided for @endRidePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Please capture a parking photo before ending your ride.'**
  String get endRidePhotoRequired;

  /// No description provided for @endRidePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Parking verification'**
  String get endRidePhotoTitle;

  /// No description provided for @captureParkingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture parking photo'**
  String get captureParkingPhoto;

  /// No description provided for @phoneHintLocal.
  ///
  /// In en, this message translates to:
  /// **'1004832172'**
  String get phoneHintLocal;

  /// No description provided for @phoneInvalidLength.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 10 digits for Egypt numbers.'**
  String get phoneInvalidLength;

  /// No description provided for @phoneInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Egyptian mobile number starting with 1.'**
  String get phoneInvalidFormat;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we\'ll send a verification code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get resetPasswordSubtitle;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully. You can sign in now.'**
  String get passwordResetSuccess;

  /// No description provided for @otpCountdownHint.
  ///
  /// In en, this message translates to:
  /// **'Resend available in {seconds}s'**
  String otpCountdownHint(int seconds);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
