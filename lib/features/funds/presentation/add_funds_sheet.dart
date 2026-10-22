import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/socket_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/funds.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../data/real_funds_repository.dart';
import 'transaction_receipt_dialog.dart';

enum _DepositStep {
  amountInput,
  paymentOrderActive,
  simulatedDebug,
}

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
  _DepositStep _currentStep = _DepositStep.amountInput;

  PaymentOrder? _activeOrder;
  bool _isCreatingOrder = false;
  bool _isCheckingStatus = false;
  bool _isCancelling = false;
  String? _errorText;
  String? _statusBannerMessage;

  // Countdown timer for 15-minute order window
  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15 minutes = 900s

  // Status polling timer (fallback alongside socket)
  Timer? _pollingTimer;
  StreamSubscription? _socketPaymentSub;

  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _validateAmount();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _socketPaymentSub?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _validateAmount() {
    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt < 100.0) {
      _errorText = 'Minimum deposit amount is ₹100';
    } else if (amt > 200000.0) {
      _errorText = 'UPI standard limit is ₹2,00,000 per transaction';
    } else if (amt > 1000000.0) {
      _errorText = 'Maximum deposit limit is ₹10,00,000 per transaction';
    } else {
      _errorText = null;
    }
  }

  void _addQuickAmount(double amt) {
    final cur = double.tryParse(_amountController.text) ?? 0.0;
    _amountController.text = (cur + amt).toInt().toString();
    _validateAmount();
    setState(() {});
  }

  /// 1. Create real UPI Payment Order
  Future<void> _handleCreatePaymentOrder() async {
    if (_isCreatingOrder) return;
    _validateAmount();
    if (_errorText != null) {
      setState(() {});
      return;
    }

    final amt = double.tryParse(_amountController.text);
    if (amt == null) return;

    setState(() {
      _isCreatingOrder = true;
      _statusBannerMessage = null;
    });

    try {
      final repo = ref.read(fundsRepositoryProvider);
      final idempotencyKey = 'po_${_uuid.v4()}';

      final order = await repo.createPaymentOrder(
        amount: amt,
        currency: 'INR',
        idempotencyKey: idempotencyKey,
      );

      if (!mounted) return;

      setState(() {
        _isCreatingOrder = false;
        _activeOrder = order;
        _currentStep = _DepositStep.paymentOrderActive;
        _secondsRemaining = _calculateSecondsRemaining(order.expiresAt);
      });

      _startTimersAndListeners(order.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
          _errorText = 'Failed to create payment order: $e';
        });
      }
    }
  }

  int _calculateSecondsRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return 900;
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void _startTimersAndListeners(String orderId) {
    // A. 1-second countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _onOrderExpired();
      }
    });

    // B. Real-time Socket Listener for payment:update
    final socketService = ref.read(socketServiceProvider);
    _socketPaymentSub?.cancel();
    _socketPaymentSub = socketService.paymentUpdatesStream.listen((event) {
      final updatedId = (event['orderId'] ?? event['_id'] ?? event['paymentOrderId'] ?? '').toString();
      if (updatedId == orderId) {
        final statusStr = (event['status'] ?? '').toString().toUpperCase();
        _handleStatusTransition(statusStr, utr: event['utr']?.toString());
      }
    });

    // C. Fallback Polling every 4 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _checkPaymentStatus(silent: true);
    });
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    final order = _activeOrder;
    if (order == null || _activeOrder?.isPaid == true) return;

    if (!silent && mounted) {
      setState(() => _isCheckingStatus = true);
    }

    try {
      final repo = ref.read(fundsRepositoryProvider);
      final refreshed = await repo.getPaymentOrder(order.id);
      if (!mounted) return;

      setState(() {
        _activeOrder = refreshed;
        if (!silent) _isCheckingStatus = false;
      });

      if (refreshed.isPaid) {
        _handlePaid(refreshed);
      } else if (refreshed.isExpired) {
        _onOrderExpired();
      } else if (refreshed.isCancelled) {
        setState(() => _statusBannerMessage = 'Payment order was cancelled.');
      } else if (refreshed.isFailed) {
        setState(() => _statusBannerMessage = 'Payment failed. Please try again.');
      } else if (!silent) {
        setState(() => _statusBannerMessage = 'Payment pending: awaiting bank confirmation.');
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  void _handleStatusTransition(String status, {String? utr}) {
    if (!mounted) return;
    if (status == 'PAID' || status == 'SUCCESS' || status == 'SETTLED') {
      final updated = PaymentOrder(
        id: _activeOrder!.id,
        amount: _activeOrder!.amount,
        status: PaymentOrderStatus.PAID,
        createdAt: _activeOrder!.createdAt,
        utr: utr ?? _activeOrder!.utr,
      );
      setState(() => _activeOrder = updated);
      _handlePaid(updated);
    } else if (status == 'EXPIRED') {
      _onOrderExpired();
    } else if (status == 'CANCELLED') {
      setState(() {
        _activeOrder = PaymentOrder(
          id: _activeOrder!.id,
          amount: _activeOrder!.amount,
          status: PaymentOrderStatus.CANCELLED,
          createdAt: _activeOrder!.createdAt,
        );
        _statusBannerMessage = 'Payment order was cancelled.';
      });
    } else if (status == 'FAILED') {
      setState(() {
        _activeOrder = PaymentOrder(
          id: _activeOrder!.id,
          amount: _activeOrder!.amount,
          status: PaymentOrderStatus.FAILED,
          createdAt: _activeOrder!.createdAt,
        );
        _statusBannerMessage = 'Payment failed: transaction declined by UPI.';
      });
    }
  }

  Future<void> _handlePaid(PaymentOrder order) async {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _socketPaymentSub?.cancel();

    // Invalidate providers to immediately refresh ledger and wallet summary
    ref.invalidate(fundsSummaryProvider);
    ref.invalidate(walletLedgerProvider);
    ref.invalidate(walletTransactionsListProvider);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close sheet

    // Show confirmed receipt dialog
    final txn = WalletTransaction(
      id: order.id,
      referenceId: order.utr ?? order.id,
      type: WalletTransactionType.DEPOSIT,
      amount: order.amount,
      status: WalletTransactionStatus.COMPLETED,
      method: PaymentMethod.UPI,
      upiId: 'UPI Instant Settle',
      createdAt: order.createdAt,
      updatedAt: DateTime.now(),
      payoutUtr: order.utr,
    );
    await TransactionReceiptDialog.show(context, txn);
  }

  void _onOrderExpired() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {
        if (_activeOrder != null) {
          _activeOrder = PaymentOrder(
            id: _activeOrder!.id,
            amount: _activeOrder!.amount,
            status: PaymentOrderStatus.EXPIRED,
            createdAt: _activeOrder!.createdAt,
          );
        }
        _statusBannerMessage = 'Order expired. 15-minute payment window closed.';
      });
    }
  }

  Future<void> _handleCancelOrder() async {
    final order = _activeOrder;
    if (order == null || _isCancelling) return;

    setState(() => _isCancelling = true);
    try {
      final repo = ref.read(fundsRepositoryProvider);
      final cancelled = await repo.cancelPaymentOrder(order.id);
      if (!mounted) return;
      _countdownTimer?.cancel();
      _pollingTimer?.cancel();
      setState(() {
        _isCancelling = false;
        _activeOrder = cancelled;
        _statusBannerMessage = 'Payment order cancelled.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
          _statusBannerMessage = 'Failed to cancel: $e';
        });
      }
    }
  }

  Future<void> _launchUpiIntent(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open UPI app directly. Please copy the UPI link or scan the QR code.'),
            ),
          );
        }
      }
    }
  }

  // Legacy Simulated Instant Deposit (Gated strictly behind kDebugMode)
  Future<void> _handleSimulatedDeposit() async {
    final amt = double.tryParse(_amountController.text);
    if (amt == null) return;

    setState(() => _isCreatingOrder = true);
    try {
      final repo = ref.read(fundsRepositoryProvider);
      final idempotencyKey = 'sim_${_uuid.v4()}';
      final pendingTxn = await repo.createDeposit(
        amount: amt,
        currency: 'INR',
        idempotencyKey: idempotencyKey,
      );
      final verifiedTxn = await repo.verifyDeposit(depositId: pendingTxn.id);

      ref.invalidate(fundsSummaryProvider);
      ref.invalidate(walletLedgerProvider);
      ref.invalidate(walletTransactionsListProvider);

      if (!mounted) return;
      Navigator.pop(context);
      await TransactionReceiptDialog.show(context, verifiedTxn);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
          _errorText = 'Simulated Deposit Failed: $e';
        });
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

              if (_currentStep == _DepositStep.amountInput)
                _buildAmountInputView(colors)
              else if (_currentStep == _DepositStep.paymentOrderActive)
                _buildPaymentOrderView(colors)
              else if (_currentStep == _DepositStep.simulatedDebug)
                _buildSimulatedDebugView(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInputView(TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Add Funds', style: AppTypography.h1(color: colors.textPrimary)),
            if (kDebugMode)
              TextButton(
                onPressed: () => setState(() => _currentStep = _DepositStep.simulatedDebug),
                child: Text(
                  'Debug Sim',
                  style: GoogleFonts.inter(fontSize: 12, color: colors.bearish, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Instant deposit via official UPI payment order with zero transaction fees.',
          style: AppTypography.caption(color: colors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Amount Input Field
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
          runSpacing: 8,
          children: [
            _buildQuickChip('+ ₹1,000', 1000),
            _buildQuickChip('+ ₹5,000', 5000),
            _buildQuickChip('+ ₹10,000', 10000),
            _buildQuickChip('+ ₹25,000', 25000),
          ],
        ),
        const SizedBox(height: 20),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 20, color: colors.bullish),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Supports Google Pay, PhonePe, Paytm, BHIM UPI and all Indian banking apps with real-time settlement.',
                  style: AppTypography.caption(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        ElevatedButton(
          onPressed: _isCreatingOrder ? null : _handleCreatePaymentOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isCreatingOrder
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Proceed to Deposit ₹${_amountController.text}', style: AppTypography.h2(color: Colors.white, weight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildPaymentOrderView(TradingColors colors) {
    final order = _activeOrder!;
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final isTerminal = order.isPaid || order.isExpired || order.isCancelled || order.isFailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Complete UPI Payment', style: AppTypography.h2(color: colors.textPrimary)),
            if (!isTerminal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.timer, size: 14, color: _secondsRemaining < 120 ? colors.bearish : colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$minutes:$seconds',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining < 120 ? colors.bearish : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Order ID: ${order.id}', style: GoogleFonts.robotoMono(fontSize: 11, color: colors.textSecondary)),
        const SizedBox(height: 16),

        // Amount Display Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider, width: 0.5),
          ),
          child: Column(
            children: [
              Text('AMOUNT TO DEPOSIT', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(order.amount),
                style: AppTypography.display(color: colors.textPrimary, weight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status Feedback Banner
        if (_statusBannerMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: order.isExpired || order.isFailed || order.isCancelled
                  ? colors.bearish.withValues(alpha: 0.12)
                  : colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: order.isExpired || order.isFailed || order.isCancelled
                    ? colors.bearish.withValues(alpha: 0.4)
                    : colors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              _statusBannerMessage!,
              textAlign: TextAlign.center,
              style: AppTypography.caption(
                color: order.isExpired || order.isFailed || order.isCancelled ? colors.bearish : colors.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // QR Code & Intent Action Area
        if (!isTerminal) ...[
          // UPI Intent Launch Button
          if (order.upiIntentUrl != null && order.upiIntentUrl!.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: () => _launchUpiIntent(order.upiIntentUrl!),
              icon: const Icon(LucideIcons.arrowUpRight, size: 18),
              label: const Text('Pay with UPI App (GPay / PhonePe / Paytm)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.bullish,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // QR Code Display Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              children: [
                Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.qrCode, size: 72, color: Colors.grey.shade800),
                        const SizedBox(height: 6),
                        Text(
                          'Scan with any UPI App',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (order.upiIntentUrl != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: order.upiIntentUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI payment link copied to clipboard')),
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 14),
                    label: const Text('Copy UPI Payment Link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: I have paid & Cancel
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _handleCancelOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.bearish,
                    side: BorderSide(color: colors.bearish.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel Order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCheckingStatus ? null : () => _checkPaymentStatus(silent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isCheckingStatus
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('I have paid'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Terminal Retry Action
          ElevatedButton(
            onPressed: () {
              setState(() {
                _activeOrder = null;
                _currentStep = _DepositStep.amountInput;
                _statusBannerMessage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Try Again with New Order'),
          ),
        ],
      ],
    );
  }

  // Debug-only simulated instant deposit sheet
  Widget _buildSimulatedDebugView(TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Simulated Deposit (Debug)', style: AppTypography.h2(color: colors.bearish)),
            TextButton(
              onPressed: () => setState(() => _currentStep = _DepositStep.amountInput),
              child: const Text('Back to Real'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.bearish.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.bearish.withValues(alpha: 0.3)),
          ),
          child: Text(
            'WARNING: This bypasses real UPI gateway orders and calls deposit/create & deposit/verify directly. Fails with 403 on production backends.',
            style: AppTypography.caption(color: colors.bearish),
          ),
        ),
        const SizedBox(height: 16),
        Text('Amount: ₹${_amountController.text}', style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isCreatingOrder ? null : _handleSimulatedDeposit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.bearish,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isCreatingOrder
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirm Simulated Deposit'),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, double amount) {
    final colors = context.tradingColors;
    return InkWell(
      onTap: () => _addQuickAmount(amount),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.divider, width: 0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
      ),
    );
  }
}
