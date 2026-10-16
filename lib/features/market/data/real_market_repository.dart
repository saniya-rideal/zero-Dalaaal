import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';
import '../domain/market_repository.dart';

class RealMarketRepository implements MarketRepository {
  final ApiClient _apiClient;
  List<Instrument>? _cachedInstruments;

  RealMarketRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  List<Instrument> get cachedInstruments => _cachedInstruments ?? const [];

  @override
  Instrument? findBySymbol(String symbol) {
    final clean = symbol.trim().toUpperCase();
    return _cachedInstruments
        ?.where((i) => i.symbol.toUpperCase() == clean || i.token.toUpperCase() == clean)
        .firstOrNull;
  }

  @override
  Future<List<Instrument>> getInstruments() async {
    if (_cachedInstruments != null && _cachedInstruments!.isNotEmpty) {
      return _cachedInstruments!;
    }

    final data = await _apiClient.get(
      ApiPaths.marketInstruments,
      queryParameters: {'market': 'INDIAN'},
    );

    final items = ResponseReader.list(data, 'instruments');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
    final list = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => Instrument.fromJson(item))
        .toList();

    _cachedInstruments = list;
    return list;
  }

  @override
  Future<Map<String, Quote>> getQuotes({List<String>? symbols}) async {
    final Map<String, dynamic> params = {};
    if (symbols != null && symbols.isNotEmpty) {
      params['symbols'] = symbols.join(',');
    }

    final data = await _apiClient.get(
      ApiPaths.marketQuotes,
      queryParameters: params.isNotEmpty ? params : null,
    );
    final Map<String, Quote> result = {};

    if (data is Map && data.containsKey('quotes')) {
      final qData = data['quotes'];
      if (qData is List) {
        for (final item in qData) {
          if (item is Map<String, dynamic>) {
            final quote = Quote.fromJson(item);
            result[quote.token] = quote;
          }
        }
        return result;
      } else if (qData is Map) {
        qData.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            result[key.toString()] = Quote.fromJson(val);
          }
        });
        return result;
      }
    }

    final items = ResponseReader.list(data, 'quotes');
    if (items.isNotEmpty) {
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final quote = Quote.fromJson(item);
          result[quote.token] = quote;
        }
      }
    } else if (data is Map) {
      data.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          result[key.toString()] = Quote.fromJson(val);
        }
      });
    }

    return result;
  }

  @override
  Future<Quote?> getQuote(String symbol) async {
    final quotes = await getQuotes(symbols: [symbol]);
    if (quotes.containsKey(symbol)) {
      return quotes[symbol];
    }
    return quotes.values.firstOrNull;
  }

  @override
  Future<List<Candle>> getCandles(
    String symbol, {
    String interval = '1m',
    int limit = 100,
    int? from,
    int? to,
  }) async {
    // Contract supported resolution: 1m, 5m, 15m, 1h, 1d, 1D
    String resolution = interval;
    if (interval.toLowerCase() == '1d') resolution = '1D';

    final Map<String, dynamic> params = {
      'symbol': symbol,
      'resolution': resolution,
    };
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (limit > 0) params['limit'] = limit;

    final data = await _apiClient.get(
      ApiPaths.marketCandles,
      queryParameters: params,
    );

    final items = ResponseReader.list(data, 'candles');
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => Candle.fromJson(item))
        .toList();
  }

  @override
  Future<List<Instrument>> searchInstruments(
    String query, {
    Exchange? exchange,
    InstrumentType? type,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getInstruments();
    }

    try {
      final data = await _apiClient.get(
        ApiPaths.marketSearch,
        queryParameters: {'q': cleanQuery},
      );
      final items = ResponseReader.list(data, 'results');
      final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
      var list = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => Instrument.fromJson(item))
          .toList();

      if (exchange != null) {
        list = list.where((i) => i.exchange == exchange).toList();
      }
      if (type != null) {
        list = list.where((i) => i.type == type).toList();
      }
      return list;
    } catch (_) {
      // Fallback to local cache search
      final all = await getInstruments();
      final upper = cleanQuery.toUpperCase();
      return all.where((i) {
        final matchesQuery = i.symbol.toUpperCase().contains(upper) ||
            i.name.toUpperCase().contains(upper) ||
            i.token.toUpperCase().contains(upper);
        final matchesExchange = exchange == null || i.exchange == exchange;
        final matchesType = type == null || i.type == type;
        return matchesQuery && matchesExchange && matchesType;
      }).toList();
    }
  }

  @override
  Future<Map<String, dynamic>> getMarketStatus() async {
    final data = await _apiClient.get(ApiPaths.marketStatus);
    return ResponseReader.object(data);
  }

  @override
  Future<List<dynamic>> getMarketHolidays({int? year}) async {
    final data = await _apiClient.get(
      ApiPaths.marketHolidays,
      queryParameters: {'year': year ?? DateTime.now().year},
    );
    return ResponseReader.list(data, 'holidays');
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RealMarketRepository(apiClient: apiClient);
});

final marketStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getMarketStatus();
});

final marketHolidaysProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getMarketHolidays();
});
