import 'package:glider/domain/entities/ride.dart';
import 'package:glider/domain/repositories/ride_repository.dart';

class CheckActiveRideUseCase {
  CheckActiveRideUseCase(this._rideRepository);

  final RideRepository _rideRepository;

  Future<Ride?> call(String userId) async {
    return _rideRepository.checkActiveRide(userId);
  }
}
