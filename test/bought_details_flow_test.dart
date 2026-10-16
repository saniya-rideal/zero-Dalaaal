import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/config/app_config.dart';
import 'package:zero_dalali/core/network/api_client.dart';
import 'package:zero_dalali/core/network/token_storage.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/orders/data/real_trading_repository.dart';

Dio _createMockDio(dynamic responseBody, {int statusCode = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: responseBody,
            statusCode: statusCode,
          ),
        );
      },
    ),
  );
  return dio;
}

ApiClient _createMockApiClient(dynamic responseBody, {int statusCode = 200}) {
  final mockDio = _createMockDio(responseBody, statusCode: statusCode);
  return ApiClient(
    config: const AppConfig(
      apiBaseUrl: 'http://test',
      socketBaseUrl: 'http://test',
    ),
    tokenStorage: TokenStorage(),
    dio: mockDio,
  );
}

void main() {
  group('Real Trading Data Feeds and Order Flow Integration Tests', () {
    test('1. BUY order creation returns order with full ticket details', () async {
      final backendResponse = {
        'success': true,
        'message': 'Order placed successfully',
        'data': {
          'orderId': 'ord_rel_101',
          'symbol': 'RELIANCE',
          'side': 'BUY',
          'orderType': 'MARKET',
          'productType': 'CNC',
          'quantity': 10,
          'filledQuantity': 10,
          'price': 2500.0,
          'status': 'COMPLETE',
          'placedAt': '2026-03-31T09:15:00Z',
          'stt': 2.5,
        },
      };

      final client = _createMockApiClient(backendResponse);
      final repo = RealTradingRepository(apiClient: client);

      const request = OrderRequest(
        instrumentToken: 'RELIANCE',
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.MARKET,
        quantity: 10,
      );

      final order = await repo.placeOrder(request);

      expect(order.orderId, equals('ord_rel_101'));
      expect(order.instrument.symbol, equals('RELIANCE'));
      expect(order.request.side, equals(TransactionType.BUY));
      expect(order.request.quantity, equals(10));
      expect(order.status, equals(OrderStatus.COMPLETE));
    });

    test('2. Positions feed parses open positions with net quantity, buy price, & MTM', () async {
      final backendResponse = {
        'success': true,
        'data': {
          'positions': [
            {
              'symbol': 'TATAMOTORS',
              'product': 'MIS',
              'netQty': 50,
              'buyAvg': 950.0,
              'sellAvg': 0.0,
              'ltp': 962.0,
              'pnl': 600.0,
              'realizedPnl': 0.0,
              'unrealizedPnl': 600.0,
            }
          ]
        }
      };

      final client = _createMockApiClient(backendResponse);
      final repo = RealTradingRepository(apiClient: client);

      final positions = await repo.getPositions();

      expect(positions, hasLength(1));
      final pos = positions.first;
      expect(pos.instrument.symbol, equals('TATAMOTORS'));
      expect(pos.netQty, equals(50));
      expect(pos.buyAvg, equals(950.0));
      expect(pos.unrealizedPnl, equals(600.0));
      expect(pos.isLong, isTrue);
    });

    test('3. Holdings feed parses Demat holdings with settled quantity and PnL', () async {
      final backendResponse = {
        'success': true,
        'data': {
          'holdings': [
            {
              'symbol': 'INFY',
              'quantity': 15,
              'averagePrice': 1480.0,
              'ltp': 1520.0,
              'pnl': 600.0,
              'pnlPercent': 2.70,
            }
          ]
        }
      };

      final client = _createMockApiClient(backendResponse);
      final repo = RealTradingRepository(apiClient: client);

      final holdings = await repo.getHoldings();

      expect(holdings, hasLength(1));
      final holding = holdings.first;
      expect(holding.instrument.symbol, equals('INFY'));
      expect(holding.quantity, equals(15));
      expect(holding.averagePrice, equals(1480.0));
      expect(holding.currentPrice, equals(1520.0));
      expect(holding.totalPnl, equals(600.0));
    });

    test('4. Order cancel and position close invoke backend endpoints accurately', () async {
      final cancelResponse = {
        'success': true,
        'message': 'Order cancelled',
        'data': {'orderId': 'ord_rel_101', 'status': 'CANCELLED'},
      };

      final client = _createMockApiClient(cancelResponse);
      final repo = RealTradingRepository(apiClient: client);

      final cancelled = await repo.cancelOrder('ord_rel_101');
      expect(cancelled, isTrue);

      final closed = await repo.closePosition('pos_tata_1');
      expect(closed, isA<Order>());
    });

    test('5. Order and Position domain models handle edge nulls safely', () {
      final fallbackOrder = Order.fromJson({
        'orderId': 'ord_fallback',
        'symbol': 'WIPRO',
      });

      expect(fallbackOrder.orderId, 'ord_fallback');
      expect(fallbackOrder.instrument.symbol, 'WIPRO');
      expect(fallbackOrder.request.quantity, 1);
      expect(fallbackOrder.status, OrderStatus.OPEN);

      final fallbackPosition = Position.fromJson({
        'symbol': 'WIPRO',
      });
      expect(fallbackPosition.instrument.symbol, 'WIPRO');
      expect(fallbackPosition.netQty, 0);
      expect(fallbackPosition.totalPnl, 0.0);
    });
  });
}
