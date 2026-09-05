import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/funds/presentation/add_funds_sheet.dart';
import '../features/funds/presentation/withdraw_funds_sheet.dart';
import 'zero_nav_icons.dart';

class ZeroDrawer extends ConsumerWidget {
  final String activeRoute;

  const ZeroDrawer({super.key, this.activeRoute = '/quotes'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authControllerProvider);
    final profile = authState.session?.profile;
    final displayName = profile != null
        ? '${profile.userId}: ${profile.name}'
        : '159537: Anurag Sin...';
    final displayPhone = profile != null
        ? '${profile.phone} - Zero'
        : '8739039936 - Zero';
    final initials = (profile?.name.isNotEmpty == true)
        ? profile!.name.substring(0, 1).toUpperCase()
        : 'A';

    return Drawer(
      width: (screenWidth * 0.74).clamp(260.0, 320.0),
      backgroundColor: colors.background,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            InkWell(
              onTap: () => _showAccountSwitchSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.divider.withValues(alpha: 0.5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayPhone,
                            style: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: colors.textPrimary, size: 24),
                  ],
                ),
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                children: [
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Quotes',
                    iconBuilder: (color) => ZeroNavIcons.quotesIcon(color: color, size: 22),
                    route: '/quotes',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Chart',
                    iconBuilder: (color) => CustomPaint(size: const Size(22, 22), painter: _ChartLineIconPainter(color: color)),
                    route: '/chart-fullscreen/copper_mcx',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Deals',
                    iconBuilder: (color) => ZeroNavIcons.dealsIcon(color: color, size: 22),
                    route: '/deals',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Orders',
                    iconBuilder: (color) => Icon(Icons.receipt_long_outlined, color: color, size: 22),
                    route: '/orders',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Net Deals',
                    iconBuilder: (color) => ZeroNavIcons.netDealsIcon(color: color, size: 22),
                    route: '/net-deals',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'History',
                    iconBuilder: (color) => ZeroNavIcons.historyIcon(color: color, size: 22),
                    route: '/history',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Alerts',
                    iconBuilder: (color) => Icon(Icons.notifications_none_outlined, color: color, size: 23),
                    route: '/alerts',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Economic Calendar',
                    iconBuilder: (color) => Icon(Icons.calendar_month_outlined, color: color, size: 22),
                    route: '/economic-calendar',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Accounts',
                    iconBuilder: (color) => Icon(Icons.people_outline, color: color, size: 23),
                    onTap: () => _showAccountSwitchSheet(context),
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Deposit Fund',
                    iconBuilder: (color) => Center(
                      child: Text(
                        r'$',
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      AddFundsSheet.show(context);
                    },
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Withdraw Fund',
                    iconBuilder: (color) => CustomPaint(size: const Size(22, 22), painter: _WithdrawIconPainter(color: color)),
                    onTap: () {
                      Navigator.pop(context);
                      WithdrawFundsSheet.show(context);
                    },
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'News & Insights',
                    iconBuilder: (color) => Icon(Icons.newspaper_outlined, color: color, size: 22),
                    route: '/news',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Mails',
                    iconBuilder: (color) => Icon(Icons.mail_outline, color: color, size: 22),
                    route: '/mails',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Profit Calculator',
                    iconBuilder: (color) => Icon(Icons.calculate_outlined, color: color, size: 23),
                    route: '/profit-calculator',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Margin Calculator',
                    iconBuilder: (color) => Icon(Icons.calculate_outlined, color: color, size: 23),
                    route: '/margin-calculator',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Support',
                    iconBuilder: (color) => Icon(Icons.support_agent_outlined, color: color, size: 23),
                    route: '/help',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Settings',
                    iconBuilder: (color) => Icon(Icons.settings_outlined, color: color, size: 22),
                    route: '/settings',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'About',
                    iconBuilder: (color) => CustomPaint(size: const Size(22, 22), painter: _AboutBubbleIconPainter(color: color)),
                    route: '/about',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Share',
                    iconBuilder: (color) => Icon(Icons.share_outlined, color: color, size: 22),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Log out',
                    iconBuilder: (color) => Icon(Icons.logout, color: color, size: 22),
                    isLogout: true,
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDrawerItem({
    required BuildContext context,
    required String title,
    required Widget Function(Color color) iconBuilder,
    String? route,
    VoidCallback? onTap,
    bool isLogout = false,
    required TradingColors colors,
  }) {
    final isSelected = route != null && activeRoute == route;
    final itemColor = isLogout
        ? colors.primary
        : isSelected
            ? colors.primary
            : colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.15)
            : Colors.transparent, // Soft Pink Accent Pill
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.pop(context);
                if (route != null) {
                  context.go(route);
                }
              },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Center(child: iconBuilder(itemColor)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: itemColor,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountSwitchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Trading Account', style: AppTypography.h2(weight: FontWeight.w700)),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Color(0xFF00A854)),
                title: const Text('159537: Anurag Singh (LIVE)'),
                subtitle: const Text('Balance: 0.00 USD • Margin Level: 100.00%'),
                onTap: () => Navigator.pop(context),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('248901: Demo Trading Account'),
                subtitle: const Text('Balance: 10,000.00 USD (Virtual)'),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Chart Line with Nodes Painter matching screenshot
class _ChartLineIconPainter extends CustomPainter {
  final Color color;
  const _ChartLineIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path = Path()
      ..moveTo(2, 18)
      ..lineTo(7, 14)
      ..lineTo(13, 16)
      ..lineTo(20, 6);

    canvas.drawPath(path, paint);

    // 4 Nodes
    canvas.drawCircle(const Offset(2, 18), 1.5, dotPaint);
    canvas.drawCircle(const Offset(7, 14), 1.5, dotPaint);
    canvas.drawCircle(const Offset(13, 16), 1.5, dotPaint);
    canvas.drawCircle(const Offset(20, 6), 1.5, dotPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChartLineIconPainter oldDelegate) => oldDelegate.color != color;
}

/// Custom Withdraw Hand with Down Arrow Painter matching screenshot
class _WithdrawIconPainter extends CustomPainter {
  final Color color;
  const _WithdrawIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Open hand palm
    final handPath = Path()
      ..moveTo(2, 15)
      ..lineTo(6, 19)
      ..lineTo(17, 19)
      ..lineTo(21, 14);

    canvas.drawPath(handPath, paint);

    // Down arrow into hand
    canvas.drawLine(const Offset(11.5, 3), const Offset(11.5, 13), paint);
    canvas.drawLine(const Offset(7.5, 9), const Offset(11.5, 13), paint);
    canvas.drawLine(const Offset(15.5, 9), const Offset(11.5, 13), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WithdrawIconPainter oldDelegate) => oldDelegate.color != color;
}

/// Custom Speech Bubble with 'i' Painter matching screenshot
class _AboutBubbleIconPainter extends CustomPainter {
  final Color color;
  const _AboutBubbleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Chat bubble
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2, 2, 18, 15),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, paint);

    // Small speech tail
    final tailPath = Path()
      ..moveTo(5, 17)
      ..lineTo(3, 21)
      ..lineTo(8, 17);
    canvas.drawPath(tailPath, paint);

    // Letter 'i' (dot + line)
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(11, 6), 1.0, fillPaint);
    canvas.drawLine(const Offset(11, 8.5), const Offset(11, 13), paint..strokeWidth = 1.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AboutBubbleIconPainter oldDelegate) => oldDelegate.color != color;
}
