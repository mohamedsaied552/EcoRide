import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:zakzouka/l10n/app_localizations.dart';

class QrViewMobile extends StatefulWidget {
  const QrViewMobile({super.key});

  @override
  State<QrViewMobile> createState() => _QrViewMobileState();
}

class _QrViewMobileState extends State<QrViewMobile> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanQr)),
      body: MobileScanner(
        onDetect: (capture) {
          if (isScanned || capture.barcodes.isEmpty) {
            return;
          }

          final String? code = capture.barcodes.first.rawValue;
          if (code == null) {
            return;
          }

          isScanned = true;
          Navigator.pop(context, code);
        },
      ),
    );
  }
}
