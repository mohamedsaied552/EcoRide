import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakzouka/domain/entities/map_zone.dart';
import 'package:zakzouka/domain/entities/scooter.dart';
import '../../data/repositories/backend_service.dart';

enum MapStatus { initial, loading, success, failure }

class MapState {
  const MapState({
    this.status = MapStatus.initial,
    this.scooters = const [],
    this.zones = const [],
    this.errorMessage,
  });

  final MapStatus status;
  final List<Scooter> scooters;
  final List<MapZone> zones;
  final String? errorMessage;

  MapState copyWith({
    MapStatus? status,
    List<Scooter>? scooters,
    List<MapZone>? zones,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MapState(
      status: status ?? this.status,
      scooters: scooters ?? this.scooters,
      zones: zones ?? this.zones,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MapCubit extends Cubit<MapState> {
  MapCubit({BackendService? backendService})
    : _backendService = backendService ?? BackendService(),
      super(const MapState());

  final BackendService _backendService;

  Future<void> load() async {
    emit(state.copyWith(status: MapStatus.loading, clearError: true));
    try {
      final bundle = await _backendService.fetchLiveMap();
      emit(
        state.copyWith(
          status: MapStatus.success,
          scooters: bundle.scooters,
          zones: bundle.zones,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: MapStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Refresh the live map when receiving a notification
  Future<void> refreshLiveMap() async {
    try {
      final bundle = await _backendService.fetchLiveMap();
      emit(
        state.copyWith(
          status: MapStatus.success,
          scooters: bundle.scooters,
          zones: bundle.zones,
          clearError: true,
        ),
      );
    } catch (error) {
      // Silent error - don't emit failure state to avoid disrupting the UI
      // Just log it for debugging
      debugPrint('Error refreshing live map: $error');
    }
  }
}
