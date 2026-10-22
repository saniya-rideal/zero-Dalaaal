import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/maintenance_service.dart';
import '../../../../core/services/realtime_quote_service.dart';
import '../../../../data/models/models.dart';
import '../../../funds/data/real_funds_repository.dart';
import '../../../orders/data/real_trading_repository.dart';
import '../../../profile_settings/data/settings_repository.dart';

class OrderEntryState {
  final Instrument instrument;
  final TransactionType side;
  final String orderCategory; // 'Market' or 'Pending'
  final String pendingType; // 'Buy Limit', 'Sell Limit', 'Buy Stop', 'Sell Stop', 'Stop-Limit'
  final String unitMode; // 'In Lot' or 'In Quantity'
  final double lots;
  final int quantity;
  final double limitPrice;
  final double triggerPrice;
  final String sltpMode; // 'At Price' or 'At Value'
  final double slPrice;
  final double tpPrice;
  final ProductType product;
  final Validity validity;
  final DateTime? gtcExpiry;
  final String comment;
  final double? selectedRiskPercent;

  final OrderPreview? preview;
  final bool isPreviewLoading;
  final String? previewError;

  final String? directionValidationError;
  final String? validationError;

  final bool isSubmitting;
  final String? submissionError;
  final Order? placedOrder;
  final String? lastIdempotencyKey;

  const OrderEntryState({
    required this.instrument,
    this.side = TransactionType.BUY,
    this.orderCategory = 'Market',
    this.pendingType = 'Buy Limit',
    this.unitMode = 'In Lot',
    this.lots = 1.0,
    this.quantity = 1,
    this.limitPrice = 0.0,
    this.triggerPrice = 0.0,
    this.sltpMode = 'At Price',
    this.slPrice = 0.0,
    this.tpPrice = 0.0,
    this.product = ProductType.MIS,
    this.validity = Validity.DAY,
    this.gtcExpiry,
    this.comment = '',
    this.selectedRiskPercent,
    this.preview,
    this.isPreviewLoading = false,
    this.previewError,
    this.directionValidationError,
    this.validationError,
    this.isSubmitting = false,
    this.submissionError,
    this.placedOrder,
    this.lastIdempotencyKey,
  });

  OrderEntryState copyWith({
    Instrument? instrument,
    TransactionType? side,
    String? orderCategory,
    String? pendingType,
    String? unitMode,
    double? lots,
    int? quantity,
    double? limitPrice,
    double? triggerPrice,
    String? sltpMode,
    double? slPrice,
    double? tpPrice,
    ProductType? product,
    Validity? validity,
    DateTime? gtcExpiry,
    String? comment,
    double? selectedRiskPercent,
    OrderPreview? preview,
    bool? isPreviewLoading,
    String? previewError,
    String? directionValidationError,
    String? validationError,
    bool? isSubmitting,
    String? submissionError,
    Order? placedOrder,
    String? lastIdempotencyKey,
  }) {
    return OrderEntryState(
      instrument: instrument ?? this.instrument,
      side: side ?? this.side,
      orderCategory: orderCategory ?? this.orderCategory,
      pendingType: pendingType ?? this.pendingType,
      unitMode: unitMode ?? this.unitMode,
      lots: lots ?? this.lots,
      quantity: quantity ?? this.quantity,
      limitPrice: limitPrice ?? this.limitPrice,
      triggerPrice: triggerPrice ?? this.triggerPrice,
      sltpMode: sltpMode ?? this.sltpMode,
      slPrice: slPrice ?? this.slPrice,
      tpPrice: tpPrice ?? this.tpPrice,
      product: product ?? this.product,
      validity: validity ?? this.validity,
      gtcExpiry: gtcExpiry ?? this.gtcExpiry,
      comment: comment ?? this.comment,
      selectedRiskPercent: selectedRiskPercent ?? this.selectedRiskPercent,
      preview: preview ?? this.preview,
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      previewError: previewError,
      directionValidationError: directionValidationError,
      validationError: validationError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: submissionError,
      placedOrder: placedOrder ?? this.placedOrder,
      lastIdempotencyKey: lastIdempotencyKey ?? this.lastIdempotencyKey,
    );
  }

  OrderKind get effectiveOrderKind {
    if (orderCategory == 'Market') {
      return OrderKind.MARKET;
    }
    switch (pendingType) {
      case 'Buy Limit':
      case 'Sell Limit':
        return OrderKind.LIMIT;
      case 'Buy Stop':
      case 'Sell Stop':
        return OrderKind.STOP;
      case 'Stop-Limit':
      default:
        return OrderKind.STOP_LIMIT;
    }
  }

  bool get isMarketOrder => orderCategory == 'Market';
  bool get isPendingOrder => orderCategory == 'Pending';

  bool get canPlaceOrder {
    if (isSubmitting) return false;
    if (directionValidationError != null && directionValidationError!.isNotEmpty) return false;
    if (validationError != null && validationError!.isNotEmpty) return false;
    if (preview != null && !preview!.canPlace) return false;
    return true;
  }

  String? get blockingReason {
    if (directionValidationError != null && directionValidationError!.isNotEmpty) {
      return directionValidationError;
    }
    if (validationError != null && validationError!.isNotEmpty) {
      return validationError;
    }
    if (preview != null && !preview!.canPlace) {
      return preview!.blockingReason ?? 'Order cannot be placed (Insufficient margin)';
    }
    return null;
  }
}

class OrderEntryController extends StateNotifier<OrderEntryState> {
  final Ref _ref;
  Timer? _debounceTimer;

  OrderEntryController(this._ref, Instrument initialInstrument, TransactionType initialSide)
      : super(
          () {
            final initLots = _resolveInitialLots(_ref);
            return OrderEntryState(
              instrument: initialInstrument,
              side: initialSide,
              product: _resolveDefaultProduct(initialInstrument),
              lots: initLots,
              quantity: _computeInitialQuantity(initialInstrument, initLots),
            );
          }(),
        ) {
    _initQuoteWatcher();
    schedulePreviewDebounce();
  }

  static double _resolveInitialLots(Ref ref) {
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final dl = settingsRepo.settings.defaultLots;
      if (dl > 0) return dl;
    } catch (_) {}
    return 1.0;
  }

  static ProductType _resolveDefaultProduct(Instrument inst) {
    final prods = inst.effectiveAllowedProducts;
    if (prods.isEmpty) return ProductType.MIS;
    return prods.first;
  }

  static int _computeInitialQuantity(Instrument inst, double lots) {
    final lot = inst.lotSize > 0 ? inst.lotSize : 1.0;
    final calculated = (lots * lot).round();
    final minQ = inst.minQuantity > 0 ? inst.minQuantity : 1;
    return calculated < minQ ? minQ : calculated;
  }

  void _initQuoteWatcher() {
    // Validate directions live whenever quotes tick
    _ref.listen<AsyncValue<Quote>>(quoteDetailStreamProvider(state.instrument.symbol), (prev, next) {
      final q = next.value;
      if (q != null) {
        validateDirection(q);
      }
    });
  }

  void setInstrument(Instrument instrument) {
    final defaultProd = _resolveDefaultProduct(instrument);
    final qty = _computeInitialQuantity(instrument, state.lots);
    state = state.copyWith(
      instrument: instrument,
      product: defaultProd,
      quantity: qty,
      limitPrice: 0.0,
      triggerPrice: 0.0,
      slPrice: 0.0,
      tpPrice: 0.0,
    );
    final quote = _ref.read(quoteDetailStreamProvider(instrument.symbol)).value;
    validateDirection(quote);
    schedulePreviewDebounce();
  }

  void setSide(TransactionType side) {
    if (state.side == side) return;
    state = state.copyWith(side: side);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
    schedulePreviewDebounce();
  }

  void setOrderCategory(String category) {
    state = state.copyWith(orderCategory: category);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
    schedulePreviewDebounce();
  }

  void setPendingType(String type) {
    TransactionType derivedSide = state.side;
    if (type.startsWith('Buy')) {
      derivedSide = TransactionType.BUY;
    } else if (type.startsWith('Sell')) {
      derivedSide = TransactionType.SELL;
    }
    state = state.copyWith(pendingType: type, side: derivedSide);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
    schedulePreviewDebounce();
  }

  void setUnitMode(String mode) {
    state = state.copyWith(unitMode: mode);
    schedulePreviewDebounce();
  }

  void setLots(double lots) {
    final cleanLots = lots > 0 ? lots : 0.01;
    final lotSize = state.instrument.lotSize > 0 ? state.instrument.lotSize : 1.0;
    final qty = (cleanLots * lotSize).round().clamp(state.instrument.minQuantity, state.instrument.freezeQty);
    state = state.copyWith(lots: cleanLots, quantity: qty);
    schedulePreviewDebounce();
  }

  void stepLots(bool increment) {
    final step = state.instrument.lotSize >= 1.0 ? 1.0 : 0.1;
    final newLots = increment ? (state.lots + step) : (state.lots - step);
    if (newLots > 0) {
      setLots(double.parse(newLots.toStringAsFixed(2)));
    }
  }

  void setQuantity(int qty) {
    final minQ = state.instrument.minQuantity > 0 ? state.instrument.minQuantity : 1;
    final maxQ = state.instrument.freezeQty > 0 ? state.instrument.freezeQty : 1000000;
    final cleanQty = qty.clamp(minQ, maxQ);
    final lotSize = state.instrument.lotSize > 0 ? state.instrument.lotSize : 1.0;
    final lots = double.parse((cleanQty / lotSize).toStringAsFixed(2));
    state = state.copyWith(quantity: cleanQty, lots: lots > 0 ? lots : 1.0);
    schedulePreviewDebounce();
  }

  void stepQuantity(bool increment) {
    final step = state.instrument.quantityStep > 0 ? state.instrument.quantityStep : 1;
    final newQty = increment ? (state.quantity + step) : (state.quantity - step);
    setQuantity(newQty);
  }

  void setLimitPrice(double price) {
    state = state.copyWith(limitPrice: price);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
    schedulePreviewDebounce();
  }

  void stepLimitPrice(bool increment) {
    final tick = state.instrument.tickSize > 0 ? state.instrument.tickSize : 0.05;
    double current = state.limitPrice;
    if (current <= 0) {
      final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
      current = quote?.ltp ?? 100.0;
    }
    final newPrice = increment ? (current + tick) : (current - tick);
    if (newPrice > 0) {
      setLimitPrice(double.parse(newPrice.toStringAsFixed(2)));
    }
  }

  void setTriggerPrice(double price) {
    state = state.copyWith(triggerPrice: price);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
    schedulePreviewDebounce();
  }

  void stepTriggerPrice(bool increment) {
    final tick = state.instrument.tickSize > 0 ? state.instrument.tickSize : 0.05;
    double current = state.triggerPrice;
    if (current <= 0) {
      final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
      current = quote?.ltp ?? 100.0;
    }
    final newPrice = increment ? (current + tick) : (current - tick);
    if (newPrice > 0) {
      setTriggerPrice(double.parse(newPrice.toStringAsFixed(2)));
    }
  }

  void useCurrentPriceForLimit() {
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    if (quote != null) {
      final price = state.side == TransactionType.BUY ? (quote.ask ?? quote.ltp) : (quote.bid ?? quote.ltp);
      setLimitPrice(price);
    }
  }

  void useCurrentPriceForTrigger() {
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    if (quote != null) {
      final price = state.side == TransactionType.BUY ? (quote.ask ?? quote.ltp) : (quote.bid ?? quote.ltp);
      setTriggerPrice(price);
    }
  }

  void setProduct(ProductType product) {
    state = state.copyWith(product: product);
    schedulePreviewDebounce();
  }

  void setValidity(Validity validity) {
    state = state.copyWith(validity: validity);
    schedulePreviewDebounce();
  }

  void setGtcExpiry(DateTime? expiry) {
    state = state.copyWith(gtcExpiry: expiry);
  }

  void setComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  void setSltpMode(String mode) {
    state = state.copyWith(sltpMode: mode);
  }

  void setSlPrice(double price) {
    state = state.copyWith(slPrice: price);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
  }

  void clearSl() {
    state = state.copyWith(slPrice: 0.0);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
  }

  void setTpPrice(double price) {
    state = state.copyWith(tpPrice: price);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
  }

  void clearTp() {
    state = state.copyWith(tpPrice: 0.0);
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);
  }

  /// Suggests lot size / quantity based on user risk % of available margin and SL distance
  void applyRiskPercent(double percent, double availableMargin) {
    if (percent <= 0 || availableMargin <= 0 || state.slPrice <= 0) return;
    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    final entryPrice = state.isMarketOrder
        ? (state.side == TransactionType.BUY ? (quote?.ask ?? quote?.ltp ?? 0.0) : (quote?.bid ?? quote?.ltp ?? 0.0))
        : (state.limitPrice > 0 ? state.limitPrice : state.triggerPrice);

    final slDistance = (entryPrice - state.slPrice).abs();
    if (slDistance <= 0) return;

    final riskAmount = availableMargin * (percent / 100.0);
    final contractMultiplier = state.instrument.contractMultiplier;
    final suggestedQty = (riskAmount / (slDistance * contractMultiplier)).floor();

    if (suggestedQty >= state.instrument.minQuantity) {
      state = state.copyWith(selectedRiskPercent: percent);
      setQuantity(suggestedQty);
    }
  }

  /// Live validation of price direction per MT5 / Indian market exchange invariants
  void validateDirection(Quote? quote) {
    String? dirError;
    String? generalError;

    if (!state.instrument.tradingEnabled || state.instrument.isSuspended) {
      generalError = state.instrument.suspensionReason ?? 'Trading is currently suspended for this symbol';
    }

    if (quote == null || quote.ltp <= 0) {
      state = state.copyWith(
        directionValidationError: dirError,
        validationError: generalError,
      );
      return;
    }

    final ltp = quote.ltp;
    final bid = quote.bid ?? ltp;
    final ask = quote.ask ?? ltp;

    // Requirement B.2: If quote has no bid/ask, block market orders
    if (state.isMarketOrder && !quote.hasBidAsk) {
      generalError = 'No market liquidity (Bid/Ask quote depth unavailable). Use limit order.';
    }

    if (state.isPendingOrder) {
      switch (state.pendingType) {
        case 'Buy Limit':
          if (state.limitPrice <= 0) {
            dirError = 'Please specify limit price for Buy Limit';
          } else if (state.limitPrice >= ask) {
            dirError = 'Buy Limit price (₹${state.limitPrice.toStringAsFixed(2)}) must be below current ask (₹${ask.toStringAsFixed(2)})';
          }
          break;
        case 'Sell Limit':
          if (state.limitPrice <= 0) {
            dirError = 'Please specify limit price for Sell Limit';
          } else if (state.limitPrice <= bid) {
            dirError = 'Sell Limit price (₹${state.limitPrice.toStringAsFixed(2)}) must be above current bid (₹${bid.toStringAsFixed(2)})';
          }
          break;
        case 'Buy Stop':
          if (state.triggerPrice <= 0) {
            dirError = 'Please specify trigger price for Buy Stop';
          } else if (state.triggerPrice <= ask) {
            dirError = 'Buy Stop trigger (₹${state.triggerPrice.toStringAsFixed(2)}) must be above current ask (₹${ask.toStringAsFixed(2)})';
          }
          break;
        case 'Sell Stop':
          if (state.triggerPrice <= 0) {
            dirError = 'Please specify trigger price for Sell Stop';
          } else if (state.triggerPrice >= bid) {
            dirError = 'Sell Stop trigger (₹${state.triggerPrice.toStringAsFixed(2)}) must be below current bid (₹${bid.toStringAsFixed(2)})';
          }
          break;
        case 'Stop-Limit':
          if (state.triggerPrice <= 0 || state.limitPrice <= 0) {
            dirError = 'Specify both trigger price and limit price for Stop-Limit';
          } else if (state.side == TransactionType.BUY && state.triggerPrice <= ask) {
            dirError = 'Buy Stop-Limit trigger must be above current ask (₹${ask.toStringAsFixed(2)})';
          } else if (state.side == TransactionType.SELL && state.triggerPrice >= bid) {
            dirError = 'Sell Stop-Limit trigger must be below current bid (₹${bid.toStringAsFixed(2)})';
          }
          break;
      }
    }

    // Stop Loss direction validation
    if (state.slPrice > 0) {
      final basePrice = state.isMarketOrder
          ? (state.side == TransactionType.BUY ? ask : bid)
          : (state.limitPrice > 0 ? state.limitPrice : state.triggerPrice);

      if (state.side == TransactionType.BUY && state.slPrice >= basePrice) {
        dirError = 'Stop Loss for BUY must be lower than execution price (₹${basePrice.toStringAsFixed(2)})';
      } else if (state.side == TransactionType.SELL && state.slPrice <= basePrice) {
        dirError = 'Stop Loss for SELL must be higher than execution price (₹${basePrice.toStringAsFixed(2)})';
      }
    }

    // Take Profit direction validation
    if (state.tpPrice > 0) {
      final basePrice = state.isMarketOrder
          ? (state.side == TransactionType.BUY ? ask : bid)
          : (state.limitPrice > 0 ? state.limitPrice : state.triggerPrice);

      if (state.side == TransactionType.BUY && state.tpPrice <= basePrice) {
        dirError = 'Take Profit for BUY must be higher than execution price (₹${basePrice.toStringAsFixed(2)})';
      } else if (state.side == TransactionType.SELL && state.tpPrice >= basePrice) {
        dirError = 'Take Profit for SELL must be lower than execution price (₹${basePrice.toStringAsFixed(2)})';
      }
    }

    state = state.copyWith(
      directionValidationError: dirError,
      validationError: generalError,
    );
  }

  /// Debounces calls to POST /api/orders/preview (~400ms)
  void schedulePreviewDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      fetchOrderPreview();
    });
  }

  Future<void> fetchOrderPreview() async {
    if (!mounted) return;
    try {
      state = state.copyWith(isPreviewLoading: true, previewError: null);

      final req = OrderPreviewRequest(
        symbol: state.instrument.symbol,
        side: state.side,
        orderType: state.effectiveOrderKind,
        quantity: state.quantity,
        limitPrice: state.limitPrice > 0 ? state.limitPrice : null,
        triggerPrice: state.triggerPrice > 0 ? state.triggerPrice : null,
        leverage: state.instrument.defaultLeverage > 0 ? state.instrument.defaultLeverage : null,
        product: state.product,
        validity: state.validity,
      );

      final tradingRepo = _ref.read(tradingRepositoryProvider);
      final preview = await tradingRepo.previewOrder(req);

      if (mounted) {
        state = state.copyWith(
          preview: preview,
          isPreviewLoading: false,
          previewError: null,
        );
      }
    } catch (e) {
      if (mounted) {
        // Tolerant fallback: compute preview from funds summary if preview endpoint temporarily fails
        final fundsSummary = _ref.read(fundsSummaryProvider).value;
        final avail = fundsSummary?.availableCash ?? 100000.0;
        final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
        final price = state.limitPrice > 0 ? state.limitPrice : (quote?.ltp ?? 100.0);
        final lev = state.instrument.defaultLeverage > 0 ? state.instrument.defaultLeverage : 1.0;
        final reqMargin = (price * state.quantity * state.instrument.contractMultiplier) / lev;
        final charges = ChargesBreakdown(
          brokerage: 20.0,
          stt: price * state.quantity * 0.00025,
          exchangeTxnCharge: price * state.quantity * 0.00003,
          gst: 4.0,
          sebiCharges: 0.1,
          stampDuty: 1.5,
        );

        final localPreview = OrderPreview(
          requiredMargin: reqMargin,
          availableMargin: avail,
          marginAfterTrade: avail - reqMargin - charges.total,
          charges: charges,
          canPlace: avail >= (reqMargin + charges.total),
          blockingReason: avail < (reqMargin + charges.total) ? 'Insufficient available margin' : null,
          executionPrice: price,
        );

        state = state.copyWith(
          preview: localPreview,
          isPreviewLoading: false,
          previewError: e.toString(),
        );
      }
    }
  }

  String generateIdempotencyKey(TransactionType side) {
    final sym = state.instrument.symbol.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final execPrice = state.limitPrice > 0 ? state.limitPrice : state.triggerPrice;
    final signature = '${sym}_${side.name}_${state.quantity}_${execPrice.toStringAsFixed(2)}_${state.slPrice.toStringAsFixed(2)}_${state.tpPrice.toStringAsFixed(2)}_${state.effectiveOrderKind.name}_${state.validity.name}';
    return 'ord_${signature.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<Order?> submitOrder({
    required BuildContext context,
    TransactionType? overrideSide,
  }) async {
    if (state.isSubmitting) return null;

    final targetSide = overrideSide ?? state.side;

    // Pre-flight checks
    final isOnline = _ref.read(connectivityServiceProvider) == NetworkStatus.online;
    if (!isOnline) {
      state = state.copyWith(submissionError: 'No network connection. Order placement aborted.');
      return null;
    }

    final isMaint = _ref.read(maintenanceServiceProvider).isMaintenanceActive;
    if (isMaint) {
      state = state.copyWith(submissionError: 'Trading system is under scheduled maintenance.');
      return null;
    }

    final quote = _ref.read(quoteDetailStreamProvider(state.instrument.symbol)).value;
    validateDirection(quote);

    if (state.directionValidationError != null) {
      state = state.copyWith(submissionError: state.directionValidationError);
      return null;
    }

    state = state.copyWith(isSubmitting: true, submissionError: null);

    try {
      final idempotencyKey = state.lastIdempotencyKey ?? generateIdempotencyKey(targetSide);
      state = state.copyWith(lastIdempotencyKey: idempotencyKey);

      final bracket = (state.slPrice > 0 || state.tpPrice > 0)
          ? BracketParams(
              stopLoss: state.slPrice,
              target: state.tpPrice,
            )
          : null;

      final request = OrderRequest(
        instrumentToken: state.instrument.symbol,
        side: targetSide,
        product: state.product,
        kind: state.effectiveOrderKind,
        quantity: state.quantity,
        price: state.limitPrice > 0 ? state.limitPrice : null,
        triggerPrice: state.triggerPrice > 0 ? state.triggerPrice : null,
        validity: state.validity,
        bracket: bracket,
        idempotencyKey: idempotencyKey,
        leverage: state.instrument.defaultLeverage > 0 ? state.instrument.defaultLeverage : null,
        market: state.instrument.market,
        expiresAt: state.validity == Validity.GTC ? state.gtcExpiry : null,
        comment: state.comment.isNotEmpty ? state.comment : null,
      );

      final tradingRepo = _ref.read(tradingRepositoryProvider);
      final order = await tradingRepo.placeOrder(request);

      // Refresh orders, positions, and funds state
      _ref.invalidate(ordersProvider);
      _ref.invalidate(positionsProvider);
      _ref.invalidate(fundsSummaryProvider);

      state = state.copyWith(
        isSubmitting: false,
        placedOrder: order,
        submissionError: null,
      );

      return order;
    } on AppException catch (e) {
      final mappedMessage = _mapBackendErrorCode(e);
      state = state.copyWith(
        isSubmitting: false,
        submissionError: mappedMessage,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  String _mapBackendErrorCode(AppException e) {
    switch (e.code) {
      case 'INVALID_TRIGGER_DIRECTION':
        return 'Invalid trigger price direction relative to live market spread.';
      case 'MARKET_CLOSED':
        return 'The exchange is currently closed. Order placement is restricted.';
      case 'INSUFFICIENT_MARGIN':
        return 'Insufficient available margin in wallet for this order.';
      case 'TRADING_DISABLED':
        return 'Trading is currently suspended or disabled for this security.';
      case 'INVALID_QUANTITY':
        return 'Order quantity does not conform to the lot size or quantity step.';
      case 'INVALID_LIMIT_PRICE':
        return 'Order price must fall on an exact exchange tick size interval.';
      default:
        return e.message;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final orderEntryControllerProvider = StateNotifierProvider.autoDispose
    .family<OrderEntryController, OrderEntryState, ({Instrument instrument, TransactionType initialSide})>(
  (ref, params) {
    return OrderEntryController(ref, params.instrument, params.initialSide);
  },
);
