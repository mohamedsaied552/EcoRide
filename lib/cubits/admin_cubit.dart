import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/scooter.dart';
import '../models/user.dart';
import '../services/backend_service.dart';

enum AdminStatus { initial, loading, success, saving, failure }

class AdminState {
  const AdminState({
    this.status = AdminStatus.initial,
    this.users = const [],
    this.scooters = const [],
    this.code = '',
    this.locationName = '',
    this.lat = '',
    this.lng = '',
    this.batteryPercent = '100',
    this.isAvailable = true,
    this.editingScooterId,
    this.errorMessage,
    this.successMessage,
  });

  final AdminStatus status;
  final List<AppUser> users;
  final List<Scooter> scooters;
  final String code;
  final String locationName;
  final String lat;
  final String lng;
  final String batteryPercent;
  final bool isAvailable;
  final String? editingScooterId;
  final String? errorMessage;
  final String? successMessage;

  bool get isEditing => editingScooterId != null;

  AdminState copyWith({
    AdminStatus? status,
    List<AppUser>? users,
    List<Scooter>? scooters,
    String? code,
    String? locationName,
    String? lat,
    String? lng,
    String? batteryPercent,
    bool? isAvailable,
    String? editingScooterId,
    String? errorMessage,
    String? successMessage,
    bool clearEditing = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminState(
      status: status ?? this.status,
      users: users ?? this.users,
      scooters: scooters ?? this.scooters,
      code: code ?? this.code,
      locationName: locationName ?? this.locationName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isAvailable: isAvailable ?? this.isAvailable,
      editingScooterId:
          clearEditing ? null : (editingScooterId ?? this.editingScooterId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AdminCubit extends Cubit<AdminState> {
  AdminCubit({BackendService? backendService})
      : _backendService = backendService ?? BackendService(),
        super(const AdminState());

  final BackendService _backendService;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: AdminStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final users = await _backendService.fetchAdminUsers();
      final scooters = await _backendService.fetchAdminScooters();
      emit(
        state.copyWith(
          status: AdminStatus.success,
          users: users,
          scooters: scooters,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void updateCode(String value) => emit(state.copyWith(code: value));

  void updateLocationName(String value) =>
      emit(state.copyWith(locationName: value));

  void updateLat(String value) => emit(state.copyWith(lat: value));

  void updateLng(String value) => emit(state.copyWith(lng: value));

  void updateBatteryPercent(String value) =>
      emit(state.copyWith(batteryPercent: value));

  void updateAvailability(bool value) =>
      emit(state.copyWith(isAvailable: value));

  void startEditing(Scooter scooter) {
    emit(
      state.copyWith(
        editingScooterId: scooter.id,
        code: scooter.code,
        locationName: scooter.locationName,
        lat: scooter.lat.toString(),
        lng: scooter.lng.toString(),
        batteryPercent: scooter.batteryPercent.toString(),
        isAvailable: scooter.isAvailable,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  void clearForm() {
    emit(
      state.copyWith(
        code: '',
        locationName: '',
        lat: '',
        lng: '',
        batteryPercent: '100',
        isAvailable: true,
        clearEditing: true,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  Future<void> saveScooter() async {
    final lat = double.tryParse(state.lat);
    final lng = double.tryParse(state.lng);
    final battery = int.tryParse(state.batteryPercent);

    if (state.code.trim().isEmpty ||
        state.locationName.trim().isEmpty ||
        lat == null ||
        lng == null ||
        battery == null) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          errorMessage: 'Please fill all scooter fields with valid values.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AdminStatus.saving,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final scooters = await _backendService.saveAdminScooter(
        id: state.editingScooterId,
        code: state.code.trim(),
        locationName: state.locationName.trim(),
        lat: lat,
        lng: lng,
        batteryPercent: battery,
        isAvailable: state.isAvailable,
      );
      emit(
        state.copyWith(
          status: AdminStatus.success,
          scooters: scooters,
          successMessage:
              state.isEditing ? 'Scooter updated.' : 'Scooter added.',
          code: '',
          locationName: '',
          lat: '',
          lng: '',
          batteryPercent: '100',
          isAvailable: true,
          clearEditing: true,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteScooter(String id) async {
    emit(
      state.copyWith(
        status: AdminStatus.saving,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final scooters = await _backendService.deleteAdminScooter(id);
      emit(
        state.copyWith(
          status: AdminStatus.success,
          scooters: scooters,
          successMessage: 'Scooter deleted.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
