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

extension NotificationTypeCategoryX on NotificationType {
  NotificationCategory get category {
    switch (this) {
      case NotificationType.orderSubmitted:
      case NotificationType.orderFilled:
      case NotificationType.orderPartiallyFilled:
      case NotificationType.orderRejected:
      case NotificationType.orderCancelled:
        return NotificationCategory.orders;
      case NotificationType.depositSuccess:
      case NotificationType.depositPending:
      case NotificationType.depositFailed:
      case NotificationType.withdrawalInitiated:
      case NotificationType.withdrawalCompleted:
      case NotificationType.withdrawalFailed:
        return NotificationCategory.funds;
      case NotificationType.marginWarning:
      case NotificationType.liquidationWarning:
        return NotificationCategory.riskMargin;
      case NotificationType.priceAlert:
        return NotificationCategory.priceAlerts;
      case NotificationType.newsAlert:
        return NotificationCategory.news;
      case NotificationType.securityAlert:
      case NotificationType.loginNewDevice:
      case NotificationType.passwordChanged:
      case NotificationType.kycStatusChanged:
      case NotificationType.accountNotice:
        return NotificationCategory.security;
    }
  }
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
    this.deepLink = '',
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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    NotificationType nType = NotificationType.accountNotice;
    final typeStr = (json['type'] ?? '').toString();
    try {
      nType = NotificationType.values.byName(typeStr);
    } catch (_) {
      if (typeStr.contains('ORDER')) {
        nType = NotificationType.orderFilled;
      } else if (typeStr.contains('DEPOSIT') || typeStr.contains('FUNDS')) {
        nType = NotificationType.depositSuccess;
      } else if (typeStr.contains('WITHDRAW')) {
        nType = NotificationType.withdrawalInitiated;
      } else if (typeStr.contains('ALERT')) {
        nType = NotificationType.priceAlert;
      }
    }

    NotificationCategory nCat = NotificationCategory.orders;
    final catStr = (json['category'] ?? '').toString();
    try {
      nCat = NotificationCategory.values.byName(catStr);
    } catch (_) {
      if (catStr.contains('FUND') || catStr.contains('WALLET')) {
        nCat = NotificationCategory.funds;
      } else if (catStr.contains('ALERT')) {
        nCat = NotificationCategory.priceAlerts;
      } else if (catStr.contains('NEWS')) {
        nCat = NotificationCategory.news;
      } else if (catStr.contains('SEC') || catStr.contains('AUTH')) {
        nCat = NotificationCategory.security;
      }
    }

    return NotificationItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: nType,
      category: nCat,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      isRead: (json['isRead'] ?? json['read'] ?? false) == true,
      deepLink: (json['deepLink'] ??
              (json['data'] is Map ? json['data']['route'] : null) ??
              json['route'] ??
              '/notifications')
          .toString(),
      metadata: (json['metadata'] ?? json['data'] as Map<String, dynamic>?) ?? {},
      isCritical: (json['isCritical'] ?? false) == true,
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'ordersEnabled': ordersEnabled,
      'fundsEnabled': fundsEnabled,
      'riskMarginEnabled': riskMarginEnabled,
      'priceAlertsEnabled': priceAlertsEnabled,
      'newsEnabled': newsEnabled,
      'securityEnabled': securityEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStartHour': quietHoursStartHour,
      'quietHoursStartMinute': quietHoursStartMinute,
      'quietHoursEndHour': quietHoursEndHour,
      'quietHoursEndMinute': quietHoursEndMinute,
      'allowCriticalInQuietHours': allowCriticalInQuietHours,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      ordersEnabled: json['ordersEnabled'] as bool? ?? true,
      fundsEnabled: json['fundsEnabled'] as bool? ?? true,
      riskMarginEnabled: json['riskMarginEnabled'] as bool? ?? true,
      priceAlertsEnabled: json['priceAlertsEnabled'] as bool? ?? true,
      newsEnabled: json['newsEnabled'] as bool? ?? true,
      securityEnabled: json['securityEnabled'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStartHour: json['quietHoursStartHour'] as int? ?? 22,
      quietHoursStartMinute: json['quietHoursStartMinute'] as int? ?? 0,
      quietHoursEndHour: json['quietHoursEndHour'] as int? ?? 8,
      quietHoursEndMinute: json['quietHoursEndMinute'] as int? ?? 0,
      allowCriticalInQuietHours: json['allowCriticalInQuietHours'] as bool? ?? true,
    );
  }
}
