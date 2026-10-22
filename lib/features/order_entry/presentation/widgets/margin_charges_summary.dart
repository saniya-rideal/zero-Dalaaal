import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/order_entry_controller.dart';

class MarginChargesSummary extends StatefulWidget {
  final OrderEntryState state;

  const MarginChargesSummary({
    super.key,
    required this.state,
  });

  @override
  State<MarginChargesSummary> createState() => _MarginChargesSummaryState();
}

class _MarginChargesSummaryState extends State<MarginChargesSummary> {
  bool _expandedCharges = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final preview = widget.state.preview;
    final isLoading = widget.state.isPreviewLoading;

    final colors = context.tradingColors;
    final reqMargin = preview?.requiredMargin ?? 0.0;
    final availMargin = preview?.availableMargin ?? 0.0;
    final afterTrade = preview?.marginAfterTrade ?? (availMargin - reqMargin);
    final totalCharges = preview?.charges.total ?? 0.0;
    final canPlace = preview?.canPlace ?? true;
    final blockingReason = preview?.blockingReason;
    final warnings = preview?.warnings ?? const [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF282D37) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Margin & Regulatory Preview',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedCharges = !_expandedCharges;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Charges: ${CurrencyFormatter.formatInr(totalCharges)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expandedCharges ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 14,
                      color: colors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Key Margin Indicators
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Required',
                  CurrencyFormatter.formatInr(reqMargin),
                  isDark,
                  valueColor: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  'Available',
                  CurrencyFormatter.formatInr(availMargin),
                  isDark,
                  valueColor: availMargin >= reqMargin ? colors.bullish : colors.bearish,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  'Margin After',
                  CurrencyFormatter.formatInr(afterTrade),
                  isDark,
                  valueColor: afterTrade >= 0 ? (isDark ? Colors.white70 : Colors.black54) : colors.bearish,
                ),
              ),
            ],
          ),

          // Expanded Charges Breakdown
          if (_expandedCharges && preview != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  _buildChargeLine('Brokerage', preview.charges.brokerage, isDark),
                  _buildChargeLine('Securities Transaction Tax (STT)', preview.charges.stt, isDark),
                  _buildChargeLine('Exchange Turnover Charge', preview.charges.exchangeTxnCharge, isDark),
                  _buildChargeLine('GST (18%)', preview.charges.gst, isDark),
                  _buildChargeLine('SEBI Turnover Fees', preview.charges.sebiCharges, isDark),
                  _buildChargeLine('Stamp Duty', preview.charges.stampDuty, isDark),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Estimated Charges',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatInr(totalCharges),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Warnings from backend preview
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 13, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          w,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Blocking Reason Banner
          if (!canPlace && blockingReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bearish.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.bearish.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.ban, size: 14, color: colors.bearish),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blockingReason,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.bearish,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChargeLine(String label, double amount, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
          ),
          Text(
            CurrencyFormatter.formatInr(amount),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
