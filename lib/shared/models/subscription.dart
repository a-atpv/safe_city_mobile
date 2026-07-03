class Subscription {
  final int id;
  final String status; // active, inactive, expired, cancelled, pending
  final String planType; // monthly, yearly, trial
  final DateTime? startedAt; // null while the subscription is still pending
  final DateTime? expiresAt; // null while the subscription is still pending

  Subscription({
    required this.id,
    required this.status,
    required this.planType,
    this.startedAt,
    this.expiresAt,
  });

  bool get isActive => status == 'active';

  factory Subscription.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.parse(value as String).toLocal();

    return Subscription(
      id: json['id'] as int,
      status: (json['status'] as String).trim(),
      planType: (json['plan_type'] as String).trim(),
      startedAt: parseDate(json['started_at']),
      expiresAt: parseDate(json['expires_at']),
    );
  }
}
