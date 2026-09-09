import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/funds.dart';
import 'payment_gateway_dialog.dart';
import 'transaction_receipt_dialog.dart';
import '../../../shared_widgets/shared_widgets.dart';

class AddFundsSheet extends ConsumerStatefulWidget {
  const AddFundsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFundsSheet(),
    );
  }

  @override
  ConsumerState<AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends ConsumerState<AddFundsSheet> {
  final _amountController = TextEditingController(text: '10000');
  PaymentMethod _method = PaymentMethod.UPI;
  String _selectedUpiApp = 'Google Pay';
  final _upiVpaController = TextEditingController(text: 'anurag@okhdfcbank');
  String _selectedBank = 'HDFC Bank Ltd';
  bool _isSubmitting = false;
  String? _errorText;

  final List<String> _upiApps = ['Google Pay', 'PhonePe', 'Paytm', 'BHIM UPI', 'Custom VPA'];
  final List<String> _supportedBanks = [
    'HDFC Bank Ltd',
    'ICICI Bank Ltd',
    'State Bank of India',
    'Axis Bank Ltd',
    'Kotak Mahindra Bank',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _upiVpaController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double amt) {
    final cur = double.tryParse(_amountController.text) ?? 0.0;
    _amountController.text = (cur + amt).toInt().toString();
    _validateAmount();
    setState(() {});
  }

  void _validateAmount() {
    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt < 100.0) {
      _errorText = 'Minimum deposit amount is ₹100';
    } else if (_method == PaymentMethod.UPI && amt > 200000.0) {
      _errorText = 'UPI limit is ₹2,00,000 per transaction (NPCI)';
    } else if (amt > 1000000.0) {
      _errorText = 'Maximum deposit limit is ₹10,00,000 per transaction';
    } else {
      _errorText = null;
    }
  }

  Future<void> _handleProceed() async {
    if (_isSubmitting) return;
    _validateAmount();
    if (_errorText != null) {
      setState(() {});
      return;
    }

    final amt = double.tryParse(_amountController.text);
    if (amt == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Open Simulated Gateway Dialog
      final outcome = await PaymentGatewayDialog.show(
        context,
        amount: amt,
        method: _method,
        upiId: _method == PaymentMethod.UPI ? _upiVpaController.text : null,
        bankName: _method == PaymentMethod.NET_BANKING ? _selectedBank : null,
      );

      if (!mounted) return;

      if (outcome == null || outcome == WalletTransactionStatus.CANCELLED) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit cancelled by user.')),
        );
        return;
      }

      // 2. Initiate deposit in engine with simulated outcome
      final engine = ref.read(orderSimulationEngineProvider);
      final txn = await engine.initiateDeposit(
        amount: amt,
        method: _method,
        upiId: _method == PaymentMethod.UPI ? _upiVpaController.text : null,
        bankName: _method == PaymentMethod.NET_BANKING ? _selectedBank : null,
        outcome: outcome,
        failureReason: outcome == WalletTransactionStatus.FAILED
            ? 'Payment declined by issuing bank or server timed out'
            : null,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close add funds sheet

      // 3. Show digital receipt dialog
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

              // Title & Currency Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Funds', style: AppTypography.h1(color: colors.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.bullish.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.bullish.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'INR (₹) Only',
                      style: GoogleFonts.inter(
                        color: colors.bullish,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Instant zero-fee transfer via UPI, Net Banking, or Debit Card.',
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 20),

              // Amount Input
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'DEPOSIT AMOUNT (₹)',
                    style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600),
                  ),
                  Text(
                    _method == PaymentMethod.UPI ? 'Min ₹100 • Max ₹2,00,000' : 'Min ₹100 • Max ₹10,00,000',
                    style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(_validateAmount),
                style: AppTypography.display(color: colors.textPrimary, weight: FontWeight.w700, tabular: true),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: colors.surface,
                  errorText: _errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Amount Chips
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickChip('+ ₹5,000', 5000),
                  _buildQuickChip('+ ₹10,000', 10000),
                  _buildQuickChip('+ ₹25,000', 25000),
                  _buildQuickChip('+ ₹50,000', 50000),
                ],
              ),

              const SizedBox(height: 20),

              // Payment Method Selector
              Text('PAYMENT METHOD', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildPaymentOption(
                PaymentMethod.UPI,
                'UPI Instant (Google Pay, PhonePe, UPI ID)',
                'Instant credit • Max ₹2 Lakh per txn • Zero Charges',
                LucideIcons.wallet,
              ),
              _buildPaymentOption(
                PaymentMethod.NET_BANKING,
                'Net Banking (40+ Supported Banks)',
                'Instant credit • Max ₹10 Lakh per txn • Zero Charges',
                LucideIcons.landmark,
              ),
              _buildPaymentOption(
                PaymentMethod.CARD,
                'Payment Gateway / Debit Card',
                'Instant transfer via Visa / Mastercard / RuPay',
                LucideIcons.creditCard,
              ),

              const SizedBox(height: 16),

              // Sub-selector for selected payment method
              if (_method == PaymentMethod.UPI) ...[
                Text(
                  'SELECT UPI APPLICATION OR VPA',
                  style: GoogleFonts.inter(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _upiApps.map((app) {
                    final isAppSelected = _selectedUpiApp == app;
                    return ChoiceChip(
                      label: Text(app),
                      selected: isAppSelected,
                      selectedColor: colors.primary.withValues(alpha: 0.15),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedUpiApp = app;
                            if (app == 'Google Pay') _upiVpaController.text = 'anurag@okhdfcbank';
                            if (app == 'PhonePe') _upiVpaController.text = 'anurag@ybl';
                            if (app == 'Paytm') _upiVpaController.text = 'anurag@paytm';
                            if (app == 'BHIM UPI') _upiVpaController.text = 'anurag@upi';
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _upiVpaController,
                  decoration: InputDecoration(
                    labelText: 'UPI ID / VPA',
                    hintText: 'e.g. yourname@bank',
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ] else if (_method == PaymentMethod.NET_BANKING) ...[
                Text(
                  'SELECT VERIFIED BANK',
                  style: GoogleFonts.inter(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _supportedBanks.map((bank) {
                    final isBankSelected = _selectedBank == bank;
                    return ChoiceChip(
                      label: Text(bank),
                      selected: isBankSelected,
                      selectedColor: colors.primary.withValues(alpha: 0.15),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedBank = bank);
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // Trust & Security Notice
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.lock, size: 16, color: colors.bullish),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Secured with 256-bit encryption. Funds deposited will be credited instantly to your trading margin.',
                        style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Submit Button with Duplicate Submission Protection
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bullish,
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
                    : const Text(
                        'PROCEED TO PAY',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double amt) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _addQuickAmount(amt),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, String label, String subtitle, IconData icon) {
    final isSelected = _method == method;
    final colors = context.tradingColors;
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
        clipBehavior: Clip.antiAlias,
        child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _method,
        title: Text(label, style: AppTypography.body(weight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11)),
        secondary: Icon(icon, color: isSelected ? colors.primary : colors.textSecondary),
        onChanged: (val) {
          setState(() {
            _method = val!;
            _validateAmount();
          });
        },
      ),
    ),
  );
}
}
