import 'package:zakzouka/domain/entities/ride.dart';

/// Mapper for ActiveRideResponseDto -> `Ride` domain entity.
Ride mapActiveRideDtoToRide(Map<String, dynamic> dto) {
  final rideId = (dto['rideId'] ?? dto['id'] ?? '').toString();
  final scooterSerial =
      (dto['scooterSerialNumber'] ??
              dto['scooterSerial'] ??
              dto['scooterCode'] ??
              '')
          .toString();
  final startRaw =
      (dto['startTime'] ??
              dto['startTimeUtc'] ??
              dto['start'] ??
              dto['startTimeLocal'])
          ?.toString();
  final durationMinutes =
      (dto['currentDurationMinutes'] ?? dto['durationMinutes'] ?? 0) as num;
  final currentCost = (dto['currentCost'] ?? dto['currentFare'] ?? 0) as num;

  final startedAt = startRaw != null
      ? DateTime.parse(startRaw)
      : DateTime.now();
  // For an active ride, endedAt is represented as startedAt + duration
  final endedAt = startedAt.add(Duration(minutes: durationMinutes.toInt()));

  return Ride(
    id: rideId.isEmpty
        ? 'active_${DateTime.now().millisecondsSinceEpoch}'
        : rideId,
    scooterCode: scooterSerial,
    startedAt: startedAt,
    endedAt: endedAt,
    distanceKm: ((dto['distanceKm'] ?? 0) as num).toDouble(),
    cost: currentCost.toDouble(),
    fromName: (dto['fromName'] ?? scooterSerial) as String,
    toName: (dto['toName'] ?? dto['status'] ?? '') as String,
  );
}
