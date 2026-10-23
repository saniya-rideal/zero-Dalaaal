import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/notification_item.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationsRepository(client);
});

final latestNotificationSummaryProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    final repo = ref.watch(notificationsRepositoryProvider);
    final notifs = await repo.getNotifications(limit: 1);
    if (notifs.isNotEmpty) {
      return '${notifs.first.title}: ${notifs.first.body}';
    }
  } catch (_) {}
  return null;
});

class NotificationsRepository {
  final ApiClient _client;

  NotificationsRepository(this._client);

  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      ApiPaths.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiPaths.notificationsUnreadCount);
    final data = ResponseReader.unwrap(response);
    if (data is num) return data.toInt();
    if (data is Map<String, dynamic>) {
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> markRead(String id) async {
    await _client.post(ApiPaths.notificationRead(id));
  }

  Future<void> markAllRead() async {
    await _client.post(ApiPaths.notificationsReadAll);
  }

  Future<void> deleteNotification(String id) async {
    await _client.delete(ApiPaths.notificationById(id));
  }

  Future<NotificationPreferences> getPreferences() async {
    final response = await _client.get(ApiPaths.notificationPreferences);
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return NotificationPreferences.fromJson(map);
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    await _client.put(ApiPaths.notificationPreferences, data: preferences);
  }

  Future<void> registerFcmToken(String fcmToken, {String deviceType = 'ANDROID'}) async {
    await _client.post(
      ApiPaths.notificationRegisterToken,
      data: {
        'fcmToken': fcmToken,
        'deviceType': deviceType,
      },
    );
  }
}
