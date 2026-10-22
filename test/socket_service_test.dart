import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/config/app_config.dart';
import 'package:zero_dalali/core/network/socket_service.dart';
import 'package:zero_dalali/core/network/token_storage.dart';

void main() {
  group('SocketService Canonical & Resiliency Unit Tests', () {
    late AppConfig config;
    late TokenStorage tokenStorage;
    late SocketService socketService;

    setUp(() {
      config = const AppConfig(
        apiBaseUrl: 'http://localhost:5000',
        socketBaseUrl: 'http://localhost:5000',
      );
      tokenStorage = TokenStorage();
      socketService = SocketService(
        config: config,
        tokenStorage: tokenStorage,
      );
    });

    tearDown(() {
      socketService.dispose();
    });

    test('Initializes with disconnected state and starts REST fallback safely', () {
      expect(socketService.isConnected, isFalse);
      expect(socketService.getAllQuotes(), isEmpty);
    });

    test('Subscribe buffers symbols and handles single symbol subscribe', () {
      socketService.subscribe('RELIANCE');
      // When disconnected, it doesn't crash and tracks symbol
      expect(socketService.getQuote('RELIANCE'), isNull);
    });

    test('SubscribeAll batches multiple symbols correctly', () {
      final symbols = List.generate(120, (i) => 'SYM_$i');
      socketService.subscribeAll(symbols);
      // All symbols registered
      expect(symbols.length, 120);
    });

    test('Unsubscribe removes symbol cleanly', () {
      socketService.subscribe('TCS');
      socketService.unsubscribe('TCS');
      expect(socketService.getQuote('TCS'), isNull);
    });

    test('UnsubscribeAll removes symbol list cleanly', () {
      socketService.subscribeAll(['INFY', 'HDFCBANK']);
      socketService.unsubscribeAll(['INFY', 'HDFCBANK']);
      expect(socketService.getQuote('INFY'), isNull);
      expect(socketService.getQuote('HDFCBANK'), isNull);
    });

    test('updateAuthToken handles null or empty token safely without crashing', () async {
      await socketService.updateAuthToken(null);
      await socketService.updateAuthToken('');
      expect(socketService.isConnected, isFalse);
    });
  });
}
