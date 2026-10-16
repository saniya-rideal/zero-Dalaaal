import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/socket_service.dart';
import '../../data/models/models.dart';
import '../../features/notifications/data/notifications_repository.dart';

class NotificationService extends ChangeNotifier {
  final NotificationsRepository? _repository;
  final SocketService? _socketService;
  StreamSubscription? _socketSubscription;

  final List<NotificationItem> _notifications = [];
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _isLoading = false;

  final StreamController<List<NotificationItem>> _notificationsStreamController =
      StreamController<List<NotificationItem>>.broadcast();
  final StreamController<NotificationItem> _inAppAlertStreamController =
      StreamController<NotificationItem>.broadcast();
  final StreamController<NotificationPreferences> _preferencesStreamController =
      StreamController<NotificationPreferences>.broadcast();

  Stream<List<NotificationItem>> get notificationsStream =>
      _notificationsStreamController.stream;
  Stream<NotificationItem> get inAppAlertStream =>
      _inAppAlertStreamController.stream;
  Stream<NotificationPreferences> get preferencesStream =>
      _preferencesStreamController.stream;

  NotificationService({
    NotificationsRepository? repository,
    SocketService? socketService,
  })  : _repository = repository,
        _socketService = socketService {
    if (_repository != null) {
      _init();
    }
  }

  void _init() {
    refresh();
    _socketSubscription = _socketService?.notificationStream.listen((event) {
      final item = NotificationItem.fromJson(event);
      notify(item);
    });
  }

  Future<void> refresh() async {
    if (_repository == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final items = await _repository.getNotifications();
      _notifications.clear();
      _notifications.addAll(items);
      _notificationsStreamController.add(_notifications);

      try {
        _preferences = await _repository.getPreferences();
        _preferencesStreamController.add(_preferences);
      } catch (_) {}
    } catch (_) {
      // Offline or network error handled gracefully
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isLoading => _isLoading;
  List<NotificationItem> get allNotifications => List.unmodifiable(_notifications);
  NotificationPreferences get preferences => _preferences;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool notify(NotificationItem item, [DateTime? atTime]) {
    final shouldDeliver = _preferences.shouldDeliver(item, atTime);
    if (!shouldDeliver) {
      return false;
    }

    _notifications.insert(0, item);
    _notificationsStreamController.add(_notifications);
    _inAppAlertStreamController.add(item);
    notifyListeners();
    return true;
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationsStreamController.add(_notifications);
      notifyListeners();
      try {
        await _repository?.markRead(id);
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      _notificationsStreamController.add(_notifications);
      notifyListeners();
      try {
        await _repository?.markAllRead();
      } catch (_) {}
    }
  }

  Future<void> deleteNotification(String id) async {
    final before = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != before) {
      _notificationsStreamController.add(_notifications);
      notifyListeners();
      try {
        await _repository?.deleteNotification(id);
      } catch (_) {}
    }
  }

  void clearAll() {
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      _notificationsStreamController.add(_notifications);
      notifyListeners();
    }
  }

  Future<void> updatePreferences(NotificationPreferences newPrefs) async {
    _preferences = newPrefs;
    _preferencesStreamController.add(_preferences);
    notifyListeners();
    try {
      await _repository?.updatePreferences(newPrefs.toJson());
    } catch (_) {}
  }

  List<NotificationItem> filter({
    String? query,
    NotificationCategory? category,
    bool? unreadOnly,
  }) {
    return _notifications.where((n) {
      if (category != null && n.category != category) return false;
      if (unreadOnly == true && n.isRead) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final inTitle = n.title.toLowerCase().contains(q);
        final inBody = n.body.toLowerCase().contains(q);
        final inMetadata = n.metadata.values.any((v) => v.toString().toLowerCase().contains(q));
        if (!inTitle && !inBody && !inMetadata) return false;
      }
      return true;
    }).toList();
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _socketSubscription?.cancel();
    _notificationsStreamController.close();
    _inAppAlertStreamController.close();
    _preferencesStreamController.close();
    super.dispose();
  }
}

final notificationServiceProvider = ChangeNotifierProvider<NotificationService>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);
  return NotificationService(repository: repo, socketService: socket);
});

final notificationsListProvider = StreamProvider<List<NotificationItem>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationsStream;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.unreadCount;
});

final notificationPreferencesProvider = Provider<NotificationPreferences>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.preferences;
});

final inAppAlertStreamProvider = StreamProvider<NotificationItem>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.inAppAlertStream;
});
