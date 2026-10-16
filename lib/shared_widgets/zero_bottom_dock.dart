import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/balance_privacy_service.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../core/utils/currency_formatter.dart';
import '../data/models/funds.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/funds/data/real_funds_repository.dart';

class ZeroBottomDock extends ConsumerWidget {
  final bool showRealValues;

  const ZeroBottomDock({super.key, this.showRealValues = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final fundsAsync = ref.watch(fundsSummaryProvider);
    final funds = fundsAsync.valueOrNull ??
        const FundsSummary(
          availableMargin: 0,
          usedMargin: 0,
          openingBalance: 0,
        );
    final isHidden = ref.watch(balancePrivacyProvider);
    final profile = ref.watch(authControllerProvider).session?.profile;

    String fmt(double val) {
      if (isHidden) return '••••••';
      return showRealValues ? CurrencyFormatter.format(val, showSymbol: false) : '0.00';
    }

    final balance = fmt(funds.openingBalance);
    final floatingPl = fmt(funds.unrealizedPnl);
    final usedMargin = fmt(funds.usedMargin);
    final assetsValue = isHidden ? '••••••' : '0.00';
    final totalValues = fmt(funds.availableMargin);

    final freeMargin = fmt(funds.freeMargin);
    final equity = fmt(funds.equity);
    final hldgMargin = isHidden ? '••••••' : '0.00';
    final marginLevel = isHidden
        ? '••••••'
        : (funds.usedMargin > 0
            ? '${funds.marginLevel.toStringAsFixed(1)}%'
            : 'N/A');
    final account = (profile?.clientId != null && profile!.clientId.isNotEmpty)
        ? profile.clientId
        : 'Primary';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.dockBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: colors.divider.withValues(alpha: 0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 6.0, bottom: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header Bar: Account Switcher + Eye Privacy Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Account Switcher Shortcut
              InkWell(
                onTap: () => _showAccountSwitchSheet(context, colors, account),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A854),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Acc: $account',
                        style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 14),
                    ],
                  ),
                ),
              ),

              // Eye Privacy Toggle
              IconButton(
                icon: Icon(
                  isHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: colors.textSecondary,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
                tooltip: isHidden ? 'Show Balances' : 'Hide Balances',
                onPressed: () {
                  ref.read(balancePrivacyProvider.notifier).state = !isHidden;
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 10-Metric Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (5 metrics)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRow('Balance:', balance, colors, onTap: () => context.go('/funds')),
                    const SizedBox(height: 3),
                    _buildRow('Floating PL:', floatingPl, colors, onTap: () => context.go('/deals')),
                    const SizedBox(height: 3),
                    _buildRow('Used Margin:', usedMargin, colors, onTap: () => context.go('/funds')),
                    const SizedBox(height: 3),
                    _buildRow('Assets Value:', assetsValue, colors),
                    const SizedBox(height: 3),
                    _buildRow('Total Values:', totalValues, colors, onTap: () => context.go('/funds')),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right Column (5 metrics)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRow('Free Margin:', freeMargin, colors, onTap: () => context.go('/funds')),
                    const SizedBox(height: 3),
                    _buildRow('Equity:', equity, colors, onTap: () => context.go('/funds')),
                    const SizedBox(height: 3),
                    _buildRow('Holding Margin:', hldgMargin, colors),
                    const SizedBox(height: 3),
                    _buildRow('Margin Level:', marginLevel, colors),
                    const SizedBox(height: 3),
                    _buildRow('Account:', account, colors),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, TradingColors colors, {VoidCallback? onTap}) {
    final rowContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall(
            color: colors.textPrimary,
            weight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelSmall(
            color: colors.marginValue,
            weight: FontWeight.w600,
            tabular: true,
          ),
        ),
      ],
    );

    if (onTap == null) return rowContent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: rowContent,
      ),
    );
  }

  void _showAccountSwitchSheet(BuildContext context, TradingColors colors, String account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trading Accounts',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Account 1 (Active)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      account.length >= 2 ? account.substring(0, 2).toUpperCase() : 'ZD',
                      style: GoogleFonts.inter(color: colors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                title: Text('$account • Primary Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                subtitle: Text('Individual Equity & F&O', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                trailing: const Icon(LucideIcons.checkCircle2, color: Color(0xFF00A854), size: 20),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),

              // Add Account
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link Account flow initialized.')),
                  );
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Link Another Client Account'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side: BorderSide(color: colors.divider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
