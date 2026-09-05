import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/enums.dart';

class BalanceBreakdownDialog extends ConsumerWidget {
  final Segment segment;

  const BalanceBreakdownDialog({super.key, required this.segment});

  static void show(BuildContext context, Segment segment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BalanceBreakdownDialog(segment: segment),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final breakdown = engine.getBalanceBreakdown(segment);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Balance Breakdown (${segment.name})',
                      style: GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Comprehensive view of your cash balance, collateral, and margin limits.',
                style: GoogleFonts.inter(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 16),

              // Highlight Card: Withdrawable Balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.14),
                      colors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available to Withdraw',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(breakdown.withdrawableBalance),
                          style: GoogleFonts.inter(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.account_balance_wallet_rounded, color: colors.primary, size: 36),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Itemized Breakdown Rows
              Text(
                'MARGIN COMPONENTS',
                style: GoogleFonts.inter(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              _buildBreakdownRow(
                'Opening Balance',
                CurrencyFormatter.format(breakdown.openingBalance),
                'Balance carried forward from previous trading day',
                colors,
              ),
              _buildBreakdownRow(
                'Settled Cash',
                CurrencyFormatter.format(breakdown.settledCash),
                'Deposits & settled funds available for trading & withdrawal',
                colors,
              ),
              _buildBreakdownRow(
                'Unsettled Credits (T+1)',
                CurrencyFormatter.format(breakdown.unsettledDeliveryCredits),
                '80% sale proceeds available today; 20% clears on T+1 settlement',
                colors,
              ),
              _buildBreakdownRow(
                'Collateral Margin',
                CurrencyFormatter.format(breakdown.collateralMargin),
                'Margin received against pledged Demat holdings',
                colors,
              ),
              _buildBreakdownRow(
                'Blocked for Orders / Positions',
                CurrencyFormatter.format(breakdown.blockedForOrders),
                'Margin utilized for active intraday positions and open orders',
                colors,
                isDeduction: true,
              ),

              const Divider(height: 24),

              // Total Trading Margin
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total Trading Margin Available',
                      style: GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(breakdown.totalTradingMargin),
                    style: GoogleFonts.inter(
                      color: colors.bullish,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Schedule & Security Policy Disclosures
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Processing & Cutoff Times',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Payout requests placed before 8:00 PM are processed same night.\n'
                      '• Requests placed after cutoff or on weekends process next business day.\n'
                      '• All deposits are instantly credited via IMPS/UPI.',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: colors.bullish),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Regulatory Trust & Transparency',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client funds are segregated in SEBI-registered client bank accounts. ZeroDalali charges ₹0.00 for deposits and withdrawals.',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    String title,
    String value,
    String description,
    TradingColors colors, {
    bool isDeduction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isDeduction ? '-' : ''}$value',
                style: GoogleFonts.inter(
                  color: isDeduction ? colors.bearish : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
