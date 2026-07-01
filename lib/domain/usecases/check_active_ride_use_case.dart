import 'package:zakzouka/domain/entities/ride.dart';
import 'package:zakzouka/domain/repositories/ride_repository.dart';

class CheckActiveRideUseCase {
  CheckActiveRideUseCase(this._rideRepository);

  final RideRepository _rideRepository;

  Future<Ride?> call(String userId) async {
    return _rideRepository.checkActiveRide(userId);
  }
}
