import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';

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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double amt) {
    final cur = double.tryParse(_amountController.text) ?? 0.0;
    _amountController.text = (cur + amt).toInt().toString();
    setState(() {});
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

              Text('Add Funds', style: AppTypography.h1(color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Instant transfer via UPI, Net Banking, or Debit Card (Zero Charges).',
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 20),

              // Amount Input
              Text('AMOUNT (₹)', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTypography.display(color: colors.textPrimary, weight: FontWeight.w700, tabular: true),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: colors.surface,
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

              // Payment Method
              Text('PAYMENT METHOD', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildPaymentOption(PaymentMethod.UPI, 'Google Pay / PhonePe / UPI ID', Icons.account_balance_wallet_outlined),
              _buildPaymentOption(PaymentMethod.NET_BANKING, 'Net Banking (HDFC, SBI, ICICI, etc.)', Icons.account_balance_outlined),
              _buildPaymentOption(PaymentMethod.CARD, 'Debit Card', Icons.credit_card_outlined),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(_amountController.text);
                  if (amt != null && amt > 0) {
                    await ref.read(orderSimulationEngineProvider).addFunds(amt, _method);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully added ${CurrencyFormatter.format(amt)} to Margin!'),
                          backgroundColor: const Color(0xFF00A854),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bullish,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('PROCEED TO PAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildPaymentOption(PaymentMethod method, String label, IconData icon) {
    final isSelected = _method == method;
    final colors = context.tradingColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? colors.primary : colors.divider,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _method,
        title: Text(label, style: AppTypography.body(weight: FontWeight.w600)),
        secondary: Icon(icon, color: isSelected ? colors.primary : colors.textSecondary),
        onChanged: (val) => setState(() => _method = val!),
      ),
    );
  }
}
