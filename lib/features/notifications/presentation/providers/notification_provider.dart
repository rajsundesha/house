import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/notification.dart';
import '../../data/notification_repository.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

final notificationStreamProvider = StreamProvider.family<List<AppNotification>, String>(
  (ref, userId) => ref.watch(notificationRepositoryProvider).watchNotifications(userId),
);

final unreadNotificationCountProvider = Provider.family<int, String>(
  (ref, userId) {
    final notifications = ref.watch(notificationStreamProvider(userId));
    return notifications.when(
      data: (notifications) =>
          notifications.where((notification) => !notification.isRead).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  },
);

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>(
  (ref) => NotificationNotifier(ref.watch(notificationRepositoryProvider)),
);

class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadNotifications(String userId) async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _repository.getNotifications(userId);
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) {
            if (n.id == id) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.where((n) => n.id != id).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createNotification(AppNotification notification) async {
    try {
      final newNotification = await _repository.createNotification(notification);
      state.whenData((notifications) {
        state = AsyncValue.data([newNotification, ...notifications]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}