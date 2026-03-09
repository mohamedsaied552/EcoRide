import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _amountController = TextEditingController(text: '50');
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay(String method) async {
    setState(() => _loading = true);
    await _paymentService.topUp(
      amount: double.tryParse(_amountController.text) ?? 0,
      method: method,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Top up successful via $method')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods = [
      "Visa / MasterCard",
      "Vodafone Cash",
      "Orange Cash",
      "Etisalat Cash",
      "Instapay",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Add Balance")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter amount",
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
              "Choose payment method",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ...methods.map(
                (method) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _pay(method),
                      child: Text(method),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
