import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_dalali/core/constants/app_constants.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'candle_generator_fixture.dart';

class TickerService {
  final Map<String, Quote> _latestQuotes = {};
  final Set<String> _subscribedTokens = {};
  final StreamController<Map<String, Quote>> _quotesStreamController =
      StreamController<Map<String, Quote>>.broadcast();
  final Random _random = Random(42);
  Timer? _timer;

  TickerService() {
    _initQuotes();
    _startTicker();
  }

  void _initQuotes() {
    for (final entry in CandleGenerator.basePrices.entries) {
      final token = entry.key;
      final base = entry.value;
      final prevClose = base;
      final change = (base * 0.012) * (_random.nextDouble() > 0.4 ? 1 : -1);
      final ltp = base + change;
      final changePercent = (change / prevClose) * 100;
      final open = base + (change * 0.4);
      final high = max(open, ltp) + (base * 0.005);
      final low = min(open, ltp) - (base * 0.005);

      _latestQuotes[token] = Quote(
        token: token,
        ltp: double.parse(ltp.toStringAsFixed(2)),
        open: double.parse(open.toStringAsFixed(2)),
        high: double.parse(high.toStringAsFixed(2)),
        low: double.parse(low.toStringAsFixed(2)),
        close: double.parse(ltp.toStringAsFixed(2)),
        prevClose: double.parse(prevClose.toStringAsFixed(2)),
        change: double.parse(change.toStringAsFixed(2)),
        changePercent: double.parse(changePercent.toStringAsFixed(2)),
        volume: 120000 + _random.nextInt(850000),
        lowerCircuit: double.parse((prevClose * 0.90).toStringAsFixed(2)),
        upperCircuit: double.parse((prevClose * 1.10).toStringAsFixed(2)),
        high52: double.parse((base * 1.35).toStringAsFixed(2)),
        low52: double.parse((base * 0.75).toStringAsFixed(2)),
        depth: _generateDepth(ltp),
        timestamp: DateTime.now(),
      );
    }
  }

  MarketDepth _generateDepth(double ltp) {
    final List<DepthLevel> buy = [];
    final List<DepthLevel> sell = [];

    for (int i = 1; i <= 5; i++) {
      buy.add(DepthLevel(
        price: double.parse((ltp - (i * 0.15)).toStringAsFixed(2)),
        qty: 50 + _random.nextInt(1200),
        orders: 1 + _random.nextInt(25),
      ));
      sell.add(DepthLevel(
        price: double.parse((ltp + (i * 0.15)).toStringAsFixed(2)),
        qty: 50 + _random.nextInt(1200),
        orders: 1 + _random.nextInt(25),
      ));
    }

    return MarketDepth(buy: buy, sell: sell);
  }

  void _startTicker() {
    _timer = Timer.periodic(
      const Duration(milliseconds: AppConstants.tickerIntervalMs),
      (_) => _tick(),
    );
  }

  void _tick() {
    // If no specific subscriptions, tick a random subset of all instruments
    final tokensToTick = _subscribedTokens.isNotEmpty
        ? _subscribedTokens
        : _latestQuotes.keys.take(20).toSet();

    final Map<String, Quote> updated = {};

    for (final token in tokensToTick) {
      final current = _latestQuotes[token];
      if (current == null) continue;

      // Small random delta (±0.05% to ±0.25%)
      final deltaFactor = (_random.nextDouble() - 0.495) * 0.003;
      final delta = current.ltp * deltaFactor;
      final newLtp = double.parse((current.ltp + delta).toStringAsFixed(2));
      final newChange = double.parse((newLtp - current.prevClose).toStringAsFixed(2));
      final newChangePct = double.parse(((newChange / current.prevClose) * 100).toStringAsFixed(2));
      final newHigh = max(current.high, newLtp);
      final newLow = min(current.low, newLtp);
      final newVol = current.volume + (10 + _random.nextInt(250));

      final updatedQuote = current.copyWith(
        ltp: newLtp,
        high: newHigh,
        low: newLow,
        change: newChange,
        changePercent: newChangePct,
        volume: newVol,
        depth: _generateDepth(newLtp),
        timestamp: DateTime.now(),
      );

      _latestQuotes[token] = updatedQuote;
      updated[token] = updatedQuote;
    }

    if (updated.isNotEmpty) {
      _quotesStreamController.add(Map.unmodifiable(_latestQuotes));
    }
  }

  Quote getQuote(String token) {
    if (!_latestQuotes.containsKey(token)) {
      final base = CandleGenerator.getBasePrice(token);
      _latestQuotes[token] = Quote(
        token: token,
        ltp: base,
        open: base,
        high: base * 1.01,
        low: base * 0.99,
        close: base,
        prevClose: base,
        change: 0.0,
        changePercent: 0.0,
        volume: 50000,
        depth: _generateDepth(base),
        timestamp: DateTime.now(),
      );
    }
    return _latestQuotes[token]!;
  }

  Map<String, Quote> getAllQuotes() => Map.unmodifiable(_latestQuotes);

  void subscribe(String token) {
    _subscribedTokens.add(token);
  }

  void subscribeAll(Iterable<String> tokens) {
    _subscribedTokens.addAll(tokens);
  }

  void unsubscribe(String token) {
    _subscribedTokens.remove(token);
  }

  void unsubscribeAll(Iterable<String> tokens) {
    _subscribedTokens.removeAll(tokens);
  }

  Stream<Map<String, Quote>> get stream => _quotesStreamController.stream;

  Stream<Quote> streamForToken(String token) {
    subscribe(token);
    return _quotesStreamController.stream
        .where((map) => map.containsKey(token))
        .map((map) => map[token]!);
  }

  void dispose() {
    _timer?.cancel();
    _quotesStreamController.close();
  }
}

final tickerServiceProvider = Provider<TickerService>((ref) {
  final service = TickerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final quotesStreamProvider = StreamProvider<Map<String, Quote>>((ref) {
  final service = ref.watch(tickerServiceProvider);
  return service.stream;
});

final singleQuoteProvider = StreamProvider.family<Quote, String>((ref, token) {
  final service = ref.watch(tickerServiceProvider);
  return service.streamForToken(token);
});
