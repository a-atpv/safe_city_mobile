import 'package:url_launcher/url_launcher.dart';

/// Opens the Robokassa payment page in the phone's own browser.
///
/// Deliberately not an in-app WebView and not an in-app browser sheet. Both
/// were tried and both died the same way: backgrounding the app on the card
/// form killed the process, whether the page lived in an
/// `SFSafariViewController` or in a `WKWebView` we controlled ourselves. In the
/// system browser the payment belongs to another app — ours backgrounds with a
/// plain Flutter screen on top, and the payment survives even if iOS reclaims
/// us while the user is away.
///
/// The way back is the deep link the backend's success/fail page redirects to
/// (`safecity://pay/...`), handled in `main.dart`. Nothing here can observe the
/// outcome; the caller confirms it by polling the subscription status, and the
/// server-side ResultURL callback is what actually activates it.
///
/// Returns false when no browser could be opened, so the caller can say so
/// instead of parking the user in front of a payment that never started.
class PaymentLauncher {
  static Future<bool> open(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
