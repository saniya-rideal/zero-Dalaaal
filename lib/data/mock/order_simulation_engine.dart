import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/charges_config.dart';
import '../models/models.dart';
import 'seed_instruments.dart';
import 'ticker_service.dart';

class OrderSimulationEngine {
  final Ref _ref;
  final List<Order> _orders = [];
  final List<Position> _positions = [];
  final List<Holding> _holdings = [];
  final List<LedgerEntry> _ledger = [];
  final List<GttOrder> _gtts = [];
  
  double _availableEquityMargin = 250000.0;
  double _usedEquityMargin = 0.0;
  final double _openingEquityBalance = 250000.0;

  final StreamController<List<Order>> _ordersStreamController = StreamController.broadcast();
  final StreamController<List<Position>> _positionsStreamController = StreamController.broadcast();
  final StreamController<List<Holding>> _holdingsStreamController = StreamController.broadcast();
  final StreamController<List<GttOrder>> _gttStreamController = StreamController.broadcast();

  final _uuid = const Uuid();

  OrderSimulationEngine(this._ref) {
    _seedInitialData();
  }

  void _seedInitialData() {
    // Seed initial holdings (Kite demo style)
    final rel = SeedInstruments.findByToken('eq_reliance')!;
    final tcs = SeedInstruments.findByToken('eq_tcs')!;
    final hdfc = SeedInstruments.findByToken('eq_hdfcbank')!;
    final infy = SeedInstruments.findByToken('eq_infy')!;
    final itc = SeedInstruments.findByToken('eq_itc')!;
    final tata = SeedInstruments.findByToken('eq_tatamotors')!;

    _holdings.addAll([
      Holding(
        instrument: rel,
        quantity: 25,
        t1Quantity: 0,
        averagePrice: 2840.00,
        ltp: 2985.50,
        closePrice: 2950.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Holding(
        instrument: tcs,
        quantity: 15,
        t1Quantity: 5,
        averagePrice: 3950.00,
        ltp: 4215.00,
        closePrice: 4180.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 240)),
      ),
      Holding(
        instrument: hdfc,
        quantity: 50,
        t1Quantity: 0,
        averagePrice: 1580.00,
        ltp: 1648.20,
        closePrice: 1635.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Holding(
        instrument: infy,
        quantity: 40,
        t1Quantity: 0,
        averagePrice: 1720.00,
        ltp: 1885.30,
        closePrice: 1860.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Holding(
        instrument: itc,
        quantity: 100,
        t1Quantity: 0,
        averagePrice: 440.00,
        ltp: 502.40,
        closePrice: 498.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 300)),
      ),
      Holding(
        instrument: tata,
        quantity: 30,
        t1Quantity: 0,
        averagePrice: 940.00,
        ltp: 1085.00,
        closePrice: 1070.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ]);

    // Initial Ledger Entry
    _ledger.add(LedgerEntry(
      id: _uuid.v4(),
      date: DateTime.now().subtract(const Duration(days: 3)),
      narration: 'Funds added via UPI (Ref: UPI/4938210)',
      credit: 250000.0,
      debit: 0.0,
      runningBalance: 250000.0,
    ));

    // Seed an initial executed order and a day position
    final sbin = SeedInstruments.findByToken('eq_sbin')!;
    final sbinCharges = ChargesConfig.calculateCharges(
      price: 810.0,
      quantity: 50,
      side: TransactionType.BUY,
      product: ProductType.MIS,
      instrumentType: InstrumentType.EQ,
    );

    final seedOrder = Order(
      orderId: 'ZD-${DateTime.now().millisecondsSinceEpoch}',
      exchangeOrderId: 'NSE-${1000000000 + _orders.length}',
      instrument: sbin,
      request: const OrderRequest(
        instrumentToken: 'eq_sbin',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 50,
      ),
      status: OrderStatus.COMPLETE,
      filledQty: 50,
      averagePrice: 810.00,
      placedAt: DateTime.now().subtract(const Duration(hours: 1)),
      timeline: [
        OrderEvent(status: OrderStatus.OPEN, description: 'Order submitted to exchange', at: DateTime.now().subtract(const Duration(hours: 1, seconds: 1))),
        OrderEvent(status: OrderStatus.COMPLETE, description: 'Traded at 810.00', at: DateTime.now().subtract(const Duration(hours: 1))),
      ],
      charges: sbinCharges,
    );
    _orders.add(seedOrder);

    _positions.add(Position(
      id: 'pos_eq_sbin',
      instrument: sbin,
      product: ProductType.MIS,
      buyQty: 50,
      sellQty: 0,
      netQty: 50,
      buyAvg: 810.00,
      sellAvg: 0.0,
      ltp: 815.20,
      realizedPnl: 0.0,
      unrealizedPnl: 260.00, // (815.20 - 810.00) * 50
    ));
  }

  // Getters
  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get pendingOrders => _orders.where((o) => o.status == OrderStatus.OPEN || o.status == OrderStatus.TRIGGER_PENDING).toList();
  List<Order> get executedOrders => _orders.where((o) => o.status == OrderStatus.COMPLETE || o.status == OrderStatus.CANCELLED || o.status == OrderStatus.REJECTED).toList();
  List<Position> get positions => List.unmodifiable(_positions);
  List<Holding> get holdings => List.unmodifiable(_holdings);
  List<GttOrder> get gtts => List.unmodifiable(_gtts);
  List<LedgerEntry> get ledger => List.unmodifiable(_ledger);
  
  FundsSummary getFundsSummary(Segment segment) {
    return FundsSummary(
      segment: segment,
      availableMargin: _availableEquityMargin,
      usedMargin: _usedEquityMargin,
      openingBalance: _openingEquityBalance,
    );
  }

  // Streams
  Stream<List<Order>> get ordersStream => _ordersStreamController.stream;
  Stream<List<Position>> get positionsStream => _positionsStreamController.stream;
  Stream<List<Holding>> get holdingsStream => _holdingsStreamController.stream;
  Stream<List<GttOrder>> get gttStream => _gttStreamController.stream;

  // Order Placement
  Future<Order> placeOrder(OrderRequest request) async {
    final tickerService = _ref.read(tickerServiceProvider);
    final instrument = SeedInstruments.findByToken(request.instrumentToken) ??
        const Instrument(token: 'unknown', symbol: 'UNKNOWN', name: 'Unknown', exchange: Exchange.NSE, type: InstrumentType.EQ);
    
    final currentQuote = tickerService.getQuote(request.instrumentToken);
    final execPrice = request.kind == OrderKind.MARKET ? currentQuote.ltp : (request.price ?? currentQuote.ltp);

    final charges = ChargesConfig.calculateCharges(
      price: execPrice,
      quantity: request.quantity,
      side: request.side,
      product: request.product,
      instrumentType: instrument.type,
    );

    final orderId = 'ZD-${DateTime.now().millisecondsSinceEpoch}';
    final exchangeOrderId = 'NSE-${2000000000 + _orders.length}';

    // Market Orders fill after ~800ms
    final isMarket = request.kind == OrderKind.MARKET;
    final initialStatus = isMarket ? OrderStatus.OPEN : OrderStatus.OPEN;

    final newOrder = Order(
      orderId: orderId,
      exchangeOrderId: exchangeOrderId,
      instrument: instrument,
      request: request,
      status: initialStatus,
      filledQty: 0,
      averagePrice: 0.0,
      placedAt: DateTime.now(),
      timeline: [
        OrderEvent(status: OrderStatus.OPEN, description: 'Order received and sent to exchange', at: DateTime.now()),
      ],
      charges: charges,
    );

    _orders.insert(0, newOrder);
    _ordersStreamController.add(List.unmodifiable(_orders));

    if (isMarket) {
      // Simulate asynchronous execution
      Future.delayed(const Duration(milliseconds: 750), () {
        _executeOrder(orderId, execPrice, request.quantity);
      });
    }

    return newOrder;
  }

  void _executeOrder(String orderId, double price, int qty) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;

    final existing = _orders[index];
    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(
        status: OrderStatus.COMPLETE,
        description: 'Filled $qty qty @ ₹$price',
        at: DateTime.now(),
      ));

    final completedOrder = existing.copyWith(
      status: OrderStatus.COMPLETE,
      filledQty: qty,
      averagePrice: price,
      timeline: updatedTimeline,
    );

    _orders[index] = completedOrder;
    _ordersStreamController.add(List.unmodifiable(_orders));

    // Update Positions / Holdings / Margin
    _applyFill(completedOrder);
  }

  void _applyFill(Order order) {
    final instrument = order.instrument;
    final side = order.request.side;
    final qty = order.filledQty;
    final price = order.averagePrice;
    final product = order.request.product;

    if (product == ProductType.MIS || product == ProductType.NRML) {
      // Positions
      final posIndex = _positions.indexWhere((p) => p.instrument.token == instrument.token && p.product == product);
      if (posIndex == -1) {
        _positions.insert(0, Position(
          id: 'pos_${instrument.token}',
          instrument: instrument,
          product: product,
          buyQty: side == TransactionType.BUY ? qty : 0,
          sellQty: side == TransactionType.SELL ? qty : 0,
          netQty: side == TransactionType.BUY ? qty : -qty,
          buyAvg: side == TransactionType.BUY ? price : 0.0,
          sellAvg: side == TransactionType.SELL ? price : 0.0,
          ltp: price,
          realizedPnl: 0.0,
          unrealizedPnl: 0.0,
        ));
      } else {
        final cur = _positions[posIndex];
        final newBuyQty = cur.buyQty + (side == TransactionType.BUY ? qty : 0);
        final newSellQty = cur.sellQty + (side == TransactionType.SELL ? qty : 0);
        final newNetQty = cur.netQty + (side == TransactionType.BUY ? qty : -qty);
        final newBuyAvg = side == TransactionType.BUY
            ? ((cur.buyAvg * cur.buyQty) + (price * qty)) / newBuyQty
            : cur.buyAvg;
        final newSellAvg = side == TransactionType.SELL
            ? ((cur.sellAvg * cur.sellQty) + (price * qty)) / newSellQty
            : cur.sellAvg;

        _positions[posIndex] = cur.copyWith(
          buyQty: newBuyQty,
          sellQty: newSellQty,
          netQty: newNetQty,
          buyAvg: newBuyAvg,
          sellAvg: newSellAvg,
        );
      }
      _positionsStreamController.add(List.unmodifiable(_positions));
    } else if (product == ProductType.CNC) {
      // CNC modifies holdings
      final holdIndex = _holdings.indexWhere((h) => h.instrument.token == instrument.token);
      if (side == TransactionType.BUY) {
        if (holdIndex == -1) {
          _holdings.insert(0, Holding(
            instrument: instrument,
            quantity: qty,
            averagePrice: price,
            ltp: price,
            closePrice: price,
            firstBuyDate: DateTime.now(),
          ));
        } else {
          final cur = _holdings[holdIndex];
          final totalQty = cur.quantity + qty;
          final newAvg = ((cur.averagePrice * cur.quantity) + (price * qty)) / totalQty;
          _holdings[holdIndex] = cur.copyWith(
            quantity: totalQty,
            averagePrice: newAvg,
          );
        }
      } else {
        // Sell CNC
        if (holdIndex != -1) {
          final cur = _holdings[holdIndex];
          final remQty = cur.quantity - qty;
          if (remQty <= 0) {
            _holdings.removeAt(holdIndex);
          } else {
            _holdings[holdIndex] = cur.copyWith(quantity: remQty);
          }
        }
      }
      _holdingsStreamController.add(List.unmodifiable(_holdings));
    }

    // Deduct/Add margin & ledger entry
    final totalTradeValue = price * qty;
    if (side == TransactionType.BUY) {
      _availableEquityMargin -= totalTradeValue;
      _usedEquityMargin += totalTradeValue;
    } else {
      _availableEquityMargin += totalTradeValue;
      _usedEquityMargin = (_usedEquityMargin - totalTradeValue).clamp(0.0, double.infinity);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;

    final existing = _orders[index];
    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(
        status: OrderStatus.CANCELLED,
        description: 'Cancelled by client',
        at: DateTime.now(),
      ));

    _orders[index] = existing.copyWith(
      status: OrderStatus.CANCELLED,
      timeline: updatedTimeline,
    );
    _ordersStreamController.add(List.unmodifiable(_orders));
  }

  Future<void> modifyOrder(String orderId, OrderRequest updatedReq) async {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;

    final existing = _orders[index];
    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(
        status: OrderStatus.OPEN,
        description: 'Order modified (Price: ${updatedReq.price}, Qty: ${updatedReq.quantity})',
        at: DateTime.now(),
      ));

    _orders[index] = existing.copyWith(
      request: updatedReq,
      timeline: updatedTimeline,
    );
    _ordersStreamController.add(List.unmodifiable(_orders));
  }

  // Funds Add/Withdraw
  Future<void> addFunds(double amount, PaymentMethod method) async {
    _availableEquityMargin += amount;
    _ledger.insert(0, LedgerEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      narration: 'Funds added via ${method.name}',
      credit: amount,
      debit: 0.0,
      runningBalance: _availableEquityMargin,
    ));
  }

  Future<void> withdrawFunds(double amount, String bankAccount) async {
    if (amount > _availableEquityMargin) {
      throw Exception('Withdrawal amount exceeds available balance.');
    }
    _availableEquityMargin -= amount;
    _ledger.insert(0, LedgerEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      narration: 'Payout to Bank A/C ($bankAccount)',
      credit: 0.0,
      debit: amount,
      runningBalance: _availableEquityMargin,
    ));
  }

  // GTT
  Future<GttOrder> createGtt(GttRequest req) async {
    final instrument = SeedInstruments.findByToken(req.instrumentToken) ??
        const Instrument(token: 'unknown', symbol: 'UNKNOWN', name: 'Unknown', exchange: Exchange.NSE, type: InstrumentType.EQ);
    final gtt = GttOrder(
      id: 'GTT-${DateTime.now().millisecondsSinceEpoch}',
      instrument: instrument,
      request: req,
      status: GttStatus.ACTIVE,
      createdAt: DateTime.now(),
    );
    _gtts.insert(0, gtt);
    _gttStreamController.add(List.unmodifiable(_gtts));
    return gtt;
  }

  Future<void> deleteGtt(String id) async {
    _gtts.removeWhere((g) => g.id == id);
    _gttStreamController.add(List.unmodifiable(_gtts));
  }
}

final orderSimulationEngineProvider = Provider<OrderSimulationEngine>((ref) {
  return OrderSimulationEngine(ref);
});

final ordersListProvider = StreamProvider<List<Order>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.ordersStream;
});

final positionsListProvider = StreamProvider<List<Position>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.positionsStream;
});

final holdingsListProvider = StreamProvider<List<Holding>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.holdingsStream;
});

final gttsListProvider = StreamProvider<List<GttOrder>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.gttStream;
});
