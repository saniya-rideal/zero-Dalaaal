import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/basket.dart';

final basketsRepositoryProvider = Provider<BasketsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BasketsRepository(client);
});

class BasketsRepository {
  final ApiClient _client;

  BasketsRepository(this._client);

  Future<List<Basket>> getBaskets() async {
    final response = await _client.get(ApiPaths.baskets);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Basket.fromJson)
        .toList();
  }

  Future<Basket> createBasket({
    required String name,
    required List<Map<String, dynamic>> orders,
  }) async {
    final payload = {
      'name': name,
      'orders': orders,
    };
    final response = await _client.post(ApiPaths.baskets, data: payload);
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return Basket.fromJson(map);
  }

  Future<void> deleteBasket(String id) async {
    await _client.delete(ApiPaths.basketById(id));
  }

  Future<Map<String, dynamic>> executeBasket(String id) async {
    final response = await _client.post(ApiPaths.basketExecute(id));
    final data = ResponseReader.unwrap(response);
    return ResponseReader.asMap(data);
  }
}
