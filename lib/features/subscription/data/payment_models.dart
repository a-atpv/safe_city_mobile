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
