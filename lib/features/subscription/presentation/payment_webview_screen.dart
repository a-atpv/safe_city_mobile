import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// In-app Robokassa payment page. It auto-closes when Robokassa
/// redirects the browser to the backend success/fail callback; the caller then
/// confirms the real outcome by polling the subscription status (server-side
/// ResultURL is the source of truth, not this screen).
///
/// **Background safety & 3D Secure support**:
///
/// Uses [WidgetsBindingObserver] to pause the JavaScript engine (`setJavaScriptMode(disabled)`)
/// when the app moves to background (`inactive`, `hidden`, `paused`), and resume it on return.
///
/// This prevents CPU spikes / iOS watchdog terminations (`0x8badf00d`), while preserving:
/// * Page DOM & form input values (e.g. card number entered by user)
/// * Cookies & session authentication
/// * 3D Secure / SMS OTP flow (when user switches to SMS app or bank app and comes back)
///
/// IMPORTANT: We do NOT destroy the page with `about:blank`, kill timers with JS injection,
/// or call `window.stop()` — doing so breaks 3DS verification and Robokassa state.
class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _popped = false;

  /// JS engine paused via setJavaScriptMode(disabled). Non-destructive —
  /// page state, card details, cookies, and internal timers survive.
  bool _jsPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // Pause JS engine when backgrounded to prevent background CPU usage / watchdog kills.
        // Page state, form inputs (card number), and session survive.
        _pauseJsEngine();
        break;

      case AppLifecycleState.resumed:
        _resumeJsEngine();
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  /// Pause the JS engine without destroying page state.
  Future<void> _pauseJsEngine() async {
    if (_jsPaused) return;
    _jsPaused = true;

    try {
      await _controller.setJavaScriptMode(JavaScriptMode.disabled);
    } catch (e) {
      debugPrint('PaymentWebViewScreen: error pausing JS engine: $e');
    }
  }

  /// Resume the JS engine when returning to foreground (e.g. from SMS / 3DS bank app).
  Future<void> _resumeJsEngine() async {
    if (!_jsPaused) return;
    _jsPaused = false;

    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    } catch (e) {
      debugPrint('PaymentWebViewScreen: error resuming JS engine: $e');
    }
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

  void _close() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop();
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
