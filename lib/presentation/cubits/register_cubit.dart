
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/data/datasources/firebase_auth_service.dart';
import 'package:glider/data/repositories/backend_service.dart';
import 'package:glider/domain/entities/picked_image_data.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/data/services/image_picker_service.dart';
import 'package:glider/presentation/utils/phone_utils.dart';

enum RegisterSubmissionStatus {
  idle,
  sendingOtp,
  otpSent,
  loading,
  success,
  failure,
  requiresManualId,
}

enum RegisterImageSide { front, back }

class RegisterImageError {
  static const noImageSelected = 'no_image_selected';
  static const uploadBothId = 'upload_both_id';
  static const selfieRequired = 'selfie_required';
}

class RegisterState {
  const RegisterState({
    this.fullName = '',
    this.country = CountryDialCode.egypt,
    this.localPhoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.firebaseToken = '',
    this.verificationSession,
    this.frontIdImage,
    this.backIdImage,
    this.selfieImage,
    this.isPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
    this.submissionStatus = RegisterSubmissionStatus.idle,
    this.errorMessage,
    this.imageError,
    this.registeredUser,
  });

  final String fullName;
  final CountryDialCode country;
  final String localPhoneNumber;
  final String password;
  final String confirmPassword;
  final String firebaseToken;
  final PhoneVerificationSession? verificationSession;
  final PickedImageData? frontIdImage;
  final PickedImageData? backIdImage;
  final PickedImageData? selfieImage;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final RegisterSubmissionStatus submissionStatus;
  final String? errorMessage;
  final String? imageError;
  final AppUser? registeredUser;

  String get internationalPhoneNumber => PhoneUtils.toInternational(
    dialCode: country.dialCode,
    localNumber: localPhoneNumber,
  );

  Uint8List? get frontIdBytes => frontIdImage?.bytes;

  Uint8List? get backIdBytes => backIdImage?.bytes;

  String? get frontIdName => frontIdImage?.fileName;

  String? get backIdName => backIdImage?.fileName;

  bool get hasFrontId => frontIdImage != null && frontIdImage!.bytes.isNotEmpty;

  bool get hasBackId => backIdImage != null && backIdImage!.bytes.isNotEmpty;

  bool get hasBothIdImages => hasFrontId && hasBackId;

  bool get hasSelfie =>
      selfieImage != null && selfieImage!.bytes.isNotEmpty;

  bool get isPhoneVerified => firebaseToken.isNotEmpty;

  RegisterState copyWith({
    String? fullName,
    CountryDialCode? country,
    String? localPhoneNumber,
    String? password,
    String? confirmPassword,
    String? firebaseToken,
    PhoneVerificationSession? verificationSession,
    PickedImageData? frontIdImage,
    PickedImageData? backIdImage,
    PickedImageData? selfieImage,
    bool? isPasswordObscured,
    bool? isConfirmPasswordObscured,
    RegisterSubmissionStatus? submissionStatus,
    String? errorMessage,
    String? imageError,
    AppUser? registeredUser,
    bool clearFrontId = false,
    bool clearBackId = false,
    bool clearSelfie = false,
    bool clearErrorMessage = false,
    bool clearImageError = false,
    bool clearRegisteredUser = false,
  }) {
    return RegisterState(
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      localPhoneNumber: localPhoneNumber ?? this.localPhoneNumber,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      firebaseToken: firebaseToken ?? this.firebaseToken,
      verificationSession: verificationSession ?? this.verificationSession,
      frontIdImage: clearFrontId ? null : (frontIdImage ?? this.frontIdImage),
      backIdImage: clearBackId ? null : (backIdImage ?? this.backIdImage),
      selfieImage: clearSelfie ? null : (selfieImage ?? this.selfieImage),
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isConfirmPasswordObscured:
          isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      imageError: clearImageError ? null : (imageError ?? this.imageError),
      registeredUser:
          clearRegisteredUser ? null : (registeredUser ?? this.registeredUser),
    );
  }
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({
    FirebaseAuthService? firebaseAuthService,
    BackendService? backendService,
    ImagePickerService? imagePickerService,
  }) : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService(),
       _backendService = backendService ?? BackendService(),
       _imagePickerService = imagePickerService ?? ImagePickerService(),
       super(const RegisterState());

  final FirebaseAuthService _firebaseAuthService;
  final BackendService _backendService;
  final ImagePickerService _imagePickerService;

  void updateFullName(String value) {
    emit(state.copyWith(fullName: value, clearErrorMessage: true));
  }

  void updateCountry(CountryDialCode country) {
    emit(state.copyWith(country: country, clearErrorMessage: true));
  }

  void updateLocalPhoneNumber(String value) {
    emit(state.copyWith(localPhoneNumber: value, clearErrorMessage: true));
  }

  void updatePassword(String value) {
    emit(state.copyWith(password: value, clearErrorMessage: true));
  }

  void updateConfirmPassword(String value) {
    emit(state.copyWith(confirmPassword: value, clearErrorMessage: true));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  void toggleConfirmPasswordVisibility() {
    emit(
      state.copyWith(
        isConfirmPasswordObscured: !state.isConfirmPasswordObscured,
      ),
    );
  }

  void setFirebaseToken(String token) {
    emit(state.copyWith(firebaseToken: token, clearErrorMessage: true));
  }

  void updateVerificationSession(PhoneVerificationSession session) {
    emit(state.copyWith(verificationSession: session));
  }

  /// Validates form fields and triggers Firebase OTP immediately (fail-fast).
  Future<bool> startPhoneVerification() async {
    final phoneError = _validateLocalPhone();
    if (phoneError != null) {
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.failure,
          errorMessage: phoneError,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        submissionStatus: RegisterSubmissionStatus.sendingOtp,
        clearErrorMessage: true,
      ),
    );

    try {
      final session = await _firebaseAuthService.verifyPhoneNumber(
        state.internationalPhoneNumber,
      );
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.otpSent,
          verificationSession: session,
          clearErrorMessage: true,
        ),
      );
      return true;
    } on FirebaseAuthFailure catch (error) {
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.failure,
          errorMessage: error.code.name,
        ),
      );
      return false;
    } catch (error) {
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  String? _validateLocalPhone() {
    if (state.country.dialCode == CountryDialCode.egypt.dialCode) {
      return PhoneUtils.validateEgyptLocalNumber(state.localPhoneNumber);
    }
    final digits = PhoneUtils.digitsOnly(state.localPhoneNumber);
    if (digits.length < state.country.localDigits) {
      return 'invalidLength';
    }
    return null;
  }

  Future<void> pickIdImage({
    required RegisterImageSide side,
    required ImageSource source,
  }) async {
    emit(
      state.copyWith(
        submissionStatus: RegisterSubmissionStatus.idle,
        clearErrorMessage: true,
        clearImageError: true,
      ),
    );

    try {
      final image = await _imagePickerService.pickIdImage(source);
      if (image == null) {
        emit(
          state.copyWith(imageError: RegisterImageError.noImageSelected),
        );
        return;
      }

      if (side == RegisterImageSide.front) {
        emit(state.copyWith(frontIdImage: image, clearImageError: true));
      } else {
        emit(state.copyWith(backIdImage: image, clearImageError: true));
      }
    } catch (error) {
      emit(state.copyWith(imageError: error.toString()));
    }
  }

  void setIdImageBytes({
    required RegisterImageSide side,
    required Uint8List bytes,
    required String fileName,
  }) {
    final image = PickedImageData(bytes: bytes, fileName: fileName);
    if (side == RegisterImageSide.front) {
      emit(state.copyWith(frontIdImage: image, clearImageError: true));
    } else {
      emit(state.copyWith(backIdImage: image, clearImageError: true));
    }
  }

  void clearSelectedIdImage(RegisterImageSide side) {
    if (side == RegisterImageSide.front) {
      emit(state.copyWith(clearFrontId: true, clearImageError: true));
    } else {
      emit(state.copyWith(clearBackId: true, clearImageError: true));
    }
  }

  void setSelfieImage(Uint8List bytes) {
    emit(
      state.copyWith(
        selfieImage: PickedImageData(bytes: bytes, fileName: 'selfie.jpg'),
        clearImageError: true,
      ),
    );
  }

  /// Final POST /api/Auth/register after OTP + document capture.
  Future<void> submitRegistration({String? manualNationalId}) async {
    if (!state.isPhoneVerified) {
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.failure,
          errorMessage: 'missingVerificationId',
        ),
      );
      return;
    }

    if (!state.hasBothIdImages) {
      emit(state.copyWith(imageError: RegisterImageError.uploadBothId));
      return;
    }

    if (!state.hasSelfie) {
      emit(state.copyWith(imageError: RegisterImageError.selfieRequired));
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: RegisterSubmissionStatus.loading,
        clearErrorMessage: true,
        clearImageError: true,
      ),
    );

    try {
      final user = await _backendService.register(
        fullName: state.fullName.trim(),
        phoneNumber: state.internationalPhoneNumber,
        password: state.password,
        firebaseToken: state.firebaseToken,
        idFrontPhotoBytes: state.frontIdBytes!,
        idBackPhotoBytes: state.backIdBytes!,
        selfiePhotoBytes: state.selfieImage!.bytes,
        manualNationalId: manualNationalId,
      );
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.success,
          registeredUser: user,
        ),
      );
    } on ApiException catch (error) {
      if (error.message.startsWith('REQUIRES_MANUAL_ID')) {
        emit(
          state.copyWith(
            submissionStatus: RegisterSubmissionStatus.requiresManualId,
            errorMessage: error.message,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
