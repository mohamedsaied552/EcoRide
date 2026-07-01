import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:zakzouka/core/events/app_event_bus.dart';

import 'package:zakzouka/data/repositories/backend_service.dart';
import 'package:zakzouka/data/services/ride_hub_service.dart';

class WalletState {
  const WalletState({required this.balance, this.isLoading = false});

  final double balance;
  final bool isLoading;

  WalletState copyWith({double? balance, bool? isLoading}) => WalletState(
    balance: balance ?? this.balance,
    isLoading: isLoading ?? this.isLoading,
  );
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({BackendService? backendService, RideHubService? rideHubService})
    : _backendService = backendService ?? BackendService(),
      _rideHubService = rideHubService ?? RideHubService(),
      super(const WalletState(balance: 0));

  final BackendService _backendService;
  final RideHubService _rideHubService;
  StreamSubscription<double>? _walletSub;
  StreamSubscription<WalletRefreshRequestedEvent>? _eventSub;

  Future<void> initialize({double? initialBalance}) async {
    debugPrint("WalletCubit initialize called");

    if (initialBalance != null) {
      emit(state.copyWith(balance: initialBalance));
    }

    _walletSub?.cancel();
    _walletSub = _rideHubService.walletUpdates.listen((newBalance) {
      debugPrint("WalletCubit Received: $newBalance");
      emit(state.copyWith(balance: newBalance));
    });

    // Listen for FCM refresh_wallet action
    _eventSub?.cancel();
    if (GetIt.I.isRegistered<AppEventBus>()) {
      _eventSub = GetIt.I<AppEventBus>()
          .on<WalletRefreshRequestedEvent>()
          .listen((_) => _refreshFromApi());
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final user = await _backendService.fetchCurrentUser();
      debugPrint("WalletCubit refreshed from API: ${user.walletBalance}");
      emit(state.copyWith(balance: user.walletBalance));
    } catch (e) {
      debugPrint("WalletCubit API refresh failed: $e");
    }
  }

  void updateBalance(double newBalance) =>
      emit(state.copyWith(balance: newBalance));

  @override
  Future<void> close() {
    _walletSub?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
