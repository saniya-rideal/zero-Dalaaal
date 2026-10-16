import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/order.dart';

final gttRepositoryProvider = Provider<GttRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return GttRepository(client);
});

final gttListProvider = FutureProvider<List<GttOrder>>((ref) async {
  final repo = ref.watch(gttRepositoryProvider);
  return repo.getGttOrders();
});

final gttsListProvider = gttListProvider;

class GttRepository {
  final ApiClient _client;

  GttRepository(this._client);

  Future<List<GttOrder>> getGttOrders() async {
    final response = await _client.get(ApiPaths.gtt);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(GttOrder.fromJson)
        .toList();
  }

  Future<GttOrder> createGtt({
    required String symbol,
    required String condition, // 'GTE' or 'LTE'
    required double triggerPrice,
    required String orderSide, // 'BUY' or 'SELL'
    required String orderType, // 'LIMIT' or 'MARKET'
    required double price,
    required int quantity,
    int leverage = 1,
    String market = 'INDIAN',
  }) async {
    final payload = {
      'symbol': symbol,
      'market': market,
      'condition': condition,
      'triggerPrice': triggerPrice,
      'orderSide': orderSide,
      'orderType': orderType,
      'price': price,
      'quantity': quantity,
      'leverage': leverage,
    };
    final response = await _client.post(ApiPaths.gtt, data: payload);
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return GttOrder.fromJson(map);
  }

  Future<void> deleteGtt(String id) async {
    await _client.delete(ApiPaths.gttById(id));
  }
}
