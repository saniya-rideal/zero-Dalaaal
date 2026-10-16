import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';

class OptionChainData {
  final String symbol;
  final double underlyingPrice;
  final String? expiryDate;
  final List<OptionChainRow> rows;

  const OptionChainData({
    required this.symbol,
    required this.underlyingPrice,
    this.expiryDate,
    required this.rows,
  });
}

class OptionChainRepository {
  final ApiClient _apiClient;

  OptionChainRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<String>> getExpiries(String symbol) async {
    final cleanSym = symbol.replaceAll(' ', '');
    final data = await _apiClient.get(ApiPaths.marketOptionChainExpiries(cleanSym));
    final list = ResponseReader.list(data, 'expiries');
    if (list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    final rawList = ResponseReader.list(data);
    return rawList.map((e) => e.toString()).toList();
  }

  Future<OptionChainData> getOptionChain(String symbol, {String? expiry}) async {
    final cleanSym = symbol.replaceAll(' ', '');
    final Map<String, dynamic> params = {};
    if (expiry != null && expiry.isNotEmpty) {
      params['expiry'] = expiry;
    }

    final data = await _apiClient.get(
      ApiPaths.marketOptionChain(cleanSym),
      queryParameters: params.isNotEmpty ? params : null,
    );

    final obj = ResponseReader.object(data, 'optionChain');
    final undPrice = (obj['underlyingPrice'] as num?)?.toDouble() ?? 0.0;
    final expDate = obj['expiryDate']?.toString();
    final strikes = ResponseReader.list(obj, 'strikes');

    double minDiff = double.infinity;
    double? atmStrike;
    for (final item in strikes.whereType<Map<String, dynamic>>()) {
      final s = (item['strikePrice'] ?? item['strike'] as num?)?.toDouble() ?? 0.0;
      final diff = (s - undPrice).abs();
      if (diff < minDiff) {
        minDiff = diff;
        atmStrike = s;
      }
    }

    final rows = strikes.whereType<Map<String, dynamic>>().map((item) {
      final strike = (item['strikePrice'] ?? item['strike'] as num?)?.toDouble() ?? 0.0;
      final isAtm = atmStrike != null && (strike - atmStrike).abs() < 0.01;
      final copy = Map<String, dynamic>.from(item);
      copy['isAtm'] = isAtm;
      return OptionChainRow.fromJson(copy);
    }).toList();

    return OptionChainData(
      symbol: symbol,
      underlyingPrice: undPrice,
      expiryDate: expDate,
      rows: rows,
    );
  }
}

final optionChainRepositoryProvider = Provider<OptionChainRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OptionChainRepository(apiClient: apiClient);
});
