import 'package:flutter_bloc/flutter_bloc.dart';

class WalletState {
  final double balance;

  WalletState(this.balance);
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit() : super(WalletState(100)); // start with 100 EGP

  void deduct(double amount) {
    emit(WalletState(state.balance - amount));
  }

  void topUp(double amount) {
    emit(WalletState(state.balance + amount));
  }
}
