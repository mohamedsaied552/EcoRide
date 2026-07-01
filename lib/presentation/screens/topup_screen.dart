import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakzouka/l10n/app_localizations.dart';
import 'package:zakzouka/presentation/cubits/topup_cubit.dart';
import 'package:zakzouka/presentation/cubits/user_cubit.dart';
import 'package:zakzouka/presentation/screens/topup_payment_screen.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  static const walletMethodId = 'mobile_wallet';

  final TextEditingController _amountController = TextEditingController(
    text: '50',
  );
  final TextEditingController _phoneController = TextEditingController();
  String _selectedMethodId = walletMethodId;
  bool _isNavigatingToPayment = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text) ?? 0;
    final phoneNumber = _phoneController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidAmount),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethodId == walletMethodId && phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterWalletPhone),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<TopUpCubit>().pay(
      amount: amount,
      walletPhoneNumber: phoneNumber,
    );
  }

  void _selectMethod(String methodId) {
    if (methodId == walletMethodId) {
      setState(() {
        _selectedMethodId = methodId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentMethods = <Map<String, dynamic>>[
      {'id': walletMethodId, 'label': l10n.mobileWallet, 'enabled': true},
      {'id': 'visa', 'label': l10n.visaMastercard, 'enabled': false},
      {'id': 'vodafone', 'label': l10n.vodafoneCash, 'enabled': false},
      {'id': 'orange', 'label': l10n.orangeCash, 'enabled': false},
      {'id': 'etisalat', 'label': l10n.etisalatCash, 'enabled': false},
      {'id': 'instapay', 'label': l10n.instapay, 'enabled': false},
    ];

    return BlocListener<TopUpCubit, TopUpState>(
      listener: (context, state) async {
        final messenger = ScaffoldMessenger.of(context);

        if (state.status == TopUpStatus.success) {
          final redirectUrl = state.redirectUrl;
          if (redirectUrl == null || redirectUrl.isEmpty) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.unableOpenPayment),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (_isNavigatingToPayment) {
            return;
          }
          _isNavigatingToPayment = true;

          final navigator = Navigator.of(context);
          final userCubit = context.read<UserCubit>();

          final finished = await navigator.push<bool>(
            MaterialPageRoute(
              builder: (_) => TopUpPaymentScreen(redirectUrl: redirectUrl),
            ),
          );

          if (!mounted) return;
          _isNavigatingToPayment = false;
          await userCubit.loadCurrentUser();
          //await walletCubit.loadBalance();

          if (mounted) {
            if (finished == null || finished == true) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.paymentCompleted)),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.paymentCancelled)),
              );
            }
          }
        }

        if (state.status == TopUpStatus.failure && state.errorMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<TopUpCubit, TopUpState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.addBalance)),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.enterAmount,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: l10n.egpPrefix,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.choosePaymentMethod,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: paymentMethods.map((method) {
                          final id = method['id'] as String;
                          final label = method['label'] as String;
                          final enabled = method['enabled'] as bool;
                          final selected = id == _selectedMethodId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: enabled
                                    ? () => _selectMethod(id)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: selected
                                      ? const Color.fromRGBO(31, 174, 108, 0.12)
                                      : null,
                                  foregroundColor: enabled
                                      ? selected
                                            ? const Color(0xFF1FAE6C)
                                            : null
                                      : Colors.grey,
                                  side: BorderSide(
                                    color: enabled
                                        ? selected
                                              ? const Color(0xFF1FAE6C)
                                              : Colors.grey
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: enabled ? null : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedMethodId == walletMethodId) ...[
                        const SizedBox(height: 24),
                        Text(
                          l10n.walletPhoneNumber,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: l10n.phoneHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: state.status == TopUpStatus.loading
                              ? null
                              : _submitPayment,
                          child: state.status == TopUpStatus.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l10n.topUpPay,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.status == TopUpStatus.loading)
                  Container(color: Colors.black.withAlpha(38)),
              ],
            ),
          );
        },
      ),
    );
  }
}
