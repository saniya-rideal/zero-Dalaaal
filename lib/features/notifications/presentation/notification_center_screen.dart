import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import 'notification_preferences_sheet.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  NotificationCategory? _selectedCategory;
  bool _unreadOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleDeepLink(NotificationItem item) {
    ref.read(notificationServiceProvider).markAsRead(item.id);
    if (item.deepLink.isNotEmpty && item.deepLink != '/notifications') {
      try {
        context.push(item.deepLink);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${item.title}...')),
        );
      }
    }
  }

  void _showClearAllConfirmDialog() {
    final colors = context.tradingColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text(
          'Clear All Notifications?',
          style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
        ),
        content: Text(
          'This will delete all notifications from your notification center. This action cannot be undone.',
          style: AppTypography.body(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.body(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(notificationServiceProvider).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.bearish),
            child: Text('Clear All', style: AppTypography.body(color: Colors.white, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory category, TradingColors colors) {
    switch (category) {
      case NotificationCategory.orders:
        return colors.bullish;
      case NotificationCategory.funds:
        return colors.primary;
      case NotificationCategory.riskMargin:
        return colors.bearish;
      case NotificationCategory.priceAlerts:
        return colors.warning;
      case NotificationCategory.news:
        return Colors.tealAccent;
      case NotificationCategory.security:
        return Colors.purpleAccent;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderSubmitted:
        return Icons.send_outlined;
      case NotificationType.orderFilled:
        return Icons.check_circle_outline;
      case NotificationType.orderPartiallyFilled:
        return Icons.pie_chart_outline;
      case NotificationType.orderRejected:
        return Icons.cancel_outlined;
      case NotificationType.orderCancelled:
        return Icons.close;
      case NotificationType.depositSuccess:
        return Icons.arrow_downward_rounded;
      case NotificationType.depositPending:
        return Icons.hourglass_top_outlined;
      case NotificationType.depositFailed:
        return Icons.error_outline;
      case NotificationType.withdrawalInitiated:
        return Icons.arrow_upward_rounded;
      case NotificationType.withdrawalCompleted:
        return Icons.done_all_rounded;
      case NotificationType.withdrawalFailed:
        return Icons.replay_rounded;
      case NotificationType.marginWarning:
        return Icons.warning_amber_rounded;
      case NotificationType.liquidationWarning:
        return Icons.gavel_rounded;
      case NotificationType.priceAlert:
        return Icons.notifications_active_outlined;
      case NotificationType.newsAlert:
        return Icons.newspaper_outlined;
      case NotificationType.securityAlert:
        return Icons.security_outlined;
      case NotificationType.loginNewDevice:
        return Icons.devices_outlined;
      case NotificationType.passwordChanged:
        return Icons.lock_reset_outlined;
      case NotificationType.kycStatusChanged:
        return Icons.verified_user_outlined;
      case NotificationType.accountNotice:
        return Icons.campaign_outlined;
    }
  }

  String _getCtaLabel(NotificationType type) {
    switch (type) {
      case NotificationType.orderSubmitted:
      case NotificationType.orderFilled:
      case NotificationType.orderPartiallyFilled:
      case NotificationType.orderCancelled:
        return 'View Order';
      case NotificationType.orderRejected:
      case NotificationType.marginWarning:
      case NotificationType.liquidationWarning:
        return 'Add Funds';
      case NotificationType.depositSuccess:
      case NotificationType.depositPending:
      case NotificationType.depositFailed:
      case NotificationType.withdrawalInitiated:
      case NotificationType.withdrawalCompleted:
      case NotificationType.withdrawalFailed:
        return 'View Funds';
      case NotificationType.priceAlert:
        return 'View Chart';
      case NotificationType.newsAlert:
      case NotificationType.accountNotice:
        return 'Read More';
      case NotificationType.securityAlert:
      case NotificationType.passwordChanged:
        return 'Security';
      case NotificationType.loginNewDevice:
      case NotificationType.kycStatusChanged:
        return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final notifService = ref.watch(notificationServiceProvider);
    final unreadCount = notifService.unreadCount;

    final filteredList = notifService.filter(
      query: _searchController.text,
      category: _selectedCategory,
      unreadOnly: _unreadOnly,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notifications',
                style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: AppTypography.labelSmall(color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: unreadCount > 0
                ? () {
                    ref.read(notificationServiceProvider).markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
          ),
          // Clear all button
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: notifService.allNotifications.isNotEmpty
                ? _showClearAllConfirmDialog
                : null,
          ),
          // Preferences button
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Notification Preferences',
            onPressed: () => NotificationPreferencesSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTypography.body(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search orders, funds, alerts, symbols...',
                hintStyle: AppTypography.body(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
          ),

          // 2. Category Chips Bar
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                  colors: colors,
                ),
                _buildCategoryChip(
                  label: 'Orders',
                  isSelected: _selectedCategory == NotificationCategory.orders,
                  icon: Icons.receipt_long_outlined,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.orders),
                  colors: colors,
                ),
                _buildCategoryChip(
                  label: 'Funds',
                  isSelected: _selectedCategory == NotificationCategory.funds,
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.funds),
                  colors: colors,
                ),
                _buildCategoryChip(
                  label: 'Risk & Margin',
                  isSelected: _selectedCategory == NotificationCategory.riskMargin,
                  icon: Icons.warning_amber_rounded,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.riskMargin),
                  colors: colors,
                ),
                _buildCategoryChip(
                  label: 'Price Alerts',
                  isSelected: _selectedCategory == NotificationCategory.priceAlerts,
                  icon: Icons.notifications_active_outlined,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.priceAlerts),
                  colors: colors,
                ),
                _buildCategoryChip(
                  label: 'News',
                  isSelected: _selectedCategory == NotificationCategory.news,
                  icon: Icons.newspaper_outlined,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.news),
                  colors: colors,
                ),
                _buildCategoryChip(
                  label: 'Security',
                  isSelected: _selectedCategory == NotificationCategory.security,
                  icon: Icons.shield_outlined,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.security),
                  colors: colors,
                ),
                // Unread Only toggle chip
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Unread Only', style: AppTypography.labelSmall(
                    color: _unreadOnly ? Colors.white : colors.textSecondary,
                    weight: _unreadOnly ? FontWeight.w700 : FontWeight.w500,
                  )),
                  selected: _unreadOnly,
                  selectedColor: colors.primary,
                  backgroundColor: colors.cardBackground,
                  showCheckmark: false,
                  onSelected: (v) => setState(() => _unreadOnly = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Notification List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(colors)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildNotificationCard(item, colors);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : colors.textSecondary,
              )
            : null,
        label: Text(
          label,
          style: AppTypography.labelSmall(
            color: isSelected ? Colors.white : colors.textSecondary,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedColor: colors.primary,
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.divider,
          ),
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, TradingColors colors) {
    final catColor = _getCategoryColor(item.category, colors);
    final iconData = _getTypeIcon(item.type);
    final ctaLabel = _getCtaLabel(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.bearish,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        ref.read(notificationServiceProvider).deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification removed.'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(notificationServiceProvider).notify(item);
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () => _handleDeepLink(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead
                ? colors.cardBackground
                : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isRead
                  ? colors.divider
                  : colors.primary.withValues(alpha: 0.5),
              width: item.isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category / Status Icon
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: catColor.withValues(alpha: 0.15),
                    radius: 20,
                    child: Icon(iconData, color: catColor, size: 20),
                  ),
                  if (!item.isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.cardBackground, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Relative Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.body(
                              color: colors.textPrimary,
                              weight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.timeAgo,
                          style: AppTypography.caption(color: colors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body
                    Text(
                      item.body,
                      style: AppTypography.caption(
                        color: item.isRead ? colors.textSecondary : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Deep Link Action Pill & Critical Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.isCritical)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.bearish.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.bearish.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high, size: 12, color: colors.bearish),
                                const SizedBox(width: 2),
                                Text(
                                  'CRITICAL',
                                  style: AppTypography.labelSmall(color: colors.bearish, weight: FontWeight.w700),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        // CTA Button
                        InkWell(
                          onTap: () => _handleDeepLink(item),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ctaLabel,
                                  style: AppTypography.labelSmall(
                                    color: colors.primary,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: colors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TradingColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colors.cardBackground,
              child: Icon(Icons.notifications_off_outlined, size: 36, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'All Caught Up!',
              style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty || _selectedCategory != null || _unreadOnly
                  ? 'No notifications match your search or filter.'
                  : 'You have no notifications or alerts at this moment.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (_searchController.text.isNotEmpty || _selectedCategory != null || _unreadOnly)
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Filters'),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = null;
                    _unreadOnly = false;
                  });
                },
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.tune),
                label: const Text('Notification Preferences'),
                onPressed: () => NotificationPreferencesSheet.show(context),
              ),
          ],
        ),
      ),
    );
  }
}
