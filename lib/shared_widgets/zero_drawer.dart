import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/web_redirect_service.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'zero_nav_icons.dart';

class ZeroDrawer extends ConsumerStatefulWidget {
  final String activeRoute;

  const ZeroDrawer({super.key, this.activeRoute = '/quotes'});

  @override
  ConsumerState<ZeroDrawer> createState() => _ZeroDrawerState();
}

class _ZeroDrawerState extends ConsumerState<ZeroDrawer> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authControllerProvider);
    final profile = authState.session?.profile;
    final displayName = profile != null
        ? '${profile.userId}: ${profile.name}'
        : '159537: Anurag Sin...';
    final displayPhone = profile != null
        ? '${profile.phone} - ZeroDalali'
        : '8739039936 - ZeroDalali';

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
            // User Header with Bull Logo
            InkWell(
              onTap: () {
                if (_isNavigating) return;
                _showAccountSwitchSheet(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.divider.withValues(alpha: 0.5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    // Bull Logo Icon Badge (Matching Reference Image)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.bicepsFlexed,
                          color: Colors.white,
                          size: 22,
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
                    Icon(LucideIcons.chevronDown, color: colors.textPrimary, size: 20),
                  ],
                ),
              ),
            ),

            // Navigation Items List (Matching Reference Screenshots 1-5)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                children: [
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Quotes',
                    iconBuilder: (color) => ZeroNavIcons.quotesIcon(color: color, size: 20),
                    route: '/quotes',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Chart',
                    iconBuilder: (color) => Icon(LucideIcons.lineChart, color: color, size: 20),
                    route: '/chart-fullscreen/copper_mcx',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Deals',
                    iconBuilder: (color) => ZeroNavIcons.dealsIcon(color: color, size: 20),
                    route: '/deals',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Net Deals',
                    iconBuilder: (color) => ZeroNavIcons.netDealsIcon(color: color, size: 20),
                    route: '/net-deals',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'History',
                    iconBuilder: (color) => ZeroNavIcons.historyIcon(color: color, size: 20),
                    route: '/history',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Alerts',
                    iconBuilder: (color) => Icon(LucideIcons.bell, color: color, size: 20),
                    route: '/alerts',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Economic Calendar',
                    iconBuilder: (color) => Icon(LucideIcons.calendar, color: color, size: 20),
                    route: '/economic-calendar',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Accounts',
                    iconBuilder: (color) => Icon(LucideIcons.users, color: color, size: 20),
                    onTap: () => _showAccountSwitchSheet(context),
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Deposit Fund',
                    iconBuilder: (color) => Icon(LucideIcons.dollarSign, color: color, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      WebRedirectService.openDepositWebsite(context: context);
                    },
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Withdraw Fund',
                    iconBuilder: (color) => Icon(LucideIcons.arrowDownLeft, color: color, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      WebRedirectService.openWithdrawWebsite(context: context);
                    },
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'News',
                    iconBuilder: (color) => Icon(LucideIcons.newspaper, color: color, size: 20),
                    route: '/news',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Mails',
                    iconBuilder: (color) => Icon(LucideIcons.mail, color: color, size: 20),
                    route: '/mails',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Profit Calculator',
                    iconBuilder: (color) => Icon(LucideIcons.calculator, color: color, size: 20),
                    route: '/profit-calculator',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Margin Calculator',
                    iconBuilder: (color) => Icon(LucideIcons.percent, color: color, size: 20),
                    route: '/margin-calculator',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Support',
                    iconBuilder: (color) => Icon(LucideIcons.headphones, color: color, size: 20),
                    route: '/help',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Settings',
                    iconBuilder: (color) => Icon(LucideIcons.settings, color: color, size: 20),
                    route: '/settings',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'About',
                    iconBuilder: (color) => Icon(LucideIcons.info, color: color, size: 20),
                    route: '/about',
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Share',
                    iconBuilder: (color) => Icon(LucideIcons.share2, color: color, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      _showShareAppSheet(context, colors);
                    },
                    colors: colors,
                  ),
                  _buildCustomDrawerItem(
                    context: context,
                    title: 'Log out',
                    iconBuilder: (color) => Icon(LucideIcons.logOut, color: color, size: 20),
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
    final isSelected = route != null && widget.activeRoute == route;
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
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (_isNavigating) return;
            _isNavigating = true;
            if (onTap != null) {
              onTap();
            } else {
              Navigator.pop(context);
              if (route != null && widget.activeRoute != route) {
                context.go(route);
              }
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
    final colors = context.tradingColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Trading Account', style: AppTypography.h2(weight: FontWeight.w700).copyWith(color: colors.textPrimary)),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(LucideIcons.checkCircle2, color: Color(0xFF00A854), size: 22),
                title: Text('159537: Anurag Singh (LIVE)', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Balance: 0.00 USD • Margin Level: 100.00%', style: TextStyle(color: colors.textSecondary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Active Account: 159537: Anurag Singh (LIVE)'),
                      backgroundColor: colors.surface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(LucideIcons.user, color: colors.textSecondary, size: 22),
                title: Text('248901: Demo Trading Account', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Balance: 10,000.00 USD (Virtual)', style: TextStyle(color: colors.textSecondary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Switched to Demo Trading Account (10,000 USD virtual)'),
                      backgroundColor: colors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareAppSheet(BuildContext context, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.share2, color: colors.primary, size: 22),
                const SizedBox(width: 12),
                Text('Share Zero Trading', style: AppTypography.h2(weight: FontWeight.w700).copyWith(color: colors.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Invite friends to trade with zero brokerage and seamless execution. Share your referral link below:',
              style: AppTypography.caption(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'https://zero.trade/invite/ANURAG159537',
                      style: AppTypography.body(color: colors.primary, weight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'https://zero.trade/invite/ANURAG159537'));
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Referral link copied to clipboard!'),
                          backgroundColor: colors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.copy, size: 16, color: colors.primary),
                        const SizedBox(width: 4),
                        Text('Copy', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.send, size: 18),
                label: const Text('Share Link', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'https://zero.trade/invite/ANURAG159537'));
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Referral link copied! Share it with your contacts.'),
                      backgroundColor: colors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
