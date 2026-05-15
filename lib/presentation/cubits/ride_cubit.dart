import 'package:flutter_bloc/flutter_bloc.dart';

class RideState {
  final bool isRiding;
  final String? scooterId;

  RideState({required this.isRiding, this.scooterId});
}

class RideCubit extends Cubit<RideState> {
  RideCubit() : super(RideState(isRiding: false));

  void startRide(String id) {
    emit(RideState(isRiding: true, scooterId: id));
  }

  void stopRide() {
    emit(RideState(isRiding: false));
  }
}
