import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/presentation/cubits/topup_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '50',
  );

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final methods = [
      'Visa / MasterCard',
      'Vodafone Cash',
      'Orange Cash',
      'Etisalat Cash',
      'Instapay',
    ];

    return BlocProvider(
      create: (_) => TopUpCubit(),
      child: BlocListener<TopUpCubit, TopUpState>(
        listener: (context, state) async {
          if (state.status == TopUpStatus.success) {
            final amount = double.tryParse(_amountController.text) ?? 0;
            await context.read<UserCubit>().topUp(amount);
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage ?? 'Top up successful')),
            );
            Navigator.pop(context);
          }

          if (state.status == TopUpStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
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
              body: Padding(
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
                    const SizedBox(height: 18),
                    Text(
                      'Choose payment method',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (state.status == TopUpStatus.loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ...methods.map(
                        (method) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                final amount =
                                    double.tryParse(_amountController.text) ?? 0;
                                context.read<TopUpCubit>().pay(
                                      amount: amount,
                                      method: method,
                                    );
                              },
                              child: Text(method),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
