import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/presentation/cubits/topup_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/presentation/widgets/loading_spinner.dart';
import 'topup_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state.status == UserStatus.loading) {
          return const Scaffold(
            body: LoadingSpinner(message: 'Loading balance...'),
          );
        }

        final user = state.user;
        return Scaffold(
          appBar: AppBar(title: const Text('Wallet')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: user == null
                ? Center(
                    child: Text(state.errorMessage ?? 'Please log in first.'),
                  )
                : Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current balance',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${user.walletBalance.toStringAsFixed(0)} EGP',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Linked account: ${user.email}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => TopUpCubit(),
                                  child: const TopUpScreen(),
                                ),
                              ),
                            );
                          },
                          child: const Text('Add balance'),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
