import 'package:flutter/material.dart';

import 'package:zakzouka/l10n/app_localizations.dart';
import 'qr_view_types.dart';

class QrViewImpl extends StatelessWidget {
  const QrViewImpl({super.key, required this.onScan});

  final OnScan onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Text(l10n.qrNotSupportedWeb),
    );
  }
}
