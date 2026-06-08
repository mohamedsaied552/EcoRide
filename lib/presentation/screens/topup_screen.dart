import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/presentation/cubits/topup_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/presentation/screens/topup_payment_screen.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  static const walletMethod = 'Mobile Wallet';

  final TextEditingController _amountController = TextEditingController(
    text: '50',
  );
  final TextEditingController _phoneController = TextEditingController();
  String _selectedMethod = walletMethod;
  bool _isNavigatingToPayment = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final phoneNumber = _phoneController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethod == walletMethod && phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your wallet phone number.'),
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

  void _selectMethod(String method) {
    if (method == walletMethod) {
      setState(() {
        _selectedMethod = method;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethods = <Map<String, dynamic>>[
      {'label': walletMethod, 'enabled': true},
      {'label': 'Visa / MasterCard', 'enabled': false},
      {'label': 'Vodafone Cash', 'enabled': false},
      {'label': 'Orange Cash', 'enabled': false},
      {'label': 'Etisalat Cash', 'enabled': false},
      {'label': 'Instapay', 'enabled': false},
    ];

    return BlocListener<TopUpCubit, TopUpState>(
      listener: (context, state) async {
        final messenger = ScaffoldMessenger.of(context);

        if (state.status == TopUpStatus.success) {
          final redirectUrl = state.redirectUrl;
          if (redirectUrl == null || redirectUrl.isEmpty) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Unable to open payment gateway.'),
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

          // Show result to user — true indicates success, false indicates
          // cancellation/failure. If null, treat as unknown/successful.
          if (mounted) {
            if (finished == null || finished == true) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Payment completed — refreshing balance.'),
                ),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Payment was cancelled or failed.'),
                ),
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
            appBar: AppBar(title: const Text('Add Balance')),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter amount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: 'EGP ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Choose payment method',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: paymentMethods.map((method) {
                          final label = method['label'] as String;
                          final enabled = method['enabled'] as bool;
                          final selected = label == _selectedMethod;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: enabled
                                    ? () => _selectMethod(label)
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
                      if (_selectedMethod == walletMethod) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Wallet phone number',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '010XXXXXXXX',
                            border: OutlineInputBorder(),
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
                              : const Text(
                                  'Top-up / Pay',
                                  style: TextStyle(
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
