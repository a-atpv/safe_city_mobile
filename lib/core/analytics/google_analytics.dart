import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Google Analytics for Firebase — вторая половина рекламной атрибуции, рядом
/// с `MetaAnalytics`: по этим событиям учатся кампании Google Ads, а сами
/// конверсии импортируются в Ads после связки проекта Firebase с аккаунтом Ads.
///
/// Правило о личных данных здесь ровно то же, что и для Meta, и по той же
/// причине — политике Google Play о фоновой геолокации: наружу уходят только
/// факт события, код тарифа и сумма покупки. Ни координат, ни адреса, ни
/// телефона, ни email, ни чего-либо о самом вызове SOS. По той же причине не
/// зовём `setUserId` и `setUserProperty`: наш идентификатор пользователя
/// связывает рекламный профиль с человеком, которого мы возим по адресам.
///
/// Установку считать руками не нужно: `first_open` — то самое событие, которое
/// в Google Ads импортируется как конверсия «Установка приложения», — SDK
/// отправляет сам при первом запуске после установки. `app_open`,
/// `session_start` и `screen_view` тоже собираются автоматически.
class GoogleAnalytics {
  GoogleAnalytics._();

  static FirebaseAnalytics? _analytics;

  /// Вызывается в `main()`, после `Firebase.initializeApp()`.
  ///
  /// Firebase может не подняться — нет `google-services.json` в сборке, истёк
  /// таймаут инициализации, — и тогда `FirebaseAnalytics.instance` бросит
  /// исключение. Проверяем приложение по умолчанию так же, как это делает
  /// `PushNotificationService`, и при его отсутствии просто молчим: события
  /// уйдут в никуда, но приложение экстренного вызова из-за аналитики
  /// падать не должно.
  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('GoogleAnalytics: skip init, no default Firebase app');
      return;
    }
    try {
      _analytics = FirebaseAnalytics.instance;
      debugPrint('Firebase Analytics initialized');
    } catch (e, st) {
      debugPrint('Firebase Analytics init failed: $e\n$st');
    }
  }

  /// Регистрация — стандартное `sign_up`, первое событие воронки после
  /// установки.
  static Future<void> logRegistration() =>
      _send((a) => a.logSignUp(signUpMethod: 'email_otp'));

  /// Переход на страницу оплаты — стандартное `begin_checkout`. Промежуточное
  /// событие: по нему кампании учатся на тех, кто дошёл до кассы, не дожидаясь
  /// редких покупок.
  static Future<void> logCheckoutStarted({
    required String plan,
    required int amountTiyn,
    required String currency,
  }) =>
      _send(
        (a) => a.logBeginCheckout(
          value: _tengeFrom(amountTiyn),
          currency: currency,
          items: [_planItem(plan, amountTiyn, currency)],
        ),
      );

  /// Подписка подтверждена бэкендом — стандартное `purchase`, главное событие
  /// для оптимизации кампаний.
  ///
  /// [amountTiyn] — сумма в тиынах, как её отдаёт бэкенд; [orderId] — наш
  /// внутренний номер платежа. Он уходит как `transaction_id`, чтобы одна
  /// покупка не посчиталась дважды, и о пользователе ничего не говорит.
  static Future<void> logPurchase({
    required int amountTiyn,
    required String currency,
    required String plan,
    required int orderId,
  }) =>
      _send(
        (a) => a.logPurchase(
          transactionId: '$orderId',
          value: _tengeFrom(amountTiyn),
          currency: currency,
          items: [_planItem(plan, amountTiyn, currency)],
        ),
      );

  /// Тариф как товар: код («monthly» / «yearly») и цена. Названия тарифа здесь
  /// намеренно нет — оно приходит с бэкенда и может оказаться чем угодно,
  /// а код мы задаём сами.
  static AnalyticsEventItem _planItem(
    String plan,
    int amountTiyn,
    String currency,
  ) =>
      AnalyticsEventItem(
        itemId: plan,
        itemCategory: 'subscription',
        price: _tengeFrom(amountTiyn),
        currency: currency,
        quantity: 1,
      );

  /// Бэкенд считает деньги в тиынах: 1 ₸ = 100 тиын.
  static double _tengeFrom(int amountTiyn) => amountTiyn / 100;

  static Future<void> _send(Future<void> Function(FirebaseAnalytics) event) async {
    final analytics = _analytics;
    if (analytics == null) {
      debugPrint('Firebase Analytics event skipped: not initialized');
      return;
    }
    try {
      await event(analytics);
    } catch (e, st) {
      debugPrint('Firebase Analytics event failed: $e\n$st');
    }
  }
}
