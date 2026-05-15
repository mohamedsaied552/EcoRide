import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef OnScan = Function(String code);

class QrViewWidget extends StatelessWidget {
  final OnScan onScan;

  const QrViewWidget({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    bool isScanned = false;

    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: (capture) {
          if (isScanned) return;

          final String? code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;

          if (code != null) {
            isScanned = true;

            onScan(code);

            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
