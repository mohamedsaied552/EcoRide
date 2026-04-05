import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrViewMobile extends StatefulWidget {
  const QrViewMobile({super.key});

  @override
  State<QrViewMobile> createState() => _QrViewMobileState();
}

class _QrViewMobileState extends State<QrViewMobile> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: (capture) {
          if (isScanned) return;
          if (capture.barcodes.isEmpty) return;

          final String? code = capture.barcodes.first.rawValue;

          if (code != null) {
            isScanned = true;

            print("Scanned: $code");

            // مثال: ارجع بالكود للشاشة اللي قبلها
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
