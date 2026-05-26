import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef OnScan = void Function(String? code);

class QrViewWidget extends StatefulWidget {
  const QrViewWidget({
    super.key,
    required this.onScan,
  });

  final OnScan onScan;

  @override
  State<QrViewWidget> createState() => _QrViewWidgetState();
}

class _QrViewWidgetState extends State<QrViewWidget> {
  bool _isLocked = false;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        if (_isLocked || capture.barcodes.isEmpty) {
          return;
        }

        final code = capture.barcodes.first.rawValue;
        if (code == null || code.trim().isEmpty) {
          return;
        }

        _isLocked = true;
        widget.onScan(code);

        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isLocked = false);
          }
        });
      },
    );
  }
}
