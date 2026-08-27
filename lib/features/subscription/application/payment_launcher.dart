import 'package:flutter/material.dart';

import '../presentation/payment_webview_screen.dart';

/// Opens the Robokassa payment page for a given payment URL.
///
/// Uses an in-app [PaymentWebViewScreen] on **both** platforms. The screen
/// implements [WidgetsBindingObserver] to freeze/blank the WebView when the app
/// goes to background, preventing iOS watchdog kills (`0x8badf00d`).
///
/// Previously iOS used `SFSafariViewController` via `url_launcher`, but its
/// internal WebContent process kept the main thread blocked in background,
/// triggering the watchdog. In-app WebView gives us full lifecycle control.
///
/// The future completes when the payment screen is popped (either by the user
/// or automatically when Robokassa redirects to the success/fail callback).
/// The caller must confirm the outcome by polling the subscription status
/// afterwards — this only opens the page.
class PaymentLauncher {
  static Future<void> open(BuildContext context, String url) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: url)),
    );
  }
}
