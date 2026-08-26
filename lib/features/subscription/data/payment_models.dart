// Models for the Robokassa subscription flow.
// Amounts from the backend are in tiyn (1 KZT = 100 tiyn); priceTenge converts
// for display.

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
class PendingPayment {
  final String planCode;
  final int amount; // in tiyn
  final String currency;
  final int paymentId;

  const PendingPayment({
    required this.planCode,
    required this.amount,
    required this.currency,
    required this.paymentId,
  });

  factory PendingPayment.of(String planCode, CreatePaymentResult result) {
    return PendingPayment(
      planCode: planCode,
      amount: result.amount,
      currency: result.currency,
      paymentId: result.paymentId,
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
