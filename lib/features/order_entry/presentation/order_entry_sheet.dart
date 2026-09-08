import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/charges_config.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/edge_case_service.dart';
import '../../../core/services/maintenance_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/mock/settings_repository.dart';
import '../../../data/mock/ticker_service.dart';
import '../../../data/models/models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../funds/presentation/add_funds_sheet.dart';
import 'leverage_education_dialog.dart';

class OrderEntrySheet extends ConsumerStatefulWidget {
  final Instrument instrument;
  final TransactionType initialSide;

  const OrderEntrySheet({
    super.key,
    required this.instrument,
    this.initialSide = TransactionType.BUY,
  });

  static Future<void> show(
    BuildContext context, {
    required Instrument instrument,
    TransactionType side = TransactionType.BUY,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderEntrySheet(
        instrument: instrument,
        initialSide: side,
      ),
    );
  }

  @override
  ConsumerState<OrderEntrySheet> createState() => _OrderEntrySheetState();
}

class _OrderEntrySheetState extends ConsumerState<OrderEntrySheet> {
  late Instrument _currentInstrument;
  bool _isSubmitting = false;
  // 'Market' | 'Pending' (Limit) | 'Stop' (SL-Market) | 'Stop-Limit' (SL)
  String _orderExecutionType = 'Market';
  String _amountUnit = 'In Lot'; // 'In Lot' or 'In Quantity'
  String _sltpMode = 'At Price'; // 'At Price' or 'At Value'
  // Time-in-force: DAY (default) or IOC (Immediate-or-Cancel)
  Validity _validity = Validity.DAY;

  double _lots = 0.10;
  double _limitPrice = 0.0;
  double _triggerPrice = 0.0; // Used for Stop & Stop-Limit orders
  double _slPrice = 0.0;
  double _tpPrice = 0.0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentInstrument = widget.instrument;
    final defaultLots = ref.read(appSettingsProvider).defaultLots;
    if (defaultLots > 0) {
      _lots = defaultLots;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickerService = ref.watch(tickerServiceProvider);
    final quote = tickerService.getQuote(_currentInstrument.token);

    if (_limitPrice == 0.0) {
      _limitPrice = quote.ltp;
    }

    final bid = (quote.ltp - 0.15);
    final ask = (quote.ltp + 0.15);

    final isCommodity = _currentInstrument.exchange == Exchange.MCX ||
        _currentInstrument.token.contains('mcx_');
    final lotMultiplier = isCommodity ? 2500.0 : (_currentInstrument.lotSize > 0 ? _currentInstrument.lotSize.toDouble() : 1.0);

    final totalQuantity = _amountUnit == 'In Lot' ? (_lots * lotMultiplier) : _lots;
    final estQuantity = totalQuantity.toStringAsFixed(2);

    // Dynamic Exposure & Margin
    final bool isPending = _orderExecutionType == 'Pending';
    final bool isStop = _orderExecutionType == 'Stop';
    final bool isStopLimit = _orderExecutionType == 'Stop-Limit';
    final effectivePrice = (isPending || isStopLimit) ? _limitPrice : quote.ltp;
    final totalExposure = (effectivePrice * totalQuantity);

    final leverage = _currentInstrument.leverageMultiplier > 0
        ? _currentInstrument.leverageMultiplier
        : (isCommodity ? 500.0 : 5.0);
    final marginRate = 1.0 / leverage;
    final estBuyMargin = totalExposure * marginRate;
    final estSellMargin = totalExposure * marginRate;

    // Charges calculation (Zero Brokerage model)
    final calculatedCharges = ChargesConfig.calculateCharges(
      price: effectivePrice,
      quantity: totalQuantity.toInt().clamp(1, 100000),
      side: widget.initialSide,
      product: isCommodity ? ProductType.NRML : ProductType.MIS,
      instrumentType: _currentInstrument.type,
    );

    // Target P&L & Max Risk Preview
    double? targetProfit;
    double? maxRisk;
    if (_tpPrice > 0) {
      targetProfit = (_tpPrice - effectivePrice).abs() * totalQuantity;
    }
    if (_slPrice > 0) {
      maxRisk = (effectivePrice - _slPrice).abs() * totalQuantity;
    }

    final engine = ref.watch(orderSimulationEngineProvider);
    final availableMargin = engine
        .getFundsSummary(isCommodity ? Segment.COMMODITY : Segment.EQUITY)
        .availableMargin;

    final isMarginInsufficientBuy = estBuyMargin > availableMargin;
    final isMarginInsufficientSell = estSellMargin > availableMargin;
    final postTradeUtilization =
        availableMargin > 0 ? (estBuyMargin / availableMargin) * 100 : 999.0;
    final isHighMarginUtilization =
        postTradeUtilization >= 80.0 && !isMarginInsufficientBuy;

    final colors = context.tradingColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // 1. Header: Symbol Selector & Risk Badges
              InkWell(
                onTap: () => _showInstrumentPicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentInstrument.symbol,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down,
                              size: 22, color: colors.textPrimary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_currentInstrument.isSuspended)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '🚫 SUSPENDED',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          if (_currentInstrument.surveillanceTag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF57C00),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '⚠️ ${_currentInstrument.surveillanceTag}',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.divider),
                            ),
                            child: Text(
                              '⚡ ${leverage.toStringAsFixed(0)}x Leverage',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1E88E5)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.divider),
                            ),
                            child: Text(
                              'Max: ${_currentInstrument.freezeQty} Qty',
                              style: GoogleFonts.inter(fontSize: 10, color: colors.textSecondary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.divider),
                            ),
                            child: Text(
                              'Circuit: ₹${(quote.lowerCircuit > 0 ? quote.lowerCircuit : quote.ltp * 0.9).toStringAsFixed(1)} - ₹${(quote.upperCircuit > 0 ? quote.upperCircuit : quote.ltp * 1.1).toStringAsFixed(1)}',
                              style: GoogleFonts.inter(fontSize: 10, color: colors.textSecondary),
                            ),
                          ),
                          InkWell(
                            onTap: () => LeverageEducationDialog.show(context),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school_outlined, size: 12, color: Color(0xFF1E88E5)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Risk Guide',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1E88E5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, thickness: 0.8, color: colors.divider),

              const SizedBox(height: 14),

              // 2. Order Mode: Market | Pending | Stop | Stop-Limit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildRadioOption('Market', _orderExecutionType, (val) {
                      setState(() => _orderExecutionType = val);
                    }),
                    _buildRadioOption('Pending', _orderExecutionType, (val) {
                      setState(() => _orderExecutionType = val);
                    }),
                    _buildRadioOption('Stop', _orderExecutionType, (val) {
                      setState(() {
                        _orderExecutionType = val;
                        if (_triggerPrice == 0.0) _triggerPrice = quote.ltp;
                      });
                    }),
                    _buildRadioOption('Stop-Limit', _orderExecutionType, (val) {
                      setState(() {
                        _orderExecutionType = val;
                        if (_triggerPrice == 0.0) _triggerPrice = quote.ltp;
                        if (_limitPrice == 0.0) _limitPrice = quote.ltp;
                      });
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2b. Time-in-Force: DAY | IOC
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Validity:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildRadioOption('DAY', _validity == Validity.DAY ? 'DAY' : 'IOC', (val) {
                      setState(() => _validity = Validity.DAY);
                    }),
                    const SizedBox(width: 20),
                    _buildRadioOption('IOC', _validity == Validity.IOC ? 'IOC' : 'DAY', (val) {
                      setState(() => _validity = Validity.IOC);
                    }),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'DAY: Order stays open till end of trading day.\nIOC: Order must fill immediately or is cancelled.',
                      child: Icon(Icons.info_outline, size: 14, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Bid / Ask Dual Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.divider, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Bid Box
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bid  ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D88C8),
                                  ),
                                ),
                                Text(
                                  bid.toStringAsFixed(2),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2D88C8),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Container(width: 1, height: 52, color: colors.divider),

                      // Ask Box
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ask  ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D88C8),
                                  ),
                                ),
                                Text(
                                  ask.toStringAsFixed(2),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2D88C8),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Pending / Limit Price Input (If Pending Selected)
              // 3a. Trigger Price (shown for Stop & Stop-Limit)
              if (isStop || isStopLimit) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active_outlined,
                              size: 15, color: colors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'Trigger Price:',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.warning,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isStop ? '(Stop-Market: executes at market when triggered)' : '(Stop-Limit: executes at limit price when triggered)',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.warning.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                if (_triggerPrice > 0.5) {
                                  setState(() => _triggerPrice -= 0.5);
                                }
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE82B57),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.remove, size: 16, color: Colors.white),
                              ),
                            ),
                            Text(
                              _triggerPrice.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.warning,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _triggerPrice += 0.5);
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E88E5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 3b. Limit Price (shown for Pending & Stop-Limit)
              if (isPending || isStopLimit) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPending ? 'Pending / Limit Price:' : 'Limit Price (Stop-Limit execution price):',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                if (_limitPrice > 0.5) {
                                  setState(() => _limitPrice -= 0.5);
                                }
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE82B57),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.remove, size: 16, color: Colors.white),
                              ),
                            ),
                            Text(
                              _limitPrice.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _limitPrice += 0.5);
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E88E5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 5. Amount Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Amount (Lot)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFF2D88C8)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRadioOption('In Lot', _amountUnit, (val) {
                              setState(() => _amountUnit = val);
                            }),
                            const SizedBox(width: 16),
                            _buildRadioOption('In Quantity', _amountUnit, (val) {
                              setState(() => _amountUnit = val);
                            }),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Amount Stepper Box
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.divider, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              if (_lots > 0.05) {
                                setState(() =>
                                    _lots = (_lots - 0.05).clamp(0.01, 100.0));
                              }
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE82B57),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.remove,
                                  size: 16, color: Colors.white),
                            ),
                          ),

                          Text(
                            _lots.toStringAsFixed(2),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),

                          InkWell(
                            onTap: () {
                              setState(() =>
                                  _lots = (_lots + 0.05).clamp(0.01, 100.0));
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E88E5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      'Estimated Quantity: ≈ $estQuantity units',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 6. SL / TP Orders Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SL/TP orders:',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFF2D88C8)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRadioOption('At Price', _sltpMode, (val) {
                              setState(() => _sltpMode = val);
                            }),
                            const SizedBox(width: 16),
                            _buildRadioOption('At Value', _sltpMode, (val) {
                              setState(() => _sltpMode = val);
                            }),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // S/L and T/P Dual Stepper Inputs
                    Row(
                      children: [
                        // S/L Input Box
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'S/L',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: colors.divider, width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (_slPrice > 0.5) {
                                          setState(() => _slPrice -= 0.5);
                                        }
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE82B57),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      _slPrice > 0
                                          ? _slPrice.toStringAsFixed(2)
                                          : '0.00',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() => _slPrice += 0.5);
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E88E5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // T/P Input Box
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'T/P',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: colors.divider, width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (_tpPrice > 0.5) {
                                          setState(() => _tpPrice -= 0.5);
                                        }
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE82B57),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      _tpPrice > 0
                                          ? _tpPrice.toStringAsFixed(2)
                                          : '0.00',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() => _tpPrice += 0.5);
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E88E5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Target P&L Preview Banner (if SL or TP set)
                    if (targetProfit != null || maxRisk != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (targetProfit != null)
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, size: 14, color: Color(0xFF00A854)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Est. Profit: +${CurrencyFormatter.format(targetProfit)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF00A854),
                                    ),
                                  ),
                                ],
                              ),
                            if (maxRisk != null)
                              Row(
                                children: [
                                  const Icon(Icons.trending_down, size: 14, color: Color(0xFFE82B57)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Max Risk: -${CurrencyFormatter.format(maxRisk)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFE82B57),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 7. Comment Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comment',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Optional order tag/comment...',
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: colors.divider, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 8. Financial & Margin Breakdown Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildMarginRow('Total Exposure Value:',
                        CurrencyFormatter.format(totalExposure), colors.textPrimary),
                    const SizedBox(height: 4),
                    _buildMarginRow('Instrument Leverage:',
                        '${leverage.toStringAsFixed(0)}x (${(marginRate * 100).toStringAsFixed(1)}% margin)', const Color(0xFF1E88E5)),
                    const SizedBox(height: 4),
                    _buildMarginRow('Est. Buy Margin:',
                        CurrencyFormatter.format(estBuyMargin), const Color(0xFF2D88C8)),
                    const SizedBox(height: 4),
                    _buildMarginRow('Est. Sell Margin:',
                        CurrencyFormatter.format(estSellMargin), const Color(0xFFE82B57)),
                    const SizedBox(height: 4),
                    _buildMarginRow('Est. Brokerage & Taxes:',
                        '₹0.00 Brokerage + ₹${calculatedCharges.total.toStringAsFixed(2)} Taxes', colors.textSecondary),
                    const SizedBox(height: 4),
                    _buildMarginRow('Available Margin:',
                        CurrencyFormatter.format(availableMargin), colors.textPrimary),
                    const SizedBox(height: 4),
                    _buildMarginRow('Margin Utilization:',
                        '${postTradeUtilization.toStringAsFixed(1)}%',
                        postTradeUtilization > 80 ? const Color(0xFFE82B57) : (postTradeUtilization > 50 ? const Color(0xFFF57C00) : colors.textSecondary)),
                  ],
                ),
              ),

              // 9. Margin / Risk Alerts
              if (isMarginInsufficientBuy || isMarginInsufficientSell) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE82B57).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE82B57).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFE82B57), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insufficient Margin Rejection Alert',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE82B57),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Required: ${CurrencyFormatter.format(estBuyMargin)} • Available: ${CurrencyFormatter.format(availableMargin)} • Shortfall: ${CurrencyFormatter.format(estBuyMargin - availableMargin)}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFFE82B57),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => AddFundsSheet.show(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE82B57),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Add Funds', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (isHighMarginUtilization) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF57C00).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF57C00).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'High Margin Utilization (${postTradeUtilization.toStringAsFixed(1)}%): This order utilizes over 80% of your available funds. Maintain a cash buffer against adverse price swings.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF57C00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Notice text — dynamic per order type
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _orderExecutionType == 'Market'
                      ? 'Attention! The trade will be executed at market conditions, difference with requested price may be significant!'
                      : _orderExecutionType == 'Pending'
                          ? 'Your order will remain pending until the market reaches your specified limit price.'
                          : _orderExecutionType == 'Stop'
                              ? 'Stop-Market: When the trigger price is hit, the order will execute at the best available market price.'
                              : 'Stop-Limit: When the trigger price is hit, a limit order will be placed at your specified limit price.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 10. Bottom SELL & BUY Full-width Action Buttons
              Row(
                children: [
                  // SELL Button (Rose Crimson #E82B57)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: Semantics(
                        button: true,
                        label: 'Place Sell Order',
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _promptOrderReview(
                                    context,
                                    side: TransactionType.SELL,
                                    price: (isPending || isStopLimit) ? _limitPrice : bid,
                                    totalQty: totalQuantity,
                                    marginReq: estSellMargin,
                                    availableMargin: availableMargin,
                                    charges: calculatedCharges,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE82B57),
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'SELL',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  // BUY Button (Deep Navy #1E2B60)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: Semantics(
                        button: true,
                        label: 'Place Buy Order',
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _promptOrderReview(
                                    context,
                                    side: TransactionType.BUY,
                                    price: (isPending || isStopLimit) ? _limitPrice : ask,
                                    totalQty: totalQuantity,
                                    marginReq: estBuyMargin,
                                    availableMargin: availableMargin,
                                    charges: calculatedCharges,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2B60),
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'BUY',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(
      String label, String groupValue, ValueChanged<String> onChanged) {
    final isSelected = label == groupValue;
    final colors = context.tradingColors;
    return InkWell(
      onTap: () => onChanged(label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2D88C8)
                    : colors.divider,
                width: isSelected ? 4.5 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMarginRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  void _promptOrderReview(
    BuildContext context, {
    required TransactionType side,
    required double price,
    required double totalQty,
    required double marginReq,
    required double availableMargin,
    required ChargesBreakdown charges,
  }) {
    final colors = context.tradingColors;
    final authState = ref.read(authControllerProvider);
    final profile = authState.session?.profile;
    final clientDisplay = profile != null
        ? '${profile.userId} (${profile.phone})'
        : 'Not available';

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (reviewContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Confirmation',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (side == TransactionType.BUY ? const Color(0xFF1E2B60) : const Color(0xFFE82B57)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      side.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildReviewRow('Instrument:', _currentInstrument.symbol, colors),
              _buildReviewRow(
                'Order Type:',
                _orderExecutionType == 'Market'
                    ? 'MARKET (fills at best price)'
                    : _orderExecutionType == 'Stop'
                        ? 'STOP-MARKET (SL-M — triggers at ₹${_triggerPrice.toStringAsFixed(2)}, fills at market)'
                        : _orderExecutionType == 'Stop-Limit'
                            ? 'STOP-LIMIT (SL — trigger ₹${_triggerPrice.toStringAsFixed(2)}, limit ₹${_limitPrice.toStringAsFixed(2)})'
                            : 'LIMIT / PENDING',
                colors,
              ),
              _buildReviewRow('Side:', side.name, colors),
              _buildReviewRow('Order Price:', CurrencyFormatter.format(price), colors),
              _buildReviewRow('Quantity / Lots:', '${_lots.toStringAsFixed(2)} Lots (≈ ${totalQty.toStringAsFixed(0)} Qty)', colors),
              _buildReviewRow(
                'Time-in-Force:',
                _validity == Validity.DAY
                    ? 'DAY (valid till end of trading day)'
                    : 'IOC (Immediate or Cancel)',
                colors,
              ),
              _buildReviewRow('Stop Loss (S/L):', _slPrice > 0 ? CurrencyFormatter.format(_slPrice) : 'None', colors),
              _buildReviewRow('Take Profit (T/P):', _tpPrice > 0 ? CurrencyFormatter.format(_tpPrice) : 'None', colors),
              _buildReviewRow('Estimated Margin:', CurrencyFormatter.format(marginReq), colors),
              _buildReviewRow(
                'Est. Charges:',
                '₹0.00 Brokerage + STT ₹${charges.stt.toStringAsFixed(2)} + GST ₹${charges.gst.toStringAsFixed(2)} + Other ₹${(charges.exchangeTxnCharge + charges.sebiCharges + charges.stampDuty).toStringAsFixed(2)}',
                colors,
              ),
              _buildReviewRow('Total Taxes:', '₹${charges.total.toStringAsFixed(2)}', colors),
              _buildReviewRow('Client / Account ID:', clientDisplay, colors),

              if (_currentInstrument.isSuspended) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFC62828)),
                  ),
                  child: Text(
                    '⛔ SUSPENDED: Trading in ${_currentInstrument.symbol} is suspended (${_currentInstrument.suspensionReason ?? "Regulatory action"}). Order will be rejected.',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFC62828)),
                  ),
                ),
              ] else if (_currentInstrument.surveillanceTag != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF57C00)),
                  ),
                  child: Text(
                    '⚠️ SURVEILLANCE MEASURE: ${_currentInstrument.symbol} is under ${_currentInstrument.surveillanceTag}. 100% margin required; intraday leverage restricted.',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFF57C00)),
                  ),
                ),
              ],

              if (marginReq > availableMargin * 0.8 && !_currentInstrument.isSuspended) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE82B57).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE82B57).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE82B57)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'High-Risk Order: Consumes >80% margin. Amplified volatility may lead to liquidation.',
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFE82B57), fontWeight: FontWeight.w600),
                        ),
                      ),
                      InkWell(
                        onTap: () => LeverageEducationDialog.show(context),
                        child: const Text(' Guide', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5), decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(reviewContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Edit Order'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.pop(reviewContext);
                              _executeOrder(side, price, totalQty);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: side == TransactionType.BUY ? const Color(0xFF1E2B60) : const Color(0xFFE82B57),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm & Place', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _executeOrder(TransactionType side, double execPrice, double totalQty) async {
    // 1. Double-tap and spam protection
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final isMaintenance = ref.read(isMaintenanceActiveProvider);
      if (isMaintenance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot place orders: Exchange servers are under scheduled maintenance.',
            ),
            backgroundColor: Color(0xFFE65100),
          ),
        );
        return;
      }

      final isOffline = ref.read(isOfflineProvider);
      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot place orders while offline. Please check your internet connection.',
            ),
            backgroundColor: Color(0xFFC62828),
          ),
        );
        return;
      }

      final engine = ref.read(orderSimulationEngineProvider);
      final edgeService = ref.read(edgeCaseServiceProvider);

      final isCommodity = _currentInstrument.exchange == Exchange.MCX ||
          _currentInstrument.token.contains('mcx_');

      // 2. Client-generated idempotency key
      final idempotencyKey =
          'ord_${DateTime.now().millisecondsSinceEpoch}_${_currentInstrument.token}';

      final request = OrderRequest(
        idempotencyKey: idempotencyKey,
        instrumentToken: _currentInstrument.token,
        side: side,
        product: isCommodity ? ProductType.NRML : ProductType.MIS,
        kind: _orderExecutionType == 'Market'
            ? OrderKind.MARKET
            : _orderExecutionType == 'Stop'
                ? OrderKind.SL_M
                : _orderExecutionType == 'Stop-Limit'
                    ? OrderKind.SL
                    : OrderKind.LIMIT,
        quantity: totalQty.toInt().clamp(1, 100000),
        price: (_orderExecutionType == 'Pending' || _orderExecutionType == 'Stop-Limit')
            ? _limitPrice
            : null,
        triggerPrice: (_orderExecutionType == 'Stop' || _orderExecutionType == 'Stop-Limit')
            ? _triggerPrice
            : null,
        bracket: (_slPrice > 0 || _tpPrice > 0)
            ? BracketParams(
                stopLoss: _slPrice,
                target: _tpPrice,
              )
            : null,
        validity: _validity,
      );

      // 3. Record in journal before dispatch to recover if app is killed
      edgeService.recordInFlightOrder(request, idempotencyKey);

      final placedOrder = await engine.placeOrder(request);

      // 4. Mark persisted in journal
      edgeService.markOrderPersisted(idempotencyKey, placedOrder.effectiveServerOrderId);

      if (!mounted) return;
      Navigator.pop(context);

      if (placedOrder.status == OrderStatus.REJECTED) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    placedOrder.rejectionReason ?? 'Order rejected by Risk Management System.',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${side.name} order placed! Ref: ${placedOrder.orderId} • ${_lots.toStringAsFixed(2)} lots @ ${execPrice.toStringAsFixed(2)}',
          ),
          backgroundColor: side == TransactionType.BUY
              ? const Color(0xFF1E2B60)
              : const Color(0xFFE82B57),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW DEALS',
            textColor: Colors.white,
            onPressed: () => context.go('/deals'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showInstrumentPicker(BuildContext context) {
    final colors = context.tradingColors;
    final allInstruments = SeedInstruments.all;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Instrument',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary),
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: ListView.separated(
                itemCount: allInstruments.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider.withValues(alpha: 0.5)),
                itemBuilder: (context, index) {
                  final inst = allInstruments[index];
                  final isSelected = inst.token == _currentInstrument.token;

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        inst.symbol,
                        style: GoogleFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFE82B57)
                              : colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${inst.exchange.name} • ${inst.type.name}',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFFE82B57))
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentInstrument = inst);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
