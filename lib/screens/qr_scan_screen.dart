import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../widgets/qr_view.dart';
import 'ride_summary_screen.dart';

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});

  Future<void> _handleScan(BuildContext context, String? code) async {
    if (!context.mounted) return;
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code')),
      );
      return;
    }

    final service = FirebaseService();
    try {
      final ride = await service.startAndCompleteDemoRide(code.trim());
      final user = await service.fetchCurrentUser();
      if (!context.mounted) return;

      // Replace scanner with the ride summary so user cannot start multiple rides at once.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RideSummaryScreen(
            ride: ride,
            remainingBalance: user.walletBalance,
          ),
        ),
      );
    } on StateError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start ride. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: Stack(
        children: [
          QrViewWidget(
            onScan: (code) => _handleScan(context, code),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Align the QR code within the frame to unlock and start your ride.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
