import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Meta App Events — атрибуция рекламных кампаний, и только она.
///
/// Правило, которое здесь нельзя нарушать: **в Meta не уходит ничего личного**
/// — ни координаты, ни адрес, ни телефон, ни email, ни идентификатор вызова
/// SOS. Причина не в осторожности вообще, а в конкретном пункте политики Google
/// Play: фоновую геолокацию (а разрешение на неё у приложения есть, и оно
/// проходило отдельное ревью с видео) запрещено использовать в рекламных
/// целях. Поэтому наружу идут только факт события, код тарифа и сумма покупки.
///
/// Сам SDK инициализируется нативно — из `strings.xml` на Android и `Info.plist`
/// на iOS, — поэтому App ID и client token в Dart не нужны. Отсюда управляем
/// только согласием на сбор рекламного идентификатора и отправкой событий.
class MetaAnalytics {
  MetaAnalytics._();

  static final FacebookAppEvents _events = FacebookAppEvents();

  /// Вызывается в `main()`. Ошибки глотаем: аналитика не тот повод, чтобы
  /// приложение экстренного вызова не запустилось.
  static Future<void> initialize() async {
    try {
      await _syncAdvertiserId();
      debugPrint('Meta App Events initialized');
    } catch (e, st) {
      debugPrint('Meta analytics init failed: $e\n$st');
    }
  }

  /// Показывает системный запрос App Tracking Transparency, если пользователь
  /// ещё не отвечал. Без него Apple отклоняет сбор IDFA (гайдлайн 5.1.2).
  ///
  /// Вызывать, когда экран уже устоялся и никакой другой системный диалог не
  /// висит: iOS схлопывает системные промпты, если их просят одновременно, и
  /// запрос молча теряется — второй раз его уже не показать.
  static Future<void> requestTrackingPermission() async {
    if (!Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Пауза на анимацию появления экрана — рекомендация самого плагина.
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
      await _syncAdvertiserId();
    } catch (e, st) {
      debugPrint('ATT request failed: $e\n$st');
    }
  }

  /// Сбор IDFA включаем ровно тогда, когда пользователь разрешил трекинг.
  ///
  /// На iOS 17+ SDK и сам смотрит на статус ATT, но минимальная версия у нас
  /// 15.0 — на 15 и 16 флаг всё ещё нужно выставлять руками. На Android
  /// ничего не трогаем: сбор Google Advertising ID включён по умолчанию, а
  /// отказ от него у пользователя есть в системных настройках.
  static Future<void> _syncAdvertiserId() async {
    if (!Platform.isIOS) return;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    await _events.setAdvertiserIdCollectionEnabled(
      status == TrackingStatus.authorized,
    );
  }

  /// Регистрация — первое событие воронки после установки.
  static Future<void> logRegistration() => _send(
        () => _events.logCompletedRegistration(registrationMethod: 'email_otp'),
      );

  /// Пользователь ушёл на страницу оплаты. Промежуточное событие: по нему
  /// кампании учатся на тех, кто дошёл до кассы, не дожидаясь редких покупок.
  static Future<void> logCheckoutStarted({
    required String plan,
    required int amountTiyn,
    required String currency,
  }) =>
      _send(
        () => _events.logInitiatedCheckout(
          totalPrice: _tengeFrom(amountTiyn),
          currency: currency,
          contentType: 'subscription',
          contentId: plan,
          numItems: 1,
        ),
      );

  /// Подписка подтверждена бэкендом. Главное событие для оптимизации кампаний.
  ///
  /// [amountTiyn] — сумма в тиынах, как её отдаёт бэкенд; [orderId] — наш
  /// внутренний номер платежа, он нужен Meta, чтобы не считать одну покупку
  /// дважды, и о пользователе ничего не говорит.
  static Future<void> logPurchase({
    required int amountTiyn,
    required String currency,
    required String plan,
    required int orderId,
  }) =>
      _send(() async {
        await _events.logPurchase(
          amount: _tengeFrom(amountTiyn),
          currency: currency,
          parameters: {
            'fb_content_type': 'subscription',
            'fb_content_id': plan,
            'fb_order_id': '$orderId',
          },
        );
        // Покупка — самое дорогое событие для оптимизации, ждать общей
        // отправки батча ради него незачем.
        await _events.flush();
      });

  /// Бэкенд считает деньги в тиынах: 1 ₸ = 100 тиын.
  static double _tengeFrom(int amountTiyn) => amountTiyn / 100;

  static Future<void> _send(Future<void> Function() event) async {
    try {
      await event();
    } catch (e, st) {
      debugPrint('Meta event failed: $e\n$st');
    }
  }
}
