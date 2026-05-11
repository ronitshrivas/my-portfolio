import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Notification/Notification_Listscreen.dart';

const String _kNotifBaseUrl = 'http://36.253.137.34:8005';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    bool clearCursor = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final token = AppData().accessToken;
      if (token == null) throw Exception('No auth token');

      final response = await http.get(
        Uri.parse('$_kNotifBaseUrl/api/notifications/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        state = state.copyWith(
          notifications:
              jsonList.map((j) => NotificationModel.fromJson(j)).toList(),
          isLoading: false,
          hasMore: false,
          clearCursor: true,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchMoreNotifications() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);

    try {
      final token = AppData().accessToken;
      if (token == null) throw Exception('No auth token');

      final response = await http.get(
        Uri.parse(
          '$_kNotifBaseUrl/api/notifications/?cursor=${state.nextCursor}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        state = state.copyWith(
          notifications: [
            ...state.notifications,
            ...jsonList.map((j) => NotificationModel.fromJson(j)),
          ],
          isLoadingMore: false,
          hasMore: jsonList.isNotEmpty,
          clearCursor: true,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final previous = state.notifications;
    state = state.copyWith(
      notifications:
          state.notifications.map((n) {
            return n.id == notificationId ? n.copyWith(isRead: true) : n;
          }).toList(),
    );

    try {
      final token = AppData().accessToken;
      if (token == null) throw Exception('No auth token');

      final response = await http.post(
        Uri.parse(
          '$_kNotifBaseUrl/api/notifications/$notificationId/mark-as-read/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        state = state.copyWith(notifications: previous);
      }
    } catch (_) {
      state = state.copyWith(notifications: previous);
    }
  }

  Future<void> markAllAsRead() async {
    final previous = state.notifications;
    state = state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      final token = AppData().accessToken;
      if (token == null) throw Exception('No auth token');

      final response = await http.post(
        Uri.parse('$_kNotifBaseUrl/api/notifications/mark-all-as-read/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        state = state.copyWith(notifications: previous);
      }
    } catch (_) {
      state = state.copyWith(notifications: previous);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final previous = state.notifications;
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n.id != notificationId).toList(),
    );

    try {
      final token = AppData().accessToken;
      if (token == null) throw Exception('No auth token');

      final response = await http.delete(
        Uri.parse('$_kNotifBaseUrl/api/notifications/$notificationId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        state = state.copyWith(notifications: previous);
      }
    } catch (_) {
      state = state.copyWith(notifications: previous);
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
      (ref) => NotificationNotifier(),
    );

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
