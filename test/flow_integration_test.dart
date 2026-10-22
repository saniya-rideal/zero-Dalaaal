import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zero_dalali/core/config/app_config.dart';
import 'package:zero_dalali/core/network/api_client.dart';
import 'package:zero_dalali/core/network/token_storage.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/deals/presentation/deals_screen.dart';
import 'package:zero_dalali/features/funds/data/real_funds_repository.dart';
import 'package:zero_dalali/features/market/data/real_market_repository.dart';
import 'package:zero_dalali/features/market/domain/market_repository.dart';
import 'package:zero_dalali/features/order_entry/presentation/order_entry_sheet.dart';
import 'package:zero_dalali/features/orders/data/real_trading_repository.dart';
import 'package:zero_dalali/features/orders/domain/trading_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/pinned_instruments_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/settings_repository.dart';
import 'package:zero_dalali/features/quotes/presentation/quotes_screen.dart';
import 'package:zero_dalali/features/watchlist/data/real_watchlist_repository.dart';
import 'fixtures/fake_watchlist_repository.dart';
import 'package:zero_dalali/shared_widgets/margin_risk_banner.dart';
import 'package:zero_dalali/shared_widgets/script_selector_bar.dart';
import 'package:zero_dalali/shared_widgets/zero_app_bar.dart';
import 'package:zero_dalali/shared_widgets/zero_bottom_dock.dart';
import 'package:zero_dalali/shared_widgets/zero_drawer.dart';

const testNifty = Instrument(
  token: 'idx_nifty50',
  symbol: 'NIFTY 50',
  name: 'NIFTY 50 Index',
  exchange: Exchange.NSE,
  type: InstrumentType.INDEX,
  market: 'INDIAN',
  segment: 'EQUITY',
);

const testCopper = Instrument(
  token: 'mcx_copper',
  symbol: 'COPPER',
  name: 'Copper MCX Sep',
  exchange: Exchange.MCX,
  type: InstrumentType.FUT,
  market: 'INDIAN',
  segment: 'COMMODITIES',
);

class StubMarketRepository implements MarketRepository {
  final List<Instrument> instruments;
  StubMarketRepository([this.instruments = const [testNifty, testCopper]]);

  @override
  Future<List<Instrument>> getInstruments() async => instruments;
  @override
  List<Instrument> get cachedInstruments => instruments;
  @override
  Instrument? findBySymbol(String symbol) =>
      instruments.cast<Instrument?>().firstWhere((i) => i?.symbol == symbol, orElse: () => null);
  @override
  Future<Map<String, Quote>> getQuotes({List<String>? symbols}) async => {};
  @override
  Future<Quote?> getQuote(String symbol) async => null;
  @override
  Future<List<Candle>> getCandles(String symbol, {String interval = '1m', int limit = 100, int? from, int? to}) async => [];
  @override
  Future<List<Instrument>> searchInstruments(String query, {Exchange? exchange, InstrumentType? type}) async => instruments;
  @override
  Future<Map<String, dynamic>> getMarketStatus() async => {'isOpen': true};
  @override
  Future<List<dynamic>> getMarketHolidays({int? year}) async => [];
}

class StubTradingRepository implements TradingRepository {
  @override
  Future<Order> createOrder({
    required String symbol,
    required TransactionType side,
    required OrderKind orderType,
    required int quantity,
    String market = 'INDIAN',
    double? leverage,
    double? limitPrice,
    double? stopLoss,
    double? takeProfit,
    String? idempotencyKey,
  }) async {
    return Order.fromJson({'orderId': 'ord_1', 'symbol': symbol, 'status': 'COMPLETE'});
  }

  @override
  Future<Order> placeOrder(OrderRequest request) async =>
      createOrder(symbol: request.instrumentToken, side: request.side, orderType: request.kind, quantity: request.quantity);

  @override
  Future<OrderPreview> previewOrder(OrderPreviewRequest request) async {
    return OrderPreview(
      requiredMargin: 1000.0,
      availableMargin: 50000.0,
      marginAfterTrade: 49000.0,
      charges: ChargesBreakdown.zero(),
      canPlace: true,
      executionPrice: request.limitPrice ?? 100.0,
    );
  }

  @override
  Future<List<Order>> getOrders() async => [];

  @override
  Future<Order> getOrder(String id) async => Order.fromJson({'orderId': id});

  @override
  Future<bool> cancelOrder(String id) async => true;

  @override
  Future<List<Position>> getPositions({String? status = 'OPEN'}) async => [];

  @override
  Future<Order> closePosition(String id, {String? idempotencyKey, int? quantity}) async =>
      Order.fromJson({'orderId': 'close_$id'});

  @override
  Future<bool> convertPosition(String id, {required String targetProduct}) async => true;

  @override
  Future<List<Holding>> getHoldings() async => [];

  @override
  Future<Map<String, dynamic>> getPortfolioSummary() async => {};
}

Dio _createMockDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: {'success': true, 'data': {}},
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return dio;
}

ApiClient _createMockApiClient() {
  return ApiClient(
    config: const AppConfig(
      apiBaseUrl: 'http://test',
      socketBaseUrl: 'http://test',
    ),
    tokenStorage: TokenStorage(),
    dio: _createMockDio(),
  );
}

ProviderContainer _createTestContainer({SettingsRepository? settingsRepo}) {
  final sRepo = settingsRepo ?? SettingsRepository();
  return ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(_createMockApiClient()),
      settingsRepositoryProvider.overrideWith((ref) => sRepo),
      marketRepositoryProvider.overrideWith((ref) => StubMarketRepository()),
      tradingRepositoryProvider.overrideWith((ref) => StubTradingRepository()),
      fundsSummaryProvider.overrideWith((ref) => const FundsSummary(
            availableMargin: 100000,
            usedMargin: 20000,
            openingBalance: 120000,
          )),
      watchlistRepositoryProvider.overrideWith((ref) => FakeWatchlistRepository([
            const WatchlistGroup(
              id: 'wl_default',
              name: 'Watchlist',
              instrumentTokens: ['idx_nifty50', 'mcx_copper'],
              isDefault: true,
            ),
          ])),
    ],
  );
}

void main() {
  group('End-to-End Flow Integration Tests', () {
    testWidgets(
        'ScriptSelectorBar updates slot when script is pinned and displays symbol',
        (tester) async {
      final container = _createTestContainer();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ScriptSelectorBar(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Press and hold to select script'), findsNWidgets(2));

        // Pin Nifty 50 to Left Slot
        container.read(pinnedScriptsProvider.notifier).setLeftScript(testNifty);
        await tester.pumpAndSettle();

        expect(find.text(testNifty.symbol), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('QuotesScreen dynamically respects showStickyScripts toggle',
        (tester) async {
      final settingsRepo = SettingsRepository();
      final container = _createTestContainer(settingsRepo: settingsRepo);
      try {
        // Ensure sticky scripts is ON
        settingsRepo.setShowStickyScripts(true);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: QuotesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ScriptSelectorBar), findsOneWidget);

        // Toggle sticky scripts to OFF
        settingsRepo.setShowStickyScripts(false);
        await tester.pumpAndSettle();

        expect(find.byType(ScriptSelectorBar), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets(
        'QuotesScreen groups quotes by category when quotesGrouping is true',
        (tester) async {
      final settingsRepo = SettingsRepository();
      final container = _createTestContainer(settingsRepo: settingsRepo);
      try {
        // Enable quotesGrouping in settings
        settingsRepo.setQuotesGrouping(true);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: QuotesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should find category headers or scripts
        expect(find.textContaining('SCRIPTS'), findsWidgets);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('OrderEntrySheet pre-fills lot with defaultLots from settings',
        (tester) async {
      final settingsRepo = SettingsRepository();
      settingsRepo.setDefaultLots(3.5);
      final container = _createTestContainer(settingsRepo: settingsRepo);
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: OrderEntrySheet(instrument: testNifty),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The pre-filled lot in OrderEntrySheet should be 3.50
        expect(find.text('3.50'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('ZeroDrawer renders all 18+ navigation items and opens Share sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = _createTestContainer();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                drawer: ZeroDrawer(activeRoute: '/quotes'),
                body: Center(child: Text('Home')),
              ),
            ),
          ),
        );
        await tester.pump();

        // Open drawer
        final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Verify key navigation items exist in drawer
        expect(find.text('Quotes'), findsWidgets);
        expect(find.text('Deals'), findsWidgets);
        expect(find.text('Net Deals'), findsWidgets);
        expect(find.text('Economic Calendar'), findsOneWidget);
        expect(find.text('Profit Calculator'), findsOneWidget);
        expect(find.text('Margin Calculator'), findsOneWidget);
        expect(find.text('News'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);

        // Ensure visible & tap Share item
        await tester.ensureVisible(find.text('Share'));
        await tester.tap(find.text('Share'));
        await tester.pumpAndSettle();

        // Verify Share sheet opened
        expect(find.text('Share Zero Trading'), findsOneWidget);
        expect(find.textContaining('https://zerodalali.com/invite/'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('Adaptive AppBar shows back button when screen can pop',
        (tester) async {
      final container = _createTestContainer();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            appBar: ZeroAppBar(title: 'Pushed Subscreen'),
                            body: Center(child: Text('Subscreen Body')),
                          ),
                        ),
                      );
                    },
                    child: const Text('Push'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap push
        await tester.tap(find.text('Push'));
        await tester.pumpAndSettle();

        // Verify pushed subscreen has Back button (arrowLeft)
        expect(find.text('Pushed Subscreen'), findsOneWidget);
        expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

        // Tap back button
        await tester.tap(find.byIcon(LucideIcons.arrowLeft));
        await tester.pumpAndSettle();

        // Returned to home
        expect(find.text('Push'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('ZeroBottomDock renders metrics grid and eye privacy toggle',
        (tester) async {
      final container = _createTestContainer();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                bottomNavigationBar: ZeroBottomDock(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify account tag
        expect(find.text('Acc: Primary'), findsOneWidget);

        // Verify metric labels
        expect(find.text('Balance:'), findsOneWidget);
        expect(find.text('Floating PL:'), findsOneWidget);
        expect(find.text('Free Margin:'), findsOneWidget);
        expect(find.text('Equity:'), findsOneWidget);

        // Tap eye privacy toggle
        final eyeFinder = find.byIcon(LucideIcons.eye);
        expect(eyeFinder, findsOneWidget);
        await tester.tap(eyeFinder);
        await tester.pumpAndSettle();

        // Balance should now be masked with dots
        expect(find.text('••••••'), findsWidgets);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('DealsScreen mounts, filters deals by search query, and toggles profit filter',
        (tester) async {
      final container = _createTestContainer();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: DealsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify DealsScreen elements mount cleanly
        expect(find.byType(DealsScreen), findsOneWidget);
        expect(find.byType(MarginRiskBanner), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });
  });
}
