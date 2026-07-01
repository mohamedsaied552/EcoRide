import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakzouka/l10n/app_localizations.dart';
import 'package:zakzouka/presentation/cubits/topup_cubit.dart';
import 'package:zakzouka/presentation/cubits/user_cubit.dart';
import 'package:zakzouka/presentation/cubits/wallet_cubit.dart';
import 'package:zakzouka/presentation/widgets/loading_spinner.dart';
import 'topup_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        if (userState.status == UserStatus.loading) {
          return Scaffold(
            body: LoadingSpinner(message: l10n.loadingBalance),
          );
        }

        final user = userState.user;
        return BlocBuilder<WalletCubit, WalletState>(
          builder: (context, walletState) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.wallet)),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: user == null
                ? Center(
                    child: Text(userState.errorMessage ?? l10n.pleaseLoginFirst),
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
                                l10n.currentBalance,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.costEgp(
                                  walletState.balance.toStringAsFixed(0),
                                ),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.linkedAccount(user.email),
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
                          child: Text(l10n.addBalanceButton),
                        ),
                      ),
                    ],
                  ),
          ),
        );
          },
        );
      },
    );
  }
}
