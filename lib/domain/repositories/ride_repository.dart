import 'package:zakzouka/domain/entities/ride.dart';

abstract class RideRepository {
  /// Checks whether the current user has an active ride in the backend.
  Future<Ride?> checkActiveRide(String userId);
}
