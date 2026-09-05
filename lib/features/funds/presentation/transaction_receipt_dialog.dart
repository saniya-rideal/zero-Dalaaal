import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/funds.dart';

class TransactionReceiptDialog extends ConsumerWidget {
  final WalletTransaction transaction;

  const TransactionReceiptDialog({super.key, required this.transaction});

  static Future<void> show(BuildContext context, WalletTransaction transaction) {
    return showDialog<void>(
      context: context,
      builder: (_) => TransactionReceiptDialog(transaction: transaction),
    );
  }

  Color _getStatusColor(WalletTransactionStatus status, TradingColors colors) {
    switch (status) {
      case WalletTransactionStatus.SUCCESS:
      case WalletTransactionStatus.COMPLETED:
        return colors.bullish;
      case WalletTransactionStatus.PENDING:
      case WalletTransactionStatus.INITIATED:
        return colors.warning;
      case WalletTransactionStatus.PROCESSING:
        return colors.primary;
      case WalletTransactionStatus.FAILED:
      case WalletTransactionStatus.REJECTED:
        return colors.bearish;
      case WalletTransactionStatus.CANCELLED:
        return colors.textSecondary;
    }
  }

  IconData _getStatusIcon(WalletTransactionStatus status) {
    switch (status) {
      case WalletTransactionStatus.SUCCESS:
      case WalletTransactionStatus.COMPLETED:
        return Icons.check_circle_rounded;
      case WalletTransactionStatus.PENDING:
      case WalletTransactionStatus.INITIATED:
        return Icons.hourglass_top_rounded;
      case WalletTransactionStatus.PROCESSING:
        return Icons.sync_rounded;
      case WalletTransactionStatus.FAILED:
      case WalletTransactionStatus.REJECTED:
        return Icons.cancel_rounded;
      case WalletTransactionStatus.CANCELLED:
        return Icons.do_not_disturb_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final statusColor = _getStatusColor(transaction.status, colors);
    final statusIcon = _getStatusIcon(transaction.status);
    final isDeposit = transaction.isDeposit;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colors.cardBackground,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 36),
              ),
            ),
            const SizedBox(height: 12),

            // Status Badge & Title
            Center(
              child: Text(
                isDeposit ? 'Deposit Transaction' : 'Withdrawal Request',
                style: GoogleFonts.inter(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  transaction.status.name,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Big Amount
            Center(
              child: Text(
                '${isDeposit ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Key Value Details
            _buildDetailRow(
              'Reference ID',
              transaction.referenceId,
              colors,
              copyable: true,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: transaction.referenceId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied ${transaction.referenceId} to clipboard!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildDetailRow(
              'Payment Method',
              transaction.method.name.replaceAll('_', ' '),
              colors,
            ),
            const SizedBox(height: 10),

            if (transaction.upiId != null) ...[
              _buildDetailRow('UPI VPA', transaction.upiId!, colors),
              const SizedBox(height: 10),
            ],

            if (transaction.bankAccount != null) ...[
              _buildDetailRow('Destination Bank', transaction.bankAccount!, colors),
              const SizedBox(height: 10),
            ],

            _buildDetailRow(
              'Initiated On',
              DateFormatter.formatOrderDate(transaction.createdAt),
              colors,
            ),
            const SizedBox(height: 10),

            if (transaction.failureReason != null) ...[
              _buildDetailRow('Reason', transaction.failureReason!, colors, isError: true),
              const SizedBox(height: 10),
            ],

            _buildDetailRow(
              'Charges / Fee',
              '₹0.00 (Zero Fee)',
              colors,
            ),

            const SizedBox(height: 20),

            // Pending Withdrawal Cancel Button
            if (transaction.isWithdrawal && transaction.status == WalletTransactionStatus.PENDING) ...[
              OutlinedButton.icon(
                onPressed: () async {
                  final engine = ref.read(orderSimulationEngineProvider);
                  try {
                    await engine.cancelWithdrawal(transaction.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Withdrawal ${transaction.referenceId} cancelled. Margin restored!'),
                          backgroundColor: colors.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: colors.bearish),
                      );
                    }
                  }
                },
                icon: Icon(Icons.cancel_outlined, size: 18, color: colors.bearish),
                label: Text(
                  'Cancel Withdrawal Request',
                  style: GoogleFonts.inter(
                    color: colors.bearish,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.bearish),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
            ],

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
              child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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
    bool isError = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: isError ? colors.bearish : colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onCopy,
                  child: Icon(Icons.copy_rounded, size: 14, color: colors.primary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
