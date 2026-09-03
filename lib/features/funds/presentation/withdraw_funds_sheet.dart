import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';

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
  final _amountController = TextEditingController(text: '5000');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final summary = engine.getFundsSummary(Segment.EQUITY);

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
                'Funds will be credited to your verified primary bank account within 24 hours.',
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Available to withdraw', style: AppTypography.caption(color: colors.textSecondary)),
                    Text(
                      CurrencyFormatter.format(summary.availableMargin),
                      style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700, tabular: true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Amount Input
              Text('WITHDRAW AMOUNT (₹)', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
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

              const SizedBox(height: 20),

              // Linked Bank Account
              Text('DESTINATION BANK ACCOUNT', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HDFC Bank Ltd', style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600)),
                        Text('A/C: •••• •••• 4912 (Primary)', style: AppTypography.caption(color: colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(_amountController.text);
                  if (amt != null && amt > 0) {
                    try {
                      await ref.read(orderSimulationEngineProvider).withdrawFunds(amt, 'HDFC •••• 4912');
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payout request of ${CurrencyFormatter.format(amt)} placed successfully!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e'), backgroundColor: colors.bearish),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('CONFIRM WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
