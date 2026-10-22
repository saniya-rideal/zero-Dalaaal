import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router.dart';
import '../../data/models/notification_item.dart';
import '../../features/notifications/data/notifications_repository.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM background message received: ${message.messageId}');
}

class PushNotificationService {
  final Ref _ref;
  bool _initialized = false;
  String? _fcmToken;

  PushNotificationService(this._ref);

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Initialize Firebase Core safely (supports graceful fallback if config absent)
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request Notification Permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 3. Fetch Initial Token
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            _fcmToken = token;
            await _registerTokenWithBackend(token);
          }
        } catch (e) {
          debugPrint('Error getting initial FCM token: $e');
        }

        // 4. Listen for Token Refreshes
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _registerTokenWithBackend(newToken);
        });

        // 5. Foreground Notification Handling
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        // 6. Handle App Launch from Terminated State via Notification Tap
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // 7. Handle App Resume from Background State via Notification Tap
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationTap(message);
        });
      }
    } catch (e) {
      debugPrint('PushNotificationService initialization skipped or failed: $e');
    }
  }

  Future<void> registerCurrentToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      await _registerTokenWithBackend(_fcmToken!);
    } else {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _fcmToken = token;
          await _registerTokenWithBackend(token);
        }
      } catch (_) {}
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      String deviceType = 'ANDROID';
      if (kIsWeb) {
        deviceType = 'WEB';
      } else if (!kIsWeb && Platform.isIOS) {
        deviceType = 'IOS';
      } else if (!kIsWeb && Platform.isAndroid) {
        deviceType = 'ANDROID';
      }

      final repo = _ref.read(notificationsRepositoryProvider);
      await repo.registerFcmToken(token, deviceType: deviceType);
      debugPrint('FCM token successfully registered with backend ($deviceType): $token');
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground FCM notification: ${message.notification?.title}');
    final notificationItem = _mapRemoteMessageToNotificationItem(message);
    _ref.read(notificationServiceProvider).notify(notificationItem);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final rawRoute = message.data['route']?.toString() ??
        message.data['deepLink']?.toString() ??
        message.data['url']?.toString();

    final targetRoute = resolveNotificationRoute(rawRoute);
    if (targetRoute.isNotEmpty) {
      try {
        final router = _ref.read(routerProvider);
        router.push(targetRoute);
      } catch (e) {
        debugPrint('Failed to navigate to route $targetRoute: $e');
      }
    }
  }

  NotificationItem _mapRemoteMessageToNotificationItem(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Notification';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
    final rawRoute = message.data['route']?.toString() ??
        message.data['deepLink']?.toString() ??
        message.data['url']?.toString() ??
        '/notifications';

    final resolved = resolveNotificationRoute(rawRoute);

    return NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseNotificationType(message.data['type']?.toString()),
      category: _parseNotificationCategory(message.data['category']?.toString()),
      title: title,
      body: body,
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      deepLink: resolved,
      metadata: Map<String, dynamic>.from(message.data),
      isCritical: message.data['isCritical'] == 'true' || message.data['isCritical'] == true,
    );
  }

  static String resolveNotificationRoute(String? rawRoute) {
    if (rawRoute == null || rawRoute.isEmpty) return '/notifications';
    if (rawRoute == '/wallet') return '/funds';
    if (rawRoute == '/gtt') return '/orders';
    if (rawRoute.startsWith('/orders/')) {
      final id = rawRoute.replaceFirst('/orders/', '');
      return '/order-detail/$id';
    }
    if (rawRoute.startsWith('/support/tickets/')) {
      final id = rawRoute.replaceFirst('/support/tickets/', '');
      return '/help/tickets/$id';
    }
    return rawRoute;
  }

  NotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == null || typeStr.isEmpty) return NotificationType.accountNotice;
    try {
      return NotificationType.values.byName(typeStr);
    } catch (_) {
      final upper = typeStr.toUpperCase();
      if (upper.contains('ORDER')) return NotificationType.orderFilled;
      if (upper.contains('DEPOSIT') || upper.contains('FUNDS') || upper.contains('PAYMENT')) {
        return NotificationType.depositSuccess;
      }
      if (upper.contains('WITHDRAW')) return NotificationType.withdrawalInitiated;
      if (upper.contains('ALERT')) return NotificationType.priceAlert;
      if (upper.contains('KYC')) return NotificationType.kycStatusChanged;
      return NotificationType.accountNotice;
    }
  }

  NotificationCategory _parseNotificationCategory(String? catStr) {
    if (catStr == null || catStr.isEmpty) return NotificationCategory.orders;
    try {
      return NotificationCategory.values.byName(catStr);
    } catch (_) {
      final upper = catStr.toUpperCase();
      if (upper.contains('FUND') || upper.contains('WALLET') || upper.contains('PAYMENT')) {
        return NotificationCategory.funds;
      }
      if (upper.contains('ALERT')) return NotificationCategory.priceAlerts;
      if (upper.contains('NEWS')) return NotificationCategory.news;
      if (upper.contains('SEC') || upper.contains('AUTH') || upper.contains('KYC')) {
        return NotificationCategory.security;
      }
      if (upper.contains('MARGIN') || upper.contains('RISK')) return NotificationCategory.riskMargin;
      return NotificationCategory.orders;
    }
  }

  Future<void> unregisterOnLogout() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted on logout');
    } catch (e) {
      debugPrint('Failed to delete FCM token on logout: $e');
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
