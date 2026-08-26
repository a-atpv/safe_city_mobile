import 'google_analytics.dart';
import 'meta_analytics.dart';

/// Единственная точка, через которую приложение шлёт аналитику.
///
/// Рекламных площадок у нас две — Meta (Facebook, Instagram) и Google Ads, —
/// и воронка им нужна одна и та же. Поэтому экраны зовут `AppAnalytics`, а он
/// разводит событие по обоим SDK: новое событие тогда добавляется в одном
/// месте и не может «случайно уйти только в Meta».
///
/// Что здесь можно отправлять, описано в `MetaAnalytics` и `GoogleAnalytics`
/// и одинаково для обоих: только факт события, код тарифа и сумма покупки.
/// Никакой геолокации, ничего о вызове SOS, никаких контактов — это не
/// осторожность вообще, а требование политики Google Play к приложениям с
/// фоновой геолокацией.
///
/// Установку («app install») ни одному из SDK сообщать не нужно: Meta считает
/// её сама при первом запуске, Firebase отправляет `first_open` — именно это
/// событие импортируется в Google Ads как конверсия «Установка приложения».
class AppAnalytics {
  AppAnalytics._();

  /// Вызывается в `main()` после `Firebase.initializeApp()`: Google Analytics
  /// без поднятого Firebase работать не будет.
  static Future<void> initialize() async {
    await Future.wait([
      MetaAnalytics.initialize(),
      GoogleAnalytics.initialize(),
    ]);
  }

  /// Системный запрос App Tracking Transparency на iOS — один на оба SDK.
  /// IDFA читают и Meta, и Firebase Analytics (в подах он тянется как
  /// `GoogleAppMeasurement/IdentitySupport`), но диалог система показывает
  /// один раз на приложение, и отказ закрывает идентификатор сразу для всех.
  /// Сам вызов оставлен на стороне Meta: там же живёт синхронизация флага
  /// сбора IDFA, которую Firebase делает за нас.
  static Future<void> requestTrackingPermission() =>
      MetaAnalytics.requestTrackingPermission();

  /// Регистрация — первое событие воронки после установки.
  static Future<void> logRegistration() => Future.wait([
        MetaAnalytics.logRegistration(),
        GoogleAnalytics.logRegistration(),
      ]);

  /// Пользователь ушёл на страницу оплаты.
  static Future<void> logCheckoutStarted({
    required String plan,
    required int amountTiyn,
    required String currency,
  }) =>
      Future.wait([
        MetaAnalytics.logCheckoutStarted(
          plan: plan,
          amountTiyn: amountTiyn,
          currency: currency,
        ),
        GoogleAnalytics.logCheckoutStarted(
          plan: plan,
          amountTiyn: amountTiyn,
          currency: currency,
        ),
      ]);

  /// Подписка подтверждена бэкендом.
  static Future<void> logPurchase({
    required int amountTiyn,
    required String currency,
    required String plan,
    required int orderId,
  }) =>
      Future.wait([
        MetaAnalytics.logPurchase(
          amountTiyn: amountTiyn,
          currency: currency,
          plan: plan,
          orderId: orderId,
        ),
        GoogleAnalytics.logPurchase(
          amountTiyn: amountTiyn,
          currency: currency,
          plan: plan,
          orderId: orderId,
        ),
      ]);
}
