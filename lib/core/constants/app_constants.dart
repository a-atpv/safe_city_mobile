class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'https://safe-city-back-7c8ed50edd7d.herokuapp.com/api/v1';
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  
  // Subscription (display fallback; source of truth is GET /payments/plans)
  static const int monthlyPriceKzt = 800;
  static const int yearlyPriceKzt = 6900;
  // Auto-renewal: send recurring=true only after «Периодические платежи» is
  // enabled in the Robokassa cabinet (until then Robokassa returns error 34).
  // Flip to true at go-live.
  static const bool subscriptionRecurring = false;
  
  // OTP
  static const int otpLength = 4;
  static const int otpResendSeconds = 60;
  
  // Location
  static const int locationUpdateIntervalSeconds = 10;

  // WebSocket
  static const String wsUserUrl = 'wss://safe-city-back-7c8ed50edd7d.herokuapp.com/api/v1/ws/user';
}
