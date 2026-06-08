import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:glider/core/constants/app_constants.dart';

class TopUpPaymentScreen extends StatefulWidget {
  const TopUpPaymentScreen({super.key, required this.redirectUrl});

  final String redirectUrl;

  @override
  State<TopUpPaymentScreen> createState() => _TopUpPaymentScreenState();
}

class _TopUpPaymentScreenState extends State<TopUpPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final uri = Uri.tryParse(widget.redirectUrl);
    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw ArgumentError.value(
        widget.redirectUrl,
        'redirectUrl',
        'Expected an absolute http(s) URL.',
      );
    }

    final backendHost = Uri.tryParse(AppConstants.baseUrl)?.host;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Only intercept navigations that return to our backend host
            // (ngrok or production). Do NOT intercept Paymob or other
            // intermediate hosts so the user can complete checkout.
            try {
              final reqUri = Uri.parse(request.url);
              if (backendHost != null && reqUri.host == backendHost) {
                final finished = _isSuccessFromCallback(reqUri);
                if (mounted) Navigator.of(context).pop(finished);
                return NavigationDecision.prevent;
              }
            } catch (_) {
              // If parsing fails, do not intercept.
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(uri);
  }

  bool _isSuccessFromCallback(Uri uri) {
    // Heuristic: check common query params or path fragments used by payment
    // callbacks. If nothing obvious is present, treat as success to let the
    // app refresh user state and verify on the backend.
    final q = uri.queryParameters;
    final successCandidates = <String>['success', 'status', 'result'];
    for (final key in successCandidates) {
      final value = q[key];
      if (value != null) {
        final v = value.toLowerCase();
        if (v == '1' || v == 'true' || v.contains('success')) return true;
        if (v == '0' ||
            v == 'false' ||
            v.contains('fail') ||
            v.contains('cancel')) {
          return false;
        }
      }
    }

    final path = uri.path.toLowerCase();
    if (path.contains('success') ||
        path.contains('completed') ||
        path.contains('return')) {
      return true;
    }
    if (path.contains('fail') ||
        path.contains('cancel') ||
        path.contains('error')) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
