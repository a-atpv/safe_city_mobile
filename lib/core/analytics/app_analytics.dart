import 'appsflyer_analytics.dart';
import 'google_analytics.dart';
import 'meta_analytics.dart';

/// Единственная точка, через которую приложение шлёт аналитику.
///
/// Рекламных площадок у нас две — Meta (Facebook, Instagram) и Google Ads, —
/// а поверх них AppsFlyer, который сводит кампании обеих в один кабинет. Воронка
/// всем троим нужна одна и та же. Поэтому экраны зовут `AppAnalytics`, а он
/// разводит событие по всем SDK: новое событие тогда добавляется в одном
/// месте и не может «случайно уйти только в Meta».
///
/// Что здесь можно отправлять, описано в `MetaAnalytics`, `GoogleAnalytics` и
/// `AppsFlyerAnalytics` и одинаково для всех: только факт события, код тарифа
/// и сумма покупки.
/// Никакой геолокации, ничего о вызове SOS, никаких контактов — это не
/// осторожность вообще, а требование политики Google Play к приложениям с
/// фоновой геолокацией.
///
/// Установку («app install») ни одному из SDK сообщать не нужно: Meta считает
/// её сама при первом запуске, Firebase отправляет `first_open` — именно это
/// событие импортируется в Google Ads как конверсия «Установка приложения», —
/// а для AppsFlyer установка и есть первая сессия.
class AppAnalytics {
  AppAnalytics._();

  /// Вызывается в `main()` после `Firebase.initializeApp()`: Google Analytics
  /// без поднятого Firebase работать не будет.
  static Future<void> initialize() async {
    await Future.wait([
      MetaAnalytics.initialize(),
      GoogleAnalytics.initialize(),
      AppsFlyerAnalytics.initialize(),
    ]);
  }

  /// Системный запрос App Tracking Transparency на iOS — один на все SDK.
  /// IDFA читают и Meta, и Firebase Analytics (в подах он тянется как
  /// `GoogleAppMeasurement/IdentitySupport`), и AppsFlyer, но диалог система
  /// показывает один раз на приложение, и отказ закрывает идентификатор сразу
  /// для всех. Сам вызов оставлен на стороне Meta: там же живёт синхронизация
  /// флага сбора IDFA, которую Firebase и AppsFlyer делают за нас. Зато
  /// AppsFlyer до ответа придерживает сессию, и после ответа его нужно
  /// отпустить.
  static Future<void> requestTrackingPermission() async {
    await MetaAnalytics.requestTrackingPermission();
    AppsFlyerAnalytics.trackingPermissionSettled();
  }

  /// Маршруты, о которых аналитика не узнаёт: показ экрана вызова уже сам
  /// по себе сообщает, что человек нажал SOS, а про вызовы наружу не уходит
  /// ничего. Сплеш — не экран, а ожидание проверки токена.
  static bool _isTrackedScreen(String name) =>
      name != 'splash' && !name.startsWith('emergency');

  /// Переход на экран — `screen_view` в Firebase, по имени маршрута из
  /// `app_router.dart` («home», «subscribe», …). Только Firebase: в Meta и
  /// AppsFlyer просмотры экранов кампаниям ничего не дают, а Firebase сам
  /// видит во Flutter лишь один нативный экран на всё приложение.
  ///
  /// В именах маршрутов нет ни идентификаторов, ни параметров — только это и
  /// делает их безопасными для отправки.
  static void logScreen(String? name) {
    if (name == null || !_isTrackedScreen(name)) return;
    GoogleAnalytics.logScreen(name);
  }

  /// Регистрация — первое событие воронки после установки.
  static Future<void> logRegistration() => Future.wait([
        MetaAnalytics.logRegistration(),
        GoogleAnalytics.logRegistration(),
        AppsFlyerAnalytics.logRegistration(),
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
        AppsFlyerAnalytics.logCheckoutStarted(
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
        AppsFlyerAnalytics.logPurchase(
          amountTiyn: amountTiyn,
          currency: currency,
          plan: plan,
          orderId: orderId,
        ),
      ]);
}
