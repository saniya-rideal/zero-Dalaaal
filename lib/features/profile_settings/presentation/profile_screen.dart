import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../auth/presentation/auth_controller.dart';
import 'kyc_management_sheet.dart';
import 'nominee_management_sheet.dart';
import 'personal_details_sheet.dart';
import 'fatca_declaration_sheet.dart';
import 'risk_profile_sheet.dart';
import '../../../data/mock/fatca_repository.dart';
import '../../../data/mock/risk_profile_repository.dart';
import '../../../data/models/investor_risk_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);
    final fatca = ref.watch(fatcaDeclarationProvider);
    final riskProfile = ref.watch(riskProfileProvider);
    final profile = authState.session?.profile;

    Color riskBadgeColor;
    switch (riskProfile.category) {
      case RiskCategory.conservative:
        riskBadgeColor = const Color(0xFF0284C7);
        break;
      case RiskCategory.moderate:
        riskBadgeColor = const Color(0xFF10B981);
        break;
      case RiskCategory.aggressive:
        riskBadgeColor = const Color(0xFFF59E0B);
        break;
    }

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
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text('Account & Profile',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: Column(
        children: [
          // Combined Market Header Strip
          const ZeroMarketHeaderStrip(),

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
                                    Icon(LucideIcons.penSquare, size: 16, color: colors.primary),
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
                      icon: LucideIcons.user,
                      title: 'Personal & Demat Details',
                      subtitle: 'Edit contact, address, DOB, BO ID',
                      onTap: () => PersonalDetailsSheet.show(context),
                    ),
                    _MenuItem(
                      icon: LucideIcons.shieldCheck,
                      title: 'Identity & KYC Documents',
                      subtitle: 'PAN, Aadhaar, verification status',
                      onTap: () => KycManagementSheet.show(context),
                    ),
                    _MenuItem(
                      icon: LucideIcons.fileCheck2,
                      title: 'FATCA / CRS & PEP Declaration',
                      subtitle: 'Tax residency (IT Rules 114F–114H)',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.bullish.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fatca.status == 'VERIFIED'
                                  ? 'COMPLIED'
                                  : 'PENDING',
                              style: GoogleFonts.inter(
                                color: colors.bullish,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.chevronRight,
                                size: 14, color: colors.textSecondary),
                          ],
                        ),
                      ),
                      onTap: () => FatcaDeclarationSheet.show(context),
                    ),
                    _MenuItem(
                      icon: LucideIcons.gauge,
                      title: 'Investor Risk Profile',
                      subtitle: 'SEBI suitability & risk tolerance assessment',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: riskBadgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              riskProfile.category.label.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: riskBadgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.chevronRight,
                                size: 14, color: colors.textSecondary),
                          ],
                        ),
                      ),
                      onTap: () => RiskProfileSheet.show(context),
                    ),
                    _MenuItem(
                      icon: LucideIcons.users,
                      title: 'Nominee / Beneficiary',
                      subtitle: 'SEBI compliant nominee allocation',
                      onTap: () => NomineeManagementSheet.show(context),
                    ),
                    const _MenuItem(
                      icon: LucideIcons.landmark,
                      title: 'Bank Accounts & UPI',
                      subtitle: 'Linked bank, IFSC, instant pay-in',
                      route: '/funds',
                    ),
                  ], colors),

                  const SizedBox(height: 8),

                  // 3. Products & Utilities Section
                  _buildMenuGroup(context, const [
                    _MenuItem(
                        icon: LucideIcons.wallet,
                        title: 'Funds & Ledger',
                        subtitle: 'Pay in, withdraw, balance',
                        route: '/funds'),
                    _MenuItem(
                        icon: LucideIcons.shoppingBag,
                        title: 'Baskets',
                        subtitle: 'Multi-leg order baskets',
                        route: '/baskets'),
                    _MenuItem(
                        icon: LucideIcons.calendar,
                        title: 'Stock SIP',
                        subtitle: 'Automated recurring investments',
                        route: '/sip'),
                    _MenuItem(
                        icon: LucideIcons.bell,
                        title: 'Alerts',
                        subtitle: 'Price and percentage triggers',
                        route: '/alerts'),
                    _MenuItem(
                        icon: LucideIcons.rocket,
                        title: 'IPO',
                        subtitle: 'Initial public offerings',
                        route: '/ipo'),
                    _MenuItem(
                        icon: LucideIcons.candlestickChart,
                        title: 'Option Chain',
                        subtitle: 'Nifty & Bank Nifty derivatives',
                        route: '/option-chain'),
                  ], colors),

                  const SizedBox(height: 8),

                  // 4. Reports, Settings & Support
                  _buildMenuGroup(context, const [
                    _MenuItem(
                        icon: LucideIcons.barChart2,
                        title: 'Reports & Tax P&L',
                        subtitle: 'Capital gains, trade log',
                        route: '/reports'),
                    _MenuItem(
                        icon: LucideIcons.settings,
                        title: 'Settings & Security',
                        subtitle: 'Theme, Security, PIN',
                        route: '/settings'),
                    _MenuItem(
                        icon: LucideIcons.helpCircle,
                        title: 'Help & Support',
                        subtitle: 'FAQs, tickets, contact desk',
                        route: '/help'),
                  ], colors),

                  const SizedBox(height: 12),

                  // 5. Account Deletion / Data Closure Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TextButton.icon(
                      icon: Icon(LucideIcons.userX, color: colors.bearish, size: 20),
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
                      icon: Icon(LucideIcons.logOut, color: colors.bearish, size: 18),
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
            Icon(LucideIcons.alertTriangle, color: colors.bearish, size: 26),
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
                  trailing: item.trailingWidget ??
                      Icon(LucideIcons.chevronRight,
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
  final Widget? trailingWidget;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route = '',
    this.onTap,
    this.trailingWidget,
  });
}
