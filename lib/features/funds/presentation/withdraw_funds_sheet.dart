import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/enums.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/real_funds_repository.dart';
import 'balance_breakdown_dialog.dart';
import 'transaction_receipt_dialog.dart';
import '../../../shared_widgets/shared_widgets.dart';

class WithdrawFundsSheet extends ConsumerStatefulWidget {
  const WithdrawFundsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WithdrawFundsSheet(),
    );
  }

  @override
  ConsumerState<WithdrawFundsSheet> createState() => _WithdrawFundsSheetState();
}

class _WithdrawFundsSheetState extends ConsumerState<WithdrawFundsSheet> {
  final _amountController = TextEditingController(text: '10000');
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).session?.profile;
    _accountNumberController = TextEditingController(
      text: profile?.bankAccountNumber.isNotEmpty == true
          ? profile!.bankAccountNumber.replaceAll(' ', '')
          : '987654321012',
    );
    _ifscController = TextEditingController(text: 'HDFC0001234');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _validateAmount(double available) {
    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt < 100.0) {
      _errorText = 'Minimum withdrawal amount is ₹100';
    } else if (amt > available) {
      _errorText = 'Amount exceeds available withdrawable balance of ${CurrencyFormatter.format(available)}';
    } else {
      _errorText = null;
    }
  }

  void _applyPercentage(double pct, double available) {
    final amt = (available * pct).clamp(0.0, available);
    _amountController.text = amt.toInt().toString();
    _validateAmount(available);
    setState(() {});
  }

  Future<void> _handleConfirmWithdrawal(double available) async {
    if (_isSubmitting) return;
    _validateAmount(available);
    if (_errorText != null) {
      setState(() {});
      return;
    }

    final amt = double.tryParse(_amountController.text);
    if (amt == null) return;

    if (_accountNumberController.text.trim().isEmpty) {
      setState(() => _errorText = 'Please enter bank account number');
      return;
    }
    if (_ifscController.text.trim().isEmpty) {
      setState(() => _errorText = 'Please enter IFSC code');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(fundsRepositoryProvider);
      final idempotencyKey = 'wth_${DateTime.now().millisecondsSinceEpoch}';

      // Contract Section 4.4: POST /api/wallet/withdraw
      final txn = await repo.withdraw(
        amount: amt,
        accountNumber: _accountNumberController.text.trim(),
        ifsc: _ifscController.text.trim(),
        method: 'BANK_TRANSFER',
        currency: 'INR',
        idempotencyKey: idempotencyKey,
      );

      ref.invalidate(fundsSummaryProvider);
      ref.invalidate(walletLedgerProvider);
      ref.invalidate(walletTransactionsListProvider);

      if (!mounted) return;
      Navigator.pop(context); // Close sheet

      // Show receipt dialog
      await TransactionReceiptDialog.show(context, txn);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal Failed: $e'),
            backgroundColor: context.tradingColors.bearish,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final fundsAsync = ref.watch(fundsSummaryProvider);
    final available = fundsAsync.valueOrNull?.withdrawable ?? 0.0;
    final profile = ref.watch(authControllerProvider).session?.profile;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZeroDragHandle(padding: EdgeInsets.zero),
              const SizedBox(height: 16),

              Text('Withdraw Funds', style: AppTypography.h1(color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Transfer settled cash directly to your verified bank account.',
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 16),

              // Available to withdraw banner with explainer button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available to withdraw', style: AppTypography.caption(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(available),
                            style: AppTypography.h2(color: colors.textPrimary, tabular: true),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => BalanceBreakdownDialog.show(context, Segment.EQUITY),
                      icon: Icon(LucideIcons.info, size: 14, color: colors.primary),
                      label: Text(
                        'Breakdown',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Amount Input
              Text('WITHDRAWAL AMOUNT', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() => _validateAmount(available)),
                style: AppTypography.display(color: colors.textPrimary, weight: FontWeight.w700, tabular: true),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: colors.surface,
                  errorText: _errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 10),

              // Quick percentage chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPctChip('25%', 0.25, available),
                  _buildPctChip('50%', 0.50, available),
                  _buildPctChip('75%', 0.75, available),
                  _buildPctChip('100% (All)', 1.00, available),
                ],
              ),

              const SizedBox(height: 20),

              // Destination Bank Details
              Text('BANK ACCOUNT DETAILS', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 8),

              TextField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Enter bank account number',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'IFSC Code',
                  hintText: 'e.g. HDFC0001234',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              if (profile?.bankName.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  'Linked Bank: ${profile!.bankName}',
                  style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary),
                ),
              ],

              const SizedBox(height: 20),

              // Information Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.clock, size: 18, color: colors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Withdrawal requests reserve your cash balance immediately and are reviewed and disbursed via NEFT/RTGS during banking hours.',
                        style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action CTA
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _handleConfirmWithdrawal(available),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.arrowDownLeft, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Request Withdrawal',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPctChip(String label, double pct, double available) {
    final colors = context.tradingColors;
    return ActionChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.divider, width: 0.5),
      onPressed: () => _applyPercentage(pct, available),
    );
  }
}
