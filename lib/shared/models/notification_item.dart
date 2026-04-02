class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type; // call_update, system, payment
  final String? data; // json string containing extra payload
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class NotificationList {
  final List<NotificationItem> notifications;
  final int total;
  final int unreadCount;

  NotificationList({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationList.fromJson(Map<String, dynamic> json) {
    var list = json['notifications'] as List;
    return NotificationList(
      notifications: list.map((v) => NotificationItem.fromJson(v)).toList(),
      total: json['total'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
