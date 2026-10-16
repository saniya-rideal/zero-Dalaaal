import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/funds.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/real_funds_repository.dart';
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
  late final TextEditingController _upiVpaController;
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
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).session?.profile;
    final userHandle = (profile != null && profile.email.isNotEmpty)
        ? profile.email.split('@').first
        : (profile?.phone ?? 'trader');
    _upiVpaController = TextEditingController(
      text: userHandle.isNotEmpty ? '$userHandle@okhdfcbank' : 'trader@upi',
    );
    if (profile != null && profile.bankName.isNotEmpty) {
      _selectedBank = profile.bankName;
    }
  }

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
      final repo = ref.read(fundsRepositoryProvider);
      final idempotencyKey = 'dep_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Contract Section 4.2: POST /api/wallet/deposit/create
      final pendingTxn = await repo.createDeposit(
        amount: amt,
        currency: 'INR',
        idempotencyKey: idempotencyKey,
      );

      // 2. Contract Section 4.3: POST /api/wallet/deposit/verify
      final verifiedTxn = await repo.verifyDeposit(
        depositId: pendingTxn.id,
      );

      ref.invalidate(fundsSummaryProvider);
      ref.invalidate(walletLedgerProvider);
      ref.invalidate(walletTransactionsListProvider);

      if (!mounted) return;
      Navigator.pop(context); // Close add funds sheet

      // 3. Show digital receipt dialog
      await TransactionReceiptDialog.show(context, verifiedTxn);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deposit Failed: $e'),
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

              Text('Add Funds', style: AppTypography.h1(color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Instant credit to your equity & F&O trading account balance.',
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 20),

              // Amount Input
              Text('ENTER AMOUNT', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() => _validateAmount()),
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
                'Net Banking (Verified Bank Account)',
                'Instant credit • Max ₹10 Lakh per txn • Zero Charges',
                LucideIcons.landmark,
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
                          final profile = ref.read(authControllerProvider).session?.profile;
                          final handle = (profile?.email != null && profile!.email.isNotEmpty)
                              ? profile.email.split('@').first
                              : 'trader';
                          setState(() {
                            _selectedUpiApp = app;
                            if (app == 'Google Pay') _upiVpaController.text = '$handle@okhdfcbank';
                            if (app == 'PhonePe') _upiVpaController.text = '$handle@ybl';
                            if (app == 'Paytm') _upiVpaController.text = '$handle@paytm';
                            if (app == 'BHIM UPI') _upiVpaController.text = '$handle@upi';
                            if (app == 'Custom VPA') _upiVpaController.text = '';
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
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _supportedBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Important Regulatory Notice
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
                    Icon(LucideIcons.shieldCheck, size: 18, color: colors.bullish),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deposits must originate strictly from your linked bank account. Third-party transfers are automatically rejected per SEBI regulations.',
                        style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action CTA
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleProceed,
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
                          const Icon(LucideIcons.arrowUpRight, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Deposit ${CurrencyFormatter.format(double.tryParse(_amountController.text) ?? 0.0)}',
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

  Widget _buildQuickChip(String label, double amt) {
    final colors = context.tradingColors;
    return ActionChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.divider, width: 0.5),
      onPressed: () => _addQuickAmount(amt),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, String title, String subtitle, IconData icon) {
    final colors = context.tradingColors;
    final isSelected = _method == method;

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
          leading: Icon(icon, color: isSelected ? colors.primary : colors.textSecondary),
          title: Text(title, style: AppTypography.body(weight: FontWeight.w600)),
          subtitle: Text(subtitle, style: AppTypography.caption(color: colors.textSecondary)),
          trailing: Radio<PaymentMethod>(
            value: method,
            groupValue: _method,
            onChanged: (val) {
              if (val != null) setState(() => _method = val);
            },
          ),
          onTap: () => setState(() => _method = method),
        ),
      ),
    );
  }
}
