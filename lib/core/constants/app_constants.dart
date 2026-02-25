class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'https://safe-city-back-7c8ed50edd7d.herokuapp.com/api/v1';
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  
  // Subscription
  static const int monthlyPriceKzt = 2990;
  static const int yearlyPriceKzt = 24990;
  
  // OTP
  static const int otpLength = 4;
  static const int otpResendSeconds = 60;
  
  // Location
  static const int locationUpdateIntervalSeconds = 10;
}
