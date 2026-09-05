import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/section_card.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../auth/presentation/auth_controller.dart';
import 'kyc_management_sheet.dart';
import 'nominee_management_sheet.dart';
import 'personal_details_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);
    final profile = authState.session?.profile;

    final name = profile?.name ?? AppConstants.demoUserName;
    final userId = profile?.userId ?? AppConstants.demoUserId;
    final pan = profile?.pan ?? AppConstants.demoPan;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/profile'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (innerContext) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text('Account & Profile',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Profile Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // 1. User Header Card (Clickable to open PersonalDetailsSheet)
                  InkWell(
                    onTap: () => PersonalDetailsSheet.show(context),
                    child: SectionCard(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                colors.primary.withValues(alpha: 0.15),
                            child: Text(
                              name.isNotEmpty ? name.substring(0, 1) : 'A',
                              style: GoogleFonts.inter(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.edit_outlined, size: 16, color: colors.primary),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$userId • PAN: $pan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      color: colors.textSecondary,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => KycManagementSheet.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.bullish.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'KYC VERIFIED',
                                style: GoogleFonts.inter(
                                    color: colors.bullish,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 2. Profile, KYC & Account Management Section
                  _buildMenuGroup(context, [
                    _MenuItem(
                      icon: Icons.person_outline,
                      title: 'Personal & Demat Details',
                      subtitle: 'Edit contact, address, DOB, BO ID',
                      onTap: () => PersonalDetailsSheet.show(context),
                    ),
                    _MenuItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Identity & KYC Documents',
                      subtitle: 'PAN, Aadhaar, verification status',
                      onTap: () => KycManagementSheet.show(context),
                    ),
                    _MenuItem(
                      icon: Icons.family_restroom_outlined,
                      title: 'Nominee / Beneficiary',
                      subtitle: 'SEBI compliant nominee allocation',
                      onTap: () => NomineeManagementSheet.show(context),
                    ),
                    const _MenuItem(
                      icon: Icons.account_balance_outlined,
                      title: 'Bank Accounts & UPI',
                      subtitle: 'Linked bank, IFSC, instant pay-in',
                      route: '/funds',
                    ),
                  ], colors),

                  const SizedBox(height: 8),

                  // 3. Products & Utilities Section
                  _buildMenuGroup(context, const [
                    _MenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Funds & Ledger',
                        subtitle: 'Pay in, withdraw, balance',
                        route: '/funds'),
                    _MenuItem(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Baskets',
                        subtitle: 'Multi-leg order baskets',
                        route: '/baskets'),
                    _MenuItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Stock SIP',
                        subtitle: 'Automated recurring investments',
                        route: '/sip'),
                    _MenuItem(
                        icon: Icons.notifications_none_outlined,
                        title: 'Alerts',
                        subtitle: 'Price and percentage triggers',
                        route: '/alerts'),
                    _MenuItem(
                        icon: Icons.rocket_launch_outlined,
                        title: 'IPO',
                        subtitle: 'Initial public offerings',
                        route: '/ipo'),
                    _MenuItem(
                        icon: Icons.table_chart_outlined,
                        title: 'Option Chain',
                        subtitle: 'Nifty & Bank Nifty derivatives',
                        route: '/option-chain'),
                  ], colors),

                  const SizedBox(height: 8),

                  // 4. Reports, Settings & Support
                  _buildMenuGroup(context, const [
                    _MenuItem(
                        icon: Icons.assessment_outlined,
                        title: 'Reports & Tax P&L',
                        subtitle: 'Capital gains, trade log',
                        route: '/reports'),
                    _MenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings & Security',
                        subtitle: 'Theme, Security, PIN',
                        route: '/settings'),
                    _MenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'FAQs, tickets, contact desk',
                        route: '/help'),
                  ], colors),

                  const SizedBox(height: 12),

                  // 5. Account Deletion / Data Closure Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TextButton.icon(
                      icon: Icon(Icons.delete_forever_outlined, color: colors.bearish, size: 20),
                      label: Text(
                        'Close Trading Account & Request Data Deletion',
                        style: GoogleFonts.inter(
                          color: colors.bearish,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _showAccountClosureDialog(context, ref, colors),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 6. Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.logout, color: colors.bearish),
                      label: Text('Logout from Zero',
                          style: TextStyle(
                              color: colors.bearish,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: colors.bearish.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        context.go('/login');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountClosureDialog(BuildContext context, WidgetRef ref, TradingColors colors) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.bearish, size: 28),
            const SizedBox(width: 8),
            Text('Account Closure', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: colors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently close your Zero Trading Account?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5, color: colors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              '• All open positions and orders must be squared off.\n• Unused ledger balance will be refunded to your primary bank.\n• In accordance with SEBI/PMLA regulatory mandates, financial audit logs will be preserved securely for 5 years.',
              style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.bearish,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account closure request submitted. Session terminated.'),
                  backgroundColor: Color(0xFFC62828),
                ),
              );
            },
            child: const Text('CONFIRM CLOSURE'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(
      BuildContext context, List<_MenuItem> items, TradingColors colors) {
    return SectionCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.zero,
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(item.icon, color: colors.primary, size: 22),
                  title: Text(item.title,
                      style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  subtitle: Text(item.subtitle,
                      style: GoogleFonts.inter(
                          color: colors.textSecondary, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right,
                      size: 20, color: colors.textSecondary),
                  onTap: () {
                    if (item.onTap != null) {
                      item.onTap!();
                    } else if (item.route.isNotEmpty) {
                      context.push(item.route);
                    }
                  },
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    indent: 54,
                    color: colors.divider.withValues(alpha: 0.5)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route = '',
    this.onTap,
  });
}
