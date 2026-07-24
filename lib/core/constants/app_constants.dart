class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'https://safe-city-back-7c8ed50edd7d.herokuapp.com/api/v1';
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  
  // Payments feature flag. While false, the whole purchase flow (paywall /
  // Robokassa checkout) is hidden from the UI — no entry point can reach
  // `/subscribe`. Subscription STATUS still gates SOS (subs are activated
  // out-of-band). Flip to true once Robokassa is live & App-Store approved.
  static const bool paymentEnabled = true;

  // Subscription (display fallback; source of truth is GET /payments/plans)
  static const int monthlyPriceKzt = 800;
  static const int yearlyPriceKzt = 6900;
  // Auto-renewal: send recurring=true only after «Периодические платежи» is
  // enabled in the Robokassa cabinet (until then Robokassa returns error 34).
  // Flip to true at go-live.
  static const bool subscriptionRecurring = false;
  // Whether the paywall DESCRIBES the subscription as auto-renewing (amount,
  // frequency, duration, how to cancel). Deliberately separate from
  // `subscriptionRecurring`: the Robokassa «Периодические платежи» заявка
  // requires a screenshot of a form that already spells those terms out, while
  // the API must keep sending recurring=false until the cabinet approves.
  // Flip to true for that screenshot build, then permanently together with
  // `subscriptionRecurring` at go-live. Keep false in shipped builds while
  // charges are one-off — otherwise the copy promises renewals that never run.
  static const bool subscriptionRecurringCopy = false;
  
  // OTP
  static const int otpLength = 4;
  static const int otpResendSeconds = 60;
  
  // Location
  static const int locationUpdateIntervalSeconds = 10;

  // WebSocket
  static const String wsUserUrl = 'wss://safe-city-back-7c8ed50edd7d.herokuapp.com/api/v1/ws/user';
}
