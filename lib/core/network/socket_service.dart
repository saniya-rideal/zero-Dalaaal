import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../../data/models/models.dart';
import 'api_client.dart';
import 'api_paths.dart';
import 'token_storage.dart';

class SocketService {
  final AppConfig _config;
  final TokenStorage _tokenStorage;
  final ApiClient? _apiClient;
  io.Socket? _socket;

  static const int _maxBatchSize = 50;

  final Map<String, Quote> _latestQuotes = {};
  final Set<String> _subscribedSymbols = {};
  String? _activeTicketId;
  bool _isRefreshingToken = false;

  // Stream controllers
  final StreamController<Map<String, Quote>> _quotesStreamController =
      StreamController<Map<String, Quote>>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _orderUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _positionUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _gttTriggeredController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _alertTriggeredController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _sipExecutedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _supportMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _paymentUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _withdrawalUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  Stream<bool> get connectionStream => _connectionStateController.stream;

  // Streams for per-user events
  Stream<Map<String, Quote>> get quotesStream => _quotesStreamController.stream;
  Stream<Map<String, dynamic>> get orderUpdatesStream => _orderUpdatesController.stream;
  Stream<Map<String, dynamic>> get positionUpdatesStream => _positionUpdatesController.stream;
  Stream<Map<String, dynamic>> get gttTriggeredStream => _gttTriggeredController.stream;
  Stream<Map<String, dynamic>> get alertTriggeredStream => _alertTriggeredController.stream;
  Stream<Map<String, dynamic>> get sipExecutedStream => _sipExecutedController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  Stream<Map<String, dynamic>> get supportMessageStream => _supportMessageController.stream;
  Stream<Map<String, dynamic>> get paymentUpdatesStream => _paymentUpdatesController.stream;
  Stream<Map<String, dynamic>> get withdrawalUpdatesStream => _withdrawalUpdatesController.stream;

  // REST polling fallback timer (only active when socket is down)
  Timer? _restFallbackTimer;
  Dio? _fallbackDio;

  SocketService({
    required AppConfig config,
    required TokenStorage tokenStorage,
    ApiClient? apiClient,
  })  : _config = config,
        _tokenStorage = tokenStorage,
        _apiClient = apiClient {
    _initSocket();
  }

  Future<void> _initSocket() async {
    final token = await _tokenStorage.getAccessToken();
    final uri = _config.socketBaseUrl;

    final optionsBuilder = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(9999)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000);

    if (token != null && token.isNotEmpty) {
      optionsBuilder.setAuth({'token': 'Bearer $token'});
    }

    _socket = io.io(uri, optionsBuilder.build());

    _socket?.onConnect((_) {
      _isConnected = true;
      _stopRestFallback();
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(true);
      }
      // Dual auth: handshake auth option is sent during connection, and authenticate event for post-connect listeners
      _tokenStorage.getAccessToken().then((t) {
        if (t != null && t.isNotEmpty && _socket != null && _isConnected) {
          _socket?.emit('authenticate', {'token': 'Bearer $t'});
        }
      });
      _resubscribeAll();
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(false);
      }
      _startRestFallback();
    });

    _socket?.onConnectError((err) {
      _isConnected = false;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(false);
      }
      _startRestFallback();
      _checkAuthError(err);
    });

    _socket?.on('error', (err) {
      _checkAuthError(err);
    });

    // Contract Section 12.3: Server-Emitted Events
    _socket?.on('quote:update', (data) => _handleIncomingQuote(data));
    _socket?.on('order:update', (data) => _handleSafeMapEvent(data, _orderUpdatesController));
    _socket?.on('position:update', (data) => _handleSafeMapEvent(data, _positionUpdatesController));
    _socket?.on('gtt:triggered', (data) => _handleSafeMapEvent(data, _gttTriggeredController));
    _socket?.on('alert:triggered', (data) => _handleSafeMapEvent(data, _alertTriggeredController));
    _socket?.on('sip:executed', (data) => _handleSafeMapEvent(data, _sipExecutedController));
    _socket?.on('notification:new', (data) => _handleSafeMapEvent(data, _notificationController));
    _socket?.on('support:message', (data) => _handleSafeMapEvent(data, _supportMessageController));
    _socket?.on('payment:update', (data) => _handleSafeMapEvent(data, _paymentUpdatesController));
    _socket?.on('withdrawal:update', (data) => _handleSafeMapEvent(data, _withdrawalUpdatesController));
  }

  void _checkAuthError(dynamic err) {
    if (err == null) return;
    final errStr = err.toString().toLowerCase();
    if (errStr.contains('401') ||
        errStr.contains('unauthorized') ||
        errStr.contains('jwt') ||
        errStr.contains('token') ||
        errStr.contains('auth')) {
      _handleAuthFailureAndReconnect();
    }
  }

  Future<void> _handleAuthFailureAndReconnect() async {
    if (_isRefreshingToken || _apiClient == null) return;
    _isRefreshingToken = true;
    try {
      final newToken = await _apiClient.refreshToken();
      if (newToken != null && newToken.isNotEmpty) {
        if (_socket != null) {
          _socket?.io.options?['auth'] = {'token': 'Bearer $newToken'};
          _socket?.disconnect().connect();
        }
      }
    } catch (_) {
    } finally {
      _isRefreshingToken = false;
    }
  }

  void _handleSafeMapEvent(
    dynamic data,
    StreamController<Map<String, dynamic>> controller,
  ) {
    if (!controller.isClosed) {
      if (data is Map<String, dynamic>) {
        controller.add(data);
      } else if (data is Map) {
        controller.add(Map<String, dynamic>.from(data));
      }
    }
  }

  /// Update auth token on socket (e.g., after login or token refresh)
  Future<void> updateAuthToken([String? explicitToken]) async {
    final token = explicitToken ?? await _tokenStorage.getAccessToken();
    if (_socket != null) {
      if (token != null && token.isNotEmpty) {
        _socket?.io.options?['auth'] = {'token': 'Bearer $token'};
        if (_socket!.connected) {
          _socket?.emit('authenticate', {'token': 'Bearer $token'});
        } else {
          _socket?.connect();
        }
      } else {
        _socket?.io.options?['auth'] = {};
        if (_socket!.connected) {
          _socket?.disconnect();
        }
      }
    }
  }

  /// Emit subscribe batches using canonical `quotes:subscribe` with { symbols: [...] }
  void _emitSubscribeBatches(List<String> symbols) {
    if (symbols.isEmpty) return;
    for (var i = 0; i < symbols.length; i += _maxBatchSize) {
      final end = (i + _maxBatchSize < symbols.length) ? i + _maxBatchSize : symbols.length;
      final batch = symbols.sublist(i, end);
      _emitSubscribeBatch(batch);
    }
  }

  void _emitSubscribeBatch(List<String> batch) {
    if (_socket == null || !_isConnected) return;
    try {
      _socket?.emitWithAck(
        'quotes:subscribe',
        {'symbols': batch},
        ack: (dynamic ackData) {
          _handleSubscriptionAck(ackData);
        },
      );
    } catch (_) {
      _socket?.emit('quotes:subscribe', {'symbols': batch});
    }
  }

  /// Emit unsubscribe batches using canonical `quotes:unsubscribe` with { symbols: [...] }
  void _emitUnsubscribeBatches(List<String> symbols) {
    if (symbols.isEmpty) return;
    for (var i = 0; i < symbols.length; i += _maxBatchSize) {
      final end = (i + _maxBatchSize < symbols.length) ? i + _maxBatchSize : symbols.length;
      final batch = symbols.sublist(i, end);
      _emitUnsubscribeBatch(batch);
    }
  }

  void _emitUnsubscribeBatch(List<String> batch) {
    if (_socket == null || !_isConnected) return;
    try {
      _socket?.emitWithAck(
        'quotes:unsubscribe',
        {'symbols': batch},
        ack: (dynamic ackData) {},
      );
    } catch (_) {
      _socket?.emit('quotes:unsubscribe', {'symbols': batch});
    }
  }

  void _handleSubscriptionAck(dynamic ackData) {
    if (ackData is Map) {
      final rejected = ackData['rejected'];
      if (rejected is List) {
        for (final item in rejected) {
          if (item != null) {
            _subscribedSymbols.remove(item.toString());
          }
        }
      }
    }
  }

  void _resubscribeAll() {
    if (_socket != null && _isConnected && _subscribedSymbols.isNotEmpty) {
      _emitSubscribeBatches(_subscribedSymbols.toList());
    }
    if (_socket != null && _isConnected && _activeTicketId != null) {
      _socket?.emit('ticket:join', {'ticketId': _activeTicketId});
    }
  }

  void _handleIncomingQuote(dynamic data) {
    if (_quotesStreamController.isClosed) return;
    if (data is Map<String, dynamic>) {
      final quote = _parseContractQuote(data);
      if (quote != null) {
        _latestQuotes[quote.token] = quote;
        if (!_quotesStreamController.isClosed) {
          _quotesStreamController.add(Map.unmodifiable(_latestQuotes));
        }
      }
    } else if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final quote = _parseContractQuote(item);
          if (quote != null) {
            _latestQuotes[quote.token] = quote;
          }
        }
      }
      if (data.isNotEmpty && !_quotesStreamController.isClosed) {
        _quotesStreamController.add(Map.unmodifiable(_latestQuotes));
      }
    }
  }

  Quote? _parseContractQuote(Map<String, dynamic> json) {
    try {
      final symbol = (json['symbol'] ?? json['token'] ?? json['_id'] ?? '').toString();
      if (symbol.isEmpty) return null;

      final last = _toDouble(json['last'] ?? json['ltp'] ?? json['price']) ?? 0.0;
      final open = _toDouble(json['open']) ?? last;
      final prevClose = _toDouble(json['prevClose'] ?? json['previousClose']) ?? open;
      final high = _toDouble(json['high']) ?? last;
      final low = _toDouble(json['low']) ?? last;
      final close = _toDouble(json['close']) ?? last;
      final change = _toDouble(json['change']) ?? (last - prevClose);
      final changePercent = _toDouble(json['changePercent'] ?? json['pChange']) ??
          (prevClose != 0 ? ((change / prevClose) * 100) : 0.0);
      final volume = _toInt(json['volume'] ?? json['vol']) ?? 0;

      final bid = _toDouble(json['bid']) ?? last;
      final ask = _toDouble(json['ask']) ?? last;

      final MarketDepth depth = MarketDepth(
        buy: [DepthLevel(price: bid, qty: 1, orders: 1)],
        sell: [DepthLevel(price: ask, qty: 1, orders: 1)],
      );

      DateTime timestamp;
      if (json['timestamp'] != null) {
        timestamp = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
      } else {
        timestamp = DateTime.now();
      }

      return Quote(
        token: symbol,
        ltp: last,
        open: open,
        high: high,
        low: low,
        close: close,
        prevClose: prevClose,
        change: double.parse(change.toStringAsFixed(2)),
        changePercent: double.parse(changePercent.toStringAsFixed(2)),
        volume: volume,
        lowerCircuit: _toDouble(json['lowerCircuit']) ?? (prevClose * 0.9),
        upperCircuit: _toDouble(json['upperCircuit']) ?? (prevClose * 1.1),
        high52: _toDouble(json['high52']) ?? (high * 1.2),
        low52: _toDouble(json['low52']) ?? (low * 0.8),
        depth: depth,
        timestamp: timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? double.tryParse(val)?.toInt();
    return null;
  }

  Quote? getQuote(String token) {
    return _latestQuotes[token];
  }

  Map<String, Quote> getAllQuotes() => Map.unmodifiable(_latestQuotes);

  /// Subscribe to live quote ticks for a symbol using canonical events
  void subscribe(String symbol) {
    final clean = symbol.trim();
    if (clean.isEmpty) return;
    _subscribedSymbols.add(clean);
    if (_socket != null && _isConnected) {
      _emitSubscribeBatches([clean]);
    } else {
      _startRestFallback();
    }
  }

  void subscribeAll(Iterable<String> symbols) {
    final validSymbols = symbols.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (validSymbols.isEmpty) return;
    _subscribedSymbols.addAll(validSymbols);
    if (_socket != null && _isConnected) {
      _emitSubscribeBatches(validSymbols);
    } else {
      _startRestFallback();
    }
  }

  /// Unsubscribe from symbol quote ticks using canonical events
  void unsubscribe(String symbol) {
    final clean = symbol.trim();
    _subscribedSymbols.remove(clean);
    if (_socket != null && _isConnected) {
      _emitUnsubscribeBatches([clean]);
    }
  }

  void unsubscribeAll(Iterable<String> symbols) {
    final validSymbols = symbols.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    for (final s in validSymbols) {
      _subscribedSymbols.remove(s);
    }
    if (_socket != null && _isConnected) {
      _emitUnsubscribeBatches(validSymbols);
    }
  }

  /// Join support ticket chat room
  void joinTicket(String ticketId) {
    _activeTicketId = ticketId;
    if (_socket != null && _socket!.connected) {
      _socket?.emit('ticket:join', {'ticketId': ticketId});
    }
  }

  /// Leave support ticket chat room
  void leaveTicket(String ticketId) {
    if (_activeTicketId == ticketId) {
      _activeTicketId = null;
    }
    if (_socket != null && _socket!.connected) {
      _socket?.emit('ticket:leave', {'ticketId': ticketId});
    }
  }

  // --- REST Polling Fallback when Socket is Down ---

  void _startRestFallback() {
    if (_restFallbackTimer != null) return;
    _fallbackDio ??= Dio(
      BaseOptions(
        baseUrl: _config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    // Initial poll immediately if disconnected and symbols exist
    if (_subscribedSymbols.isNotEmpty && !_isConnected) {
      _pollRestQuotes();
    }

    _restFallbackTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (_subscribedSymbols.isEmpty || _isConnected) {
        return;
      }
      await _pollRestQuotes();
    });
  }

  Future<void> _pollRestQuotes() async {
    if (_subscribedSymbols.isEmpty || _isConnected) return;
    try {
      final symbols = _subscribedSymbols.take(_maxBatchSize).join(',');
      final response = await _fallbackDio!.get(
        ApiPaths.marketQuotes,
        queryParameters: {'symbols': symbols},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          _handleIncomingQuote(data['data']);
        } else {
          _handleIncomingQuote(data);
        }
      }
    } catch (_) {}
  }

  void _stopRestFallback() {
    _restFallbackTimer?.cancel();
    _restFallbackTimer = null;
  }

  Stream<Map<String, Quote>> get stream => _quotesStreamController.stream;

  Stream<Quote> streamForToken(String token) {
    subscribe(token);
    return _quotesStreamController.stream
        .where((map) => map.containsKey(token))
        .map((map) => map[token]!);
  }

  void dispose() {
    _stopRestFallback();
    try {
      _socket?.clearListeners();
      _socket?.disconnect();
      _socket?.close();
      _socket?.destroy();
      _socket?.dispose();
      _socket = null;
    } catch (_) {}
    if (!_quotesStreamController.isClosed) _quotesStreamController.close();
    if (!_connectionStateController.isClosed) _connectionStateController.close();
    if (!_orderUpdatesController.isClosed) _orderUpdatesController.close();
    if (!_positionUpdatesController.isClosed) _positionUpdatesController.close();
    if (!_gttTriggeredController.isClosed) _gttTriggeredController.close();
    if (!_alertTriggeredController.isClosed) _alertTriggeredController.close();
    if (!_sipExecutedController.isClosed) _sipExecutedController.close();
    if (!_notificationController.isClosed) _notificationController.close();
    if (!_supportMessageController.isClosed) _supportMessageController.close();
    if (!_paymentUpdatesController.isClosed) _paymentUpdatesController.close();
    if (!_withdrawalUpdatesController.isClosed) _withdrawalUpdatesController.close();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  final service = SocketService(
    config: config,
    tokenStorage: tokenStorage,
    apiClient: apiClient,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final socketConnectedProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.connectionStream;
});
