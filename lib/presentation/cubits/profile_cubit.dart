import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:zakzouka/domain/entities/user.dart';
import '../../data/repositories/backend_service.dart';
import 'package:zakzouka/data/services/image_picker_service.dart';

enum ProfileStatus {
  initial,
  loading,
  ready,
  saving,
  changingPassword,
  failure,
}

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.avatarBytes,
    this.avatarFileName,
    this.errorMessage,
    this.successMessage,
  });

  final ProfileStatus status;
  final AppUser? user;
  final String fullName;
  final String email;
  final String phone;
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final Uint8List? avatarBytes;
  final String? avatarFileName;
  final String? errorMessage;
  final String? successMessage;

  String? get avatarDataUrl {
    if (avatarBytes == null) {
      return user?.avatarUrl;
    }
    return 'data:image/jpeg;base64,${base64Encode(avatarBytes!)}';
  }

  ProfileState copyWith({
    ProfileStatus? status,
    AppUser? user,
    String? fullName,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? errorMessage,
    String? successMessage,
    bool clearAvatar = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearPasswordFields = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      currentPassword: clearPasswordFields
          ? ''
          : (currentPassword ?? this.currentPassword),
      newPassword: clearPasswordFields ? '' : (newPassword ?? this.newPassword),
      confirmPassword: clearPasswordFields
          ? ''
          : (confirmPassword ?? this.confirmPassword),
      avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
      avatarFileName: clearAvatar
          ? null
          : (avatarFileName ?? this.avatarFileName),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    BackendService? backendService,
    ImagePickerService? imagePickerService,
  }) : _backendService = backendService ?? BackendService(),
       _imagePickerService = imagePickerService ?? ImagePickerService(),
       super(const ProfileState());

  final BackendService _backendService;
  final ImagePickerService _imagePickerService;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final user = await _backendService.fetchCurrentUser();
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          user: user,
          fullName: user.name,
          email: user.email,
          phone: user.phone,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void updateFullName(String value) => emit(state.copyWith(fullName: value));

  void updateEmail(String value) => emit(state.copyWith(email: value));

  void updatePhone(String value) => emit(state.copyWith(phone: value));

  void updateCurrentPassword(String value) =>
      emit(state.copyWith(currentPassword: value));

  void updateNewPassword(String value) =>
      emit(state.copyWith(newPassword: value));

  void updateConfirmPassword(String value) =>
      emit(state.copyWith(confirmPassword: value));

  Future<void> pickAvatar(ImageSource source) async {
    try {
      final image = await _imagePickerService.pickIdImage(source);
      if (image == null) {
        return;
      }
      emit(
        state.copyWith(
          avatarBytes: image.bytes,
          avatarFileName: image.fileName,
          clearError: true,
          clearSuccess: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<AppUser?> saveProfile() async {
    emit(
      state.copyWith(
        status: ProfileStatus.saving,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final user = await _backendService.updateProfile(
        fullName: state.fullName.trim(),
        email: state.email.trim(),
        phoneNumber: state.phone.trim(),
        avatarBytes: state.avatarBytes,
        avatarFileName: state.avatarFileName,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          user: user,
          fullName: user.name,
          email: user.email,
          phone: user.phone,
          successMessage: 'Profile updated successfully.',
          clearError: true,
          clearAvatar: true,
        ),
      );
      return user;
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      return null;
    }
  }

  Future<bool> changePassword() async {
    emit(
      state.copyWith(
        status: ProfileStatus.changingPassword,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await _backendService.changePassword(
        currentPassword: state.currentPassword,
        newPassword: state.newPassword,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          successMessage: 'Password updated successfully.',
          clearError: true,
          clearPasswordFields: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }
}
