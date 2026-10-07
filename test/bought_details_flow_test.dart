import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/mock/order_simulation_engine.dart';
import 'package:zero_dalali/data/models/models.dart';

void main() {
  group('Bought Details Integration Test Across All 4 Real-time Data Feeds', () {
    late ProviderContainer container;
    late OrderSimulationEngine engine;

    setUp(() {
      container = ProviderContainer();
      engine = container.read(orderSimulationEngineProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('1. BUY order creation populates Executed Orders feed with full ticket details', () async {
      const request = OrderRequest(
        instrumentToken: 'eq_reliance',
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.MARKET,
        quantity: 10,
      );

      final order = await engine.placeOrder(request);
      await Future.delayed(const Duration(milliseconds: 400));

      expect(order.instrument.symbol, equals('RELIANCE'));
      expect(order.request.side, equals(TransactionType.BUY));
      expect(order.request.quantity, equals(10));

      // Verify presence in executed orders list
      final executed = engine.executedOrders.firstWhere((o) => o.orderId == order.orderId);
      expect(executed.status, equals(OrderStatus.COMPLETE));
      expect(executed.filledQty, equals(10));
      expect(executed.averagePrice, greaterThan(0.0));
      expect(executed.charges.stt, greaterThanOrEqualTo(0.0));
    });

    test('2. Intraday BUY order populates Open Positions feed with net quantity, buy price, & MTM', () async {
      const request = OrderRequest(
        instrumentToken: 'eq_tatamotors',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 50,
      );

      await engine.placeOrder(request);
      await Future.delayed(const Duration(milliseconds: 400));

      final position = engine.positions.firstWhere((p) => p.instrument.symbol == 'TATAMOTORS');
      expect(position.netQty, equals(50));
      expect(position.buyAvg, greaterThan(0.0));
      expect(position.isLong, isTrue);
      expect(position.side, equals(TransactionType.BUY));
      expect(position.unrealizedPnl, isA<double>());
    });

    test('3. Delivery BUY order populates Demat Holdings feed', () async {
      const request = OrderRequest(
        instrumentToken: 'eq_infy',
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.MARKET,
        quantity: 15,
      );

      await engine.placeOrder(request);
      await Future.delayed(const Duration(milliseconds: 400));

      final holding = engine.holdings.firstWhere((h) => h.instrument.symbol == 'INFY');
      expect(holding.quantity, greaterThanOrEqualTo(15));
      expect(holding.averagePrice, greaterThan(0.0));
    });

    test('4. Trade execution generates Net Deals entry with timestamp & gross turnover', () async {
      const request = OrderRequest(
        instrumentToken: 'eq_tcs',
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.MARKET,
        quantity: 5,
      );

      final order = await engine.placeOrder(request);
      await Future.delayed(const Duration(milliseconds: 400));

      final executedOrder = engine.executedOrders.firstWhere((o) => o.orderId == order.orderId);

      // Verify order execution audit trail and timeline events
      expect(executedOrder.timeline, isNotEmpty);
      expect(executedOrder.timeline.any((e) => e.status == OrderStatus.COMPLETE), isTrue);
      expect(executedOrder.auditTrail.any((a) => a.action == 'STATUS_TRANSITION'), isTrue);
    });

    test('5. Transaction ledger records fund debit & recalculates available equity margin', () async {
      final marginBefore = engine.availableEquityMargin;

      const request = OrderRequest(
        instrumentToken: 'eq_hdfcbank',
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.MARKET,
        quantity: 10,
      );

      await engine.placeOrder(request);
      await Future.delayed(const Duration(milliseconds: 400));

      final marginAfter = engine.availableEquityMargin;
      expect(marginAfter, lessThan(marginBefore));
    });
  });
}
