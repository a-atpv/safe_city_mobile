import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

/// AppsFlyer — атрибуция установок и покупок сразу по всем рекламным
/// кампаниям. `MetaAnalytics` и `GoogleAnalytics` видят каждая свою площадку,
/// AppsFlyer сводит их в одном кабинете.
///
/// Правило о личных данных здесь то же, что у соседей, и по той же причине —
/// политике Google Play о фоновой геолокации: наружу уходят только факт
/// события, код тарифа, сумма покупки и наш номер платежа. Ни координат, ни
/// адреса, ни телефона, ни email, ни чего-либо о вызове SOS. По той же причине
/// не зовём `setCustomerUserId` и хешированные `setUserEmail`/`setUserPhone`:
/// хеш почты всё равно связывает рекламный профиль с конкретным человеком.
///
/// Установку и запуски SDK считает сам: install — это первая сессия после
/// установки, отдельного события для неё нет.
///
/// Вне Dart у интеграции одна деталь: `NSAdvertisingAttributionReportEndpoint`
/// в `ios/Runner/Info.plist`. По этому адресу Apple шлёт AppsFlyer копии
/// постбэков SKAdNetwork, и по ним AppsFlyer сверяет, какие установки
/// приписали себе рекламные сети. Адрес в приложении может быть только один.
class AppsFlyerAnalytics {
  AppsFlyerAnalytics._();

  /// Dev key аккаунта (кабинет AppsFlyer → App Settings → Dev Key). Секретом
  /// не является: он лежит внутри каждой установленной сборки, а серверный API
  /// событий с 2023 года принимает отдельный S2S-ключ, а не этот.
  static const _devKey = 'Y8JbrreeJ4vxUzMTYHuWGZ';

  /// App Store ID приложения — строго без префикса «id», с которым его
  /// показывает кабинет: iOS SDK принимает только число и с префиксом не
  /// отправит ни одной сессии. Android берёт имя пакета и этот ID не читает.
  static const _appleAppId = '6759368857';

  /// Сколько сессия на iOS ждёт ответа на запрос отслеживания (ATT).
  ///
  /// Установку с IDFA AppsFlyer приписывает кампании точно, без него — только
  /// в агрегированной статистике SKAdNetwork, поэтому SDK советует отправлять
  /// первую сессию после ответа. Но запрос у нас намеренно живёт на главном
  /// экране, то есть после входа по коду из письма, — минуты через две после
  /// установки. Для запроса, который появляется после двухминутного
  /// онбординга, AppsFlyer и советует ждать две минуты. Дольше нельзя: пока
  /// сессия не отправлена, установки для AppsFlyer не существует, и тот, кто
  /// закрыл приложение раньше и не вернулся, в статистику не попадёт вовсе.
  /// События, записанные за время ожидания (регистрация), SDK копит сам и
  /// отправляет сразу после старта сессии.
  static const _trackingAnswerTimeout = Duration(minutes: 2);

  static final AppsFlyerSdk _sdk = AppsFlyerSdk.instance;

  static bool _initialized = false;

  /// Сессия уже поставлена в очередь и ждёт ответа на ATT. Слушатель
  /// готовности срабатывает на каждом выходе на передний план, и без этого
  /// флага человек, сходивший за кодом в почту, получил бы по сессии на каждое
  /// возвращение в приложение, отправленные разом.
  static bool _startPending = false;

  static final Completer<void> _trackingAnswered = Completer<void>();

  /// Вызывается в `main()`. Ошибки глотаем: аналитика не тот повод, чтобы
  /// приложение экстренного вызова не запустилось.
  static Future<void> initialize() async {
    try {
      // Подробный лог SDK — только в отладочной сборке: по нему проверяется
      // интеграция (отправка сессии и ответ 200 от AppsFlyer).
      if (kDebugMode) await _sdk.enableDebug(true);
      await _sdk.init(devKey: _devKey, appId: _appleAppId);
      // SDK 7 сам сессию не шлёт: `start()` нужен на каждом выходе приложения
      // на передний план, и ровно об этом сообщает слушатель готовности.
      // Регистрируется последним — он может сработать сразу же.
      await _sdk.registerSessionReadyListener(_onSessionReady);
      _initialized = true;
      debugPrint('AppsFlyer initialized');
    } catch (e, st) {
      debugPrint('AppsFlyer init failed: $e\n$st');
    }
  }

  /// Пользователь ответил на запрос ATT (или запрос не удалось показать) —
  /// ждать дальше незачем.
  static void trackingPermissionSettled() {
    if (!_trackingAnswered.isCompleted) _trackingAnswered.complete();
  }

  static void _onSessionReady() {
    if (_startPending) return;
    _startPending = true;
    unawaited(_startSession());
  }

  static Future<void> _startSession() async {
    try {
      await _waitForTrackingAnswer();
      await _sdk.start();
    } catch (e, st) {
      debugPrint('AppsFlyer start failed: $e\n$st');
    } finally {
      _startPending = false;
    }
  }

  static Future<void> _waitForTrackingAnswer() async {
    if (!Platform.isIOS) return;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;
    await _trackingAnswered.future.timeout(
      _trackingAnswerTimeout,
      onTimeout: () {},
    );
  }

  /// Регистрация — первое событие воронки после установки.
  static Future<void> logRegistration() => _send(
        'af_complete_registration',
        {'af_registration_method': 'email_otp'},
      );

  /// Пользователь ушёл на страницу оплаты. Сумма идёт как цена, а не как
  /// выручка (`af_revenue`): иначе AppsFlyer засчитал бы доходом каждый
  /// переход к кассе.
  static Future<void> logCheckoutStarted({
    required String plan,
    required int amountTiyn,
    required String currency,
  }) =>
      _send('af_initiated_checkout', {
        'af_price': _tengeFrom(amountTiyn),
        'af_currency': currency,
        'af_content_type': 'subscription',
        'af_content_id': plan,
        'af_quantity': 1,
      });

  /// Подписка подтверждена бэкендом. Единственное событие с `af_revenue` —
  /// по нему AppsFlyer считает доход кампаний.
  ///
  /// [amountTiyn] — сумма в тиынах, как её отдаёт бэкенд; [orderId] — наш
  /// внутренний номер платежа: по нему видно, что одна покупка не посчиталась
  /// дважды, а о пользователе он ничего не говорит.
  static Future<void> logPurchase({
    required int amountTiyn,
    required String currency,
    required String plan,
    required int orderId,
  }) =>
      _send('af_purchase', {
        'af_revenue': _tengeFrom(amountTiyn),
        'af_currency': currency,
        'af_content_type': 'subscription',
        'af_content_id': plan,
        'af_quantity': 1,
        'af_order_id': '$orderId',
      });

  /// Бэкенд считает деньги в тиынах: 1 ₸ = 100 тиын.
  static double _tengeFrom(int amountTiyn) => amountTiyn / 100;

  static Future<void> _send(String event, Map<String, dynamic> values) async {
    if (!_initialized) {
      debugPrint('AppsFlyer event skipped: not initialized');
      return;
    }
    try {
      await _sdk.logEvent(event, eventValues: values);
    } catch (e, st) {
      debugPrint('AppsFlyer event failed: $e\n$st');
    }
  }
}
