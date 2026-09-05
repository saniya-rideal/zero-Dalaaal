import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/enums.dart';
import 'balance_breakdown_dialog.dart';
import 'transaction_receipt_dialog.dart';

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
  final _otpController = TextEditingController(text: '1234');
  String _selectedDestinationType = 'BANK'; // 'BANK' or 'UPI'
  String _selectedBankId = 'bank_hdfc_01';
  final String _selectedUpiId = 'anurag@okhdfcbank';
  bool _showOtpStep = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _otpController.dispose();
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
    _validateAmount(available);
    if (_errorText != null) {
      setState(() {});
      return;
    }

    // Step 1: Open OTP 2FA confirmation if not already shown
    if (!_showOtpStep) {
      setState(() => _showOtpStep = true);
      return;
    }

    final amt = double.tryParse(_amountController.text);
    if (amt == null) return;

    setState(() => _isSubmitting = true);

    try {
      final engine = ref.read(orderSimulationEngineProvider);
      final isUpi = _selectedDestinationType == 'UPI';
      final destination = isUpi
          ? _selectedUpiId
          : (_selectedBankId == 'bank_hdfc_01'
              ? 'HDFC Bank Ltd (•••• 4912)'
              : 'ICICI Bank Ltd (•••• 8841)');

      final txn = await engine.requestWithdrawal(
        amount: amt,
        destination: destination,
        isUpi: isUpi,
        otp: _otpController.text,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close sheet

      // Show receipt dialog
      await TransactionReceiptDialog.show(context, txn);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.tradingColors.bearish,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final breakdown = engine.getBalanceBreakdown(Segment.EQUITY);
    final available = breakdown.withdrawableBalance;
    final bankAccounts = engine.linkedBankAccounts;

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

              Text('Withdraw Funds', style: AppTypography.h1(color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Transfer settled cash directly to your verified bank account or UPI.',
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
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Available to withdraw', style: AppTypography.caption(color: colors.textSecondary)),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => BalanceBreakdownDialog.show(context, Segment.EQUITY),
                              child: Icon(Icons.info_outline_rounded, size: 14, color: colors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(available),
                          style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w800, tabular: true),
                        ),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onPressed: () => BalanceBreakdownDialog.show(context, Segment.EQUITY),
                      child: Text(
                        'View Breakdown',
                        style: GoogleFonts.inter(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Amount Input
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text('WITHDRAWAL AMOUNT', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
                  Text(
                    'Min: ₹100 • Max: ${CurrencyFormatter.format(available)}',
                    style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
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

              // Destination Selector
              Text('PAYOUT DESTINATION', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 8),

              // Bank Accounts
              ...bankAccounts.map((bank) {
                final isSelected = _selectedDestinationType == 'BANK' && _selectedBankId == bank.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? colors.primary.withValues(alpha: 0.08) : colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? colors.primary : colors.divider,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.account_balance, size: 24),
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(bank.bankName, style: AppTypography.body(weight: FontWeight.w600)),
                          if (bank.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.bullish.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Primary',
                                style: TextStyle(color: colors.bullish, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text('${bank.accountNumberMasked} • ${bank.ifsc}', style: AppTypography.caption(color: colors.textSecondary)),
                          if (bank.isVerified)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: colors.bullish, size: 12),
                                const SizedBox(width: 2),
                                Text('Verified', style: TextStyle(color: colors.bullish, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                        ],
                      ),
                      trailing: Radio<String>(
                        value: bank.id,
                        groupValue: _selectedDestinationType == 'BANK' ? _selectedBankId : null,
                        onChanged: (val) {
                          setState(() {
                            _selectedDestinationType = 'BANK';
                            _selectedBankId = val!;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedDestinationType = 'BANK';
                          _selectedBankId = bank.id;
                        });
                      },
                    ),
                  ),
                );
              }),

              // Instant UPI Destination
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _selectedDestinationType == 'UPI' ? colors.primary.withValues(alpha: 0.08) : colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _selectedDestinationType == 'UPI' ? colors.primary : colors.divider,
                      width: _selectedDestinationType == 'UPI' ? 1.5 : 0.5,
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined, size: 24),
                    title: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text('Verified UPI ID', style: AppTypography.body(weight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Instant Payout',
                            style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(_selectedUpiId, style: AppTypography.caption(color: colors.textSecondary)),
                    trailing: Radio<String>(
                      value: 'UPI',
                      groupValue: _selectedDestinationType,
                      onChanged: (val) => setState(() => _selectedDestinationType = val!),
                    ),
                    onTap: () => setState(() => _selectedDestinationType = 'UPI'),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // OTP 2FA Step
              if (_showOtpStep) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_rounded, color: colors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Enter 2FA Security OTP',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sent via SMS to registered mobile ••••••9124 (Demo OTP: 1234)',
                        style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '1234',
                          counterText: '',
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Schedule & Cutoff Disclosures
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cutoff time: 8:00 PM on trading days. Requests are pending until cutoff and can be cancelled anytime with instant margin restoration.',
                        style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Withdrawal Button
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _showOtpStep ? 'SUBMIT WITHDRAWAL' : 'VERIFY & PROCEED',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPctChip(String label, double pct, double available) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: () => _applyPercentage(pct, available),
    );
  }
}
