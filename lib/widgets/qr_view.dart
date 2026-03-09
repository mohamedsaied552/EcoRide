import 'package:flutter/material.dart';

import 'qr_view_types.dart';
import 'qr_view_stub.dart' if (dart.library.io) 'qr_view_mobile.dart';

class QrViewWidget extends StatelessWidget {
  const QrViewWidget({super.key, required this.onScan});

  final OnScan onScan;

  @override
  Widget build(BuildContext context) {
    return QrViewImpl(onScan: onScan);
  }
}
