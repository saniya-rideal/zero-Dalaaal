import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AlertsRepository(client);
});

class AlertsRepository {
  final ApiClient _client;

  AlertsRepository(this._client);

  Future<List<PriceAlert>> getAlerts() async {
    final response = await _client.get(ApiPaths.alerts);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(PriceAlert.fromJson)
        .toList();
  }

  Future<PriceAlert> createAlert({
    required String symbol,
    required double targetPrice,
    required String condition, // 'GTE' or 'LTE'
    String? note,
  }) async {
    final payload = {
      'symbol': symbol,
      'targetPrice': targetPrice,
      'condition': condition,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final response = await _client.post(ApiPaths.alerts, data: payload);
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return PriceAlert.fromJson(map);
  }

  Future<void> deleteAlert(String id) async {
    await _client.delete(ApiPaths.alertById(id));
  }

  Future<PriceAlert> toggleAlert(String id) async {
    final response = await _client.patch(ApiPaths.alertToggle(id));
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return PriceAlert.fromJson(map);
  }
}
