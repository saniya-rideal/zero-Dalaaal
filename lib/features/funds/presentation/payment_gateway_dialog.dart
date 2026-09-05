import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/funds.dart';

class PaymentGatewayDialog extends StatefulWidget {
  final double amount;
  final PaymentMethod method;
  final String? upiId;
  final String? bankName;

  const PaymentGatewayDialog({
    super.key,
    required this.amount,
    required this.method,
    this.upiId,
    this.bankName,
  });

  static Future<WalletTransactionStatus?> show(
    BuildContext context, {
    required double amount,
    required PaymentMethod method,
    String? upiId,
    String? bankName,
  }) {
    return showDialog<WalletTransactionStatus>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentGatewayDialog(
        amount: amount,
        method: method,
        upiId: upiId,
        bankName: bankName,
      ),
    );
  }

  @override
  State<PaymentGatewayDialog> createState() => _PaymentGatewayDialogState();
}

class _PaymentGatewayDialogState extends State<PaymentGatewayDialog> {
  bool _isProcessing = false;
  String _processingMessage = 'Connecting to Bank Gateway...';

  Future<void> _simulateOutcome(WalletTransactionStatus outcome, [String? msg]) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = msg ?? 'Contacting payment processor...';
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      Navigator.of(context).pop(outcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final methodName = widget.method == PaymentMethod.UPI
        ? 'UPI Instant Payment'
        : widget.method == PaymentMethod.NET_BANKING
            ? 'Net Banking Portal'
            : 'Debit Card Gateway';

    final detail = widget.method == PaymentMethod.UPI
        ? (widget.upiId ?? 'UPI VPA')
        : (widget.bankName ?? 'HDFC Bank Ltd');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colors.cardBackground,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(22),
        child: _isProcessing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 20),
                  Text(
                    _processingMessage,
                    style: GoogleFonts.inter(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Do not press back or refresh this screen',
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gateway Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.security_rounded, color: colors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Payment Gateway',
                                style: GoogleFonts.inter(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '256-bit SSL Encrypted • NPCI Certified',
                                style: GoogleFonts.inter(
                                  color: colors.textSecondary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                        onPressed: () => _simulateOutcome(WalletTransactionStatus.CANCELLED, 'Cancelling transaction...'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Merchant Details
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
                        Text(
                          'PAY TO MERCHANT',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ZeroDalali Broking Ltd',
                          style: GoogleFonts.inter(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'SEBI Regn: INZ000031633 • Client Trust A/C',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Amount & Method Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              methodName,
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              detail,
                              style: GoogleFonts.inter(
                                color: colors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(widget.amount),
                          style: GoogleFonts.inter(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Simulation Outcome Buttons
                  Text(
                    'SIMULATE PAYMENT OUTCOME',
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Success Button
                  ElevatedButton.icon(
                    onPressed: () => _simulateOutcome(WalletTransactionStatus.SUCCESS, 'Authorizing & Crediting Margin...'),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Simulate Successful Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.bullish,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Pending Button
                  OutlinedButton.icon(
                    onPressed: () => _simulateOutcome(WalletTransactionStatus.PENDING, 'Marking Payment as Pending...'),
                    icon: Icon(Icons.hourglass_top_rounded, size: 18, color: colors.warning),
                    label: Text(
                      'Simulate Pending / Delayed Response',
                      style: TextStyle(color: colors.warning),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.warning.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Failed Button
                  OutlinedButton.icon(
                    onPressed: () => _simulateOutcome(WalletTransactionStatus.FAILED, 'Processing Bank Decline...'),
                    icon: Icon(Icons.cancel_rounded, size: 18, color: colors.bearish),
                    label: Text(
                      'Simulate Bank Decline / Failure',
                      style: TextStyle(color: colors.bearish),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.bearish.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Footer Security Note
                  Center(
                    child: Text(
                      'Funds are held securely in RBI/SEBI compliant escrow.',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
