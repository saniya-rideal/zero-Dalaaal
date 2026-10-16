import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';
import '../domain/trading_repository.dart';

class RealTradingRepository implements TradingRepository {
  final ApiClient _apiClient;

  RealTradingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

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
    final orderTypeStr = orderType == OrderKind.LIMIT ? 'LIMIT' : 'MARKET';
    final payload = <String, dynamic>{
      'symbol': symbol,
      'market': market,
      'side': side.name,
      'orderType': orderTypeStr,
      'type': orderTypeStr,
      'quantity': quantity,
      'leverage': (leverage != null && leverage > 0) ? leverage : 5.0,
    };

    if (limitPrice != null && limitPrice > 0) {
      payload['limitPrice'] = limitPrice;
      payload['price'] = limitPrice;
    }
    if (stopLoss != null && stopLoss > 0) payload['stopLoss'] = stopLoss;
    if (takeProfit != null && takeProfit > 0) payload['takeProfit'] = takeProfit;

    final data = await _apiClient.post(
      ApiPaths.orders,
      data: payload,
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );

    final obj = ResponseReader.object(data, 'order');
    if (obj.isNotEmpty) {
      return Order.fromJson(obj);
    }
    return Order.fromJson(ResponseReader.object(data));
  }

  @override
  Future<Order> placeOrder(OrderRequest request) async {
    final orderTypeStr = (request.kind == OrderKind.LIMIT || (request.price != null && request.price! > 0))
        ? 'LIMIT'
        : 'MARKET';
    final payload = <String, dynamic>{
      'symbol': request.instrumentToken,
      'instrumentToken': request.instrumentToken,
      'market': request.market ?? 'INDIAN',
      'side': request.side.name,
      'orderType': orderTypeStr,
      'type': orderTypeStr,
      'quantity': request.quantity,
      'product': request.product.name,
      'validity': request.validity.name,
      'leverage': (request.leverage != null && request.leverage! > 0) ? request.leverage! : 5.0,
    };

    if (request.price != null && request.price! > 0) {
      payload['limitPrice'] = request.price;
      payload['price'] = request.price;
    }
    if (request.triggerPrice != null && request.triggerPrice! > 0) {
      payload['triggerPrice'] = request.triggerPrice;
    }
    final sl = (request.bracket?.stopLoss != null && request.bracket!.stopLoss > 0)
        ? request.bracket!.stopLoss
        : (request.triggerPrice != null && request.triggerPrice! > 0 ? request.triggerPrice : null);
    if (sl != null && sl > 0) {
      payload['stopLoss'] = sl;
    }
    if (request.bracket?.target != null && request.bracket!.target > 0) {
      payload['takeProfit'] = request.bracket!.target;
    }

    final data = await _apiClient.post(
      ApiPaths.orders,
      data: payload,
      options: request.idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': request.idempotencyKey})
          : null,
    );

    final obj = ResponseReader.object(data, 'order');
    if (obj.isNotEmpty) {
      return Order.fromJson(obj);
    }
    return Order.fromJson(ResponseReader.object(data));
  }

  @override
  Future<List<Order>> getOrders() async {
    final data = await _apiClient.get(ApiPaths.orders);
    final items = ResponseReader.list(data, 'orders');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => Order.fromJson(item))
        .toList();
  }

  @override
  Future<Order> getOrder(String id) async {
    final data = await _apiClient.get(ApiPaths.orderDetail(id));
    final obj = ResponseReader.object(data, 'order');
    if (obj.isNotEmpty) {
      return Order.fromJson(obj);
    }
    return Order.fromJson(ResponseReader.object(data));
  }

  @override
  Future<bool> cancelOrder(String id) async {
    // Contract Section 6.2: POST /api/orders/:id/cancel
    await _apiClient.post(ApiPaths.orderCancel(id));
    return true;
  }

  @override
  Future<List<Position>> getPositions({String? status = 'OPEN'}) async {
    final data = await _apiClient.get(
      ApiPaths.positions,
      queryParameters: status != null ? {'status': status} : null,
    );
    final items = ResponseReader.list(data, 'positions');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => Position.fromJson(item))
        .toList();
  }

  @override
  Future<Order> closePosition(
    String id, {
    String? idempotencyKey,
    int? quantity,
  }) async {
    // Contract Section 6.3: POST /api/positions/:id/close
    final data = await _apiClient.post(
      ApiPaths.closePosition(id),
      data: quantity != null ? {'quantity': quantity} : null,
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );

    final obj = ResponseReader.object(data, 'order');
    if (obj.isNotEmpty) {
      return Order.fromJson(obj);
    }
    return Order.fromJson(ResponseReader.object(data));
  }

  @override
  Future<bool> convertPosition(String id, {required String targetProduct}) async {
    // Contract Section 6.3: PUT /api/positions/:id/convert with { "targetProduct": "CNC" }
    await _apiClient.put(
      ApiPaths.convertPosition(id),
      data: {'targetProduct': targetProduct},
    );
    return true;
  }

  @override
  Future<List<Holding>> getHoldings() async {
    // Contract Section 6.4: GET /api/portfolio/holdings
    final data = await _apiClient.get(ApiPaths.portfolioHoldings);
    final items = ResponseReader.list(data, 'holdings');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => Holding.fromJson(item))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getPortfolioSummary() async {
    // Contract Section 6.4: GET /api/portfolio/summary
    final data = await _apiClient.get(ApiPaths.portfolioSummary);
    return ResponseReader.object(data);
  }
}

final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RealTradingRepository(apiClient: apiClient);
});

final ordersListProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.getOrders();
});

final positionsListProvider = FutureProvider<List<Position>>((ref) async {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.getPositions(status: 'OPEN');
});

final holdingsListProvider = FutureProvider<List<Holding>>((ref) async {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.getHoldings();
});

final portfolioSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.getPortfolioSummary();
});
