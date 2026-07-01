import 'package:zakzouka/data/datasources/ride_remote_data_source.dart';
import 'package:zakzouka/domain/entities/ride.dart';
import 'package:zakzouka/domain/repositories/ride_repository.dart';

class RideRepositoryImpl implements RideRepository {
  RideRepositoryImpl({RideRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? RideRemoteDataSourceImpl();

  final RideRemoteDataSource _remoteDataSource;

  @override
  Future<Ride?> checkActiveRide(String userId) {
    return _remoteDataSource.checkActiveRide(userId: userId);
  }
}
