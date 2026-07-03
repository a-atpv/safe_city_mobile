import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../presentation/payment_webview_screen.dart';

/// Opens the Robokassa payment page for a given payment URL.
///
/// * Android — an in-app [PaymentWebViewScreen] (auto-closes on return); the
///   future completes when that screen is popped.
/// * iOS — SFSafariViewController via `url_launcher` (App-Store friendly:
///   payment happens outside the app UI). The future completes right after the
///   sheet is presented.
///
/// In both cases the caller must confirm the outcome by polling the
/// subscription status afterwards — this only opens the page.
class PaymentLauncher {
  static Future<void> open(BuildContext context, String url) async {
    if (Platform.isAndroid) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: url)),
      );
    } else {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    }
  }
}
