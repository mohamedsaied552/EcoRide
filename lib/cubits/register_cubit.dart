import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../services/backend_service.dart';
import '../services/image_picker_service.dart';

enum RegisterStep { details, idScan }

enum RegisterSubmissionStatus { idle, loading, success, failure }

class RegisterState {
  const RegisterState({
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.idImageBytes,
    this.idImageName,
    this.currentStep = RegisterStep.details,
    this.isPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
    this.submissionStatus = RegisterSubmissionStatus.idle,
    this.errorMessage,
    this.imageError,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final Uint8List? idImageBytes;
  final String? idImageName;
  final RegisterStep currentStep;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final RegisterSubmissionStatus submissionStatus;
  final String? errorMessage;
  final String? imageError;

  bool get hasIdImage => idImageBytes != null && idImageBytes!.isNotEmpty;

  RegisterState copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    String? confirmPassword,
    Uint8List? idImageBytes,
    String? idImageName,
    RegisterStep? currentStep,
    bool? isPasswordObscured,
    bool? isConfirmPasswordObscured,
    RegisterSubmissionStatus? submissionStatus,
    String? errorMessage,
    String? imageError,
    bool clearIdImage = false,
    bool clearErrorMessage = false,
    bool clearImageError = false,
  }) {
    return RegisterState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      idImageBytes: clearIdImage ? null : (idImageBytes ?? this.idImageBytes),
      idImageName: clearIdImage ? null : (idImageName ?? this.idImageName),
      currentStep: currentStep ?? this.currentStep,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isConfirmPasswordObscured:
          isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      imageError: clearImageError ? null : (imageError ?? this.imageError),
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

  Future<void> pickIdImage(ImageSource source) async {
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

      emit(
        state.copyWith(
          idImageBytes: image.bytes,
          idImageName: image.fileName,
          clearImageError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(imageError: error.toString()));
    }
  }

  void clearSelectedIdImage() {
    emit(state.copyWith(clearIdImage: true, clearImageError: true));
  }

  Future<void> submitRegistration() async {
    if (!state.hasIdImage) {
      emit(state.copyWith(imageError: 'Please upload a clear ID image.'));
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
      final imagePayload = base64Encode(state.idImageBytes!);
      await _backendService.signup(
        fullName: state.fullName.trim(),
        email: state.email.trim(),
        phoneNumber: state.phoneNumber.trim(),
        password: state.password,
        idPhotoUrl: 'data:image/jpeg;base64,$imagePayload',
      );
      emit(
        state.copyWith(
          submissionStatus: RegisterSubmissionStatus.success,
          clearErrorMessage: true,
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
