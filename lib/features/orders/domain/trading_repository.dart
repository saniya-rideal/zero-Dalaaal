import '../../../data/models/models.dart';

abstract class TradingRepository {
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
  });

  Future<Order> placeOrder(OrderRequest request);
  Future<OrderPreview> previewOrder(OrderPreviewRequest request);

  Future<List<Order>> getOrders();
  Future<Order> getOrder(String id);
  Future<bool> cancelOrder(String id);

  Future<List<Position>> getPositions({String? status = 'OPEN'});
  Future<Order> closePosition(String id, {String? idempotencyKey, int? quantity});
  Future<bool> convertPosition(String id, {required String targetProduct});

  Future<List<Holding>> getHoldings();
  Future<Map<String, dynamic>> getPortfolioSummary();
}
