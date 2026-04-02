class Subscription {
  final int id;
  final String status; // active, inactive, expired, cancelled
  final String planType; // monthly, yearly, trial
  final DateTime startedAt;
  final DateTime expiresAt;

  Subscription({
    required this.id,
    required this.status,
    required this.planType,
    required this.startedAt,
    required this.expiresAt,
  });

  bool get isActive => status == 'active';

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      status: (json['status'] as String).trim(),
      planType: (json['plan_type'] as String).trim(),
      startedAt: DateTime.parse(json['started_at']).toLocal(),
      expiresAt: DateTime.parse(json['expires_at']).toLocal(),
    );
  }
}
