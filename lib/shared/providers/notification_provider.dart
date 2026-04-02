import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../models/notification_item.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final int total;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.total = 0,
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    int? total,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  late final ApiClient _apiClient;

  @override
  NotificationState build() {
    _apiClient = ApiClient();
    return const NotificationState();
  }

  Future<void> fetchNotifications({int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.dio.get('/notifications', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      if (response.statusCode == 200) {
        final list = NotificationList.fromJson(response.data);
        state = state.copyWith(
          isLoading: false,
          notifications: list.notifications,
          total: list.total,
          unreadCount: list.unreadCount,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await _apiClient.dio.patch('/notifications/$id/read');
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Optimistic update
        final newNotifications = state.notifications.map((e) {
          if (e.id == id && !e.isRead) {
            return NotificationItem(
              id: e.id,
              title: e.title,
              body: e.body,
              type: e.type,
              data: e.data,
              isRead: true,
              createdAt: e.createdAt,
            );
          }
          return e;
        }).toList();
        state = state.copyWith(
          notifications: newNotifications,
          unreadCount: (state.unreadCount > 0) ? state.unreadCount - 1 : 0,
        );
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.post('/notifications/read-all');
      if (response.statusCode == 200 || response.statusCode == 204) {
        final newNotifications = state.notifications.map((e) {
          return NotificationItem(
            id: e.id,
            title: e.title,
            body: e.body,
            type: e.type,
            data: e.data,
            isRead: true,
            createdAt: e.createdAt,
          );
        }).toList();
        state = state.copyWith(
          notifications: newNotifications,
          unreadCount: 0,
        );
      }
    } catch (_) {}
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(NotificationNotifier.new);
