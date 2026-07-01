import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:zakzouka/core/notifications/notification_manager.dart';
import 'package:zakzouka/data/datasources/firebase_auth_service.dart';
import 'package:zakzouka/domain/entities/user.dart';
import '../../data/repositories/backend_service.dart';

enum UserStatus { initial, loading, authenticated, unauthenticated, failure }

class UserState {
  const UserState({
    this.status = UserStatus.initial,
    this.user,
    this.errorMessage,
  });

  final UserStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == UserStatus.authenticated && user != null;

  bool get isAdmin => user?.isAdmin ?? false;

  UserState copyWith({
    UserStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return UserState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserCubit extends Cubit<UserState> {
  UserCubit({
    BackendService? backendService,
    FirebaseAuthService? firebaseAuthService,
  }) : _backendService = backendService ?? BackendService(),
       _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService(),
       super(const UserState(status: UserStatus.unauthenticated));

  final BackendService _backendService;
  final FirebaseAuthService _firebaseAuthService;

  Future<void> loadCurrentUser() async {
    emit(state.copyWith(status: UserStatus.loading, clearError: true));
    try {
      final user = await _backendService.fetchCurrentUser();
      emit(
        state.copyWith(
          status: UserStatus.authenticated,
          user: user,
          clearError: true,
        ),
      );
      unawaited(_syncFcmTokenIfNeeded());
    } catch (error) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          errorMessage: error.toString(),
          clearUser: true,
        ),
      );
    }
  }

  Future<bool> restoreSession() async {
    emit(state.copyWith(status: UserStatus.loading, clearError: true));

    if (await _backendService.hasSavedSession()) {
      try {
        final user = await _backendService.fetchCurrentUser();
        emit(
          state.copyWith(
            status: UserStatus.authenticated,
            user: user,
            clearError: true,
          ),
        );
        unawaited(_syncFcmTokenIfNeeded());
        return true;
      } catch (_) {
        await _backendService.logout();
      }
    }

    emit(
      state.copyWith(
        status: UserStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      ),
    );
    return false;
  }

  void applyAuthenticatedUser(AppUser user) {
    emit(
      state.copyWith(
        status: UserStatus.authenticated,
        user: user,
        clearError: true,
      ),
    );
    unawaited(_syncFcmTokenIfNeeded());
  }

  Future<void> topUp(double amount) async {
    try {
      final user = await _backendService.topUpWallet(amount);
      emit(
        state.copyWith(
          status: UserStatus.authenticated,
          user: user,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _syncFcmTokenIfNeeded() async {
    if (!GetIt.I.isRegistered<NotificationManager>()) return;
    try {
      await GetIt.I<NotificationManager>().syncTokenWithServer();
    } catch (_) {
      // Silent — failure to register the FCM token must not block login.
    }
  }

  Future<void> logout() async {
    await _firebaseAuthService.signOut();
    await _backendService.logout();
    await GetIt.I<NotificationManager>().logoutCleanup();
    emit(
      state.copyWith(
        status: UserStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      ),
    );
  }
}
