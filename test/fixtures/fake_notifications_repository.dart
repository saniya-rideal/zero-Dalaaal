import 'package:zero_dalali/data/models/notification_item.dart';
import 'package:zero_dalali/features/notifications/data/notifications_repository.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  final List<NotificationItem> _items = [];
  NotificationPreferences _prefs = const NotificationPreferences();

  @override
  Future<List<NotificationItem>> getNotifications({int page = 1, int limit = 20}) async {
    return List.unmodifiable(_items);
  }

  @override
  Future<int> getUnreadCount() async {
    return _items.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllRead() async {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    _items.removeWhere((n) => n.id == id);
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    return _prefs;
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    _prefs = NotificationPreferences.fromJson(preferences);
  }

  @override
  Future<void> registerFcmToken(String fcmToken, {String deviceType = 'ANDROID'}) async {}
}
