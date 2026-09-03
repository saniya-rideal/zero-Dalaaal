import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/balance_privacy_service.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../core/utils/currency_formatter.dart';
import '../data/mock/order_simulation_engine.dart';
import '../data/models/enums.dart';

class ZeroBottomDock extends ConsumerWidget {
  final bool showRealValues;

  const ZeroBottomDock({super.key, this.showRealValues = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final funds = engine.getFundsSummary(Segment.EQUITY);
    final isHidden = ref.watch(balancePrivacyProvider);

    String fmt(double val) {
      if (isHidden) return '••••••';
      return showRealValues ? CurrencyFormatter.format(val, showSymbol: false) : '0.00';
    }

    final balance = fmt(funds.openingBalance);
    final floatingPl = isHidden ? '••••••' : '0.00';
    final usedMargin = fmt(funds.usedMargin);
    final assetsValue = isHidden ? '••••••' : '0.00';
    final totalValues = fmt(funds.availableMargin);

    final freeMargin = fmt(funds.availableMargin);
    final equity = fmt(funds.openingBalance - funds.usedMargin);
    final hldgMargin = isHidden ? '••••••' : '0.00';
    final marginLevel = isHidden ? '••••••' : (showRealValues ? '100.00%' : '100.00%');
    const account = '159537';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.dockBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar: Account Switcher + Eye Privacy Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Account Switcher Shortcut
              InkWell(
                onTap: () => _showAccountSwitchSheet(context, colors),
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
                        'Acc: 159537 (Primary)',
                        style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: colors.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),

              // Eye Privacy Toggle
              IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                    _buildRow('Balance:', balance, colors),
                    const SizedBox(height: 3),
                    _buildRow('Floating PL:', floatingPl, colors),
                    const SizedBox(height: 3),
                    _buildRow('Used Margin:', usedMargin, colors),
                    const SizedBox(height: 3),
                    _buildRow('Assets Value:', assetsValue, colors),
                    const SizedBox(height: 3),
                    _buildRow('Total Values:', totalValues, colors),
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
                    _buildRow('Free Margin:', freeMargin, colors),
                    const SizedBox(height: 3),
                    _buildRow('Equity:', equity, colors),
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

  Widget _buildRow(String label, String value, TradingColors colors) {
    return Row(
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
  }

  void _showAccountSwitchSheet(BuildContext context, TradingColors colors) {
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
                    'Switch Trading Account',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
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
                    child: Text('ZD', style: GoogleFonts.inter(color: colors.primary, fontWeight: FontWeight.w800)),
                  ),
                ),
                title: Text('159537 • Primary Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                subtitle: Text('Individual Equity & F&O', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF00A854)),
                onTap: () => Navigator.pop(ctx),
              ),
              const Divider(height: 12),

              // Account 2
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('H2', style: GoogleFonts.inter(color: colors.textSecondary, fontWeight: FontWeight.w800)),
                  ),
                ),
                title: Text('892014 • Hedge & MCX', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                subtitle: Text('Commodity Derivatives Account', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Switched to Account 892014')),
                    );
                  },
                  child: const Text('Switch'),
                ),
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
                icon: const Icon(Icons.add, size: 18),
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
