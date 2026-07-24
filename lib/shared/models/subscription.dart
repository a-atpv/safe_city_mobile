class Subscription {
  final int id;
  final String status; // active, inactive, expired, cancelled, pending
  final String planType; // monthly, yearly, trial
  final bool autoRenew; // true while the sub will be recharged near expiry
  final DateTime? startedAt; // null while the subscription is still pending
  final DateTime? expiresAt; // null while the subscription is still pending
  final DateTime? cancelledAt; // set once the user turns off auto-renewal

  Subscription({
    required this.id,
    required this.status,
    required this.planType,
    this.autoRenew = false,
    this.startedAt,
    this.expiresAt,
    this.cancelledAt,
  });

  bool get isActive => status == 'active';

  /// Auto-renewal was switched off but the paid period hasn't ended yet.
  bool get isCancelled => cancelledAt != null;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.parse(value as String).toLocal();

    return Subscription(
      id: json['id'] as int,
      status: (json['status'] as String).trim(),
      planType: (json['plan_type'] as String).trim(),
      autoRenew: json['auto_renew'] as bool? ?? false,
      startedAt: parseDate(json['started_at']),
      expiresAt: parseDate(json['expires_at']),
      cancelledAt: parseDate(json['cancelled_at']),
    );
  }
}
