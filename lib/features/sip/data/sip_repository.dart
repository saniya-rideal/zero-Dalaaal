import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/sip.dart';

final sipRepositoryProvider = Provider<SipRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return SipRepository(client);
});

class SipRepository {
  final ApiClient _client;

  SipRepository(this._client);

  Future<List<Sip>> getSips() async {
    final response = await _client.get(ApiPaths.sip);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Sip.fromJson)
        .toList();
  }

  Future<Sip> createSip({
    required String symbol,
    required String frequency, // 'DAILY', 'WEEKLY', 'MONTHLY'
    required double amount,
    int? quantity,
    int? dayOfMonth,
    String market = 'INDIAN',
  }) async {
    final payload = {
      'symbol': symbol,
      'market': market,
      'frequency': frequency,
      'amount': amount,
      if (quantity != null) 'quantity': quantity,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
    };
    final response = await _client.post(ApiPaths.sip, data: payload);
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return Sip.fromJson(map);
  }

  Future<void> deleteSip(String id) async {
    await _client.delete(ApiPaths.sipById(id));
  }

  Future<Sip> pauseSip(String id) async {
    final response = await _client.post(ApiPaths.sipPause(id));
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return Sip.fromJson(map);
  }

  Future<Sip> resumeSip(String id) async {
    final response = await _client.post(ApiPaths.sipResume(id));
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return Sip.fromJson(map);
  }
}
