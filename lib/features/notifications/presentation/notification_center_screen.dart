import 'package:flutter/material.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    final notifications = [
      {
        'title': 'Order Executed',
        'body': 'Your BUY order for 50 shares of SBIN was filled at ₹810.00.',
        'time': '10 mins ago',
        'icon': Icons.check_circle_outline,
        'color': colors.bullish,
      },
      {
        'title': 'Corporate Action Alert',
        'body': 'INFY has announced a dividend of ₹18.00 per share with Ex-Date 12 Sep.',
        'time': '1 hour ago',
        'icon': Icons.campaign_outlined,
        'color': colors.primary,
      },
      {
        'title': 'Market Opening Nudge',
        'body': 'Equity markets are open. NIFTY 50 started strong +0.45% in pre-open.',
        'time': '09:15 AM',
        'icon': Icons.trending_up,
        'color': colors.warning,
      },
      {
        'title': 'Funds Added',
        'body': '₹2,50,000.00 was credited to your Equity Trading Margin via UPI.',
        'time': 'Yesterday',
        'icon': Icons.account_balance_wallet_outlined,
        'color': colors.bullish,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications & Nudges', style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (item['color'] as Color).withValues(alpha: 0.15),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
            ),
            title: Text(item['title'] as String, style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(item['body'] as String, style: AppTypography.caption(color: colors.textSecondary)),
                const SizedBox(height: 4),
                Text(item['time'] as String, style: AppTypography.labelSmall(color: colors.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }
}
