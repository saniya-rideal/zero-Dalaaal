import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/socket_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/funds.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/real_funds_repository.dart';
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
  final _amountController = TextEditingController(text: '5000');
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;
  bool _isSubmitting = false;
  String? _errorText;
  StreamSubscription? _withdrawalSocketSub;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).session?.profile;
    _accountNumberController = TextEditingController(
      text: (profile != null && profile.bankAccountNumber.isNotEmpty)
          ? profile.bankAccountNumber.replaceAll(' ', '')
          : '',
    );
    _ifscController = TextEditingController();

    // Listen to real-time withdrawal updates from backend socket
    final socketService = ref.read(socketServiceProvider);
    _withdrawalSocketSub = socketService.withdrawalUpdatesStream.listen((_) {
      ref.invalidate(withdrawalsListProvider);
      ref.invalidate(fundsSummaryProvider);
    });
  }

  @override
  void dispose() {
    _withdrawalSocketSub?.cancel();
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
      setState(() => _errorText = 'Please enter bank IFSC code');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(fundsRepositoryProvider);
      final idempotencyKey = 'wth_${_uuid.v4()}';

      final txn = await repo.withdraw(
        amount: amt,
        accountNumber: _accountNumberController.text.trim(),
        ifsc: _ifscController.text.trim().toUpperCase(),
        method: 'BANK_TRANSFER',
        currency: 'INR',
        idempotencyKey: idempotencyKey,
      );

      ref.invalidate(fundsSummaryProvider);
      ref.invalidate(walletLedgerProvider);
      ref.invalidate(walletTransactionsListProvider);
      ref.invalidate(withdrawalsListProvider);

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
    final hasVerifiedBank = profile != null && profile.bankAccountNumber.isNotEmpty;

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
                'Withdrawal requests transfer settled cash balance directly to your verified bank account.',
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 16),

              // Available to withdraw banner
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
              Text('DESTINATION BANK ACCOUNT', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 8),

              if (hasVerifiedBank) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.landmark, size: 22, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile.bankName.isNotEmpty ? profile.bankName : 'Primary Bank Account',
                                  style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.bullish.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: colors.bullish.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'Verified',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: colors.bullish),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'A/C No: ${profile.bankAccountNumber}',
                              style: GoogleFonts.robotoMono(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Bank Account Number',
                    hintText: 'Enter your savings/current account number',
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
              ],

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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.arrowDownLeft, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Request Payout of ₹${_amountController.text}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Recent Withdrawals History Section
              _buildRecentWithdrawalsSection(colors),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWithdrawalsSection(TradingColors colors) {
    final withdrawalsAsync = ref.watch(withdrawalsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT WITHDRAWALS',
              style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600),
            ),
            IconButton(
              icon: Icon(LucideIcons.refreshCw, size: 14, color: colors.textSecondary),
              onPressed: () => ref.invalidate(withdrawalsListProvider),
              tooltip: 'Refresh Status',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        withdrawalsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    'No past withdrawal requests found.',
                    style: AppTypography.caption(color: colors.textSecondary),
                  ),
                ),
              );
            }

            final recentList = list.take(5).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final w = recentList[index];
                return _buildWithdrawalItemCard(w, colors);
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Unable to load withdrawals history.', style: AppTypography.caption(color: colors.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalItemCard(WalletTransaction w, TradingColors colors) {
    Color statusBg;
    Color statusFg;
    String statusLabel;

    switch (w.status) {
      case WalletTransactionStatus.PENDING:
      case WalletTransactionStatus.INITIATED:
        statusBg = colors.warning.withValues(alpha: 0.12);
        statusFg = colors.warning;
        statusLabel = 'Pending Review';
        break;
      case WalletTransactionStatus.APPROVED:
      case WalletTransactionStatus.PROCESSING:
        statusBg = colors.primary.withValues(alpha: 0.12);
        statusFg = colors.primary;
        statusLabel = 'Approved / In Transit';
        break;
      case WalletTransactionStatus.SUCCESS:
      case WalletTransactionStatus.COMPLETED:
        statusBg = colors.bullish.withValues(alpha: 0.12);
        statusFg = colors.bullish;
        statusLabel = 'Completed';
        break;
      case WalletTransactionStatus.FAILED:
      case WalletTransactionStatus.REJECTED:
        statusBg = colors.bearish.withValues(alpha: 0.12);
        statusFg = colors.bearish;
        statusLabel = 'Rejected';
        break;
      case WalletTransactionStatus.CANCELLED:
        statusBg = colors.textSecondary.withValues(alpha: 0.12);
        statusFg = colors.textSecondary;
        statusLabel = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(w.amount),
                style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormatter.formatDateTime(w.createdAt),
                style: GoogleFonts.robotoMono(fontSize: 10, color: colors.textSecondary),
              ),
              if (w.payoutUtr != null && w.payoutUtr!.isNotEmpty)
                Text(
                  'UTR: ${w.payoutUtr}',
                  style: GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.bold, color: colors.bullish),
                ),
            ],
          ),
          if (w.adminNote != null && w.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Note: ${w.adminNote}',
              style: AppTypography.caption(color: colors.bearish),
            ),
          ],
        ],
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
