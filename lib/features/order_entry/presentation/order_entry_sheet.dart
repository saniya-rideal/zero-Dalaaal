import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderEntrySheet(
          instrument: instrument,
          initialSide: side,
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

    _lotCtrl = TextEditingController(text: '1.00');
    _qtyCtrl = TextEditingController(text: '1');
    _slCtrl = TextEditingController();
    _tpCtrl = TextEditingController();
    _atPriceCtrl = TextEditingController();
    _commentCtrl = TextEditingController();
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
                await notifier.submitOrder(
                  context: context,
                  overrideSide: side,
                );
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1218) : Colors.white,
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
                      color: isDark ? Colors.white : Colors.black87,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showInstrumentPicker(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                state.instrument.name.isNotEmpty
                                    ? state.instrument.name
                                    : state.instrument.symbol,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
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

                    // Dual Bid / Ask Box with Live Tick Color (Blue on profit/up, Red on loss/down)
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
                                    color: isDark ? Colors.white : const Color(0xFF111827),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildInfoIcon(),
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
                    _buildStepperInputBox(
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
                    const SizedBox(height: 3),

                    // Subtitle Estimated Quantity
                    Text(
                      'Estimated Quantity: \u2248 ${isLotMode ? (state.lots * (state.instrument.lotSize > 0 ? state.instrument.lotSize : 1.0)).toStringAsFixed(2) : state.quantity.toString()}',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: isDark ? Colors.white54 : const Color(0xFF78909C),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pending Orders Controls (When Pending is selected)
                    if (!isMarket) ...[
                      // Pending type radio options: Buy Limit, Sell Limit, Buy Stop, Sell Stop
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
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
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          _buildInfoIcon(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildStepperInputBox(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1F2C) : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C3240) : const Color(0xFFCFD8DC),
                            width: 1,
                          ),
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
                                    color: isDark ? Colors.white : const Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.gtcExpiry != null
                                      ? '${state.gtcExpiry!.day}/${state.gtcExpiry!.month}/${state.gtcExpiry!.year}'
                                      : 'Good till cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF546E7A),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (state.gtcExpiry != null)
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFF03A9F4)),
                                    onPressed: () => notifier.setGtcExpiry(null),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(right: 6),
                                  ),
                                IconButton(
                                  icon: const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF03A9F4)),
                                  onPressed: () async {
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
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildInfoIcon(),
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
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                    _buildInfoIcon(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _buildStepperInputBox(
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
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                    _buildInfoIcon(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _buildStepperInputBox(
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

                    // Comment Section
                    Text(
                      'Comment',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1F2C) : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFCFD8DC),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: TextField(
                        controller: _commentCtrl,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: notifier.setComment,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Direction Validation Banner if present
                    if (state.directionValidationError != null && state.directionValidationError!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
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

            // Bottom Section: Margins Summary & Edge-to-Edge Action Buttons
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12151C) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2C3240) : const Color(0xFFECEFF1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Three-Row Margin Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Est. Buy Margin:',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0288D1),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              estBuyMargin.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0288D1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Est. Sell Margin:',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE91E63),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              estSellMargin.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE91E63),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Available Margin:',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF263238),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              availMargin.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF263238),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons: SELL (Red) & BUY (Navy Blue) or PLACE
                  if (isMarket)
                    Row(
                      children: [
                        // SELL (Red)
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEB2A53),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              onPressed: () => _onConfirmPlacement(context, TransactionType.SELL),
                              child: Text(
                                'SELL',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // BUY (Navy Blue)
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B357F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              onPressed: () => _onConfirmPlacement(context, TransactionType.BUY),
                              child: Text(
                                'BUY',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
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
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEB2A53),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () {
                          final side = state.pendingType.startsWith('Buy')
                              ? TransactionType.BUY
                              : TransactionType.SELL;
                          _onConfirmPlacement(context, side);
                        },
                        child: Text(
                          'PLACE',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
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

  Widget _buildInfoIcon() {
    return const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Icon(
        Icons.info_outline,
        size: 14,
        color: Color(0xFF03A9F4),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF1E88E5) : (isDark ? Colors.white54 : const Color(0xFF90A4AE)),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperInputBox({
    required TextEditingController controller,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required ValueChanged<String> onChanged,
    String? hintText,
    required bool isDark,
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2C) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFCFD8DC),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          // Red Minus Circle Button
          InkWell(
            onTap: onMinus,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB2A53),
              ),
              child: const Center(
                child: Icon(Icons.remove, color: Colors.white, size: 15),
              ),
            ),
          ),
          // Centered Text Input
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hintText ?? '',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
          // Blue Plus Circle Button
          InkWell(
            onTap: onPlus,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2979FF),
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

/// Dual Bid / Ask Box with Live Tick Color (Blue on tick up / profit, Red on tick down / loss)
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
  Color _bidColor = const Color(0xFF1976D2); // Blue default
  Color _askColor = const Color(0xFF1976D2); // Blue default

  @override
  void didUpdateWidget(_LiveBidAskBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final curBid = widget.quote?.bid ?? widget.quote?.ltp ?? 0.0;
    final curAsk = widget.quote?.ask ?? widget.quote?.ltp ?? 0.0;

    if (_prevBid != null && curBid != _prevBid) {
      if (curBid > _prevBid!) {
        _bidColor = const Color(0xFF1976D2); // Blue (tick up / profit)
      } else if (curBid < _prevBid!) {
        _bidColor = const Color(0xFFE53935); // Red (tick down / loss)
      }
    } else if (_prevBid == null && widget.quote != null) {
      _bidColor = (widget.quote!.change >= 0) ? const Color(0xFF1976D2) : const Color(0xFFE53935);
    }
    _prevBid = curBid;

    if (_prevAsk != null && curAsk != _prevAsk) {
      if (curAsk > _prevAsk!) {
        _askColor = const Color(0xFF1976D2); // Blue (tick up / profit)
      } else if (curAsk < _prevAsk!) {
        _askColor = const Color(0xFFE53935); // Red (tick down / loss)
      }
    } else if (_prevAsk == null && widget.quote != null) {
      _askColor = (widget.quote!.change >= 0) ? const Color(0xFF1976D2) : const Color(0xFFE53935);
    }
    _prevAsk = curAsk;
  }

  @override
  Widget build(BuildContext context) {
    final ltp = widget.quote?.ltp ?? 0.0;
    final bid = widget.quote?.bid ?? ltp;
    final ask = widget.quote?.ask ?? ltp;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1A1F2C) : Colors.white,
        border: Border.all(
          color: widget.isDark ? const Color(0xFF2C3240) : const Color(0xFFB0BEC5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Half: Bid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bid',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _bidColor,
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          bid.toStringAsFixed(2),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _bidColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Vertical Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: widget.isDark ? const Color(0xFF2C3240) : const Color(0xFFB0BEC5),
            ),
            // Right Half: Ask
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ask',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _askColor,
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          ask.toStringAsFixed(2),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _askColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
