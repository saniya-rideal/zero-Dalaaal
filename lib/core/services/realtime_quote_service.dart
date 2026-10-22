import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/api_paths.dart';
import '../network/socket_service.dart';
import '../../data/models/models.dart';

/// Production Real-Time Quote Service
/// Manages live streaming quotes via Socket.IO with REST fallback
class RealtimeQuoteService {
  final SocketService _socketService;
  final ApiClient _apiClient;
  final Map<String, Quote> _quotes = {};
  final StreamController<Map<String, Quote>> _controller =
      StreamController<Map<String, Quote>>.broadcast();

  StreamSubscription? _socketSub;

  RealtimeQuoteService({
    required SocketService socketService,
    required ApiClient apiClient,
  })  : _socketService = socketService,
        _apiClient = apiClient {
    _socketSub = _socketService.quotesStream.listen((incoming) {
      _quotes.addAll(incoming);
      _controller.add(Map.unmodifiable(_quotes));
    });
  }

  /// Get cached quote or a fallback zero-quote for safe UI rendering
  Quote getQuote(String symbol) {
    if (_quotes.containsKey(symbol)) {
      return _quotes[symbol]!;
    }
    final clean = symbol.trim().toUpperCase();
    for (final entry in _quotes.entries) {
      if (entry.key.toUpperCase() == clean) {
        return entry.value;
      }
    }
    return Quote.zero(symbol);
  }

  Map<String, Quote> getAllQuotes() => Map.unmodifiable(_quotes);

  Stream<Map<String, Quote>> get stream => _controller.stream;

  Stream<Quote> streamForToken(String symbol) async* {
    subscribe(symbol);
    final cached = getQuote(symbol);
    if (cached.lastPrice > 0 || cached.token.isNotEmpty) {
      yield cached;
    }
    yield* _controller.stream
        .where((map) => map.containsKey(symbol))
        .map((map) => map[symbol]!);
  }

  void subscribe(String symbol) {
    _socketService.subscribe(symbol);
    // If not in cache, trigger initial fetch
    if (!_quotes.containsKey(symbol)) {
      _fetchSingleQuote(symbol);
    }
  }

  void subscribeAll(Iterable<String> symbols) {
    _socketService.subscribeAll(symbols);
    final missing = symbols.where((s) => !_quotes.containsKey(s)).toList();
    if (missing.isNotEmpty) {
      _fetchMultipleQuotes(missing);
    }
  }

  void unsubscribe(String symbol) {
    _socketService.unsubscribe(symbol);
  }

  void unsubscribeAll(Iterable<String> symbols) {
    _socketService.unsubscribeAll(symbols);
  }

  Future<void> _fetchSingleQuote(String symbol) async {
    try {
      final data = await _apiClient.get(
        ApiPaths.marketQuotes,
        queryParameters: {'symbols': symbol},
      );
      _parseAndCacheQuotes(data);
    } catch (_) {}
  }

  Future<void> _fetchMultipleQuotes(List<String> symbols) async {
    try {
      final joined = symbols.take(20).join(',');
      final data = await _apiClient.get(
        ApiPaths.marketQuotes,
        queryParameters: {'symbols': joined},
      );
      _parseAndCacheQuotes(data);
    } catch (_) {}
  }

  void _parseAndCacheQuotes(dynamic data) {
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final q = Quote.fromJson(item);
          _quotes[q.token] = q;
        }
      }
      _controller.add(Map.unmodifiable(_quotes));
    } else if (data is Map<String, dynamic>) {
      if (data.containsKey('quotes') && data['quotes'] is List) {
        for (final item in data['quotes'] as List) {
          if (item is Map<String, dynamic>) {
            final q = Quote.fromJson(item);
            _quotes[q.token] = q;
          }
        }
        _controller.add(Map.unmodifiable(_quotes));
      } else {
        final q = Quote.fromJson(data);
        if (q.token.isNotEmpty) {
          _quotes[q.token] = q;
          _controller.add(Map.unmodifiable(_quotes));
        }
      }
    }
  }

  void dispose() {
    _socketSub?.cancel();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}

final realtimeQuoteServiceProvider = Provider<RealtimeQuoteService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final service = RealtimeQuoteService(
    socketService: socketService,
    apiClient: apiClient,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Drop-in alias provider for existing code transitioning from tickerServiceProvider
final tickerServiceProvider = Provider<RealtimeQuoteService>((ref) {
  return ref.watch(realtimeQuoteServiceProvider);
});

final quotesStreamProvider = StreamProvider<Map<String, Quote>>((ref) {
  final service = ref.watch(realtimeQuoteServiceProvider);
  return service.stream;
});

final quoteDetailStreamProvider = StreamProvider.family<Quote, String>((ref, symbol) {
  final service = ref.watch(realtimeQuoteServiceProvider);
  return service.streamForToken(symbol);
});

