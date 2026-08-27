import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// In-app Robokassa payment page. It auto-closes when Robokassa
/// redirects the browser to the backend success/fail callback; the caller then
/// confirms the real outcome by polling the subscription status (server-side
/// ResultURL is the source of truth, not this screen).
///
/// Nothing here touches the page across app lifecycle changes, and that is
/// deliberate. Freezing the payment page while the app is backgrounded belongs
/// in `AppDelegate`, which does it natively and only on a real background:
///
/// * `AppLifecycleState.inactive` fires on any loss of focus — the notification
///   banner carrying the 3DS code, Control Center, an incoming call. Cutting JS
///   there kills the payment page mid-payment.
/// * `setJavaScriptMode` on iOS writes `allowsContentJavaScript` on
///   `defaultWebpagePreferences`, which WebKit reads at navigation time. It
///   leaves the current page alone and disables JS for the *next* one — which
///   is the backend return page, and that page bounces back into the app with
///   `location.replace`.
class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _popped = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isReturnUrl(request.url)) {
              _close();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (_isReturnUrl(url)) {
              _close();
              return;
            }
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  bool _isReturnUrl(String url) =>
      url.contains('/payments/robokassa/success') ||
      url.contains('/payments/robokassa/fail') ||
      // The backend success/fail page redirects here to bounce back to the app;
      // catch it too so the WebView never chokes on the unknown scheme.
      url.startsWith('safecity://');

  /// Both callers are WebView callbacks, and `onNavigationRequest` runs while
  /// WebKit waits for the policy decision — popping right there tears the
  /// WKWebView down mid-decision. Hand the decision back first, pop on the next
  /// turn of the event loop.
  void _close() {
    if (_popped) return;
    _popped = true;
    Timer.run(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Оплата'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
