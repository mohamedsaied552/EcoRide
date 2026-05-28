import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:glider/core/notifications/notification_manager.dart';
import 'package:glider/domain/entities/user.dart';
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
  UserCubit({BackendService? backendService})
    : _backendService = backendService ?? BackendService(),
      super(const UserState(status: UserStatus.unauthenticated));

  final BackendService _backendService;

  Future<AppUser?> login(String email, String password) async {
    emit(state.copyWith(status: UserStatus.loading, clearError: true));
    try {
      final user = await _backendService.login(email, password);
      emit(
        state.copyWith(
          status: UserStatus.authenticated,
          user: user,
          clearError: true,
        ),
      );
      // Fire-and-forget: FCM token sync must never block the login flow
      // (Firebase token retrieval can hang on cold start or denied perms).
      unawaited(_syncFcmTokenIfNeeded());
      return user;
    } catch (error) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          errorMessage: error.toString(),
          clearUser: true,
        ),
      );
      return null;
    }
  }

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

  void applyAuthenticatedUser(AppUser user) {
    emit(
      state.copyWith(
        status: UserStatus.authenticated,
        user: user,
        clearError: true,
      ),
    );
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
