import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:glider/data/repositories/backend_service.dart';
import 'package:glider/data/services/ride_service.dart';
import 'package:glider/domain/entities/ride.dart';
import 'package:glider/domain/entities/scooter.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/core/location/location_accuracy_validator.dart';
import 'package:glider/data/repositories/ride_repository_impl.dart';
import 'package:glider/domain/usecases/check_active_ride_use_case.dart';

class RidePreview {
  const RidePreview({
    required this.serialNumber,
    required this.scooter,
    required this.user,
    required this.minimumRequiredBalance,
    required this.allowedUnlockRadiusMeters,
    this.distanceToScooterMeters,
  });

  final String serialNumber;
  final Scooter scooter;
  final AppUser user;
  final double minimumRequiredBalance;
  final double allowedUnlockRadiusMeters;
  final double? distanceToScooterMeters;

  bool get hasSufficientBalance => user.walletBalance >= minimumRequiredBalance;

  bool get isWithinUnlockRadius =>
      distanceToScooterMeters != null &&
      distanceToScooterMeters! <= allowedUnlockRadiusMeters;

  RidePreview copyWith({
    String? serialNumber,
    Scooter? scooter,
    AppUser? user,
    double? minimumRequiredBalance,
    double? allowedUnlockRadiusMeters,
    double? distanceToScooterMeters,
    bool clearDistance = false,
  }) {
    return RidePreview(
      serialNumber: serialNumber ?? this.serialNumber,
      scooter: scooter ?? this.scooter,
      user: user ?? this.user,
      minimumRequiredBalance:
          minimumRequiredBalance ?? this.minimumRequiredBalance,
      allowedUnlockRadiusMeters:
          allowedUnlockRadiusMeters ?? this.allowedUnlockRadiusMeters,
      distanceToScooterMeters: clearDistance
          ? null
          : (distanceToScooterMeters ?? this.distanceToScooterMeters),
    );
  }
}

abstract class RideState {
  const RideState();
}

class RideInitial extends RideState {
  const RideInitial();
}

class CheckingActiveRide extends RideState {
  const CheckingActiveRide();
}

class ScooterLoading extends RideState {
  const ScooterLoading({required this.serialNumber});

  final String serialNumber;
}

class ScooterLoaded extends RideState {
  const ScooterLoaded({required this.preview});

  final RidePreview preview;
}

class InsufficientFunds extends RideState {
  const InsufficientFunds({required this.preview});

  final RidePreview preview;
}

class ProximityChecking extends RideState {
  const ProximityChecking({required this.preview});

  final RidePreview preview;
}

class ProximityFailure extends RideState {
  const ProximityFailure({required this.preview});

  final RidePreview preview;
}

class RideStarting extends RideState {
  const RideStarting({required this.preview});

  final RidePreview preview;
}

class RideEnding extends RideState {
  const RideEnding({required this.preview});

  final RidePreview preview;
}

class RideInProgress extends RideState {
  const RideInProgress({required this.preview, required this.ride});

  final RidePreview preview;
  final Ride ride;
}

class RideFailure extends RideState {
  const RideFailure({required this.message, this.serialNumber, this.preview});

  final String message;
  final String? serialNumber;
  final RidePreview? preview;
}

class RideCubit extends Cubit<RideState> {
  RideCubit({
    BackendService? backendService,
    RideService? rideService,
    CheckActiveRideUseCase? checkActiveRideUseCase,
  }) : _backendService = backendService ?? BackendService(),
       _rideService = rideService ?? RideService(),
       _checkActiveRideUseCase =
           checkActiveRideUseCase ??
           CheckActiveRideUseCase(RideRepositoryImpl()),
       super(const RideInitial());

  final BackendService _backendService;
  final RideService _rideService;
  final CheckActiveRideUseCase _checkActiveRideUseCase;

  static const double minimumWalletBalance = 10.0;
  static const double unlockRadiusMeters = 35.0;

  Future<void> scanScooter(String rawCode) async {
    final serialNumber = _extractSerialNumber(rawCode);
    if (serialNumber == null || serialNumber.isEmpty) {
      emit(
        const RideFailure(
          message:
              'Unable to read this QR code. Please scan a Glider scooter QR.',
        ),
      );
      return;
    }

    emit(ScooterLoading(serialNumber: serialNumber));

    debugPrint('RIDE: scanScooter started for serial=$serialNumber');
    try {
      final user =
          _backendService.currentUser ??
          await _backendService.fetchCurrentUser();
      debugPrint(
        'RIDE: current user loaded, walletBalance=${user.walletBalance}',
      );
      final bundle = await _backendService.fetchLiveMap();
      debugPrint(
        'RIDE: live map loaded, scooter count=${bundle.scooters.length}',
      );
      final scooter = bundle.scooters.where((item) {
        final candidate = item.code.trim().toLowerCase();
        return candidate == serialNumber.toLowerCase();
      }).firstOrNull;

      if (scooter == null) {
        emit(
          RideFailure(
            message: 'Scooter $serialNumber was not found.',
            serialNumber: serialNumber,
          ),
        );
        return;
      }

      // Verify the scooter's live status (battery + availability) right
      // before allowing the user to start a ride. GET /Scooter/{serial}/status
      final liveStatus = await _backendService.fetchScooterStatus(scooter.code);
      if (!liveStatus.isAvailable) {
        emit(
          RideFailure(
            message:
                'This scooter is currently ${liveStatus.status.toLowerCase()}.',
            serialNumber: serialNumber,
          ),
        );
        return;
      }

      final refreshedScooter = scooter.copyWith(
        batteryPercent: liveStatus.batteryLevel,
        rawStatus: liveStatus.status,
        isAvailable: liveStatus.isAvailable,
      );

      final preview = RidePreview(
        serialNumber: serialNumber,
        scooter: refreshedScooter,
        user: user,
        minimumRequiredBalance: minimumWalletBalance,
        allowedUnlockRadiusMeters: unlockRadiusMeters,
      );

      if (!preview.hasSufficientBalance) {
        emit(InsufficientFunds(preview: preview));
        return;
      }

      await validateProximity(preview: preview);
    } catch (error) {
      debugPrint('RIDE ERROR: scanScooter failed for serial=$serialNumber');
      debugPrint('Error: $error');
      emit(RideFailure(message: error.toString(), serialNumber: serialNumber));
    }
  }

  Future<void> refreshRidePreview() async {
    final preview = _previewFromState();
    if (preview == null) {
      emit(const RideInitial());
      return;
    }

    debugPrint('RIDE: refreshRidePreview for serial=${preview.serialNumber}');
    try {
      final refreshedUser = await _backendService.fetchCurrentUser();
      debugPrint(
        'RIDE: refreshed current user, walletBalance=${refreshedUser.walletBalance}',
      );
      final refreshedPreview = preview.copyWith(user: refreshedUser);
      if (!refreshedPreview.hasSufficientBalance) {
        emit(InsufficientFunds(preview: refreshedPreview));
        return;
      }

      await validateProximity(preview: refreshedPreview);
    } catch (error) {
      debugPrint('RIDE ERROR: refreshRidePreview failed');
      debugPrint('Error: $error');
      emit(
        RideFailure(
          message: error.toString(),
          serialNumber: preview.serialNumber,
          preview: preview,
        ),
      );
    }
  }

  Future<void> validateProximity({RidePreview? preview}) async {
    final activePreview = preview ?? _previewFromState();
    if (activePreview == null) {
      emit(const RideInitial());
      return;
    }

    emit(ProximityChecking(preview: activePreview));

    try {
      final position = await _resolveCurrentPosition();
      debugPrint(
        'RIDE: current position resolved lat=${position.latitude} lng=${position.longitude}',
      );
      final distance = calculateDistanceMeters(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        scooterLatitude: activePreview.scooter.lat,
        scooterLongitude: activePreview.scooter.lng,
      );
      debugPrint('RIDE: distance calculated=${distance.toStringAsFixed(2)}m');

      final updatedPreview = activePreview.copyWith(
        distanceToScooterMeters: distance,
      );

      if (!updatedPreview.isWithinUnlockRadius) {
        emit(ProximityFailure(preview: updatedPreview));
        return;
      }

      emit(ScooterLoaded(preview: updatedPreview));
    } catch (error) {
      debugPrint(
        'RIDE ERROR: validateProximity failed for serial=${activePreview.serialNumber}',
      );
      debugPrint('Error: $error');
      emit(
        RideFailure(
          message: error.toString(),
          serialNumber: activePreview.serialNumber,
          preview: activePreview,
        ),
      );
    }
  }

  Future<void> startRide() async {
    final preview = _previewFromState();
    if (preview == null) {
      emit(
        const RideFailure(
          message: 'Scan a scooter first before starting a ride.',
        ),
      );
      return;
    }

    if (!preview.hasSufficientBalance) {
      emit(InsufficientFunds(preview: preview));
      return;
    }

    emit(RideStarting(preview: preview));

    try {
      final position = await _resolveCurrentPosition();
      final distance = calculateDistanceMeters(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        scooterLatitude: preview.scooter.lat,
        scooterLongitude: preview.scooter.lng,
      );
      final verifiedPreview = preview.copyWith(
        distanceToScooterMeters: distance,
      );

      if (!verifiedPreview.isWithinUnlockRadius) {
        emit(ProximityFailure(preview: verifiedPreview));
        return;
      }

      final ride = await _rideService.startRide(
        preview.serialNumber,
        userLatitude: position.latitude,
        userLongitude: position.longitude,
      );
      emit(RideInProgress(preview: verifiedPreview, ride: ride));
    } catch (error) {
      emit(
        RideFailure(
          message: error.toString(),
          serialNumber: preview.serialNumber,
          preview: preview,
        ),
      );
    }
  }

  void reset() {
    emit(const RideInitial());
  }

  Future<void> appStartedCheck({AppUser? currentUser}) async {
    if (state is! RideInitial) return;

    emit(const CheckingActiveRide());

    final user =
        currentUser ??
        _backendService.currentUser ??
        await _backendService.fetchCurrentUser();

    try {
      final activeRide = await _checkActiveRideUseCase.call(user.id);
      if (activeRide == null) {
        emit(const RideInitial());
        return;
      }

      await _rideService.restoreActiveRide(activeRide, user);

      final recoveredPreview = RidePreview(
        serialNumber: activeRide.scooterCode,
        scooter: Scooter(
          id: activeRide.scooterCode,
          code: activeRide.scooterCode,
          lat: _rideService.latestState?.scooterPosition.latitude ?? 0,
          lng: _rideService.latestState?.scooterPosition.longitude ?? 0,
          batteryPercent: _rideService.latestState?.batteryPercent ?? 0,
          isAvailable: false,
          locationName: activeRide.fromName,
          modelName: null,
          rawStatus: 'Active ride recovered',
        ),
        user: user,
        minimumRequiredBalance: minimumWalletBalance,
        allowedUnlockRadiusMeters: unlockRadiusMeters,
        distanceToScooterMeters: 0,
      );

      emit(RideInProgress(preview: recoveredPreview, ride: activeRide));
    } catch (error) {
      debugPrint('RIDE ERROR: active ride restoration failed: $error');
      emit(const RideInitial());
    }
  }

  double calculateDistanceMeters({
    required double userLatitude,
    required double userLongitude,
    required double scooterLatitude,
    required double scooterLongitude,
  }) {
    return Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      scooterLatitude,
      scooterLongitude,
    );
  }

  RidePreview? _previewFromState() {
    final current = state;
    if (current is ScooterLoaded) return current.preview;
    if (current is InsufficientFunds) return current.preview;
    if (current is ProximityChecking) return current.preview;
    if (current is ProximityFailure) return current.preview;
    if (current is RideStarting) return current.preview;
    if (current is RideEnding) return current.preview;
    if (current is RideInProgress) return current.preview;
    if (current is RideFailure) return current.preview;
    return null;
  }

  String? _extractSerialNumber(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    final querySerial =
        uri?.queryParameters['serialNumber'] ??
        uri?.queryParameters['serial'] ??
        uri?.queryParameters['code'];
    if (querySerial != null && querySerial.trim().isNotEmpty) {
      return querySerial.trim();
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final jsonSerial =
            decoded['serialNumber'] ?? decoded['serial'] ?? decoded['code'];
        if (jsonSerial is String && jsonSerial.trim().isNotEmpty) {
          return jsonSerial.trim();
        }
      }
    } catch (_) {
      // Fall back to plain-text parsing below.
    }

    final parts = trimmed.split(RegExp(r'[:|/\s]'));
    final candidate = parts.isNotEmpty ? parts.last.trim() : trimmed;
    return candidate.isEmpty ? trimmed : candidate;
  }

  Future<Position> _resolveCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to unlock a scooter.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    LocationAccuracyValidator.validate(position);
    return position;
  }

  /// Temporarily bypass proximity/accuracy guards during end-ride for indoor testing.
static const bool bypassEndRideGuards = false;
  
  Null get endPhotoPath => null;

  Future<Position> _resolveCurrentPositionForEndRide() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to end a ride.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<Ride> endActiveRide({Uint8List? endPhotoBytes}) async {
    var preview = _previewFromState();

    // لو الـ cubit مش عارف الـ preview، جيبه من الـ RideService مباشرة
    if (preview == null && _rideService.currentRide != null) {
      final activeRide = _rideService.currentRide!;
      preview = RidePreview(
        serialNumber: activeRide.scooterCode,
        scooter: Scooter(
          id: activeRide.scooterCode,
          code: activeRide.scooterCode,
          lat: _rideService.latestState?.scooterPosition.latitude ?? 0,
          lng: _rideService.latestState?.scooterPosition.longitude ?? 0,
          batteryPercent: _rideService.latestState?.batteryPercent ?? 0,
          isAvailable: false,
          locationName: activeRide.fromName,
          modelName: null,
          rawStatus: 'Recovered',
        ),
        user: _backendService.currentUser ?? AppUser.empty(),
        minimumRequiredBalance: minimumWalletBalance,
        allowedUnlockRadiusMeters: unlockRadiusMeters,
        distanceToScooterMeters: 0,
      );
      emit(RideInProgress(preview: preview, ride: activeRide));
    }

    if (preview == null) {
      throw StateError('No active ride preview available to end.');
    }

    // تأكيد إن الـ UI باعت أي داتا للصورة
    if ((endPhotoBytes == null || endPhotoBytes.isEmpty) &&
        (endPhotoPath == null)) {
      throw StateError('A parking photo is required to end the ride.');
    }

    emit(RideEnding(preview: preview));

    try {
      final position = bypassEndRideGuards
          ? await _resolveCurrentPositionForEndRide()
          : await _resolveCurrentPosition();

      _rideService.updateUserPosition(position.latitude, position.longitude);

      // 💡 التعديل هنا: بنمرر الـ Path والـ Bytes للـ RideService
      final ride = await _rideService.endRide(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        endPhotoBytes: endPhotoBytes,
        endPhotoPath: endPhotoPath, // 👈 باصي الـ Path الجديد هنا
      );

      emit(const RideInitial());
      return ride;
    } catch (error) {
      emit(
        RideFailure(
          message: error.toString(),
          serialNumber: preview.serialNumber,
          preview: preview,
        ),
      );
      rethrow;
    }
  }
}
