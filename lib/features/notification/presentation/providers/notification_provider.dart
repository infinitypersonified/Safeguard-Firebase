import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguard/features/notification/data/models/notification_model.dart';
import 'package:safeguard/features/notification/data/services/notification_service.dart';

// Service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification state
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(NotificationState());

  /// Initialize notification service
  Future<void> initialize() async {
    await _service.initialize();
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.system,
  }) async {
    await _service.showNotification(
      title: title,
      body: body,
      payload: payload,
      type: type,
    );
  }

  /// Show SOS alert notification
  Future<void> showSOSAlert({
    required String userName,
    String? location,
  }) async {
    await _service.showSOSAlert(
      userName: userName,
      location: location,
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    _updateUnreadCount();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (final notification in state.notifications) {
      if (!notification.isRead) {
        await _service.markAsRead(notification.id);
      }
    }
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    final unread = state.notifications.where((n) => !n.isRead).length;
    state = state.copyWith(unreadCount: unread);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service);
});

// Convenience providers
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

final hasUnreadProvider = Provider<bool>((ref) {
  return ref.watch(unreadCountProvider) > 0;
});
