import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/services/realtime_quote_service.dart';
import 'package:zero_dalali/data/models/enums.dart';
import 'package:zero_dalali/data/models/holding.dart';
import 'package:zero_dalali/data/models/instrument.dart';
import 'package:zero_dalali/data/models/order.dart';
import 'package:zero_dalali/data/models/position.dart';
import 'package:zero_dalali/data/models/quote.dart';
import 'package:zero_dalali/features/orders/data/real_trading_repository.dart';
import 'package:zero_dalali/features/orders/domain/trading_repository.dart';
import 'package:zero_dalali/features/order_entry/presentation/controllers/order_entry_controller.dart';

class MockTradingRepo implements TradingRepository {
  OrderRequest? lastPlaceOrderRequest;
  OrderPreviewRequest? lastPreviewRequest;

  @override
  Future<Order> createOrder({
    required String symbol,
    required TransactionType side,
    required OrderKind orderType,
    required int quantity,
    String market = 'INDIAN',
    double? leverage,
    double? limitPrice,
    double? stopLoss,
    double? takeProfit,
    String? idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Order> placeOrder(OrderRequest request) async {
    lastPlaceOrderRequest = request;
    return Order.fromJson({
      'orderId': 'ord_mock_123',
      'exchangeOrderId': 'ex_mock_123',
      'symbol': request.instrumentToken,
      'status': 'OPEN',
      'filledQty': 0,
      'averagePrice': request.price ?? 100.0,
      'placedAt': DateTime.now().toIso8601String(),
      'timeline': [],
      'charges': {},
      'request': request.toJson(),
    });
  }

  @override
  Future<OrderPreview> previewOrder(OrderPreviewRequest request) async {
    lastPreviewRequest = request;
    return const OrderPreview(
      requiredMargin: 2000.0,
      availableMargin: 100000.0,
      marginAfterTrade: 98000.0,
      charges: ChargesBreakdown(
        brokerage: 20.0,
        stt: 5.0,
        exchangeTxnCharge: 1.0,
        gst: 3.8,
        sebiCharges: 0.1,
        stampDuty: 1.5,
      ),
      canPlace: true,
      executionPrice: 2850.0,
    );
  }

  @override
  Future<bool> cancelOrder(String id) async => true;
  @override
  Future<Order> closePosition(String id, {String? idempotencyKey, int? quantity}) async => throw UnimplementedError();
  @override
  Future<bool> convertPosition(String id, {required String targetProduct}) async => true;
  @override
  Future<List<Holding>> getHoldings() async => [];
  @override
  Future<Order> getOrder(String id) async => throw UnimplementedError();
  @override
  Future<List<Order>> getOrders() async => [];
  @override
  Future<Map<String, dynamic>> getPortfolioSummary() async => {};
  @override
  Future<List<Position>> getPositions({String? status = 'OPEN'}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Instrument testInstrument;
  late MockTradingRepo mockTradingRepo;

  setUp(() {
    mockTradingRepo = MockTradingRepo();
    testInstrument = const Instrument(
      token: 'RELIANCE',
      symbol: 'RELIANCE',
      name: 'Reliance Industries',
      exchange: Exchange.NSE,
      type: InstrumentType.EQ,
      lotSize: 10.0,
      tickSize: 0.05,
      minQuantity: 1,
      quantityStep: 1,
      defaultLeverage: 5.0,
      maxLeverage: 5.0,
      allowedProducts: [ProductType.MIS, ProductType.CNC],
    );
  });

  ProviderContainer createContainer({Quote? initialQuote}) {
    final container = ProviderContainer(
      overrides: [
        tradingRepositoryProvider.overrideWithValue(mockTradingRepo),
        if (initialQuote != null)
          quoteDetailStreamProvider(testInstrument.symbol).overrideWith(
            (ref) => Stream.value(initialQuote),
          ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('OrderEntryController - Stepping & Units', () {
    test('Initializes with default lot size and derived quantity', () {
      final container = createContainer();
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final state = container.read(orderEntryControllerProvider(key));

      expect(state.lots, equals(1.0));
      expect(state.quantity, equals(10)); // 1.0 lot * 10 lotSize
      expect(state.product, equals(ProductType.MIS));
      expect(state.side, equals(TransactionType.BUY));
    });

    test('stepLots increments and decrements quantity correctly', () {
      final container = createContainer();
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.stepLots(true);
      var state = container.read(orderEntryControllerProvider(key));
      expect(state.lots, equals(2.0));
      expect(state.quantity, equals(20)); // 2.0 * 10

      notifier.stepLots(false);
      state = container.read(orderEntryControllerProvider(key));
      expect(state.lots, equals(1.0));
      expect(state.quantity, equals(10));
    });

    test('stepQuantity respects quantityStep', () {
      final container = createContainer();
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.setUnitMode('In Quantity');
      notifier.stepQuantity(true);
      final state = container.read(orderEntryControllerProvider(key));
      expect(state.quantity, equals(11));
    });

    test('stepLimitPrice respects tickSize', () {
      final container = createContainer();
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.setLimitPrice(100.0);
      notifier.stepLimitPrice(true);
      var state = container.read(orderEntryControllerProvider(key));
      expect(state.limitPrice, equals(100.05));

      notifier.stepLimitPrice(false);
      state = container.read(orderEntryControllerProvider(key));
      expect(state.limitPrice, equals(100.0));
    });
  });

  group('OrderEntryController - Direction Validation', () {
    final quoteWithSpread = Quote(
      token: 'RELIANCE',
      ltp: 2900.0,
      open: 2890.0,
      high: 2920.0,
      low: 2880.0,
      close: 2890.0,
      prevClose: 2890.0,
      change: 10.0,
      changePercent: 0.35,
      volume: 1000000,
      depth: const MarketDepth(
        buy: [DepthLevel(price: 2899.80, qty: 500, orders: 10)],
        sell: [DepthLevel(price: 2900.20, qty: 300, orders: 8)],
      ),
      timestamp: DateTime.now(),
      rawBid: 2899.80,
      rawAsk: 2900.20,
    );

    test('Buy Limit must be below ask price', () {
      final container = createContainer(initialQuote: quoteWithSpread);
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.setOrderCategory('Pending');
      notifier.setPendingType('Buy Limit');

      // Invalid: Limit price above ask (2900.20)
      notifier.setLimitPrice(2910.0);
      notifier.validateDirection(quoteWithSpread);
      var state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, contains('must be below current ask'));

      // Valid: Limit price below ask
      notifier.setLimitPrice(2890.0);
      notifier.validateDirection(quoteWithSpread);
      state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, isNull);
    });

    test('Sell Limit must be above bid price', () {
      final container = createContainer(initialQuote: quoteWithSpread);
      final key = (instrument: testInstrument, initialSide: TransactionType.SELL);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.setOrderCategory('Pending');
      notifier.setPendingType('Sell Limit');

      // Invalid: Limit price below bid (2899.80)
      notifier.setLimitPrice(2850.0);
      notifier.validateDirection(quoteWithSpread);
      var state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, contains('must be above current bid'));

      // Valid: Limit price above bid
      notifier.setLimitPrice(2910.0);
      notifier.validateDirection(quoteWithSpread);
      state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, isNull);
    });

    test('Buy Stop trigger must be above ask price', () {
      final container = createContainer(initialQuote: quoteWithSpread);
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.setOrderCategory('Pending');
      notifier.setPendingType('Buy Stop');

      // Invalid: trigger below ask
      notifier.setTriggerPrice(2850.0);
      notifier.validateDirection(quoteWithSpread);
      var state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, contains('must be above current ask'));

      // Valid: trigger above ask
      notifier.setTriggerPrice(2920.0);
      notifier.validateDirection(quoteWithSpread);
      state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, isNull);
    });

    test('Sell Stop trigger must be below bid price', () {
      final container = createContainer(initialQuote: quoteWithSpread);
      final key = (instrument: testInstrument, initialSide: TransactionType.SELL);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.setOrderCategory('Pending');
      notifier.setPendingType('Sell Stop');

      // Invalid: trigger above bid
      notifier.setTriggerPrice(2950.0);
      notifier.validateDirection(quoteWithSpread);
      var state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, contains('must be below current bid'));

      // Valid: trigger below bid
      notifier.setTriggerPrice(2850.0);
      notifier.validateDirection(quoteWithSpread);
      state = container.read(orderEntryControllerProvider(key));
      expect(state.directionValidationError, isNull);
    });

    test('Market order blocks placement if quote has no bid/ask depth', () {
      final quoteNoDepth = Quote(
        token: 'RELIANCE',
        ltp: 2900.0,
        open: 2890.0,
        high: 2920.0,
        low: 2880.0,
        close: 2890.0,
        prevClose: 2890.0,
        change: 10.0,
        changePercent: 0.35,
        volume: 1000000,
        depth: const MarketDepth(buy: [], sell: []),
        timestamp: DateTime.now(),
        rawBid: null,
        rawAsk: null,
      );

      final container = createContainer(initialQuote: quoteNoDepth);
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      notifier.setOrderCategory('Market');
      notifier.validateDirection(quoteNoDepth);
      final state = container.read(orderEntryControllerProvider(key));

      expect(state.validationError, contains('No market liquidity'));
      expect(state.canPlaceOrder, isFalse);
    });
  });

  group('OrderEntryController - Payload Mapping for Each Order Type', () {
    test('Market order payload maps orderType to MARKET without limit/trigger prices', () {
      const req = OrderRequest(
        instrumentToken: 'RELIANCE',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 10,
        validity: Validity.DAY,
        leverage: 5.0,
      );

      final json = req.toJson();
      expect(json['orderType'], equals('MARKET'));
      expect(json['type'], equals('MARKET'));
      expect(json['side'], equals('BUY'));
      expect(json['product'], equals('MIS'));
      expect(json['quantity'], equals(10));
      expect(json['price'], isNull);
      expect(json['triggerPrice'], isNull);
      expect(json['stopLoss'], isNull);
      expect(json['leverage'], equals(5.0));
    });

    test('Limit order payload maps orderType to LIMIT with limitPrice and no triggerPrice', () {
      const req = OrderRequest(
        instrumentToken: 'RELIANCE',
        side: TransactionType.SELL,
        product: ProductType.CNC,
        kind: OrderKind.LIMIT,
        quantity: 5,
        price: 2950.0,
        validity: Validity.DAY,
      );

      final json = req.toJson();
      expect(json['orderType'], equals('LIMIT'));
      expect(json['limitPrice'], equals(2950.0));
      expect(json['price'], equals(2950.0));
      expect(json['triggerPrice'], isNull);
      expect(json['stopLoss'], isNull);
    });

    test('STOP order payload maps orderType to STOP with triggerPrice and never copies to stopLoss', () {
      const req = OrderRequest(
        instrumentToken: 'RELIANCE',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.STOP,
        quantity: 10,
        triggerPrice: 2920.0,
        validity: Validity.DAY,
      );

      final json = req.toJson();
      expect(json['orderType'], equals('STOP'));
      expect(json['triggerPrice'], equals(2920.0));
      expect(json['stopLoss'], isNull); // BUG FIX: never copies trigger into stopLoss!
    });

    test('STOP_LIMIT order payload sends both limitPrice and triggerPrice', () {
      const req = OrderRequest(
        instrumentToken: 'RELIANCE',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.STOP_LIMIT,
        quantity: 10,
        price: 2925.0,
        triggerPrice: 2920.0,
        bracket: BracketParams(stopLoss: 2890.0, target: 3000.0),
        validity: Validity.GTC,
        comment: 'Breakout setup',
      );

      final json = req.toJson();
      expect(json['orderType'], equals('STOP_LIMIT'));
      expect(json['limitPrice'], equals(2925.0));
      expect(json['triggerPrice'], equals(2920.0));
      expect(json['stopLoss'], equals(2890.0)); // ONLY from bracket
      expect(json['takeProfit'], equals(3000.0)); // ONLY from bracket
      expect(json['validity'], equals('GTC'));
      expect(json['comment'], equals('Breakout setup'));
    });
  });

  group('OrderEntryController - Debounce Preview', () {
    test('fetchOrderPreview triggers previewOrder and sets state', () async {
      final container = createContainer();
      final key = (instrument: testInstrument, initialSide: TransactionType.BUY);
      final notifier = container.read(orderEntryControllerProvider(key).notifier);

      await notifier.fetchOrderPreview();
      final state = container.read(orderEntryControllerProvider(key));

      expect(mockTradingRepo.lastPreviewRequest, isNotNull);
      expect(mockTradingRepo.lastPreviewRequest!.symbol, equals('RELIANCE'));
      expect(mockTradingRepo.lastPreviewRequest!.orderType, equals(OrderKind.MARKET));
      expect(state.preview, isNotNull);
      expect(state.preview!.canPlace, isTrue);
      expect(state.preview!.requiredMargin, equals(2000.0));
      expect(state.preview!.charges.brokerage, equals(20.0));
    });
  });
}
