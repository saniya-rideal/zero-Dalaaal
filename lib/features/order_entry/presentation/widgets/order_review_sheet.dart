import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/order.dart';
import '../controllers/order_entry_controller.dart';

class OrderReviewSheet extends StatelessWidget {
  final OrderEntryState state;
  final TransactionType side;
  final double executionPrice;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const OrderReviewSheet({
    super.key,
    required this.state,
    required this.side,
    required this.executionPrice,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;
    final isBuy = side == TransactionType.BUY;
    final sideColor = isBuy ? colors.bullish : colors.bearish;

    final placedOrder = state.placedOrder;
    final isSuccess = placedOrder != null;
    final isSubmitting = state.isSubmitting;
    final error = state.submissionError;

    final preview = state.preview;
    final reqMargin = preview?.requiredMargin ?? 0.0;
    final charges = preview?.charges.total ?? 0.0;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 12
            : 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: isSuccess
          ? _buildSuccessView(context, placedOrder, isDark)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confirm Order',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sideColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${side.name} ${state.instrument.symbol}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sideColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Parameters Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildReviewRow('Execution Type', state.effectiveOrderKind.name, isDark),
                      const SizedBox(height: 8),
                      _buildReviewRow('Product', state.product.name, isDark),
                      const SizedBox(height: 8),
                      _buildReviewRow('Quantity', '${state.quantity} (${state.lots} lots)', isDark),
                      const SizedBox(height: 8),
                      _buildReviewRow(
                        'Price',
                        executionPrice > 0 ? CurrencyFormatter.formatInr(executionPrice) : 'MARKET',
                        isDark,
                      ),
                      if (state.triggerPrice > 0) ...[
                        const SizedBox(height: 8),
                        _buildReviewRow(
                          'Trigger Price',
                          CurrencyFormatter.formatInr(state.triggerPrice),
                          isDark,
                        ),
                      ],
                      if (state.slPrice > 0) ...[
                        const SizedBox(height: 8),
                        _buildReviewRow('Stop Loss', CurrencyFormatter.formatInr(state.slPrice), isDark),
                      ],
                      if (state.tpPrice > 0) ...[
                        const SizedBox(height: 8),
                        _buildReviewRow('Take Profit', CurrencyFormatter.formatInr(state.tpPrice), isDark),
                      ],
                      const SizedBox(height: 8),
                      _buildReviewRow('Validity', state.validity.name, isDark),
                      const Divider(height: 16),
                      _buildReviewRow('Estimated Margin', CurrencyFormatter.formatInr(reqMargin), isDark),
                      const SizedBox(height: 8),
                      _buildReviewRow('Estimated Charges', CurrencyFormatter.formatInr(charges), isDark),
                    ],
                  ),
                ),

                // Error Message Display
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.bearish.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.bearish.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertCircle, size: 16, color: colors.bearish),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.bearish,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting ? null : onCancel,
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sideColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting ? null : onConfirm,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Confirm ${side.name}',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSuccessView(BuildContext context, Order order, bool isDark) {
    final colors = context.tradingColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Center(
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF00A854),
            child: Icon(LucideIcons.check, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Order Placed Successfully!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Order ID: ${order.id}',
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // dismiss review sheet
            Navigator.of(context).maybePop(); // dismiss order sheet
            context.push('/orders/${order.id}');
          },
          child: Text(
            'View in Orders',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
