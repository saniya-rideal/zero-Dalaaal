import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_record.dart';
import '../../../shared_widgets/shared_widgets.dart';

class TransactionDetailSheet extends StatelessWidget {
  final TransactionRecord transaction;

  const TransactionDetailSheet({super.key, required this.transaction});

  static Future<void> show(BuildContext context, TransactionRecord transaction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailSheet(transaction: transaction),
    );
  }

  Color _getStatusColor(String status, TradingColors colors) {
    switch (status.toUpperCase()) {
      case 'COMPLETE':
      case 'SUCCESS':
      case 'COMPLETED':
        return colors.bullish;
      case 'PENDING':
      case 'INITIATED':
        return colors.warning;
      case 'FAILED':
      case 'REJECTED':
        return colors.bearish;
      case 'CANCELLED':
      default:
        return colors.textSecondary;
    }
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.TRADE:
        return LucideIcons.candlestickChart;
      case TransactionCategory.DEPOSIT:
        return LucideIcons.arrowDownLeft;
      case TransactionCategory.WITHDRAWAL:
        return LucideIcons.arrowUpRight;
      case TransactionCategory.FEE_CHARGE:
        return LucideIcons.receipt;
      case TransactionCategory.DIVIDEND:
        return LucideIcons.sparkles;
      case TransactionCategory.TRANSFER:
        return LucideIcons.arrowLeftRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final statusColor = _getStatusColor(transaction.status, colors);
    final categoryIcon = _getCategoryIcon(transaction.category);
    final isCredit = transaction.isCredit;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ZeroDragHandle(padding: EdgeInsets.zero),
              const SizedBox(height: 16),

              // Category & Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCredit ? colors.bullish : colors.primary)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcon,
                          color: isCredit ? colors.bullish : colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            transaction.category.name.replaceAll('_', ' '),
                            style: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      transaction.status,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Gross Amount Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: (isCredit ? colors.bullish : colors.bearish).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isCredit ? colors.bullish : colors.bearish).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCredit ? 'CREDITED TO CASH' : 'DEBITED FROM CASH',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                      style: GoogleFonts.inter(
                        color: isCredit ? colors.bullish : colors.bearish,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Key Item Details
              _buildDetailRow(
                'Transaction ID',
                transaction.id,
                colors,
                copyable: true,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: transaction.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied ${transaction.id} to clipboard!')),
                  );
                },
              ),

              if (transaction.orderId != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Order ID',
                  transaction.orderId!,
                  colors,
                  copyable: true,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: transaction.orderId!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied ${transaction.orderId} to clipboard!')),
                    );
                  },
                ),
              ],

              if (transaction.instrumentSymbol != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow('Instrument', transaction.instrumentSymbol!, colors),
              ],

              if (transaction.quantity != null && transaction.price != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow('Quantity', '${transaction.quantity} Shares / Lots', colors),
                const SizedBox(height: 10),
                _buildDetailRow('Executed Price', CurrencyFormatter.format(transaction.price!), colors),
              ],

              const SizedBox(height: 10),
              _buildDetailRow('Account / Segment', transaction.account, colors),

              const SizedBox(height: 10),
              _buildDetailRow(
                'Date & Time',
                DateFormatter.formatOrderDateTime(transaction.timestamp),
                colors,
              ),

              const SizedBox(height: 10),
              _buildDetailRow(
                'Running Cash Balance',
                CurrencyFormatter.format(transaction.runningBalance),
                colors,
              ),

              // Fee Breakdown if present
              if (transaction.feeBreakdown != null && transaction.feeBreakdown!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STATUTORY CHARGES & TAXES',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Total: ${CurrencyFormatter.format(transaction.totalFees)}',
                      style: GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.divider, width: 0.5),
                  ),
                  child: Column(
                    children: transaction.feeBreakdown!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.inter(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(entry.value),
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Narration
              Text(
                'Narration',
                style: GoogleFonts.inter(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.narration,
                style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 20),

              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    TradingColors colors, {
    bool copyable = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onCopy,
                child: Icon(LucideIcons.copy, size: 14, color: colors.primary),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
