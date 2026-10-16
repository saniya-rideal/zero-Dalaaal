import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';

class FundamentalsRepository {
  final ApiClient _apiClient;

  FundamentalsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<StockFundamentals> getFundamentals(String symbol) async {
    final cleanSym = symbol.trim().toUpperCase();
    final data = await _apiClient.get(ApiPaths.marketFundamentals(cleanSym));
    final obj = ResponseReader.object(data, 'fundamentals');
    return StockFundamentals.fromJson(obj.isNotEmpty ? obj : ResponseReader.object(data));
  }

  Future<List<CorporateAction>> getCorporateActions({String? symbol}) async {
    final Map<String, dynamic> params = {};
    if (symbol != null && symbol.isNotEmpty) {
      params['symbol'] = symbol.trim().toUpperCase();
    }

    final data = await _apiClient.get(
      ApiPaths.marketCorporateActions,
      queryParameters: params.isNotEmpty ? params : null,
    );

    final items = ResponseReader.list(data, 'corporateActions');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => CorporateAction.fromJson(e))
        .toList();
  }
}

final fundamentalsRepositoryProvider = Provider<FundamentalsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FundamentalsRepository(apiClient: apiClient);
});

final stockFundamentalsProvider =
    FutureProvider.family<StockFundamentals, String>((ref, symbol) async {
  final repo = ref.watch(fundamentalsRepositoryProvider);
  return repo.getFundamentals(symbol);
});

final corporateActionsProvider =
    FutureProvider.family<List<CorporateAction>, String?>((ref, symbol) async {
  final repo = ref.watch(fundamentalsRepositoryProvider);
  return repo.getCorporateActions(symbol: symbol);
});
