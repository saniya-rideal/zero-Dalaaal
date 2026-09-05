enum NotificationType {
  orderSubmitted,
  orderFilled,
  orderPartiallyFilled,
  orderRejected,
  orderCancelled,
  depositSuccess,
  depositPending,
  depositFailed,
  withdrawalInitiated,
  withdrawalCompleted,
  withdrawalFailed,
  marginWarning,
  liquidationWarning,
  priceAlert,
  newsAlert,
  securityAlert,
  loginNewDevice,
  passwordChanged,
  kycStatusChanged,
  accountNotice,
}

enum NotificationCategory {
  orders,
  funds,
  riskMargin,
  priceAlerts,
  news,
  security,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String deepLink;
  final Map<String, dynamic> metadata;
  final bool isCritical;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.deepLink,
    this.metadata = const {},
    this.isCritical = false,
  });

  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? deepLink,
    Map<String, dynamic>? metadata,
    bool? isCritical,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      deepLink: deepLink ?? this.deepLink,
      metadata: metadata ?? this.metadata,
      isCritical: isCritical ?? this.isCritical,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'category': category.name,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'deepLink': deepLink,
    'metadata': metadata,
    'isCritical': isCritical,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'] as String,
    type: NotificationType.values.byName(json['type'] as String),
    category: NotificationCategory.values.byName(json['category'] as String),
    title: json['title'] as String,
    body: json['body'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isRead: json['isRead'] as bool? ?? false,
    deepLink: json['deepLink'] as String? ?? '/notifications',
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    isCritical: json['isCritical'] as bool? ?? false,
  );
}

class NotificationPreferences {
  final bool ordersEnabled;
  final bool fundsEnabled;
  final bool riskMarginEnabled;
  final bool priceAlertsEnabled;
  final bool newsEnabled;
  final bool securityEnabled;
  final bool quietHoursEnabled;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;
  final bool allowCriticalInQuietHours;

  const NotificationPreferences({
    this.ordersEnabled = true,
    this.fundsEnabled = true,
    this.riskMarginEnabled = true,
    this.priceAlertsEnabled = true,
    this.newsEnabled = true,
    this.securityEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 8,
    this.quietHoursEndMinute = 0,
    this.allowCriticalInQuietHours = true,
  });

  NotificationPreferences copyWith({
    bool? ordersEnabled,
    bool? fundsEnabled,
    bool? riskMarginEnabled,
    bool? priceAlertsEnabled,
    bool? newsEnabled,
    bool? securityEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
    bool? allowCriticalInQuietHours,
  }) {
    return NotificationPreferences(
      ordersEnabled: ordersEnabled ?? this.ordersEnabled,
      fundsEnabled: fundsEnabled ?? this.fundsEnabled,
      riskMarginEnabled: riskMarginEnabled ?? this.riskMarginEnabled,
      priceAlertsEnabled: priceAlertsEnabled ?? this.priceAlertsEnabled,
      newsEnabled: newsEnabled ?? this.newsEnabled,
      securityEnabled: securityEnabled ?? this.securityEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      allowCriticalInQuietHours: allowCriticalInQuietHours ?? this.allowCriticalInQuietHours,
    );
  }

  bool isCategoryEnabled(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.orders:
        return ordersEnabled;
      case NotificationCategory.funds:
        return fundsEnabled;
      case NotificationCategory.riskMargin:
        return riskMarginEnabled;
      case NotificationCategory.priceAlerts:
        return priceAlertsEnabled;
      case NotificationCategory.news:
        return newsEnabled;
      case NotificationCategory.security:
        return securityEnabled;
    }
  }

  bool isInQuietHours(DateTime time) {
    if (!quietHoursEnabled) return false;
    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = quietHoursStartHour * 60 + quietHoursStartMinute;
    final endMinutes = quietHoursEndHour * 60 + quietHoursEndMinute;

    if (startMinutes <= endMinutes) {
      // Quiet hours within same day e.g. 13:00 to 15:00
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Quiet hours crossing midnight e.g. 22:00 to 08:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  bool shouldDeliver(NotificationItem item, [DateTime? atTime]) {
    // 1. Check if category is enabled
    if (!isCategoryEnabled(item.category)) {
      return false;
    }

    // 2. Check quiet hours
    final time = atTime ?? DateTime.now();
    if (isInQuietHours(time)) {
      if (item.isCritical && allowCriticalInQuietHours) {
        return true;
      }
      return false;
    }

    return true;
  }
}
