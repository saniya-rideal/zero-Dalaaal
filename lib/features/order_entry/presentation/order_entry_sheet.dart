import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/charges_config.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/maintenance_service.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/instrument.dart';
import '../../../data/models/quote.dart';
import '../../funds/data/real_funds_repository.dart';
import 'controllers/order_entry_controller.dart';
import 'widgets/order_header.dart';
import 'widgets/order_review_sheet.dart';

class OrderEntrySheet extends ConsumerStatefulWidget {
  final Instrument instrument;
  final TransactionType initialSide;
  final double? initialLots;
  final int? initialQuantity;
  final double? initialStopLoss;
  final double? initialTakeProfit;

  const OrderEntrySheet({
    super.key,
    required this.instrument,
    this.initialSide = TransactionType.BUY,
    this.initialLots,
    this.initialQuantity,
    this.initialStopLoss,
    this.initialTakeProfit,
  });

  static Future<void> show(
    BuildContext context, {
    required Instrument instrument,
    TransactionType side = TransactionType.BUY,
    double? initialLots,
    int? initialQuantity,
    double? initialStopLoss,
    double? initialTakeProfit,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderEntrySheet(
          instrument: instrument,
          initialSide: side,
          initialLots: initialLots,
          initialQuantity: initialQuantity,
          initialStopLoss: initialStopLoss,
          initialTakeProfit: initialTakeProfit,
        ),
      ),
    );
  }

  @override
  ConsumerState<OrderEntrySheet> createState() => _OrderEntrySheetState();
}

class _OrderEntrySheetState extends ConsumerState<OrderEntrySheet> {
  late ({Instrument instrument, TransactionType initialSide}) _familyKey;
  late final TextEditingController _lotCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _slCtrl;
  late final TextEditingController _tpCtrl;
  late final TextEditingController _atPriceCtrl;
  late final TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _familyKey = (instrument: widget.instrument, initialSide: widget.initialSide);

    final lotText = widget.initialLots != null && widget.initialLots! > 0
        ? widget.initialLots!.toStringAsFixed(2)
        : '1.00';
    final qtyText = widget.initialQuantity != null && widget.initialQuantity! > 0
        ? widget.initialQuantity!.toString()
        : '1';
    final slText = widget.initialStopLoss != null && widget.initialStopLoss! > 0
        ? widget.initialStopLoss!.toStringAsFixed(2)
        : '';
    final tpText = widget.initialTakeProfit != null && widget.initialTakeProfit! > 0
        ? widget.initialTakeProfit!.toStringAsFixed(2)
        : '';

    _lotCtrl = TextEditingController(text: lotText);
    _qtyCtrl = TextEditingController(text: qtyText);
    _slCtrl = TextEditingController(text: slText);
    _tpCtrl = TextEditingController(text: tpText);
    _atPriceCtrl = TextEditingController();
    _commentCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(orderEntryControllerProvider(_familyKey).notifier);
      if (widget.initialLots != null && widget.initialLots! > 0) {
        notifier.setLots(widget.initialLots!);
      } else if (widget.initialQuantity != null && widget.initialQuantity! > 0) {
        notifier.setQuantity(widget.initialQuantity!);
      }
      if (widget.initialStopLoss != null && widget.initialStopLoss! > 0) {
        notifier.setSlPrice(widget.initialStopLoss!);
      }
      if (widget.initialTakeProfit != null && widget.initialTakeProfit! > 0) {
        notifier.setTpPrice(widget.initialTakeProfit!);
      }
    });
  }

  @override
  void dispose() {
    _lotCtrl.dispose();
    _qtyCtrl.dispose();
    _slCtrl.dispose();
    _tpCtrl.dispose();
    _atPriceCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(OrderEntryState state) {
    if (double.tryParse(_lotCtrl.text) != state.lots) {
      _lotCtrl.text = state.lots.toStringAsFixed(2);
    }
    if (int.tryParse(_qtyCtrl.text) != state.quantity) {
      _qtyCtrl.text = state.quantity.toString();
    }
    if (state.slPrice > 0 && double.tryParse(_slCtrl.text) != state.slPrice) {
      _slCtrl.text = state.slPrice.toStringAsFixed(2);
    } else if (state.slPrice == 0 && _slCtrl.text.isNotEmpty) {
      _slCtrl.clear();
    }
    if (state.tpPrice > 0 && double.tryParse(_tpCtrl.text) != state.tpPrice) {
      _tpCtrl.text = state.tpPrice.toStringAsFixed(2);
    } else if (state.tpPrice == 0 && _tpCtrl.text.isNotEmpty) {
      _tpCtrl.clear();
    }
    final activePrice = state.limitPrice > 0 ? state.limitPrice : state.triggerPrice;
    if (activePrice > 0 && double.tryParse(_atPriceCtrl.text) != activePrice) {
      _atPriceCtrl.text = activePrice.toStringAsFixed(2);
    } else if (activePrice == 0 && _atPriceCtrl.text.isNotEmpty) {
      _atPriceCtrl.clear();
    }
  }

  void _onConfirmPlacement(BuildContext context, TransactionType side) {
    final notifier = ref.read(orderEntryControllerProvider(_familyKey).notifier);
    final state = ref.read(orderEntryControllerProvider(_familyKey));
    final quote = ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;

    final execPrice = state.isMarketOrder
        ? (side == TransactionType.BUY ? (quote?.ask ?? quote?.ltp ?? 0.0) : (quote?.bid ?? quote?.ltp ?? 0.0))
        : (state.limitPrice > 0 ? state.limitPrice : state.triggerPrice);

    // Immediate user-friendly pre-validation check for Stop Loss & Take Profit
    if (state.slPrice > 0) {
      if (side == TransactionType.BUY && state.slPrice >= execPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stop Loss for BUY must be lower than entry price (₹${execPrice.toStringAsFixed(2)})'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      } else if (side == TransactionType.SELL && state.slPrice <= execPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stop Loss for SELL must be higher than entry price (₹${execPrice.toStringAsFixed(2)})'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (state.tpPrice > 0) {
      if (side == TransactionType.BUY && state.tpPrice <= execPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Take Profit for BUY must be higher than entry price (₹${execPrice.toStringAsFixed(2)})'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      } else if (side == TransactionType.SELL && state.tpPrice >= execPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Take Profit for SELL must be lower than entry price (₹${execPrice.toStringAsFixed(2)})'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    notifier.setSide(side);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final latestState = sheetRef.watch(orderEntryControllerProvider(_familyKey));
            return OrderReviewSheet(
              state: latestState,
              side: side,
              executionPrice: execPrice,
              onConfirm: () async {
                final order = await notifier.submitOrder(
                  context: context,
                  overrideSide: side,
                );
                if (order == null && context.mounted) {
                  final err = ref.read(orderEntryControllerProvider(_familyKey)).submissionError;
                  if (err != null && err.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: const Color(0xFFD32F2F),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              onCancel: () => Navigator.of(bottomSheetContext).pop(),
            );
          },
        );
      },
    );
  }

  void _showInstrumentPicker(BuildContext context) {
    final notifier = ref.read(orderEntryControllerProvider(_familyKey).notifier);
    final state = ref.read(orderEntryControllerProvider(_familyKey));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InstrumentPickerSheet(
        currentInstrument: state.instrument,
        onSelected: (selected) {
          notifier.setInstrument(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOnline = ref.watch(connectivityServiceProvider) == NetworkStatus.online;
    final isMaint = ref.watch(maintenanceServiceProvider).isMaintenanceActive;

    final state = ref.watch(orderEntryControllerProvider(_familyKey));
    final notifier = ref.read(orderEntryControllerProvider(_familyKey).notifier);
    _syncControllers(state);

    final quoteAsync = ref.watch(quoteDetailStreamProvider(state.instrument.symbol));
    final quote = quoteAsync.valueOrNull;

    final fundsSummaryAsync = ref.watch(fundsSummaryProvider);
    final availMargin = fundsSummaryAsync.valueOrNull?.availableCash ?? 100000.0;

    final isMarket = state.orderCategory == 'Market';
    final isLotMode = state.unitMode == 'In Lot';
    final isAtPrice = state.sltpMode == 'At Price';

    // Margins calculation
    final ltp = quote?.ltp ?? 100.0;
    final bid = quote?.bid ?? ltp;
    final ask = quote?.ask ?? ltp;
    final leverage = state.instrument.defaultLeverage > 0 ? state.instrument.defaultLeverage : 1.0;
    final qty = state.quantity > 0 ? state.quantity : 1;
    final estBuyMargin = (qty * ask) / leverage;
    final estSellMargin = (qty * bid) / leverage;
    final chargesBreakdown = ChargesConfig.calculateCharges(
      price: ltp,
      quantity: qty,
      side: state.side,
      product: state.product,
      instrumentType: state.instrument.type,
    );
    final estCharges = state.preview?.charges.total ?? chargesBreakdown.total;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E14) : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Connectivity / Maintenance Warning
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: Colors.red.shade700,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.wifiOff, size: 13, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'No Internet Connection — Real-time quotes paused',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else if (isMaint)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: Colors.amber.shade800,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 13, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Exchange Maintenance Window in Progress',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // Top Header: Centered Instrument Name with Down Dropdown Arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 19,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).maybePop();
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showInstrumentPicker(context);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                state.instrument.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 19),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF232936) : const Color(0xFFE2E8F0),
            ),

            // Scrollable Form Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Type Radio Selection: Market vs Pending (Centered)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRadioItem(
                          label: 'Market',
                          selected: isMarket,
                          onTap: () => notifier.setOrderCategory('Market'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 20),
                        _buildRadioItem(
                          label: 'Pending',
                          selected: !isMarket,
                          onTap: () => notifier.setOrderCategory('Pending'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Dual Bid / Ask Box with Live Tick Flash & Micro-Animation
                    _LiveBidAskBox(
                      quote: quote,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Amount Section: Header with info & In Lot / In Quantity radio buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isLotMode ? 'Amount (Lot)' : 'Amount (Quantity)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildInfoIcon('Specify trade volume either in contract lots or unit quantity.'),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRadioItem(
                              label: 'In Lot',
                              selected: isLotMode,
                              onTap: () => notifier.setUnitMode('In Lot'),
                              isDark: isDark,
                              fontSize: 11.5,
                            ),
                            const SizedBox(width: 4),
                            _buildRadioItem(
                              label: 'In Quantity',
                              selected: !isLotMode,
                              onTap: () => notifier.setUnitMode('In Quantity'),
                              isDark: isDark,
                              fontSize: 11.5,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Amount Stepper Box: Red minus circle, centered amount, Blue plus circle
                    _SmoothStepperBox(
                      controller: isLotMode ? _lotCtrl : _qtyCtrl,
                      onMinus: isLotMode ? () => notifier.stepLots(false) : () => notifier.stepQuantity(false),
                      onPlus: isLotMode ? () => notifier.stepLots(true) : () => notifier.stepQuantity(true),
                      onChanged: (val) {
                        if (isLotMode) {
                          final parsed = double.tryParse(val) ?? 1.0;
                          notifier.setLots(parsed);
                        } else {
                          final parsed = int.tryParse(val) ?? 1;
                          notifier.setQuantity(parsed);
                        }
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle Estimated Quantity
                    Text(
                      'Estimated Quantity: \u2248 ${isLotMode ? (state.lots * (state.instrument.lotSize > 0 ? state.instrument.lotSize : 1.0)).toStringAsFixed(2) : state.quantity.toString()}',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pending Orders Controls (When Pending is selected)
                    if (!isMarket) ...[
                      // Pending type radio options: Buy Limit, Sell Limit, Buy Stop, Sell Stop
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildRadioItem(
                              label: 'Buy Limit',
                              selected: state.pendingType == 'Buy Limit',
                              onTap: () => notifier.setPendingType('Buy Limit'),
                              isDark: isDark,
                              fontSize: 11.5,
                            ),
                            const SizedBox(width: 6),
                            _buildRadioItem(
                              label: 'Sell Limit',
                              selected: state.pendingType == 'Sell Limit',
                              onTap: () => notifier.setPendingType('Sell Limit'),
                              isDark: isDark,
                              fontSize: 11.5,
                            ),
                            const SizedBox(width: 6),
                            _buildRadioItem(
                              label: 'Buy Stop',
                              selected: state.pendingType == 'Buy Stop',
                              onTap: () => notifier.setPendingType('Buy Stop'),
                              isDark: isDark,
                              fontSize: 11.5,
                            ),
                            const SizedBox(width: 6),
                            _buildRadioItem(
                              label: 'Sell Stop',
                              selected: state.pendingType == 'Sell Stop',
                              onTap: () => notifier.setPendingType('Sell Stop'),
                              isDark: isDark,
                              fontSize: 11.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // At Price Stepper Section
                      Row(
                        children: [
                          Text(
                            'At Price',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          _buildInfoIcon('Execution trigger target price for the order.'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _SmoothStepperBox(
                        controller: _atPriceCtrl,
                        hintText: (quote?.ltp ?? 0.0).toStringAsFixed(2),
                        onMinus: () {
                          if (state.pendingType.contains('Limit')) {
                            notifier.stepLimitPrice(false);
                          } else {
                            notifier.stepTriggerPrice(false);
                          }
                        },
                        onPlus: () {
                          if (state.pendingType.contains('Limit')) {
                            notifier.stepLimitPrice(true);
                          } else {
                            notifier.stepTriggerPrice(true);
                          }
                        },
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          if (state.pendingType.contains('Limit')) {
                            notifier.setLimitPrice(parsed);
                          } else {
                            notifier.setTriggerPrice(parsed);
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Expiry Date Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151922) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF232936) : const Color(0xFFCFD8DC),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expiry Date',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.gtcExpiry != null
                                      ? '${state.gtcExpiry!.day}/${state.gtcExpiry!.month}/${state.gtcExpiry!.year}'
                                      : 'Good till cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (state.gtcExpiry != null)
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFF03A9F4)),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      notifier.setGtcExpiry(null);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(right: 8),
                                  ),
                                IconButton(
                                  icon: const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF03A9F4)),
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().add(const Duration(days: 30)),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      notifier.setGtcExpiry(picked);
                                    }
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Market Mode SL/TP Controls
                    if (isMarket) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'SL/TP orders:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildInfoIcon('Automatic risk management orders to protect profit and cap loss.'),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildRadioItem(
                                label: 'At Price',
                                selected: isAtPrice,
                                onTap: () => notifier.setSltpMode('At Price'),
                                isDark: isDark,
                                fontSize: 11.5,
                              ),
                              const SizedBox(width: 4),
                              _buildRadioItem(
                                label: 'At Value',
                                selected: !isAtPrice,
                                onTap: () => notifier.setSltpMode('At Value'),
                                isDark: isDark,
                                fontSize: 11.5,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // S/L and T/P Stepper Input Columns
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'S/L',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    _buildInfoIcon('Stop Loss threshold.'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _SmoothStepperBox(
                                  controller: _slCtrl,
                                  hintText: isAtPrice ? 'Price' : 'Points',
                                  onMinus: () {
                                    final current = double.tryParse(_slCtrl.text) ?? 0.0;
                                    final updated = (current - 1.0) > 0 ? (current - 1.0) : 0.0;
                                    notifier.setSlPrice(updated);
                                  },
                                  onPlus: () {
                                    final current = double.tryParse(_slCtrl.text) ?? 0.0;
                                    notifier.setSlPrice(current + 1.0);
                                  },
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val) ?? 0.0;
                                    notifier.setSlPrice(parsed);
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'T/P',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    _buildInfoIcon('Take Profit target.'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _SmoothStepperBox(
                                  controller: _tpCtrl,
                                  hintText: isAtPrice ? 'Price' : 'Points',
                                  onMinus: () {
                                    final current = double.tryParse(_tpCtrl.text) ?? 0.0;
                                    final updated = (current - 1.0) > 0 ? (current - 1.0) : 0.0;
                                    notifier.setTpPrice(updated);
                                  },
                                  onPlus: () {
                                    final current = double.tryParse(_tpCtrl.text) ?? 0.0;
                                    notifier.setTpPrice(current + 1.0);
                                  },
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val) ?? 0.0;
                                    notifier.setTpPrice(parsed);
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Estimates Section (Placed Before Comment)
                    Row(
                      children: [
                        Text(
                          'Estimates',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        _buildInfoIcon('Live exchange margin and regulatory charges calculation.'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151922) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF232936) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildEstimateRow(
                            label: 'Est. Buy Margin:',
                            value: estBuyMargin.toStringAsFixed(2),
                            valueColor: const Color(0xFF0288D1),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 5),
                          _buildEstimateRow(
                            label: 'Est. Sell Margin:',
                            value: estSellMargin.toStringAsFixed(2),
                            valueColor: const Color(0xFFE91E63),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 5),
                          _buildEstimateRow(
                            label: 'Est. Brokerage & Taxes:',
                            value: estCharges.toStringAsFixed(2),
                            valueColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 5),
                          _buildEstimateRow(
                            label: 'Available Margin:',
                            value: availMargin.toStringAsFixed(2),
                            valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Comment Section (At the end)
                    Text(
                      'Comment',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Focus(
                      child: Builder(
                        builder: (context) {
                          final hasFocus = Focus.of(context).hasFocus;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF151922) : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: hasFocus
                                    ? const Color(0xFF2979FF)
                                    : (isDark ? const Color(0xFF232936) : const Color(0xFFCFD8DC)),
                                width: hasFocus ? 1.5 : 1,
                              ),
                              boxShadow: hasFocus
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: TextField(
                              controller: _commentCtrl,
                              maxLines: 2,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              cursorColor: const Color(0xFF2979FF),
                              decoration: InputDecoration(
                                hintText: 'Add a comment (optional)',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: notifier.setComment,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Direction Validation Banner if present
                    if (state.directionValidationError != null && state.directionValidationError!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: Text(
                          state.directionValidationError!,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Section: Edge-to-Edge Action Buttons
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10131A) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF232936) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Buttons: SELL (Red) & BUY (Navy Blue) or PLACE
                  if (isMarket)
                    Row(
                      children: [
                        // SELL (Red)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: Material(
                              color: const Color(0xFFEB2A53),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _onConfirmPlacement(context, TransactionType.SELL);
                                },
                                splashColor: Colors.white.withValues(alpha: 0.25),
                                highlightColor: Colors.black.withValues(alpha: 0.12),
                                child: Center(
                                  child: Text(
                                    'SELL',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // BUY (Navy Blue)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: Material(
                              color: const Color(0xFF1B357F),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _onConfirmPlacement(context, TransactionType.BUY);
                                },
                                splashColor: Colors.white.withValues(alpha: 0.25),
                                highlightColor: Colors.black.withValues(alpha: 0.12),
                                child: Center(
                                  child: Text(
                                    'BUY',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Material(
                        color: const Color(0xFFEB2A53),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            final side = state.pendingType.startsWith('Buy')
                                ? TransactionType.BUY
                                : TransactionType.SELL;
                            _onConfirmPlacement(context, side);
                          },
                          splashColor: Colors.white.withValues(alpha: 0.25),
                          highlightColor: Colors.black.withValues(alpha: 0.12),
                          child: Center(
                            child: Text(
                              'PLACE',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateRow({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoIcon(String message) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: GoogleFonts.inter(
        fontSize: 11.5,
        color: Colors.white,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(
          Icons.info_outline,
          size: 14,
          color: Color(0xFF03A9F4),
        ),
      ),
    );
  }

  Widget _buildRadioItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
    double fontSize = 12.5,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF1E88E5)
                      : (isDark ? const Color(0xFF5A6678) : const Color(0xFF90A4AE)),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  width: selected ? 7 : 0,
                  height: selected ? 7 : 0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dual Bid / Ask Box with Live Tick Color & Smooth Flash Animation
class _LiveBidAskBox extends StatefulWidget {
  final Quote? quote;
  final bool isDark;

  const _LiveBidAskBox({
    required this.quote,
    required this.isDark,
  });

  @override
  State<_LiveBidAskBox> createState() => _LiveBidAskBoxState();
}

class _LiveBidAskBoxState extends State<_LiveBidAskBox> {
  double? _prevBid;
  double? _prevAsk;
  int _bidTickDirection = 0; // 1 = up, -1 = down, 0 = neutral
  int _askTickDirection = 0; // 1 = up, -1 = down, 0 = neutral

  @override
  void didUpdateWidget(_LiveBidAskBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final curBid = widget.quote?.bid ?? widget.quote?.ltp ?? 0.0;
    final curAsk = widget.quote?.ask ?? widget.quote?.ltp ?? 0.0;

    if (_prevBid != null && curBid != _prevBid) {
      if (curBid > _prevBid!) {
        _bidTickDirection = 1;
      } else if (curBid < _prevBid!) {
        _bidTickDirection = -1;
      }
    } else if (_prevBid == null && widget.quote != null) {
      _bidTickDirection = widget.quote!.change >= 0 ? 1 : -1;
    }
    _prevBid = curBid;

    if (_prevAsk != null && curAsk != _prevAsk) {
      if (curAsk > _prevAsk!) {
        _askTickDirection = 1;
      } else if (curAsk < _prevAsk!) {
        _askTickDirection = -1;
      }
    } else if (_prevAsk == null && widget.quote != null) {
      _askTickDirection = widget.quote!.change >= 0 ? 1 : -1;
    }
    _prevAsk = curAsk;
  }

  @override
  Widget build(BuildContext context) {
    final ltp = widget.quote?.ltp ?? 0.0;
    final bid = widget.quote?.bid ?? ltp;
    final ask = widget.quote?.ask ?? ltp;

    final baseTextColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    const tickUpColor = Color(0xFF2979FF);
    const tickDownColor = Color(0xFFEB2A53);

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF151922) : Colors.white,
        border: Border.all(
          color: widget.isDark ? const Color(0xFF232936) : const Color(0xFFCFD8DC),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: widget.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Half: Bid
            Expanded(
              child: TweenAnimationBuilder<Color?>(
                key: ValueKey('bid_${bid}_$_bidTickDirection'),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                tween: ColorTween(
                  begin: _bidTickDirection > 0
                      ? tickUpColor.withValues(alpha: 0.15)
                      : (_bidTickDirection < 0 ? tickDownColor.withValues(alpha: 0.15) : Colors.transparent),
                  end: Colors.transparent,
                ),
                builder: (context, highlightBg, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: highlightBg,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bid',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0288D1),
                              ),
                            ),
                            if (_bidTickDirection != 0) ...[
                              const SizedBox(width: 3),
                              Icon(
                                _bidTickDirection > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                size: 14,
                                color: _bidTickDirection > 0 ? tickUpColor : tickDownColor,
                              ),
                            ],
                          ],
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              bid.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _bidTickDirection > 0
                                    ? tickUpColor
                                    : (_bidTickDirection < 0 ? tickDownColor : baseTextColor),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Vertical Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: widget.isDark ? const Color(0xFF232936) : const Color(0xFFCFD8DC),
            ),
            // Right Half: Ask
            Expanded(
              child: TweenAnimationBuilder<Color?>(
                key: ValueKey('ask_${ask}_$_askTickDirection'),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                tween: ColorTween(
                  begin: _askTickDirection > 0
                      ? tickUpColor.withValues(alpha: 0.15)
                      : (_askTickDirection < 0 ? tickDownColor.withValues(alpha: 0.15) : Colors.transparent),
                  end: Colors.transparent,
                ),
                builder: (context, highlightBg, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: highlightBg,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ask',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE91E63),
                              ),
                            ),
                            if (_askTickDirection != 0) ...[
                              const SizedBox(width: 3),
                              Icon(
                                _askTickDirection > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                size: 14,
                                color: _askTickDirection > 0 ? tickUpColor : tickDownColor,
                              ),
                            ],
                          ],
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              ask.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _askTickDirection > 0
                                    ? tickUpColor
                                    : (_askTickDirection < 0 ? tickDownColor : baseTextColor),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// Smooth Stepper Box with Focus Glow, Tactile Scale Buttons, and Tabular Figures
class _SmoothStepperBox extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool isDark;

  const _SmoothStepperBox({
    required this.controller,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
    this.hintText,
    required this.isDark,
  });

  @override
  State<_SmoothStepperBox> createState() => _SmoothStepperBoxState();
}

class _SmoothStepperBoxState extends State<_SmoothStepperBox> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _isFocused) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 40,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF151922) : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF2979FF)
              : (widget.isDark ? const Color(0xFF232936) : const Color(0xFFCFD8DC)),
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // Red Minus Circle Button with Tactile Scale
          _ScaleButton(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onMinus();
            },
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEB2A53),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEB2A53).withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.remove, color: Colors.white, size: 15),
              ),
            ),
          ),
          // Centered Text Input with Tabular Figures
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              cursorColor: const Color(0xFF2979FF),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: widget.hintText ?? '',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: widget.isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
          ),
          // Blue Plus Circle Button with Tactile Scale
          _ScaleButton(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onPlus();
            },
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2979FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile Scale Micro-Animation Wrapper
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
