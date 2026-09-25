// Models for the Robokassa subscription flow.
// Amounts from the backend are in tiyn (1 KZT = 100 tiyn); priceTenge converts
// for display.

import '../../../shared/models/subscription.dart';

class Plan {
  final String code; // "monthly" | "yearly"
  final String title;
  final int amount; // in tiyn
  final String currency; // "KZT"
  final int periodMonths;

  const Plan({
    required this.code,
    required this.title,
    required this.amount,
    required this.currency,
    required this.periodMonths,
  });

  int get priceTenge => amount ~/ 100;

  bool get isYearly => code == 'yearly';

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      code: json['code'] as String,
      title: json['title'] as String,
      amount: json['amount'] as int,
      currency: (json['currency'] as String?) ?? 'KZT',
      periodMonths: json['period_months'] as int,
    );
  }
}

/// Платёж, который создан и отправлен на страницу оплаты, но ещё не подтверждён
/// бэкендом. Экран статуса ждёт именно его и по нему же отправляет событие
/// покупки в Meta — иначе сумму на том экране взять неоткуда.
/// Платёж, ушедший на оплату в браузер, — ждёт, пока бэкенд его подтвердит,
/// чтобы приложение отправило событие покупки в рекламные кабинеты.
///
/// Лежит на диске, а не только в памяти: человек платит в другом приложении,
/// и Android за это время спокойно выгружает наше. Раньше такая покупка не
/// засчитывалась ни в Meta, ни в Firebase, ни в AppsFlyer — ровно самое ценное
/// для оптимизации кампаний событие.
class PendingPayment {
  final String planCode;
  final int amount; // in tiyn
  final String currency;
  final int paymentId;

  /// Чей это платёж: после выхода и входа под другим аккаунтом чужую покупку
  /// засчитывать нельзя.
  final int userId;
  final DateTime createdAt;

  /// Подписка в момент создания платежа — по ней отличаем «оплата прошла» от
  /// «подписка и так была активна». Без неё продление досрочно выглядело бы
  /// оплаченным ещё до того, как человек что-то заплатил.
  final int? subscriptionIdBefore;
  final DateTime? expiresAtBefore;

  const PendingPayment({
    required this.planCode,
    required this.amount,
    required this.currency,
    required this.paymentId,
    required this.userId,
    required this.createdAt,
    this.subscriptionIdBefore,
    this.expiresAtBefore,
  });

  factory PendingPayment.of(
    String planCode,
    CreatePaymentResult result, {
    required int userId,
    Subscription? subscriptionBefore,
    DateTime? now,
  }) {
    final active = subscriptionBefore?.isActive ?? false;
    return PendingPayment(
      planCode: planCode,
      amount: result.amount,
      currency: result.currency,
      paymentId: result.paymentId,
      userId: userId,
      createdAt: now ?? DateTime.now(),
      subscriptionIdBefore: active ? subscriptionBefore!.id : null,
      expiresAtBefore: active ? subscriptionBefore!.expiresAt : null,
    );
  }

  /// Сколько ждём подтверждения. Робокасса подтверждает за минуты; платёж,
  /// не подтверждённый за сутки, считаем брошенным — иначе через неделю его
  /// «подтвердило» бы автопродление.
  static const maxAge = Duration(hours: 24);

  bool isStale(DateTime now) => now.difference(createdAt) > maxAge;

  /// Подтверждена ли оплата тем, что сейчас отдаёт `/user/me`.
  ///
  /// Отдельной ручки статуса платежа у бэкенда нет, поэтому судим по подписке:
  /// она активна и при этом новая (другая запись или срок сдвинулся дальше),
  /// а не та же самая, что была до оплаты.
  bool isConfirmedBy({required int userId, Subscription? subscription}) {
    if (userId != this.userId) return false;
    if (subscription == null || !subscription.isActive) return false;
    if (subscriptionIdBefore == null) return true;
    if (subscription.id != subscriptionIdBefore) return true;
    final before = expiresAtBefore;
    final after = subscription.expiresAt;
    if (before == null) return after != null;
    return after != null && after.isAfter(before);
  }

  Map<String, dynamic> toJson() => {
    'plan_code': planCode,
    'amount': amount,
    'currency': currency,
    'payment_id': paymentId,
    'user_id': userId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'subscription_id_before': subscriptionIdBefore,
    'expires_at_before': expiresAtBefore?.toUtc().toIso8601String(),
  };

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.parse(value as String).toLocal();
    return PendingPayment(
      planCode: json['plan_code'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      paymentId: json['payment_id'] as int,
      userId: json['user_id'] as int,
      createdAt: parseDate(json['created_at'])!,
      subscriptionIdBefore: json['subscription_id_before'] as int?,
      expiresAtBefore: parseDate(json['expires_at_before']),
    );
  }
}

class CreatePaymentResult {
  final int paymentId;
  final int invId;
  final int amount; // in tiyn
  final String currency;
  final String paymentUrl;

  const CreatePaymentResult({
    required this.paymentId,
    required this.invId,
    required this.amount,
    required this.currency,
    required this.paymentUrl,
  });

  factory CreatePaymentResult.fromJson(Map<String, dynamic> json) {
    return CreatePaymentResult(
      paymentId: json['payment_id'] as int,
      invId: json['inv_id'] as int,
      amount: json['amount'] as int,
      currency: (json['currency'] as String?) ?? 'KZT',
      paymentUrl: json['payment_url'] as String,
    );
  }
}
