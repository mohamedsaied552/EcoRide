import 'package:flutter/material.dart';

import 'qr_view_types.dart';

class QrViewImpl extends StatelessWidget {
  const QrViewImpl({super.key, required this.onScan});

  final OnScan onScan;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('QR scanning is not supported on Web.'),
    );
  }
}
