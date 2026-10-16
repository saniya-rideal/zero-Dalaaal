import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/config/app_config.dart';
import 'package:zero_dalali/core/network/api_client.dart';
import 'package:zero_dalali/core/network/token_storage.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/alerts/data/alerts_repository.dart';
import 'package:zero_dalali/features/auth/data/real_auth_repository.dart';
import 'package:zero_dalali/features/baskets/data/baskets_repository.dart';
import 'package:zero_dalali/features/calculator/data/charges_repository.dart';
import 'package:zero_dalali/features/calendar/data/calendar_repository.dart';
import 'package:zero_dalali/features/funds/data/real_funds_repository.dart';
import 'package:zero_dalali/features/heatmap/data/heatmap_repository.dart';
import 'package:zero_dalali/features/ipo/data/ipo_repository.dart';
import 'package:zero_dalali/features/market/data/real_market_repository.dart';
import 'package:zero_dalali/features/news/data/learning_repository.dart';
import 'package:zero_dalali/features/news/data/news_repository.dart';
import 'package:zero_dalali/features/notifications/data/notifications_repository.dart';
import 'package:zero_dalali/features/option_chain/data/option_chain_repository.dart';
import 'package:zero_dalali/features/order_entry/data/gtt_repository.dart';
import 'package:zero_dalali/features/orders/data/real_trading_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/app_config_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/compliance_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/kyc_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/pinned_instruments_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/reports_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/support_repository.dart';
import 'package:zero_dalali/features/quote_detail/data/fundamentals_repository.dart';
import 'package:zero_dalali/features/sip/data/sip_repository.dart';
import 'package:zero_dalali/features/watchlist/data/real_watchlist_repository.dart';

class CallRecording {
  String method = '';
  String path = '';
  dynamic data;
  Map<String, dynamic>? queryParameters;
}

Dio _createMockDio(dynamic responseBody, {int statusCode = 200, CallRecording? recording}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (recording != null) {
          recording.method = options.method;
          recording.path = options.path;
          recording.data = options.data;
          recording.queryParameters = options.queryParameters;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            data: responseBody,
            statusCode: statusCode,
          ),
        );
      },
    ),
  );
  return dio;
}

ApiClient _createMockApiClient(dynamic responseBody, {int statusCode = 200, CallRecording? recording}) {
  final mockDio = _createMockDio(responseBody, statusCode: statusCode, recording: recording);
  return ApiClient(
    config: const AppConfig(
      apiBaseUrl: 'http://test',
      socketBaseUrl: 'http://test',
    ),
    tokenStorage: TokenStorage(),
    dio: mockDio,
  );
}

void main() {
  group('Real Repositories with Mocked Dio Tests', () {
    test('1. RealMarketRepository.getInstruments: unwraps items list from envelope', () async {
      final rec = CallRecording();
      final backendEnvelope = {
        'success': true,
        'message': 'Instruments retrieved',
        'data': {
          'items': [
            {
              'symbol': 'RELIANCE',
              'name': 'Reliance Industries Ltd',
              'market': 'INDIAN',
              'segment': 'EQUITY',
              'exchange': 'NSE',
              'type': 'EQ',
              'quoteCurrency': 'INR',
              'tickSize': 0.05,
              'lotSize': 1,
              'minQuantity': 1,
              'quantityStep': 1,
              'maxLeverage': 5,
              'defaultLeverage': 5,
              'takerFeeRate': 0.0002,
              'isActive': true,
            },
            {
              'symbol': 'NIFTY 50',
              'name': 'Nifty 50 Index',
              'market': 'INDIAN',
              'segment': 'INDICES',
              'exchange': 'NSE',
              'type': 'INDEX',
              'quoteCurrency': 'INR',
              'tickSize': 0.05,
              'lotSize': 1,
              'minQuantity': 1,
              'quantityStep': 1,
              'maxLeverage': 1,
              'defaultLeverage': 1,
              'takerFeeRate': 0.0,
              'isActive': true,
            }
          ]
        }
      };

      final apiClient = _createMockApiClient(backendEnvelope, recording: rec);
      final repo = RealMarketRepository(apiClient: apiClient);

      final instruments = await repo.getInstruments();

      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/instruments');
      expect(instruments.length, 2);
      expect(instruments[0].symbol, 'RELIANCE');
      expect(instruments[0].token, 'RELIANCE');
      expect(instruments[0].exchange, Exchange.NSE);
      expect(instruments[0].type, InstrumentType.EQ);
      expect(instruments[1].symbol, 'NIFTY 50');
      expect(instruments[1].type, InstrumentType.INDEX);
    });

    test('2. RealTradingRepository.getOrders: unwraps items list from envelope', () async {
      final rec = CallRecording();
      final backendEnvelope = {
        'success': true,
        'message': 'Orders retrieved',
        'data': {
          'items': [
            {
              'id': 'ord_101',
              'symbol': 'INFY',
              'side': 'BUY',
              'orderType': 'MARKET',
              'quantity': 50,
              'avgPrice': 1750.00,
              'status': 'FILLED',
              'margin': 17500.00,
              'fees': 15.00,
              'leverage': 5.0,
              'stopLoss': 1700.00,
              'takeProfit': 1850.00,
              'createdAt': '2026-10-10T10:00:00.000Z',
            }
          ]
        }
      };

      final apiClient = _createMockApiClient(backendEnvelope, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final orders = await repo.getOrders();

      expect(rec.method, 'GET');
      expect(rec.path, '/api/orders');
      expect(orders.length, 1);
      expect(orders[0].orderId, 'ord_101');
      expect(orders[0].instrument.symbol, 'INFY');
      expect(orders[0].request.side, TransactionType.BUY);
      expect(orders[0].request.quantity, 50);
      expect(orders[0].status, OrderStatus.COMPLETE);
    });

    test('3. RealTradingRepository.createOrder: unwraps nested order from envelope', () async {
      final rec = CallRecording();
      final backendEnvelope = {
        'success': true,
        'message': 'Order placed successfully',
        'data': {
          'order': {
            'id': 'ord_202',
            'symbol': 'TCS',
            'side': 'BUY',
            'orderType': 'LIMIT',
            'quantity': 10,
            'limitPrice': 3950.00,
            'avgPrice': 3950.00,
            'status': 'OPEN',
            'margin': 7900.00,
            'fees': 10.00,
            'leverage': 5.0,
            'stopLoss': 3900.00,
            'takeProfit': 4100.00,
            'createdAt': '2026-10-10T10:15:00.000Z',
          }
        }
      };

      final apiClient = _createMockApiClient(backendEnvelope, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final order = await repo.createOrder(
        symbol: 'TCS',
        side: TransactionType.BUY,
        orderType: OrderKind.LIMIT,
        quantity: 10,
        limitPrice: 3950.00,
        stopLoss: 3900.00,
        takeProfit: 4100.00,
        idempotencyKey: 'test_key_123',
      );

      expect(rec.method, 'POST');
      expect(rec.path, '/api/orders');
      expect(order.orderId, 'ord_202');
      expect(order.instrument.symbol, 'TCS');
      expect(order.request.side, TransactionType.BUY);
      expect(order.status, OrderStatus.OPEN);
      expect(order.request.bracket?.stopLoss, 3900.00);
      expect(order.request.bracket?.target, 4100.00);
    });

    test('4. RealTradingRepository.getPositions: unwraps positions list from envelope', () async {
      final rec = CallRecording();
      final backendEnvelope = {
        'success': true,
        'message': 'Positions retrieved',
        'data': {
          'positions': [
            {
              'id': 'pos_303',
              'symbol': 'HDFCBANK',
              'side': 'BUY',
              'quantity': 20,
              'entryPrice': 1550.00,
              'currentPrice': 1580.00,
              'unrealizedPnl': 600.00,
              'realizedPnl': 0.00,
              'margin': 6200.00,
              'leverage': 5.0,
              'status': 'OPEN',
              'createdAt': '2026-10-10T09:30:00.000Z',
            }
          ]
        }
      };

      final apiClient = _createMockApiClient(backendEnvelope, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final positions = await repo.getPositions();

      expect(rec.method, 'GET');
      expect(rec.path, '/api/positions');
      expect(positions.length, 1);
      expect(positions[0].id, 'pos_303');
      expect(positions[0].instrument.symbol, 'HDFCBANK');
      expect(positions[0].buyAvg, 1550.00);
      expect(positions[0].ltp, 1580.00);
      expect(positions[0].unrealizedPnl, 600.00);
      expect(positions[0].usedMargin, 6200.00);
    });

    test('5. RealWatchlistRepository.getAllWatchlists: unwraps watchlists list from envelope', () async {
      final rec = CallRecording();
      final backendEnvelope = {
        'success': true,
        'message': 'Watchlists retrieved',
        'data': {
          'watchlists': [
            {
              'id': 'wl_404',
              'name': 'Bluechips',
              'symbols': ['RELIANCE', 'TCS', 'HDFCBANK', 'INFY'],
            }
          ]
        }
      };

      final apiClient = _createMockApiClient(backendEnvelope, recording: rec);
      final repo = RealWatchlistRepository(apiClient: apiClient);

      final watchlists = await repo.getAllWatchlists();

      expect(rec.method, 'GET');
      expect(rec.path, '/api/watchlists');
      expect(watchlists.length, 1);
      expect(watchlists[0].id, 'wl_404');
      expect(watchlists[0].name, 'Bluechips');
      expect(watchlists[0].instrumentTokens, ['RELIANCE', 'TCS', 'HDFCBANK', 'INFY']);
    });

    test('6. RealFundsRepository.getFundsSummary: unwraps summary from envelope', () async {
      final rec = CallRecording();
      final backendEnvelope = {
        'success': true,
        'message': 'Funds summary retrieved',
        'data': {
          'summary': {
            'cash': 500000.00,
            'bonus': 0.0,
            'usedMargin': 25000.00,
            'freeMargin': 475000.00,
            'withdrawable': 475000.00,
            'openingBalance': 500000.00,
            'unrealizedPnl': 3450.00,
            'currency': 'INR',
          }
        }
      };

      final apiClient = _createMockApiClient(backendEnvelope, recording: rec);
      final repo = RealFundsRepository(apiClient: apiClient);

      final summary = await repo.getFundsSummary();

      expect(rec.method, 'GET');
      expect(rec.path, '/api/funds/summary');
      expect(summary.cash, 500000.00);
      expect(summary.usedMargin, 25000.00);
      expect(summary.availableMargin, 475000.00);
      expect(summary.withdrawable, 475000.00);
      expect(summary.unrealizedPnl, 3450.00);
    });

    // ─── ROUND 3 CONTRACT ENDPOINT TESTS: ASSERT EXACT METHOD AND PATH ───────────

    test('7. Trading: cancelOrder calls POST /api/orders/:id/cancel', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({'success': true, 'message': 'Order cancelled'}, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final result = await repo.cancelOrder('ord_999');

      expect(result, isTrue);
      expect(rec.method, 'POST');
      expect(rec.path, '/api/orders/ord_999/cancel');
    });

    test('8. Trading: closePosition calls POST /api/positions/:id/close', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'order': {
            'id': 'ord_close_1',
            'symbol': 'TCS',
            'side': 'SELL',
            'orderType': 'MARKET',
            'quantity': 10,
            'status': 'FILLED',
          }
        }
      }, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final order = await repo.closePosition('pos_123', quantity: 10);

      expect(order.orderId, 'ord_close_1');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/positions/pos_123/close');
    });

    test('9. Trading: convertPosition calls PUT /api/positions/:id/convert', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({'success': true}, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final res = await repo.convertPosition('pos_123', targetProduct: 'CNC');

      expect(res, isTrue);
      expect(rec.method, 'PUT');
      expect(rec.path, '/api/positions/pos_123/convert');
    });

    test('10. Trading: getHoldings calls GET /api/portfolio/holdings', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'holdings': [
            {
              'symbol': 'INFY',
              'quantity': 25,
              'avgPrice': 1500.0,
              'currentPrice': 1600.0,
              'pnl': 2500.0,
            }
          ]
        }
      }, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final holdings = await repo.getHoldings();

      expect(rec.method, 'GET');
      expect(rec.path, '/api/portfolio/holdings');
      expect(holdings.length, 1);
    });

    test('11. Trading: getPortfolioSummary calls GET /api/portfolio/summary', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'totalHoldingValue': 40000.0,
          'totalInvestment': 37500.0,
          'totalPnl': 2500.0,
        }
      }, recording: rec);
      final repo = RealTradingRepository(apiClient: apiClient);

      final summary = await repo.getPortfolioSummary();

      expect(rec.method, 'GET');
      expect(rec.path, '/api/portfolio/summary');
      expect(summary['totalHoldingValue'], 40000.0);
    });

    test('12. Alerts: toggleAlert calls PATCH /api/alerts/:id/toggle', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'id': 'alt_555',
          'symbol': 'RELIANCE',
          'targetPrice': 3000.0,
          'condition': 'GTE',
          'isActive': false,
        }
      }, recording: rec);
      final repo = AlertsRepository(apiClient);

      final alert = await repo.toggleAlert('alt_555');

      expect(rec.method, 'PATCH');
      expect(rec.path, '/api/alerts/alt_555/toggle');
      expect(alert.id, 'alt_555');
      expect(alert.isActive, isFalse);
    });

    test('13. Alerts: createAlert calls POST /api/alerts & deleteAlert calls DELETE /api/alerts/:id', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'id': 'alt_123',
          'symbol': 'TCS',
          'targetPrice': 4000.0,
          'condition': 'GTE',
          'isActive': true,
        }
      }, recording: rec);
      final repo = AlertsRepository(apiClient);

      final alert = await repo.createAlert(
        symbol: 'TCS',
        targetPrice: 4000.0,
        condition: 'GTE',
      );

      expect(rec.method, 'POST');
      expect(rec.path, '/api/alerts');
      expect(alert.id, 'alt_123');

      await repo.deleteAlert('alt_123');
      expect(rec.method, 'DELETE');
      expect(rec.path, '/api/alerts/alt_123');
    });

    test('14. Baskets: create, delete, and execute calls match contract paths & methods', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'id': 'bsk_100',
          'name': 'Heavyweights',
          'orders': [
            {'symbol': 'RELIANCE', 'quantity': 10, 'side': 'BUY'}
          ]
        }
      }, recording: rec);
      final repo = BasketsRepository(apiClient);

      final basket = await repo.createBasket(
        name: 'Heavyweights',
        orders: [{'symbol': 'RELIANCE', 'quantity': 10, 'side': 'BUY'}],
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/baskets');
      expect(basket.name, 'Heavyweights');

      await repo.executeBasket('bsk_100');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/baskets/bsk_100/execute');

      await repo.deleteBasket('bsk_100');
      expect(rec.method, 'DELETE');
      expect(rec.path, '/api/baskets/bsk_100');
    });

    test('15. GTT: get, create, and delete call contract endpoints', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'id': 'gtt_501',
          'symbol': 'INFY',
          'condition': 'LTE',
          'triggerPrice': 1700.0,
          'orderSide': 'BUY',
          'orderType': 'LIMIT',
          'price': 1700.0,
          'quantity': 10,
          'status': 'ACTIVE',
        }
      }, recording: rec);
      final repo = GttRepository(apiClient);

      final gtt = await repo.createGtt(
        symbol: 'INFY',
        condition: 'LTE',
        triggerPrice: 1700.0,
        orderSide: 'BUY',
        orderType: 'LIMIT',
        price: 1700.0,
        quantity: 10,
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/gtt');
      expect(gtt.id, 'gtt_501');

      await repo.deleteGtt('gtt_501');
      expect(rec.method, 'DELETE');
      expect(rec.path, '/api/gtt/gtt_501');
    });

    test('16. SIP: create, pause, resume, and delete call contract endpoints', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'id': 'sip_701',
          'symbol': 'NIFTYBEES',
          'frequency': 'MONTHLY',
          'amount': 5000.0,
          'status': 'ACTIVE',
        }
      }, recording: rec);
      final repo = SipRepository(apiClient);

      final sip = await repo.createSip(
        symbol: 'NIFTYBEES',
        frequency: 'MONTHLY',
        amount: 5000.0,
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/sip');
      expect(sip.id, 'sip_701');

      await repo.pauseSip('sip_701');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/sip/sip_701/pause');

      await repo.resumeSip('sip_701');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/sip/sip_701/resume');

      await repo.deleteSip('sip_701');
      expect(rec.method, 'DELETE');
      expect(rec.path, '/api/sip/sip_701');
    });

    test('17. Notifications: unread-count, read, read-all, delete, preferences, token', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {'unreadCount': 5}
      }, recording: rec);
      final repo = NotificationsRepository(apiClient);

      final count = await repo.getUnreadCount();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/notifications/unread-count');
      expect(count, 5);

      await repo.markRead('notif_1');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/notifications/notif_1/read');

      await repo.markAllRead();
      expect(rec.method, 'POST');
      expect(rec.path, '/api/notifications/read-all');

      await repo.deleteNotification('notif_1');
      expect(rec.method, 'DELETE');
      expect(rec.path, '/api/notifications/notif_1');

      await repo.updatePreferences({'orders': true});
      expect(rec.method, 'PUT');
      expect(rec.path, '/api/notifications/preferences');

      await repo.registerFcmToken('fcm_token_xyz');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/notifications/register-token');
    });

    test('18. IPO: listings, detail, apply, applications, cancel', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'id': 'ipo_app_9',
          'symbol': 'XYZTECH',
          'lots': 2,
          'bidPrice': 500.0,
          'status': 'APPLIED',
        }
      }, recording: rec);
      final repo = IpoRepository(apiClient);

      await repo.getIpos();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/ipo');

      await repo.getIpoDetail('ipo_1');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/ipo/ipo_1');

      await repo.applyIpo(id: 'ipo_1', lots: 2, bidPrice: 500.0, upiId: 'user@upi');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/ipo/ipo_1/apply');

      await repo.getApplications();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/ipo/applications');

      await repo.cancelApplication('ipo_app_9');
      expect(rec.method, 'DELETE');
      expect(rec.path, '/api/ipo/applications/ipo_app_9');
    });

    test('19. News & Learning: endpoints match contract', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'id': 'news_1',
          'title': 'RBI Monetary Policy Update',
          'content': 'Rates kept unchanged',
          'category': 'MACRO',
          'publishedAt': '2026-10-10T09:00:00Z',
        }
      }, recording: rec);
      final newsRepo = NewsRepository(apiClient);

      await newsRepo.getArticles();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/news');

      await newsRepo.getArticle('news_1');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/news/news_1');

      final learnRepo = LearningRepository(apiClient);
      await learnRepo.getModules();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/learning/modules');

      await learnRepo.getModuleDetail('mod_basics');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/learning/modules/mod_basics');

      await learnRepo.submitQuiz(lessonId: 'les_1', answers: [1, 2]);
      expect(rec.method, 'POST');
      expect(rec.path, '/api/learning/quiz/les_1/submit');
    });

    test('20. Charges & Calendar & Heatmap: endpoints match contract', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'brokerage': 0.0,
          'stt': 25.0,
          'exchangeTxnFee': 3.45,
          'gst': 0.62,
          'sebiCharges': 0.10,
          'stampDuty': 3.0,
          'totalCharges': 32.17,
        }
      }, recording: rec);
      final chargesRepo = ChargesRepository(apiClient);

      await chargesRepo.getChargesConfig();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/config/charges');

      final charges = await chargesRepo.calculateCharges(
        tradeValue: 100000.0,
        side: 'BUY',
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/config/charges/calculate');
      expect(charges.brokerage, 0.0);
      expect(charges.totalCharges, 32.17);

      final calRepo = CalendarRepository(apiClient: apiClient);
      await calRepo.getCalendarEvents();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/calendar');

      final heatRepo = HeatmapRepository(apiClient: apiClient);
      await heatRepo.getHeatmap();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/heatmap');
    });

    test('21. Funds: deposit create & verify, withdraw, and receipts', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'deposit': {
            'id': 'dep_1',
            'amount': 25000.0,
            'status': 'PENDING',
          }
        }
      }, recording: rec);
      final fundsRepo = RealFundsRepository(apiClient: apiClient);

      await fundsRepo.createDeposit(amount: 25000.0);
      expect(rec.method, 'POST');
      expect(rec.path, '/api/wallet/deposit/create');

      await fundsRepo.verifyDeposit(depositId: 'dep_1');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/wallet/deposit/verify');

      await fundsRepo.withdraw(
        amount: 10000.0,
        accountNumber: '1234567890',
        ifsc: 'HDFC0001234',
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/wallet/withdraw');

      await fundsRepo.getTransactionReceipt('dep_1');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/wallet/transactions/dep_1/receipt');

      await fundsRepo.getLedger();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/wallet/ledger');
    });

    test('22. Market: candles, quotes, search, status, holidays, option chain, fundamentals', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'candles': [],
          'quotes': {},
          'results': [],
          'status': 'OPEN',
          'holidays': [],
        }
      }, recording: rec);
      final marketRepo = RealMarketRepository(apiClient: apiClient);

      await marketRepo.getCandles('RELIANCE', interval: '1m');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/candles');

      await marketRepo.getQuotes(symbols: ['RELIANCE']);
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/quotes');

      await marketRepo.searchInstruments('TCS');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/search');

      await marketRepo.getMarketStatus();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/status');

      await marketRepo.getMarketHolidays(year: 2026);
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/holidays');

      final optRepo = OptionChainRepository(apiClient: apiClient);
      await optRepo.getExpiries('NIFTY');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/option-chain/expiries/NIFTY');

      await optRepo.getOptionChain('NIFTY');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/option-chain/NIFTY');

      final fundRepo = FundamentalsRepository(apiClient: apiClient);
      await fundRepo.getFundamentals('INFY');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/fundamentals/INFY');

      await fundRepo.getCorporateActions(symbol: 'INFY');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/market/corporate-actions');
    });

    test('23. User Profile, KYC & Compliance: all endpoints match contract', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'status': 'VERIFIED',
          'documents': [],
          'nominees': [],
          'isIndianTaxResidentOnly': true,
          'isUsPerson': false,
          'isPoliticallyExposed': false,
          'isRelatedToPoliticallyExposed': false,
          'birthCountry': 'India',
          'birthCity': 'Mumbai',
          'taxResidencyCountry': 'India',
          'taxIdentificationNumber': 'ABCDE1234F',
          'occupation': 'Salaried',
          'grossAnnualIncomeBracket': '1L - 5L',
          'declarationTimestamp': '2026-10-10T10:00:00Z',
        }
      }, recording: rec);

      final kycRepo = KycRepository(apiClient: apiClient);
      await kycRepo.getKycStatus();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/kyc/status');

      await kycRepo.uploadDocument(documentType: 'PAN', fileName: 'pan.jpg', fileData: 'data:image/jpeg;base64,...');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/kyc/upload');

      await kycRepo.submitKyc(
        panNumber: 'ABCDE1234F',
        panDocumentUrl: '/uploads/pan.jpg',
        aadhaarNumber: '123456789012',
        aadhaarDocumentUrl: '/uploads/aadhaar.jpg',
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/kyc/submit');

      final compRepo = ComplianceRepository(apiClient: apiClient);
      await compRepo.getRiskProfile();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/user/risk-profile');

      await compRepo.submitRiskProfile(
        investmentHorizon: 'LONG_TERM',
        experienceLevel: 'ADVANCED',
        lossTolerance: 'HIGH',
        answers: [],
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/user/risk-profile');

      await compRepo.getFatcaDeclaration();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/user/fatca');

      await compRepo.submitFatcaDeclaration({'isIndianResident': true});
      expect(rec.method, 'POST');
      expect(rec.path, '/api/user/fatca');

      await compRepo.getNominees();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/user/nominees');

      await compRepo.saveNominees([]);
      expect(rec.method, 'POST');
      expect(rec.path, '/api/user/nominees');

      final pinRepo = PinnedInstrumentsRepository(apiClient: apiClient);
      await pinRepo.getPinnedSymbols();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/user/pinned-instruments');

      await pinRepo.updatePinnedSymbols(['NIFTY', 'BANKNIFTY']);
      expect(rec.method, 'PUT');
      expect(rec.path, '/api/user/pinned-instruments');
    });

    test('24. Reports & Legal/Config: all endpoints match contract', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'isUnderMaintenance': false,
          'content': 'Legal terms here',
        }
      }, recording: rec);

      final repRepo = ReportsRepository(apiClient);
      await repRepo.getLedgerReport();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/reports/ledger');

      await repRepo.getTradebook();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/reports/tradebook');

      await repRepo.getPnl();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/reports/pnl');

      final cfgRepo = AppConfigRepository(apiClient: apiClient);
      await cfgRepo.getSystemAppConfig();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/system/app-config');

      await cfgRepo.getLegalDocument('risk-disclosure');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/legal/risk-disclosure');
    });

    test('25. Support: tickets fetch, create, detail, reply, attachment upload match contract', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'ticket': {
            'id': 'tk_999',
            'title': 'Order query',
            'subject': 'Order query',
            'description': 'Order query detail',
            'message': 'Order query detail',
            'category': 'tradingOrders',
            'priority': 'medium',
            'status': 'open',
            'messages': [],
            'attachments': [],
            'createdAt': '2026-10-10T10:00:00Z',
            'updatedAt': '2026-10-10T10:00:00Z',
          }
        }
      }, recording: rec);
      final supportRepo = SupportRepository(apiClient: apiClient);

      await supportRepo.fetchTickets();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/support/tickets');

      await supportRepo.createTicket(
        title: 'Order query',
        description: 'Detail query',
        category: TicketCategory.tradingOrders,
        priority: TicketPriority.medium,
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/support/tickets');

      await supportRepo.getTicketDetail('tk_999');
      expect(rec.method, 'GET');
      expect(rec.path, '/api/support/tickets/tk_999');

      await supportRepo.replyTicket('tk_999', 'Client response message');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/support/tickets/tk_999/reply');

      // Update ticket status should NOT make an invalid PUT /api/support/tickets/:id call
      rec.method = '';
      rec.path = '';
      await supportRepo.updateTicketStatus('tk_999', TicketStatus.resolved);
      expect(rec.method, '', reason: 'User updateTicketStatus must NOT invoke PUT on backend endpoint');
      expect(rec.path, '');
    });

    test('26. Auth: login, verify-pin, setup-pin, register, forgot-pw, profile match contract', () async {
      final rec = CallRecording();
      final apiClient = _createMockApiClient({
        'success': true,
        'data': {
          'token': 'access_token_123',
          'user': {
            'id': 'usr_1',
            'name': 'Test User',
            'email': 'user@example.com',
            'role': 'CLIENT',
          }
        }
      }, recording: rec);
      final authRepo = RealAuthRepository(apiClient: apiClient, tokenStorage: TokenStorage());

      await authRepo.login('user@example.com', 'password123');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/auth/login');

      await authRepo.verifyPin(tempToken: 'tmp_tok', pin: '1234');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/auth/verify-pin');

      await authRepo.setPin(tempToken: 'tmp_tok', pin: '1234');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/auth/setup-pin');

      await authRepo.register(
        name: 'New Trader',
        email: 'trader@example.com',
        phone: '9876543210',
        password: 'Password@123',
        pin: '1234',
      );
      expect(rec.method, 'POST');
      expect(rec.path, '/api/auth/register');

      await authRepo.forgotPassword('trader@example.com');
      expect(rec.method, 'POST');
      expect(rec.path, '/api/auth/forgot-password');

      await authRepo.getProfile();
      expect(rec.method, 'GET');
      expect(rec.path, '/api/account/profile');

      await authRepo.updateProfile({'name': 'Updated Name'});
      expect(rec.method, 'PUT');
      expect(rec.path, '/api/account/profile');
    });
  });
}
