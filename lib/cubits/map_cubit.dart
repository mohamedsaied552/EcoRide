import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/scooter.dart';
import '../services/backend_service.dart';

enum MapStatus { initial, loading, success, failure }

class MapState {
  const MapState({
    this.status = MapStatus.initial,
    this.scooters = const [],
    this.errorMessage,
  });

  final MapStatus status;
  final List<Scooter> scooters;
  final String? errorMessage;

  MapState copyWith({
    MapStatus? status,
    List<Scooter>? scooters,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MapState(
      status: status ?? this.status,
      scooters: scooters ?? this.scooters,
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
      final scooters = await _backendService.fetchNearbyScooters();
      emit(
        state.copyWith(
          status: MapStatus.success,
          scooters: scooters,
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
}
