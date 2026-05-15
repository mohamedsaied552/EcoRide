
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:glider/domain/entities/user.dart';
import '../../data/repositories/backend_service.dart';
import 'package:glider/data/services/image_picker_service.dart';

enum RegisterStep { details, idScan }

enum RegisterSubmissionStatus {
  idle,
  loading,
  success,
  awaitingVerification,
  failure,
}

enum RegisterImageSide { front, back }

class RegisterState {
  const RegisterState({
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.frontIdBytes,
    this.frontIdName,
    this.backIdBytes,
    this.backIdName,
    this.currentStep = RegisterStep.details,
    this.isPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
    this.submissionStatus = RegisterSubmissionStatus.idle,
    this.errorMessage,
    this.imageError,
    this.createdUser,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final Uint8List? frontIdBytes;
  final String? frontIdName;
  final Uint8List? backIdBytes;
  final String? backIdName;
  final RegisterStep currentStep;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final RegisterSubmissionStatus submissionStatus;
  final String? errorMessage;
  final String? imageError;
  final AppUser? createdUser;

  bool get hasFrontId => frontIdBytes != null && frontIdBytes!.isNotEmpty;

  bool get hasBackId => backIdBytes != null && backIdBytes!.isNotEmpty;

  bool get hasBothIdImages => hasFrontId && hasBackId;

  RegisterState copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    String? confirmPassword,
    Uint8List? frontIdBytes,
    String? frontIdName,
    Uint8List? backIdBytes,
    String? backIdName,
    RegisterStep? currentStep,
    bool? isPasswordObscured,
    bool? isConfirmPasswordObscured,
    RegisterSubmissionStatus? submissionStatus,
    String? errorMessage,
    String? imageError,
    AppUser? createdUser,
    bool clearFrontId = false,
    bool clearBackId = false,
    bool clearErrorMessage = false,
    bool clearImageError = false,
  }) {
    return RegisterState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      frontIdBytes: clearFrontId ? null : (frontIdBytes ?? this.frontIdBytes),
      frontIdName: clearFrontId ? null : (frontIdName ?? this.frontIdName),
      backIdBytes: clearBackId ? null : (backIdBytes ?? this.backIdBytes),
      backIdName: clearBackId ? null : (backIdName ?? this.backIdName),
      currentStep: currentStep ?? this.currentStep,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isConfirmPasswordObscured:
          isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      imageError: clearImageError ? null : (imageError ?? this.imageError),
      createdUser: createdUser ?? this.createdUser,
    );
  }
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({
    BackendService? backendService,
    ImagePickerService? imagePickerService,
  }) : _backendService = backendService ?? BackendService(),
       _imagePickerService = imagePickerService ?? ImagePickerService(),
       super(const RegisterState());

  final BackendService _backendService;
  final ImagePickerService _imagePickerService;

  void updateFullName(String value) {
    emit(state.copyWith(fullName: value, clearErrorMessage: true));
  }

  void updateEmail(String value) {
    emit(state.copyWith(email: value, clearErrorMessage: true));
  }

  void updatePhoneNumber(String value) {
    emit(state.copyWith(phoneNumber: value, clearErrorMessage: true));
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

  void continueToIdStep() {
    emit(
      state.copyWith(
        currentStep: RegisterStep.idScan,
        clearErrorMessage: true,
        clearImageError: true,
      ),
    );
  }

  void goBackToDetails() {
    emit(
      state.copyWith(
        currentStep: RegisterStep.details,
        clearErrorMessage: true,
        clearImageError: true,
      ),
    );
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
        emit(state.copyWith(imageError: 'No image selected.'));
        return;
      }

      if (side == RegisterImageSide.front) {
        emit(
          state.copyWith(
            frontIdBytes: image.bytes,
            frontIdName: image.fileName,
            clearImageError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            backIdBytes: image.bytes,
            backIdName: image.fileName,
            clearImageError: true,
          ),
        );
      }
    } catch (error) {
      emit(state.copyWith(imageError: error.toString()));
    }
  }

  void clearSelectedIdImage(RegisterImageSide side) {
    if (side == RegisterImageSide.front) {
      emit(state.copyWith(clearFrontId: true, clearImageError: true));
    } else {
      emit(state.copyWith(clearBackId: true, clearImageError: true));
    }
  }

  Future<void> submitRegistration() async {
    if (!state.hasBothIdImages) {
      emit(
        state.copyWith(
          imageError: 'Please upload both front and back images of your ID.',
        ),
      );
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
      final signupResult = await _backendService.signup(
        fullName: state.fullName.trim(),
        email: state.email.trim(),
        phoneNumber: state.phoneNumber.trim(),
        password: state.password,
        idFrontPhotoBytes: state.frontIdBytes!,
        idBackPhotoBytes: state.backIdBytes!,
      );
      emit(
        state.copyWith(
          submissionStatus: signupResult.requiresEmailVerification
              ? RegisterSubmissionStatus.awaitingVerification
              : RegisterSubmissionStatus.success,
          createdUser: signupResult.user,
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
