import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/config/app_config.dart';
import 'package:zero_dalali/core/network/api_client.dart';
import 'package:zero_dalali/core/network/token_storage.dart';
import 'package:zero_dalali/features/auth/data/real_auth_repository.dart';
import 'package:zero_dalali/features/orders/data/real_trading_repository.dart';
import 'package:zero_dalali/data/models/models.dart';

void main() {
  group('Saniya Account Live End-to-End Test Suite', () {
    late ApiClient apiClient;
    late TokenStorage tokenStorage;
    late RealAuthRepository authRepo;
    late RealTradingRepository tradingRepo;

    setUpAll(() async {
      tokenStorage = TokenStorage();
      apiClient = ApiClient(
        config: const AppConfig(
          apiBaseUrl: 'http://localhost:5000',
          socketBaseUrl: 'ws://localhost:5000/ws',
        ),
        tokenStorage: tokenStorage,
      );
      authRepo = RealAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
      tradingRepo = RealTradingRepository(apiClient: apiClient);
    });

    test('TC-01: Authentication with email and password', () async {
      final result = await authRepo.login('saniya@gmail.com', '#Password123');
      expect(result, isNotNull);
      final session = await tokenStorage.getSession();
      expect(session, isNotNull);
      expect(session?.profile.email, 'saniya@gmail.com');
      expect(session?.profile.clientId, 'ZD536808');
    });

    test('TC-02: User profile retrieval and client identity', () async {
      final session = await tokenStorage.getSession();
      expect(session?.token, isNotEmpty);
      final profileData = await apiClient.get('/api/account/profile');
      expect(profileData, isNotNull);
    });

    test('TC-03: Funds & margins ledger verification', () async {
      final fundsData = await apiClient.get('/api/funds/summary');
      expect(fundsData, isNotNull);
      final map = fundsData is Map<String, dynamic> ? fundsData : <String, dynamic>{};
      expect(map.containsKey('usedMargin') || map.containsKey('data'), isTrue);
    });

    test('TC-04: Market instruments retrieval', () async {
      final instruments = await apiClient.get('/api/market/instruments');
      expect(instruments, isNotNull);
    });

    test('TC-05: Fetch open positions (Deals)', () async {
      final positions = await tradingRepo.getPositions();
      expect(positions, isA<List<Position>>());
    });

    test('TC-06: Fetch order book (Orders)', () async {
      final orders = await tradingRepo.getOrders();
      expect(orders, isA<List<Order>>());
    });

    test('TC-07: Place Market BUY order for USDINR', () async {
      final order = await tradingRepo.createOrder(
        symbol: 'USDINR',
        side: TransactionType.BUY,
        orderType: OrderKind.MARKET,
        quantity: 1000,
        market: 'FOREX',
        leverage: 10.0,
        stopLoss: 80.0,
        takeProfit: 98.0,
        idempotencyKey: 'tst_ord_flt_${DateTime.now().millisecondsSinceEpoch}',
      );
      expect(order, isNotNull);
      expect(order.id, isNotEmpty);
      expect(order.status == OrderStatus.COMPLETE || order.status == OrderStatus.OPEN || order.status == OrderStatus.SUBMITTED, isTrue);
    });

    test('TC-08: Close active position with idempotency key', () async {
      final positions = await tradingRepo.getPositions();
      if (positions.isNotEmpty) {
        final pos = positions.firstWhere((p) => p.instrument.symbol == 'USDINR', orElse: () => positions.first);
        final closed = await tradingRepo.closePosition(pos.id);
        expect(closed, isNotNull);
      }
    });

    test('TC-09: Reports tradebook and ledger check', () async {
      final tb = await apiClient.get('/api/reports/tradebook');
      expect(tb, isNotNull);
      final ledger = await apiClient.get('/api/reports/ledger');
      expect(ledger, isNotNull);
    });
  });
}
