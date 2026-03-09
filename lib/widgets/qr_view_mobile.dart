import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'qr_view_types.dart';

class QrViewImpl extends StatefulWidget {
  const QrViewImpl({super.key, required this.onScan});

  final OnScan onScan;

  @override
  State<QrViewImpl> createState() => _QrViewImplState();
}

class _QrViewImplState extends State<QrViewImpl> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: (qrController) {
        controller = qrController;
        controller?.scannedDataStream.listen((scanData) {
          widget.onScan(scanData.code);
        });
      },
    );
  }
}
