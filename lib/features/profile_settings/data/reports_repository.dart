import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ReportsRepository(client);
});

class ReportsRepository {
  final ApiClient _client;

  ReportsRepository(this._client);

  Future<Map<String, dynamic>> getLedgerReport({
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final query = {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'page': page,
      'limit': limit,
    };
    final response = await _client.get(ApiPaths.reportsLedger, queryParameters: query);
    final data = ResponseReader.unwrap(response);
    return ResponseReader.asMap(data);
  }

  Future<List<Map<String, dynamic>>> getTradebook() async {
    final response = await _client.get(ApiPaths.reportsTradebook);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> getPnl() async {
    final response = await _client.get(ApiPaths.reportsPnl);
    final data = ResponseReader.unwrap(response);
    return ResponseReader.asMap(data);
  }
}
