import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/candle_generator.dart';
import 'market_status_service.dart';

enum FeedConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class MarketTickPacket {
  final String token;
  final int sequence;
  final DateTime timestamp;
  final double ltp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
  final double bid;
  final double ask;
  final bool isStale;
  final int latencyMs;

  const MarketTickPacket({
    required this.token,
    required this.sequence,
    required this.timestamp,
    required this.ltp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.bid,
    required this.ask,
    this.isStale = false,
    this.latencyMs = 0,
  });

  MarketTickPacket copyWith({
    String? token,
    int? sequence,
    DateTime? timestamp,
    double? ltp,
    double? open,
    double? high,
    double? low,
    double? close,
    int? volume,
    double? bid,
    double? ask,
    bool? isStale,
    int? latencyMs,
  }) {
    return MarketTickPacket(
      token: token ?? this.token,
      sequence: sequence ?? this.sequence,
      timestamp: timestamp ?? this.timestamp,
      ltp: ltp ?? this.ltp,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      volume: volume ?? this.volume,
      bid: bid ?? this.bid,
      ask: ask ?? this.ask,
      isStale: isStale ?? this.isStale,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'sequence': sequence,
    'timestamp': timestamp.toIso8601String(),
    'ltp': ltp,
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'volume': volume,
    'bid': bid,
    'ask': ask,
    'isStale': isStale,
    'latencyMs': latencyMs,
  };
}

class RealtimeFeedService extends ChangeNotifier {
  FeedConnectionStatus _status = FeedConnectionStatus.disconnected;
  final StreamController<MarketTickPacket> _tickStreamController =
      StreamController<MarketTickPacket>.broadcast();

  // Sequence tracking per token for out-of-order rejection
  final Map<String, int> _lastSequences = {};

  // Deduplication cache: key -> timestamp
  final Set<String> _processedTickFingerprints = {};

  // Cached last-known snapshot for graceful fallback
  final Map<String, MarketTickPacket> _cachedSnapshots = {};

  // Heartbeat tracking
  DateTime? _lastPingSentAt;
  DateTime? _lastPongReceivedAt;
  int _lastHeartbeatLatencyMs = 0;
  Timer? _heartbeatTimer;
  int _missedHeartbeats = 0;

  // Reconnection backoff
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _initialBackoffMs = 1000;
  static const int _maxBackoffMs = 30000;

  // Stale data threshold (5 seconds SLA)
  static const Duration staleThreshold = Duration(seconds: 5);

  // Market status tracking
  MarketSessionState _marketState = MarketSessionState.open;

  // Diagnostics counters
  int outOfOrderDroppedCount = 0;
  int duplicateDroppedCount = 0;
  int invalidTimestampCount = 0;
  int staleTickCount = 0;

  bool _isDisposed = false;

  RealtimeFeedService() {
    connect();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  FeedConnectionStatus get status => _status;
  Stream<MarketTickPacket> get tickStream => _tickStreamController.stream;
  int get lastHeartbeatLatencyMs => _lastHeartbeatLatencyMs;
  MarketSessionState get marketState => _marketState;
  int get reconnectAttempts => _reconnectAttempts;

  // ─── 1. Connection & Reconnection Management ───────────────────────────────

  void connect() {
    _status = FeedConnectionStatus.connecting;
    notifyListeners();

    // Simulate WebSocket handshake
    Future.delayed(const Duration(milliseconds: 100), () {
      _status = FeedConnectionStatus.connected;
      _reconnectAttempts = 0;
      _startHeartbeat();
      notifyListeners();
    });
  }

  void disconnect({bool isPlanned = true}) {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _status = FeedConnectionStatus.disconnected;
    notifyListeners();

    if (!isPlanned) {
      _scheduleReconnect();
    }
  }

  void triggerNetworkLoss() {
    disconnect(isPlanned: false);
  }

  void _scheduleReconnect() {
    _status = FeedConnectionStatus.reconnecting;
    _reconnectAttempts++;
    notifyListeners();

    // Exponential backoff: min(maxBackoff, initial * 2^(attempts-1))
    final backoffMs = min(
      _maxBackoffMs,
      _initialBackoffMs * pow(2, _reconnectAttempts - 1).toInt(),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: backoffMs), () {
      connect();
    });
  }

  // ─── 2. Heartbeat / Ping-Pong Handling ─────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      sendPing();
    });
  }

  void sendPing() {
    if (_status != FeedConnectionStatus.connected) return;
    _lastPingSentAt = DateTime.now();

    // Simulate server pong reply
    Future.delayed(const Duration(milliseconds: 25), () {
      handlePong(DateTime.now());
    });
  }

  void handlePong(DateTime pongTimestamp) {
    if (_lastPingSentAt != null) {
      _lastPongReceivedAt = pongTimestamp;
      _lastHeartbeatLatencyMs = pongTimestamp.difference(_lastPingSentAt!).inMilliseconds;
      _missedHeartbeats = 0;
      notifyListeners();
    }
  }

  void checkHeartbeatLiveness() {
    if (_lastPingSentAt != null && _lastPongReceivedAt != null) {
      if (_lastPingSentAt!.difference(_lastPongReceivedAt!).inSeconds > 15) {
        _missedHeartbeats++;
        if (_missedHeartbeats >= 2) {
          triggerNetworkLoss();
        }
      }
    }
  }

  // ─── 3. Ingestion, Validation, Out-of-Order & Duplicate Handling ────────────

  bool ingestPacket(MarketTickPacket packet) {
    final now = DateTime.now();

    // 1. Timestamp validation (check for clock skew > 2 seconds into future or > 1 hour old)
    if (packet.timestamp.isAfter(now.add(const Duration(seconds: 2)))) {
      invalidTimestampCount++;
      return false; // Future-dated tick rejected
    }
    if (now.difference(packet.timestamp).inHours > 1) {
      invalidTimestampCount++;
      return false; // Obsolete tick rejected
    }

    // 2. Duplicate tick detection
    final fingerprint = '${packet.token}:${packet.sequence}:${packet.timestamp.millisecondsSinceEpoch}:${packet.ltp}';
    if (_processedTickFingerprints.contains(fingerprint)) {
      duplicateDroppedCount++;
      return false; // Duplicate packet dropped
    }
    _processedTickFingerprints.add(fingerprint);
    if (_processedTickFingerprints.length > 5000) {
      _processedTickFingerprints.clear();
    }

    // 3. Out-of-order sequence check
    final lastSeq = _lastSequences[packet.token] ?? 0;
    if (packet.sequence <= lastSeq && lastSeq > 0) {
      outOfOrderDroppedCount++;
      return false; // Sequence is older than last processed tick
    }
    _lastSequences[packet.token] = packet.sequence;

    // 4. Stale-data detection
    final isStale = now.difference(packet.timestamp) > staleThreshold;
    if (isStale) {
      staleTickCount++;
    }

    final enrichedPacket = packet.copyWith(
      isStale: isStale,
      latencyMs: now.difference(packet.timestamp).inMilliseconds,
    );

    _cachedSnapshots[packet.token] = enrichedPacket;
    _tickStreamController.add(enrichedPacket);
    notifyListeners();
    return true;
  }

  // ─── 4. Market-Status Events ───────────────────────────────────────────────

  void handleMarketStatusEvent(MarketSessionState newState) {
    if (_marketState != newState) {
      _marketState = newState;
      notifyListeners();
    }
  }

  // ─── 5. Graceful Fallback When Feed Is Unavailable ─────────────────────────

  MarketTickPacket getFallbackSnapshot(String token) {
    if (_cachedSnapshots.containsKey(token)) {
      return _cachedSnapshots[token]!.copyWith(isStale: true);
    }

    // Generate cold snapshot from base prices
    final base = CandleGenerator.getBasePrice(token);
    final fallback = MarketTickPacket(
      token: token,
      sequence: 1,
      timestamp: DateTime.now(),
      ltp: base,
      open: base,
      high: base * 1.01,
      low: base * 0.99,
      close: base,
      volume: 10000,
      bid: base * 0.999,
      ask: base * 1.001,
      isStale: true,
      latencyMs: 0,
    );
    _cachedSnapshots[token] = fallback;
    return fallback;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _tickStreamController.close();
    super.dispose();
  }
}

final realtimeFeedServiceProvider = ChangeNotifierProvider<RealtimeFeedService>((ref) {
  final service = RealtimeFeedService();
  ref.onDispose(() => service.dispose());
  return service;
});

final feedConnectionStatusProvider = Provider<FeedConnectionStatus>((ref) {
  final service = ref.watch(realtimeFeedServiceProvider);
  return service.status;
});
