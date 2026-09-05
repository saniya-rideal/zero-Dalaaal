import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  NotificationPreferences _preferences = const NotificationPreferences();

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

  NotificationService() {
    _seedInitialNotifications();
  }

  List<NotificationItem> get allNotifications => List.unmodifiable(_notifications);

  NotificationPreferences get preferences => _preferences;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _seedInitialNotifications() {
    final now = DateTime.now();

    final seeded = [
      // 1. Order submitted
      NotificationItem(
        id: 'notif_order_sub_01',
        type: NotificationType.orderSubmitted,
        category: NotificationCategory.orders,
        title: 'Order Submitted',
        body: 'BUY 50 Qty SBIN @ ₹810.00 Limit CNC sent to exchange.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        deepLink: '/history',
        metadata: {'orderId': 'ORD-2026-8801', 'symbol': 'SBIN', 'qty': 50, 'price': 810.00},
      ),

      // 2. Order filled
      NotificationItem(
        id: 'notif_order_fill_02',
        type: NotificationType.orderFilled,
        category: NotificationCategory.orders,
        title: 'Order Executed',
        body: 'Your BUY order for 50 shares of SBIN was completely filled at ₹810.00.',
        timestamp: now.subtract(const Duration(minutes: 12)),
        isRead: false,
        deepLink: '/history',
        metadata: {'orderId': 'ORD-2026-8799', 'tradeId': 'TRD-892104', 'symbol': 'SBIN', 'qty': 50, 'price': 810.00},
      ),

      // 3. Order partially filled
      NotificationItem(
        id: 'notif_order_partial_03',
        type: NotificationType.orderPartiallyFilled,
        category: NotificationCategory.orders,
        title: 'Partial Fill Execution',
        body: 'SELL 100 Qty RELIANCE: 40/100 shares filled at ₹2,985.50. 60 Qty pending.',
        timestamp: now.subtract(const Duration(minutes: 35)),
        isRead: false,
        deepLink: '/history',
        metadata: {'orderId': 'ORD-2026-8750', 'symbol': 'RELIANCE', 'filledQty': 40, 'pendingQty': 60, 'price': 2985.50},
      ),

      // 4. Order rejected
      NotificationItem(
        id: 'notif_order_rej_04',
        type: NotificationType.orderRejected,
        category: NotificationCategory.orders,
        title: 'Order Rejected',
        body: 'BUY 250 Qty INFY rejected: Insufficient available margin ₹42,500 required.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
        isRead: true,
        deepLink: '/funds',
        metadata: {'orderId': 'ORD-2026-8712', 'symbol': 'INFY', 'reason': 'Insufficient Margin'},
      ),

      // 5. Order cancelled
      NotificationItem(
        id: 'notif_order_can_05',
        type: NotificationType.orderCancelled,
        category: NotificationCategory.orders,
        title: 'Order Cancelled',
        body: 'Limit BUY 20 Qty TCS @ ₹3,900.00 cancelled upon client request.',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: true,
        deepLink: '/history',
        metadata: {'orderId': 'ORD-2026-8690', 'symbol': 'TCS', 'qty': 20},
      ),

      // 6. Deposit success
      NotificationItem(
        id: 'notif_dep_succ_06',
        type: NotificationType.depositSuccess,
        category: NotificationCategory.funds,
        title: 'Deposit Successful',
        body: '₹50,000.00 credited to your Trading Margin via instant UPI.',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
        deepLink: '/funds',
        metadata: {'refId': 'UPI/2026/89412', 'amount': 50000.00, 'mode': 'UPI'},
      ),

      // 7. Deposit pending
      NotificationItem(
        id: 'notif_dep_pend_07',
        type: NotificationType.depositPending,
        category: NotificationCategory.funds,
        title: 'Deposit Pending Verification',
        body: '₹25,000.00 IMPS transfer is awaiting confirmation from your remitting bank.',
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
        deepLink: '/funds',
        metadata: {'refId': 'IMPS/998124', 'amount': 25000.00},
      ),

      // 8. Withdrawal initiated
      NotificationItem(
        id: 'notif_wdr_init_08',
        type: NotificationType.withdrawalInitiated,
        category: NotificationCategory.funds,
        title: 'Payout Request Initiated',
        body: '₹15,000.00 withdrawal request submitted to HDFC Bank (•••• 4912).',
        timestamp: now.subtract(const Duration(hours: 6)),
        isRead: true,
        deepLink: '/funds',
        metadata: {'refId': 'WDR-2026-4401', 'amount': 15000.00, 'bank': 'HDFC Bank'},
      ),

      // 9. Withdrawal completed
      NotificationItem(
        id: 'notif_wdr_comp_09',
        type: NotificationType.withdrawalCompleted,
        category: NotificationCategory.funds,
        title: 'Payout Processed',
        body: '₹15,000.00 credited to primary bank account. UTR: HDFCN2688910.',
        timestamp: now.subtract(const Duration(hours: 8)),
        isRead: true,
        deepLink: '/funds',
        metadata: {'refId': 'WDR-2026-4401', 'amount': 15000.00, 'utr': 'HDFCN2688910'},
      ),

      // 10. Margin warning
      NotificationItem(
        id: 'notif_margin_warn_10',
        type: NotificationType.marginWarning,
        category: NotificationCategory.riskMargin,
        title: '⚠️ Margin Utilization Advisory',
        body: 'Account margin utilization reached 84%. Maintain buffer to avoid auto square-off.',
        timestamp: now.subtract(const Duration(hours: 10)),
        isRead: false,
        deepLink: '/funds',
        metadata: {'utilization': 84.0, 'availableMargin': 18500.00},
        isCritical: true,
      ),

      // 11. Liquidation warning
      NotificationItem(
        id: 'notif_liq_warn_11',
        type: NotificationType.liquidationWarning,
        category: NotificationCategory.riskMargin,
        title: '🚨 RMS Liquidation Warning',
        body: 'Margin Level dropped below 105%. Deposit funds immediately to prevent auto-liquidation.',
        timestamp: now.subtract(const Duration(hours: 14)),
        isRead: false,
        deepLink: '/funds',
        metadata: {'marginLevel': 104.2, 'deficit': 8400.00},
        isCritical: true,
      ),

      // 12. Price alert
      NotificationItem(
        id: 'notif_price_alt_12',
        type: NotificationType.priceAlert,
        category: NotificationCategory.priceAlerts,
        title: '🔔 Price Alert Triggered',
        body: 'COPPER MCX Sep crossed above ₹1,375.00 (LTP: ₹1,378.20).',
        timestamp: now.subtract(const Duration(hours: 18)),
        isRead: true,
        deepLink: '/quote-detail/mcx_copper',
        metadata: {'symbol': 'COPPER MCX Sep', 'target': 1375.00, 'ltp': 1378.20},
      ),

      // 13. News alert
      NotificationItem(
        id: 'notif_news_alt_13',
        type: NotificationType.newsAlert,
        category: NotificationCategory.news,
        title: '📰 Breaking Market News',
        body: 'RBI MPC holds repo rate steady at 6.50%; growth projection pegged at 7.2%.',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        deepLink: '/news',
        metadata: {'headline': 'RBI MPC Rate Decision', 'source': 'Reuters'},
      ),

      // 14. Security alert
      NotificationItem(
        id: 'notif_sec_alt_14',
        type: NotificationType.securityAlert,
        category: NotificationCategory.security,
        title: '🛡️ Security Settings Changed',
        body: 'Two-Factor Authentication (TOTP App) was successfully linked to your account.',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        isRead: true,
        deepLink: '/settings',
        metadata: {'action': 'TOTP_ENABLE'},
        isCritical: true,
      ),

      // 15. Login from new device
      NotificationItem(
        id: 'notif_login_dev_15',
        type: NotificationType.loginNewDevice,
        category: NotificationCategory.security,
        title: '🔐 New Device Login Detected',
        body: 'Sign-in detected from Chrome on Windows 11 (IP: 49.37.12.98, Mumbai, India).',
        timestamp: now.subtract(const Duration(days: 1, hours: 8)),
        isRead: true,
        deepLink: '/profile',
        metadata: {'device': 'Chrome / Windows 11', 'ip': '49.37.12.98', 'location': 'Mumbai, India'},
        isCritical: true,
      ),

      // 16. Password changed
      NotificationItem(
        id: 'notif_pwd_chg_16',
        type: NotificationType.passwordChanged,
        category: NotificationCategory.security,
        title: '🔑 Password Updated',
        body: 'Your account login password was successfully updated. If this wasn\'t you, contact support.',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
        deepLink: '/settings',
        metadata: {'action': 'PASSWORD_RESET'},
        isCritical: true,
      ),

      // 17. KYC status changed
      NotificationItem(
        id: 'notif_kyc_chg_17',
        type: NotificationType.kycStatusChanged,
        category: NotificationCategory.security,
        title: '📋 KYC Verification Approved',
        body: 'Your Re-KYC document verification is complete. Equity, F&O, and Currency segments enabled.',
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        isRead: true,
        deepLink: '/profile',
        metadata: {'status': 'VERIFIED', 'segments': ['EQUITY', 'FNO', 'CURRENCY']},
      ),

      // 18. Account-related notices
      NotificationItem(
        id: 'notif_acc_not_18',
        type: NotificationType.accountNotice,
        category: NotificationCategory.security,
        title: '📢 Corporate Action Notice: INFY',
        body: 'Infosys Ltd declared an interim dividend of ₹18.00 per share with Ex-Date 12 Sep 2026.',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
        deepLink: '/news',
        metadata: {'symbol': 'INFY', 'corporateAction': 'DIVIDEND', 'amount': 18.00, 'exDate': '12 Sep 2026'},
      ),
    ];

    _notifications.addAll(seeded);
    _notificationsStreamController.add(_notifications);
    _preferencesStreamController.add(_preferences);
  }

  /// Delivers a notification if permitted by preferences and quiet hours.
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

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationsStreamController.add(_notifications);
      notifyListeners();
    }
  }

  void markAllAsRead() {
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
    }
  }

  void deleteNotification(String id) {
    final before = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != before) {
      _notificationsStreamController.add(_notifications);
      notifyListeners();
    }
  }

  void clearAll() {
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      _notificationsStreamController.add(_notifications);
      notifyListeners();
    }
  }

  void updatePreferences(NotificationPreferences newPrefs) {
    _preferences = newPrefs;
    _preferencesStreamController.add(_preferences);
    notifyListeners();
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

  @override
  void dispose() {
    _notificationsStreamController.close();
    _inAppAlertStreamController.close();
    _preferencesStreamController.close();
    super.dispose();
  }
}

final notificationServiceProvider = ChangeNotifierProvider<NotificationService>((ref) {
  return NotificationService();
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
