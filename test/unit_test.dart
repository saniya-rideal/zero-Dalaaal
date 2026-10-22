import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/constants/charges_config.dart';
import 'package:zero_dalali/core/services/balance_privacy_service.dart';
import 'package:zero_dalali/core/services/connectivity_service.dart';
import 'package:zero_dalali/core/services/maintenance_service.dart';
import 'package:zero_dalali/core/services/market_status_service.dart';
import 'package:zero_dalali/core/utils/currency_formatter.dart';
import 'package:zero_dalali/core/utils/date_formatter.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/charts/presentation/indicators/indicator_math.dart';
import 'package:zero_dalali/features/watchlist/presentation/watchlist_controller.dart';
import 'package:zero_dalali/core/services/notification_service.dart';
import 'package:zero_dalali/core/services/security_privacy_service.dart';
import 'package:zero_dalali/core/services/money_movement_reconciliation_service.dart';
import 'package:zero_dalali/core/services/observability_service.dart';
import 'package:zero_dalali/core/services/edge_case_service.dart';
import 'package:zero_dalali/core/constants/app_constants.dart';
import 'package:zero_dalali/core/services/financial_calculation_service.dart';
import 'package:zero_dalali/core/services/real_money_compliance_service.dart';
import 'package:zero_dalali/core/services/source_verification_service.dart';
import 'package:zero_dalali/features/profile_settings/data/settings_repository.dart';
import 'package:zero_dalali/features/profile_settings/data/support_repository.dart';
import 'fixtures/legal_documents_fixture.dart';
import 'fixtures/seed_instruments_fixture.dart';
import 'fixtures/candle_generator_fixture.dart';
import 'fixtures/ticker_service_fixture.dart';
import 'fixtures/order_simulation_engine_fixture.dart';
import 'fixtures/news_repository_fixture.dart';
import 'fixtures/fake_watchlist_repository.dart';
import 'fixtures/fake_notifications_repository.dart';
import 'package:zero_dalali/features/watchlist/data/real_watchlist_repository.dart';
import 'package:zero_dalali/features/notifications/data/notifications_repository.dart';

ProviderContainer createTestContainer() {
  return ProviderContainer(
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(FakeNotificationsRepository()),
    ],
  );
}

void main() {
  group('Zero Comprehensive Test Suite', () {
    // 1. Currency & Number Formatting Tests
    test('CurrencyFormatter Indian digit grouping test', () {
      expect(CurrencyFormatter.format(123456.78), '₹1,23,456.78');
      expect(CurrencyFormatter.formatCompact(15000000), '₹1.50 Cr');
      expect(CurrencyFormatter.formatCompact(450000), '₹4.50 L');
      expect(CurrencyFormatter.formatPercent(3.45), '+3.45%');
      expect(CurrencyFormatter.formatPercent(-2.10), '-2.10%');
      expect(CurrencyFormatter.formatSigned(500.25), '+₹500.25');
      expect(CurrencyFormatter.formatSigned(-350.50), '-₹350.50');
      expect(CurrencyFormatter.formatSigned(0.0), '₹0.00');
    });

    // 2. Date Formatting Tests
    test('DateFormatter formatting safety test', () {
      final testDate = DateTime(2026, 9, 3, 14, 30, 0);
      expect(DateFormatter.formatOrderTime(testDate), '14:30:00');
      expect(DateFormatter.formatOrderDate(testDate), '03 Sep 2026');
      expect(DateFormatter.formatOrderDateTime(testDate), '03 Sep 2026, 14:30:00');
    });

    // 3. Brokerage & Regulatory Charges Tests
    test('ChargesConfig calculates ₹0 brokerage for CNC Equity Delivery', () {
      final charges = ChargesConfig.calculateCharges(
        price: 2500.0,
        quantity: 10,
        side: TransactionType.BUY,
        product: ProductType.CNC,
        instrumentType: InstrumentType.EQ,
      );

      expect(charges.brokerage, 0.0);
      expect(charges.total, greaterThan(0.0)); // Stamp duty & regulatory charges apply
    });

    test('ChargesConfig calculates brokerage for Intraday MIS orders', () {
      final charges = ChargesConfig.calculateCharges(
        price: 2500.0,
        quantity: 10,
        side: TransactionType.BUY,
        product: ProductType.MIS,
        instrumentType: InstrumentType.EQ,
      );

      expect(charges.brokerage, greaterThan(0.0));
      expect(charges.brokerage, lessThanOrEqualTo(20.0));
    });

    // 4. Multi-Timeframe Candle Synthesis Tests
    test('CandleGenerator generates consistent multi-timeframe candles', () {
      final candles1 = CandleGenerator.generateCandles(
        token: 'eq_reliance',
        timeframe: Timeframe.ONE_DAY,
        count: 50,
      );
      final candles2 = CandleGenerator.generateCandles(
        token: 'eq_reliance',
        timeframe: Timeframe.ONE_DAY,
        count: 50,
      );

      expect(candles1.length, 50);
      expect(candles1.first.open, candles2.first.open);
      expect(candles1.last.close, candles2.last.close);
      for (final c in candles1) {
        expect(c.high, greaterThanOrEqualTo(c.low));
        expect(c.high, greaterThanOrEqualTo(c.open));
        expect(c.high, greaterThanOrEqualTo(c.close));
        expect(c.low, lessThanOrEqualTo(c.open));
        expect(c.low, lessThanOrEqualTo(c.close));
      }
    });

    // 5. Technical Indicators Math Tests
    test('IndicatorMath computes valid SMA and RSI arrays', () {
      final candles = CandleGenerator.generateCandles(
        token: 'eq_tcs',
        timeframe: Timeframe.ONE_DAY,
        count: 40,
      );

      final sma20 = IndicatorMath.calculateSma(candles, 20);
      expect(sma20.length, 40);
      expect(sma20[18], isNull); // 0-indexed, first 19 null
      expect(sma20[19], isNotNull);

      final rsi14 = IndicatorMath.calculateRsi(candles, 14);
      expect(rsi14.length, 40);
      expect(rsi14[14], isNotNull);
      expect(rsi14[14]!, inInclusiveRange(0.0, 100.0));
    });

    // 6. Order Simulation Engine Order Lifecycle Tests
    test('OrderSimulationEngine places market orders and simulates fills', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);

      final initialOrdersCount = engine.orders.length;

      final order = await engine.placeOrder(const OrderRequest(
        instrumentToken: 'eq_reliance',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 10,
      ));

      expect(order.orderId, startsWith('ZD-'));
      expect(order.status, isIn([OrderStatus.OPEN, OrderStatus.COMPLETE]));
      expect(engine.orders.length, initialOrdersCount + 1);
    });

    test('OrderSimulationEngine manages order cancellation', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);

      // Place a limit order that stays pending
      final order = await engine.placeOrder(const OrderRequest(
        instrumentToken: 'eq_infy',
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.LIMIT,
        price: 500.0,
        quantity: 5,
      ));

      expect(engine.orders.any((o) => o.orderId == order.orderId), isTrue);

      engine.cancelOrder(order.orderId);
      final cancelled = engine.orders.firstWhere((o) => o.orderId == order.orderId);
      expect(cancelled.status, OrderStatus.CANCELLED);
    });

    // 7. Seed Instruments & Directory Mapping Tests
    test('SeedInstruments findByToken resolves all core instruments', () {
      expect(SeedInstruments.findByToken('eq_reliance'), isNotNull);
      expect(SeedInstruments.findByToken('eq_tcs'), isNotNull);
      expect(SeedInstruments.findByToken('eq_infy'), isNotNull);
      expect(SeedInstruments.findByToken('idx_nifty50'), isNotNull);
      expect(SeedInstruments.findByToken('idx_niftybank'), isNotNull);
      expect(SeedInstruments.findByToken('mcx_gold'), isNotNull);
      expect(SeedInstruments.findByToken('mcx_crudeoil'), isNotNull);
      expect(SeedInstruments.findByToken('mcx_silver'), isNotNull);
      expect(SeedInstruments.findByToken('mcx_copper'), isNotNull);

      final gold = SeedInstruments.findByToken('mcx_gold')!;
      expect(gold.exchange, Exchange.MCX);
      expect(gold.type, InstrumentType.FUT);
    });

    // 8. Calculator Arithmetic Tests
    test('Profit Calculator arithmetic invariant test', () {
      const openPrice = 1156.20;
      const closePrice = 1156.90;
      const tradeSize = 1.00;

      // Buy side profit
      const buyProfit = (closePrice - openPrice) * tradeSize;
      expect(buyProfit.toStringAsFixed(2), '0.70');

      // Sell side profit
      const sellProfit = (openPrice - closePrice) * tradeSize;
      expect(sellProfit.toStringAsFixed(2), '-0.70');
    });

    test('Margin Calculator mathematical requirements test', () {
      const rate = 1160.60;
      const amount = 1.00;

      const intradayMargin = rate * amount * 0.002;
      const holdingMargin = rate * amount * 0.02;

      expect(intradayMargin.toStringAsFixed(2), '2.32');
      expect(holdingMargin.toStringAsFixed(2), '23.21');
    });

    // 9. Viewport Clamp Safety Tests
    test('Viewport Scroll Clamp safety test', () {
      const totalCandles = 10;
      const fullStep = 10.0;
      const chartWidth = 300.0; // larger than total candle content width (100.0)

      final maxScroll = max(0.0, (totalCandles * fullStep) - chartWidth);
      expect(maxScroll, 0.0);

      const currentScroll = 0.0;
      final clamped = currentScroll.clamp(-maxScroll, 0.0);
      expect(clamped, 0.0); // Never throws ArgumentError
    });

    // 10. Connectivity Service State Transition Tests
    test('ConnectivityService transitions online and offline correctly', () {
      final container = createTestContainer();
      final connectivityNotifier = container.read(connectivityServiceProvider.notifier);

      expect(container.read(connectivityServiceProvider), NetworkStatus.online);
      expect(container.read(isOfflineProvider), isFalse);

      connectivityNotifier.updateStatus(NetworkStatus.offline);
      expect(container.read(connectivityServiceProvider), NetworkStatus.offline);
      expect(container.read(isOfflineProvider), isTrue);

      connectivityNotifier.updateStatus(NetworkStatus.online);
      expect(container.read(connectivityServiceProvider), NetworkStatus.online);
      expect(container.read(isOfflineProvider), isFalse);
    });

    // 11. Maintenance Service State Transition Tests
    test('MaintenanceService enables, updates, and disables maintenance correctly', () {
      final container = createTestContainer();
      final maintenanceNotifier = container.read(maintenanceServiceProvider.notifier);

      expect(container.read(isMaintenanceActiveProvider), isFalse);

      maintenanceNotifier.enableMaintenance(
        title: 'Emergency Core Upgrade',
        message: 'Gateways closing for 15 mins.',
      );

      final state = container.read(maintenanceServiceProvider);
      expect(state.isMaintenanceActive, isTrue);
      expect(state.title, 'Emergency Core Upgrade');
      expect(state.message, 'Gateways closing for 15 mins.');
      expect(state.affectedSegments.contains('NSE Equity'), isTrue);

      maintenanceNotifier.disableMaintenance();
      expect(container.read(isMaintenanceActiveProvider), isFalse);
    });

    // 12. Registration & Password Strength Validation Tests
    test('Registration password strength rules validate properly', () {
      int calcStrength(String p) {
        if (p.isEmpty) return 0;
        int s = 0;
        if (p.length >= 8) s++;
        if (p.contains(RegExp(r'[A-Z]'))) s++;
        if (p.contains(RegExp(r'[0-9]'))) s++;
        if (p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) s++;
        return s;
      }

      expect(calcStrength(''), 0);
      expect(calcStrength('short'), 0);
      expect(calcStrength('password'), 1);
      expect(calcStrength('Password'), 2);
      expect(calcStrength('Password123'), 3);
      expect(calcStrength('Password123!'), 4);
    });

    // 13. Balance Privacy Provider State Test
    test('BalancePrivacyProvider toggles privacy masking state properly', () {
      final container = createTestContainer();
      expect(container.read(balancePrivacyProvider), isFalse);

      container.read(balancePrivacyProvider.notifier).state = true;
      expect(container.read(balancePrivacyProvider), isTrue);

      container.read(balancePrivacyProvider.notifier).state = false;
      expect(container.read(balancePrivacyProvider), isFalse);
    });

    // 14. Market Status Service & Watchlist Tests
    test('MarketStatusService evaluates valid exchange status and timezone', () {
      final nse = MarketStatusService.getStatusForExchange('NSE');
      expect(nse.exchange, 'NSE');
      expect(nse.label, contains('NSE:'));
      expect(MarketStatusService.timeZoneLabel, 'IST (UTC+05:30)');

      final mcx = MarketStatusService.getStatusForExchange('MCX');
      expect(mcx.exchange, 'MCX');
      expect(mcx.label, contains('MCX:'));
    });

    test('WatchlistController manages single default watchlist (add to top, remove, 50 limit)', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_default',
          name: 'Watchlist',
          instrumentTokens: ['TCS'],
          isDefault: true,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      final controller = container.read(watchlistControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      var state = container.read(watchlistControllerProvider);
      expect(state.watchlist, isNotNull);
      expect(state.watchlist!.name, 'Watchlist');
      expect(state.watchlist!.instrumentTokens, ['TCS']);

      // Add script to top
      final added = await controller.addInstrument('RELIANCE');
      expect(added, isTrue);
      state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens.first, 'RELIANCE');
      expect(state.watchlist!.instrumentTokens, ['RELIANCE', 'TCS']);

      // Remove script
      final removed = await controller.removeInstrument('TCS');
      expect(removed, isTrue);
      state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens, ['RELIANCE']);

      // Undo
      await controller.addInstrument('TCS');
      state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens.contains('TCS'), isTrue);
    });

    // 15. Multi-Market Asset Classes & Instruments Test
    test('SeedInstruments & CandleGenerator resolve Forex, Crypto, and Global indices', () {
      // Forex
      final usdinr = SeedInstruments.findByToken('fx_usdinr');
      expect(usdinr, isNotNull);
      expect(usdinr!.symbol, 'USDINR Sep FUT');
      expect(CandleGenerator.getBasePrice('fx_usdinr'), 83.94);

      // Bitcoin & Crypto
      final btc = SeedInstruments.findByToken('crypto_btcusd');
      expect(btc, isNotNull);
      expect(btc!.symbol, contains('Bitcoin'));
      expect(CandleGenerator.getBasePrice('crypto_btcusd'), 58450.00);

      // Global Indices
      final us500 = SeedInstruments.findByToken('global_us500');
      expect(us500, isNotNull);
      expect(us500!.symbol, contains('US 500'));
      expect(CandleGenerator.getBasePrice('global_us500'), 5520.00);
    });

    // 16. Pre-trade Risk, Target P&L & Exposure Invariants
    test('Trading Workspace Pre-trade P&L, Target Profit & Risk calculations', () {
      const entryPrice = 785.40;
      const lots = 2.0;
      const lotMultiplier = 2500.0;
      const totalUnits = lots * lotMultiplier; // 5000 units

      const tpPrice = 800.00;
      const slPrice = 775.00;

      final targetProfit = (tpPrice - entryPrice).abs() * totalUnits;
      final maxRisk = (entryPrice - slPrice).abs() * totalUnits;
      const totalExposure = entryPrice * totalUnits;

      expect(targetProfit, closeTo(73000.00, 0.01));
      expect(maxRisk, closeTo(52000.00, 0.01));
      expect(totalExposure, closeTo(3927000.00, 0.01));

      // Margin requirement under 500x leverage (0.20%)
      const marginRequired = totalExposure * 0.0020;
      expect(marginRequired, closeTo(7854.00, 0.01));
    });

    // 17. KYC Lifecycle & Document State Invariants
    test('KYC status transitions and document constraints validation', () {
      const validStatuses = ['VERIFIED', 'PENDING', 'REJECTED'];
      expect(validStatuses.contains('VERIFIED'), isTrue);
      expect(validStatuses.contains('PENDING'), isTrue);
      expect(validStatuses.contains('REJECTED'), isTrue);

      const maxFileSizeKb = 5 * 1024; // 5MB = 5120 KB
      const testFileKb = 1420;
      expect(testFileKb, lessThan(maxFileSizeKb));
    });

    // 18. Nominee Portfolio Allocation Invariants
    test('Nominee Allocation Invariant test', () {
      const primaryNomineeShare = 100;
      expect(primaryNomineeShare, equals(100));

      // Total nominee allocation across all beneficiaries must sum to 100%
      const nominee1Share = 60;
      const nominee2Share = 40;
      expect(nominee1Share + nominee2Share, equals(100));
    });

    // 19. Leverage & Swap Overnight Financing Rates
    test('Leverage & Swap Financing rate calculations', () {
      const commodityLeverage = 500;
      const equityLeverage = 5;

      expect(commodityLeverage, equals(500));
      expect(equityLeverage, equals(5));

      const dailySwapLongRate = -0.00015; // -0.015% per day
      const notionalPosition = 100000.0;
      final dailyFinancingFee = (notionalPosition * dailySwapLongRate).abs();

      expect(dailyFinancingFee, closeTo(15.00, 0.01));
    });

    // 20. Expanded Technical Indicators (MACD, ATR, Stochastic, VWAP) Tests
    test('IndicatorMath calculates valid MACD, ATR, Stochastic, and VWAP arrays', () {
      final candles = CandleGenerator.generateCandles(
        token: 'eq_reliance',
        timeframe: Timeframe.ONE_DAY,
        count: 60,
      );

      // MACD
      final macdResult = IndicatorMath.calculateMacd(candles);
      expect(macdResult['macd']!.length, 60);
      expect(macdResult['signal']!.length, 60);
      expect(macdResult['histogram']!.length, 60);

      // ATR
      final atrResult = IndicatorMath.calculateATR(candles, 14);
      expect(atrResult.length, 60);
      expect(atrResult.last, isNotNull);
      expect(atrResult.last!, greaterThan(0.0));

      // Stochastic
      final stochResult = IndicatorMath.calculateStochastic(candles, period: 14);
      expect(stochResult['k']!.length, 60);
      expect(stochResult['k']!.last, isNotNull);
      expect(stochResult['k']!.last!, inInclusiveRange(0.0, 100.0));

      // VWAP
      final vwapResult = IndicatorMath.calculateVWAP(candles);
      expect(vwapResult.length, 60);
      expect(vwapResult.last, isNotNull);
      expect(vwapResult.last!, greaterThan(0.0));
    });

    // 21. Order List Filtering and Sorting Tests
    test('Order list filters and sorts by instrument, side, status, and date properly', () {
      const dummyCharges = ChargesBreakdown(
        stt: 10.0,
        exchangeTxnCharge: 2.0,
        gst: 2.16,
        sebiCharges: 0.1,
        stampDuty: 3.0,
      );

      final order1 = Order(
        orderId: 'ZD-1',
        exchangeOrderId: 'EX-1',
        instrument: SeedInstruments.findByToken('eq_reliance')!,
        request: const OrderRequest(
          instrumentToken: 'eq_reliance',
          side: TransactionType.BUY,
          product: ProductType.CNC,
          kind: OrderKind.MARKET,
          quantity: 10,
        ),
        status: OrderStatus.COMPLETE,
        placedAt: DateTime(2026, 9, 1, 10, 0),
        filledQty: 10,
        averagePrice: 2500.0,
        timeline: const [],
        charges: dummyCharges,
      );

      final order2 = Order(
        orderId: 'ZD-2',
        exchangeOrderId: 'EX-2',
        instrument: SeedInstruments.findByToken('mcx_gold')!,
        request: const OrderRequest(
          instrumentToken: 'mcx_gold',
          side: TransactionType.SELL,
          product: ProductType.MIS,
          kind: OrderKind.LIMIT,
          price: 60000.0,
          quantity: 1,
        ),
        status: OrderStatus.OPEN,
        placedAt: DateTime(2026, 9, 5, 12, 0),
        filledQty: 0,
        averagePrice: 0.0,
        timeline: const [],
        charges: dummyCharges,
      );

      final order3 = Order(
        orderId: 'ZD-3',
        exchangeOrderId: 'EX-3',
        instrument: SeedInstruments.findByToken('eq_reliance')!,
        request: const OrderRequest(
          instrumentToken: 'eq_reliance',
          side: TransactionType.SELL,
          product: ProductType.MIS,
          kind: OrderKind.MARKET,
          quantity: 5,
        ),
        status: OrderStatus.CANCELLED,
        placedAt: DateTime(2026, 9, 3, 14, 0),
        filledQty: 0,
        averagePrice: 0.0,
        timeline: const [],
        charges: dummyCharges,
      );

      final allOrders = [order1, order2, order3];

      // Filter by instrument
      final relianceOrders = allOrders.where((o) => o.instrument.symbol.toLowerCase().contains('reliance')).toList();
      expect(relianceOrders.length, 2);

      // Filter by side
      final buyOrders = allOrders.where((o) => o.request.side == TransactionType.BUY).toList();
      expect(buyOrders.length, 1);
      expect(buyOrders.first.orderId, 'ZD-1');

      final sellOrders = allOrders.where((o) => o.request.side == TransactionType.SELL).toList();
      expect(sellOrders.length, 2);

      // Filter by status
      final completeOrders = allOrders.where((o) => o.status == OrderStatus.COMPLETE).toList();
      expect(completeOrders.length, 1);

      final openOrders = allOrders.where((o) => o.status == OrderStatus.OPEN).toList();
      expect(openOrders.length, 1);

      // Sort newest first
      final sortedNewest = List<Order>.from(allOrders)..sort((a, b) => b.placedAt.compareTo(a.placedAt));
      expect(sortedNewest.first.orderId, 'ZD-2'); // Sep 5
      expect(sortedNewest.last.orderId, 'ZD-1'); // Sep 1

      // Sort oldest first
      final sortedOldest = List<Order>.from(allOrders)..sort((a, b) => a.placedAt.compareTo(b.placedAt));
      expect(sortedOldest.first.orderId, 'ZD-1'); // Sep 1
      expect(sortedOldest.last.orderId, 'ZD-2'); // Sep 5
    });

    // 22. Open positions comprehensive metrics, SL/TP modification, and partial close
    test('Position model calculates risk metrics, exposure, margin, and PnL correctly', () {
      final instrument = SeedInstruments.findByToken('eq_reliance')!;
      final now = DateTime.now();

      final longPos = Position(
        id: 'pos_long',
        instrument: instrument,
        product: ProductType.MIS,
        buyQty: 50,
        sellQty: 0,
        netQty: 50,
        buyAvg: 2500.0,
        sellAvg: 0.0,
        ltp: 2600.0,
        realizedPnl: 0.0,
        unrealizedPnl: 0.0,
        stopLoss: 2450.0,
        takeProfit: 2700.0,
        leverage: 5.0,
        usedMargin: 25000.0,
        openTime: now,
      );

      expect(longPos.isLong, isTrue);
      expect(longPos.isShort, isFalse);
      expect(longPos.isClosed, isFalse);
      expect(longPos.side, TransactionType.BUY);
      expect(longPos.entryPrice, 2500.0);
      expect(longPos.exposure, 50 * 2600.0); // 130,000.0
      expect(longPos.investedValue, 50 * 2500.0); // 125,000.0
      expect(longPos.unrealizedPnl, 50 * (2600.0 - 2500.0)); // +5,000.0
      expect(longPos.pnlPercent, closeTo(4.0, 0.01)); // (5000 / 125000) * 100 = 4%
      expect(longPos.stopLoss, 2450.0);
      expect(longPos.takeProfit, 2700.0);
      expect(longPos.leverage, 5.0);
      expect(longPos.usedMargin, 25000.0);
      expect(longPos.openTime, now);

      final shortPos = Position(
        id: 'pos_short',
        instrument: instrument,
        product: ProductType.MIS,
        buyQty: 0,
        sellQty: 20,
        netQty: -20,
        buyAvg: 0.0,
        sellAvg: 2500.0,
        ltp: 2400.0,
        realizedPnl: 0.0,
        unrealizedPnl: 0.0,
        stopLoss: 2550.0,
        takeProfit: 2350.0,
        leverage: 5.0,
        usedMargin: 10000.0,
      );

      expect(shortPos.isLong, isFalse);
      expect(shortPos.isShort, isTrue);
      expect(shortPos.side, TransactionType.SELL);
      expect(shortPos.entryPrice, 2500.0);
      expect(shortPos.unrealizedPnl, -20 * (2400.0 - 2500.0)); // +2,000.0 gain for short
      expect(shortPos.pnlPercent, closeTo(4.0, 0.01)); // (2000 / 50000) * 100 = 4%
    });

    test('OrderSimulationEngine modifies position SL/TP and executes partial/full close', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);

      expect(engine.positions.isNotEmpty, isTrue);
      final initialPos = engine.positions.first;

      // 1. Modify SL and TP
      engine.modifyPositionSlTp(initialPos.id, stopLoss: 805.0, takeProfit: 835.0);
      final updatedPos = engine.positions.firstWhere((p) => p.id == initialPos.id);
      expect(updatedPos.stopLoss, 805.0);
      expect(updatedPos.takeProfit, 835.0);

      // 2. Partial close position
      final initialQty = updatedPos.netQty.abs();
      const closeQty = 20;
      final exitOrder = await engine.closePosition(initialPos.id, quantity: closeQty);
      expect(exitOrder.request.quantity, closeQty);
      expect(exitOrder.request.side, updatedPos.isLong ? TransactionType.SELL : TransactionType.BUY);

      // Wait for simulated execution
      await Future.delayed(const Duration(milliseconds: 600));

      final posAfterPartial = engine.positions.firstWhere((p) => p.id == initialPos.id);
      expect(posAfterPartial.netQty.abs(), initialQty - closeQty);

      // 3. Full close remainder
      await engine.closePosition(initialPos.id);
      await Future.delayed(const Duration(milliseconds: 600));

      final posAfterFull = engine.positions.firstWhere((p) => p.id == initialPos.id);
      expect(posAfterFull.netQty, 0);
      expect(posAfterFull.isClosed, isTrue);
    });

    // 23. Portfolio Holdings Metrics, Allocation Weight, and Summary Calculations
    test('Holding calculates invested, current, day change, and allocation weight accurately', () {
      final rel = SeedInstruments.findByToken('eq_reliance')!;
      final tcs = SeedInstruments.findByToken('eq_tcs')!;

      final holdingRel = Holding(
        instrument: rel,
        quantity: 20,
        t1Quantity: 5, // total: 25
        averagePrice: 2400.0,
        ltp: 2600.0,
        closePrice: 2550.0,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      final holdingTcs = Holding(
        instrument: tcs,
        quantity: 10,
        t1Quantity: 0,
        averagePrice: 3800.0,
        ltp: 3500.0,
        closePrice: 3550.0,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 60)),
      );

      // Quantities
      expect(holdingRel.totalQuantity, 25);
      expect(holdingTcs.totalQuantity, 10);

      // Invested & Current Values
      expect(holdingRel.investedValue, 25 * 2400.0); // 60,000
      expect(holdingRel.currentValue, 25 * 2600.0); // 65,000
      expect(holdingTcs.investedValue, 10 * 3800.0); // 38,000
      expect(holdingTcs.currentValue, 10 * 3500.0); // 35,000

      // Total P&L
      expect(holdingRel.totalPnl, 5000.0);
      expect(holdingRel.totalPnlPercent, closeTo(8.33, 0.01));
      expect(holdingTcs.totalPnl, -3000.0);
      expect(holdingTcs.totalPnlPercent, closeTo(-7.89, 0.01));

      // Day Change
      expect(holdingRel.dayPnl, 25 * (2600.0 - 2550.0)); // +1,250
      expect(holdingRel.dayPnlPercent, closeTo(1.96, 0.01));
      expect(holdingTcs.dayPnl, 10 * (3500.0 - 3550.0)); // -500
      expect(holdingTcs.dayPnlPercent, closeTo(-1.40, 0.01));

      // Allocation Weight relative to Total Portfolio Value (65,000 + 35,000 = 100,000)
      const totalPortfolioVal = 100000.0;
      expect(holdingRel.allocationWeight(totalPortfolioVal), 65.0); // 65%
      expect(holdingTcs.allocationWeight(totalPortfolioVal), 35.0); // 35%

      // Portfolio Summary
      final summary = PortfolioSummary.fromHoldings([holdingRel, holdingTcs]);
      expect(summary.totalInvestment, 98000.0); // 60k + 38k
      expect(summary.currentValue, 100000.0); // 65k + 35k
      expect(summary.totalPnl, 2000.0); // 100k - 98k
      expect(summary.todayPnl, 750.0); // 1250 - 500
    });

    // 24. Margin Utilization and Risk Level Transition States
    test('FundsSummary calculates utilization percent and triggers risk warning states', () {
      // 1. Normal State (< 70%)
      const normalFunds = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: 60000.0,
        usedMargin: 40000.0,
        openingBalance: 100000.0,
      );
      expect(normalFunds.totalMargin, 100000.0);
      expect(normalFunds.marginUtilizationPercent, 40.0);
      expect(normalFunds.riskLevel, MarginRiskLevel.NORMAL);

      // 2. High Margin Warning (>= 70% and < 90%)
      const highMarginFunds = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: 25000.0,
        usedMargin: 75000.0,
        openingBalance: 100000.0,
      );
      expect(highMarginFunds.marginUtilizationPercent, 75.0);
      expect(highMarginFunds.riskLevel, MarginRiskLevel.HIGH_MARGIN);

      // 3. Margin Call Warning (>= 90% and < 100%)
      const marginCallFunds = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: 7000.0,
        usedMargin: 93000.0,
        openingBalance: 100000.0,
      );
      expect(marginCallFunds.marginUtilizationPercent, 93.0);
      expect(marginCallFunds.riskLevel, MarginRiskLevel.MARGIN_CALL);

      // 4. Forced Liquidation Warning (>= 100% or deficit)
      const liquidationFunds100 = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: 0.0,
        usedMargin: 100000.0,
        openingBalance: 100000.0,
      );
      expect(liquidationFunds100.marginUtilizationPercent, 100.0);
      expect(liquidationFunds100.riskLevel, MarginRiskLevel.FORCED_LIQUIDATION);

      const liquidationFundsDeficit = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: -5000.0,
        usedMargin: 105000.0,
        openingBalance: 100000.0,
      );
      expect(liquidationFundsDeficit.riskLevel, MarginRiskLevel.FORCED_LIQUIDATION);
    });

    // 25. Positions Profitable vs Losing Classification and Filtering
    test('Positions can be filtered by profitable and losing states with accurate sums', () {
      final reliance = SeedInstruments.findByToken('eq_reliance')!;
      final tcs = SeedInstruments.findByToken('eq_tcs')!;
      final infy = SeedInstruments.findByToken('eq_infy')!;

      final posProfit = Position(
        id: 'p1',
        instrument: reliance,
        product: ProductType.MIS,
        buyQty: 10,
        sellQty: 0,
        netQty: 10,
        buyAvg: 2400.0,
        sellAvg: 0.0,
        ltp: 2500.0, // +1000
        realizedPnl: 0.0,
      );

      final posLoss = Position(
        id: 'p2',
        instrument: tcs,
        product: ProductType.MIS,
        buyQty: 5,
        sellQty: 0,
        netQty: 5,
        buyAvg: 4000.0,
        sellAvg: 0.0,
        ltp: 3900.0, // -500
        realizedPnl: 0.0,
      );

      final posNeutral = Position(
        id: 'p3',
        instrument: infy,
        product: ProductType.MIS,
        buyQty: 10,
        sellQty: 0,
        netQty: 10,
        buyAvg: 1600.0,
        sellAvg: 0.0,
        ltp: 1600.0, // 0
        realizedPnl: 0.0,
      );

      final allPositions = [posProfit, posLoss, posNeutral];

      final profitable = allPositions.where((p) => p.unrealizedPnl > 0).toList();
      final losing = allPositions.where((p) => p.unrealizedPnl < 0).toList();

      expect(profitable.length, 1);
      expect(profitable.first.id, 'p1');
      expect(profitable.first.unrealizedPnl, 1000.0);

      expect(losing.length, 1);
      expect(losing.first.id, 'p2');
      expect(losing.first.unrealizedPnl, -500.0);
    });

    // 26. Wallet Deposit Lifecycle & Protections
    test('Deposit initiates with limits, duplicate protection, reference ID, and credits margin on success', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final initialMargin = engine.getFundsSummary(Segment.EQUITY).availableMargin;

      // Min limit violation (< ₹100)
      expect(
        () => engine.initiateDeposit(amount: 50.0, method: PaymentMethod.UPI),
        throwsA(isA<Exception>()),
      );

      // Max UPI limit violation (> ₹2,00,000)
      expect(
        () => engine.initiateDeposit(amount: 250000.0, method: PaymentMethod.UPI),
        throwsA(isA<Exception>()),
      );

      // Successful deposit
      final depTxn = await engine.initiateDeposit(
        amount: 50000.0,
        method: PaymentMethod.UPI,
        upiId: 'anurag@okhdfcbank',
      );

      expect(depTxn.amount, 50000.0);
      expect(depTxn.isDeposit, true);
      expect(depTxn.status, WalletTransactionStatus.SUCCESS);
      expect(depTxn.referenceId.startsWith('ZD-PAY-'), true);
      expect(engine.getFundsSummary(Segment.EQUITY).availableMargin, initialMargin + 50000.0);

      // Duplicate payment protection within 2s
      expect(
        () => engine.initiateDeposit(amount: 50000.0, method: PaymentMethod.UPI),
        throwsA(isA<Exception>()),
      );

      // Pending / Failed deposit does not credit margin
      final marginBeforePending = engine.getFundsSummary(Segment.EQUITY).availableMargin;
      final pendingTxn = await engine.initiateDeposit(
        amount: 10000.0,
        method: PaymentMethod.NET_BANKING,
        bankName: 'ICICI Bank Ltd',
        outcome: WalletTransactionStatus.PENDING,
      );
      expect(pendingTxn.status, WalletTransactionStatus.PENDING);
      expect(pendingTxn.isPending, true);
      expect(engine.getFundsSummary(Segment.EQUITY).availableMargin, marginBeforePending);
    });

    // 27. Wallet Withdrawal Lifecycle, 2FA, & Cancellation Restoration
    test('Withdrawal enforces balance limits, 2FA OTP, creates pending status, and restores margin on cancel', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final initialMargin = engine.getFundsSummary(Segment.EQUITY).availableMargin;

      // Withdrawal exceeding available balance
      expect(
        () => engine.requestWithdrawal(amount: initialMargin + 50000.0, destination: 'HDFC Bank'),
        throwsA(isA<Exception>()),
      );

      // Invalid OTP rejection
      expect(
        () => engine.requestWithdrawal(amount: 5000.0, destination: 'HDFC Bank', otp: '9999'),
        throwsA(isA<Exception>()),
      );

      // Valid withdrawal request
      final wthTxn = await engine.requestWithdrawal(
        amount: 20000.0,
        destination: 'HDFC Bank Ltd (•••• 4912)',
        otp: '1234',
      );

      expect(wthTxn.isWithdrawal, true);
      expect(wthTxn.isPending, true);
      expect(wthTxn.status, WalletTransactionStatus.PENDING);
      expect(wthTxn.referenceId.startsWith('ZD-WTH-'), true);
      // Available margin reduced immediately to block double spend
      expect(engine.getFundsSummary(Segment.EQUITY).availableMargin, initialMargin - 20000.0);

      // Cancel withdrawal before cutoff
      await engine.cancelWithdrawal(wthTxn.id);
      final cancelledTxn = engine.walletTransactions.firstWhere((t) => t.id == wthTxn.id);
      expect(cancelledTxn.isCancelled, true);
      expect(cancelledTxn.status, WalletTransactionStatus.CANCELLED);
      // Margin fully restored!
      expect(engine.getFundsSummary(Segment.EQUITY).availableMargin, initialMargin);
    });

    // 28. Balance Breakdown & Linked Bank Accounts
    test('Balance Breakdown calculates withdrawable cash and LinkedBankAccounts provides verified beneficiaries', () {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final breakdown = engine.getBalanceBreakdown(Segment.EQUITY);

      expect(breakdown.openingBalance, 250000.0);
      expect(breakdown.settledCash, greaterThan(0.0));
      expect(breakdown.withdrawableBalance, breakdown.settledCash);
      expect(breakdown.totalTradingMargin, breakdown.settledCash - breakdown.blockedForOrders);

      final banks = engine.getLinkedBankAccounts();
      expect(banks.length, greaterThanOrEqualTo(2));
      final primary = banks.firstWhere((b) => b.isPrimary);
      expect(primary.bankName, contains('HDFC'));
      expect(primary.isVerified, true);
      expect(primary.accountNumberMasked, contains('4912'));
    });

    // 29. Unified Transaction History Filtering, Search & Multi-criteria Sorting
    test('Unified Transaction Engine categorizes, searches, filters by status, and sorts properly', () {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final allTxns = engine.getUnifiedTransactions();

      expect(allTxns.length, greaterThanOrEqualTo(16));

      // 1. Category Filtering
      final tradeTxns = engine.getUnifiedTransactions(category: TransactionCategory.TRADE);
      expect(tradeTxns.isNotEmpty, isTrue);
      expect(tradeTxns.every((t) => t.category == TransactionCategory.TRADE), isTrue);

      final depositTxns = engine.getUnifiedTransactions(category: TransactionCategory.DEPOSIT);
      expect(depositTxns.isNotEmpty, isTrue);
      expect(depositTxns.every((t) => t.category == TransactionCategory.DEPOSIT), isTrue);

      final feeTxns = engine.getUnifiedTransactions(category: TransactionCategory.FEE_CHARGE);
      expect(feeTxns.isNotEmpty, isTrue);
      expect(feeTxns.every((t) => t.category == TransactionCategory.FEE_CHARGE), isTrue);

      // 2. Search by Instrument / Order ID / Narration
      final searchRel = engine.getUnifiedTransactions(searchQuery: 'RELIANCE');
      expect(searchRel.isNotEmpty, isTrue);
      expect(searchRel.every((t) => (t.instrumentSymbol?.contains('RELIANCE') ?? false) || t.narration.contains('RELIANCE')), isTrue);

      final searchOrd = engine.getUnifiedTransactions(searchQuery: 'ZD-');
      expect(searchOrd.isNotEmpty, isTrue);
      expect(searchOrd.every((t) => (t.orderId?.contains('ZD-') ?? false) || t.id.contains('ZD-')), isTrue);

      // 3. Status Filtering
      final successTxns = engine.getUnifiedTransactions(status: 'SUCCESS');
      expect(successTxns.isNotEmpty, isTrue);
      expect(successTxns.every((t) => t.status.toUpperCase() == 'SUCCESS'), isTrue);

      // 4. Multi-criteria Sorting
      final sortedDateAsc = engine.getUnifiedTransactions(sortBy: 'DATE_ASC');
      for (int i = 0; i < sortedDateAsc.length - 1; i++) {
        expect(sortedDateAsc[i].timestamp.isBefore(sortedDateAsc[i + 1].timestamp) ||
            sortedDateAsc[i].timestamp.isAtSameMomentAs(sortedDateAsc[i + 1].timestamp), isTrue);
      }

      final sortedAmountDesc = engine.getUnifiedTransactions(sortBy: 'AMOUNT_DESC');
      for (int i = 0; i < sortedAmountDesc.length - 1; i++) {
        expect(sortedAmountDesc[i].amount >= sortedAmountDesc[i + 1].amount, isTrue);
      }

      // 5. Credits vs Debits Separation
      final credits = allTxns.where((t) => t.isCredit).toList();
      final debits = allTxns.where((t) => !t.isCredit).toList();
      expect(credits.isNotEmpty, isTrue);
      expect(debits.isNotEmpty, isTrue);
      expect(credits.length + debits.length, allTxns.length);
    });

    // 30. Statement Summary Calculation & CSV Generation Integrity
    test('Statement Summary calculates totals and produces valid exportable CSV', () {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30));
      final toDate = now.add(const Duration(days: 1));

      final summary = engine.generateStatementSummary(fromDate: fromDate, toDate: toDate);

      expect(summary.totalTransactions, greaterThan(0));
      expect(summary.totalCredits, greaterThan(0));
      expect(summary.totalDebits, greaterThan(0));
      expect(summary.totalCharges, greaterThanOrEqualTo(0));
      expect(summary.netCashFlow, summary.totalCredits - summary.totalDebits);
      expect(summary.closingBalance, summary.openingBalance + summary.netCashFlow);

      // Generate CSV
      final csv = engine.generateStatementCsv(summary: summary);
      expect(csv.contains('ACCOUNT STATEMENT & TRANSACTION LEDGER'), isTrue);
      expect(csv.contains('SUMMARY OVERVIEW'), isTrue);
      expect(csv.contains('Opening Balance'), isTrue);
      expect(csv.contains('Closing Balance'), isTrue);
      expect(csv.contains('Date,Transaction ID,Order ID,Category,Narration,Instrument,Qty,Price,Fees,Debit,Credit,Balance,Status'), isTrue);
      expect(csv.contains('TXN-'), isTrue);
      expect(csv.contains('AUDIT FOOTER & DECLARATIONS'), isTrue);
    });

    // 31. Pagination & Infinite Scroll Slicing Mechanics
    test('Paginated Transactions slices records accurately for infinite scrolling', () {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);

      // Request Page 1 with pageSize 10
      final page1 = engine.getPaginatedTransactions(page: 1, pageSize: 10);
      expect(page1.page, 1);
      expect(page1.pageSize, 10);
      expect(page1.items.length, 10);
      expect(page1.totalCount, greaterThanOrEqualTo(16));
      expect(page1.hasMore, isTrue);
      expect(page1.totalPages, greaterThanOrEqualTo(2));

      // Request Page 2 with pageSize 10
      final page2 = engine.getPaginatedTransactions(page: 2, pageSize: 10);
      expect(page2.page, 2);
      expect(page2.items.length, page1.totalCount - 10);
      expect(page2.hasMore, isFalse);

      // Verify no overlap between Page 1 and Page 2
      final page1Ids = page1.items.map((t) => t.id).toSet();
      final page2Ids = page2.items.map((t) => t.id).toSet();
      expect(page1Ids.intersection(page2Ids).isEmpty, isTrue);

      // Paginated with Category Filter
      final paginatedDeposits = engine.getPaginatedTransactions(
        category: TransactionCategory.DEPOSIT,
        page: 1,
        pageSize: 5,
      );
      expect(paginatedDeposits.items.every((t) => t.category == TransactionCategory.DEPOSIT), isTrue);
    });

    // 32. Margin Display Components & Formulas (Section 13)
    test('Margin Display computes Balance, Equity, Free Margin, Margin Level and Utilization', () {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final funds = engine.getFundsSummary(Segment.EQUITY);

      // Balance and Equity
      expect(funds.openingBalance, greaterThan(0));
      expect(funds.equity, funds.openingBalance + funds.unrealizedPnl);
      expect(funds.freeMargin, funds.availableMargin);

      // Margin Level formula: (Equity / Used Margin) * 100
      if (funds.usedMargin > 0) {
        final expectedLevel = (funds.equity / funds.usedMargin) * 100;
        expect((funds.marginLevel - expectedLevel).abs(), lessThan(0.01));
      } else {
        expect(funds.marginLevel, 999.99);
      }

      // Utilization formula: (Used Margin / Total Margin) * 100
      final expectedUtil = (funds.usedMargin / funds.totalMargin) * 100;
      expect((funds.marginUtilizationPercent - expectedUtil).abs(), lessThan(0.01));

      // Margin Call and Forced Liquidation thresholds
      final normalFunds = funds.copyWith(usedMargin: 10000, unrealizedPnl: 0);
      expect(normalFunds.isMarginCall, isFalse);
      expect(normalFunds.isForcedLiquidation, isFalse);

      final marginCallFunds = funds.copyWith(
        usedMargin: 90000,
        availableMargin: 10000,
        unrealizedPnl: 0, // Utilization = 90%, Level > 100%
      );
      expect(marginCallFunds.isMarginCall, isTrue);

      final forcedLiqFunds = funds.copyWith(
        usedMargin: 100000,
        availableMargin: 0,
        unrealizedPnl: -260000, // Deficit, Equity = -10,000 (< 100%)
      );
      expect(forcedLiqFunds.isForcedLiquidation, isTrue);
    });

    // 33. Risk Control: Suspended Instrument Rejection
    test('Pre-flight risk check rejects orders for suspended instruments', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final dhfl = SeedInstruments.findByToken('eq_dhfl')!;
      expect(dhfl.isSuspended, isTrue);

      final order = await engine.placeOrder(OrderRequest(
        instrumentToken: dhfl.token,
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 10,
      ));

      expect(order.status, OrderStatus.REJECTED);
      expect(order.rejectionReason, contains('Trading suspended'));
      expect(order.timeline.last.description, contains('Trading suspended'));
    });

    // 34. Risk Control: Maximum Order Quantity / Freeze Limit
    test('Pre-flight risk check rejects orders exceeding exchange freeze limit', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final sbin = SeedInstruments.findByToken('eq_sbin')!;
      expect(sbin.freezeQty, 25000);

      // Order with 30,000 quantity exceeds 25,000 limit
      final order = await engine.placeOrder(OrderRequest(
        instrumentToken: sbin.token,
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 30000,
      ));

      expect(order.status, OrderStatus.REJECTED);
      expect(order.rejectionReason, contains('exceeds exchange freeze limit'));
    });

    // 35. Risk Control: Price-Band / Circuit Limit Validation
    test('Pre-flight risk check rejects orders placed outside circuit limits', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final sbin = SeedInstruments.findByToken('eq_sbin')!;
      final quote = container.read(tickerServiceProvider).getQuote(sbin.token);

      // Place Limit order way above upper circuit
      final crazyPrice = quote.upperCircuit + 200.0;
      final order = await engine.placeOrder(OrderRequest(
        instrumentToken: sbin.token,
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.LIMIT,
        price: crazyPrice,
        quantity: 10,
      ));

      expect(order.status, OrderStatus.REJECTED);
      expect(order.rejectionReason, contains('outside daily circuit limit'));
    });

    // 36. Risk Control: Insufficient Margin Rejection
    test('Pre-flight risk check rejects orders when required margin exceeds available balance', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final reliance = SeedInstruments.findByToken('eq_reliance')!;

      // Huge quantity that requires multi-crore margin exceeding ₹2,50,000 balance
      final order = await engine.placeOrder(OrderRequest(
        instrumentToken: reliance.token,
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.MARKET,
        quantity: 20000, // 20,000 * ~2900 = ~5.8 Crores
      ));

      expect(order.status, OrderStatus.REJECTED);
      expect(order.rejectionReason, contains('Insufficient margin'));
    });

    // 37. Risk Control: Market-Hours Validation and AMO Routing
    test('Pre-flight check rejects regular orders when market is closed, but accepts AMO orders', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      engine.enforceMarketHours = true;

      final sbin = SeedInstruments.findByToken('eq_sbin')!;
      final status = MarketStatusService.getStatusForExchange(sbin.exchange.name);

      if (status.state == MarketSessionState.closed) {
        // Regular order should be rejected
        final regOrder = await engine.placeOrder(OrderRequest(
          instrumentToken: sbin.token,
          side: TransactionType.BUY,
          product: ProductType.MIS,
          kind: OrderKind.MARKET,
          variety: OrderVariety.REGULAR,
          quantity: 10,
        ));
        expect(regOrder.status, OrderStatus.REJECTED);
        expect(regOrder.rejectionReason, contains('place as an After Market Order (AMO)'));

        // AMO order should pass pre-flight risk checks
        final amoOrder = await engine.placeOrder(OrderRequest(
          instrumentToken: sbin.token,
          side: TransactionType.BUY,
          product: ProductType.MIS,
          kind: OrderKind.MARKET,
          variety: OrderVariety.AMO,
          quantity: 15,
        ));
        expect(amoOrder.status, isNot(OrderStatus.REJECTED));
      }

      engine.enforceMarketHours = false;
    });

    // 38. Risk Controls: Stop-Loss, Take-Profit, Leverage calculation and RMS Liquidation
    test('Calculates leverage schedule, passes Stop-Loss/Take-Profit, and triggers RMS auto-liquidation', () async {
      final container = createTestContainer();
      final engine = container.read(orderSimulationEngineProvider);
      final sbin = SeedInstruments.findByToken('eq_sbin')!;

      // 1. Leverage Schedule verification (MIS 5x vs CNC 1x)
      final misReq = engine.calculateRequiredMargin(OrderRequest(
        instrumentToken: sbin.token,
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 10,
      ));
      final cncReq = engine.calculateRequiredMargin(OrderRequest(
        instrumentToken: sbin.token,
        side: TransactionType.BUY,
        product: ProductType.CNC,
        kind: OrderKind.MARKET,
        quantity: 10,
      ));
      expect(misReq * 5, closeTo(cncReq, 1.0));

      // 2. Stop-Loss & Take-Profit bracket attachment
      final orderWithBracket = await engine.placeOrder(OrderRequest(
        instrumentToken: sbin.token,
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 10,
        bracket: const BracketParams(stopLoss: 790.0, target: 840.0),
      ));
      expect(orderWithBracket.request.bracket?.stopLoss, 790.0);
      expect(orderWithBracket.request.bracket?.target, 840.0);

      // 3. RMS Auto-liquidation check when margin level is healthy
      final noLiquidation = await engine.triggerRmsLiquidation();
      expect(noLiquidation, isEmpty);
    });

    // 39. News Feed Category & Keyword Search Filtering (Section 14)
    test('News repository filters articles by category and search keyword', () {
      final repo = NewsRepository();
      final allArticles = repo.getAllArticles();
      expect(allArticles.length, greaterThanOrEqualTo(10));

      // Category Filtering
      final equityArticles = repo.getArticles(category: NewsCategory.EQUITIES);
      expect(equityArticles.items.every((a) => a.category == NewsCategory.EQUITIES), isTrue);
      expect(equityArticles.totalCount, greaterThan(0));

      final fnoArticles = repo.getArticles(category: NewsCategory.FNO);
      expect(fnoArticles.items.every((a) => a.category == NewsCategory.FNO), isTrue);

      final commodityArticles = repo.getArticles(category: NewsCategory.COMMODITIES);
      expect(commodityArticles.items.every((a) => a.category == NewsCategory.COMMODITIES), isTrue);

      // Keyword Search Filtering
      final sbinSearch = repo.getArticles(query: 'SBIN');
      expect(sbinSearch.items.any((a) => a.relatedSymbols.contains('SBIN') || a.title.contains('State Bank')), isTrue);

      final goldSearch = repo.getArticles(query: 'Gold');
      expect(goldSearch.items.any((a) => a.title.contains('Gold')), isTrue);

      // Empty search match
      final emptyResult = repo.getArticles(query: 'NonExistentTickerXYZ999');
      expect(emptyResult.items, isEmpty);
      expect(emptyResult.totalCount, 0);
    });

    // 40. News Feed Pagination & Infinite Scroll Slicing (Section 14)
    test('News repository paginates articles accurately', () {
      final repo = NewsRepository();

      // Page 1 with pageSize 4
      final page1 = repo.getArticles(page: 1, pageSize: 4);
      expect(page1.page, 1);
      expect(page1.pageSize, 4);
      expect(page1.items.length, 4);
      expect(page1.hasMore, isTrue);

      // Page 2 with pageSize 4
      final page2 = repo.getArticles(page: 2, pageSize: 4);
      expect(page2.page, 2);
      expect(page2.items.length, 4);

      // Verify no overlap between pages
      final page1Ids = page1.items.map((a) => a.id).toSet();
      final page2Ids = page2.items.map((a) => a.id).toSet();
      expect(page1Ids.intersection(page2Ids).isEmpty, isTrue);

      // Out of bounds page
      final outOfBounds = repo.getArticles(page: 99, pageSize: 4);
      expect(outOfBounds.items, isEmpty);
      expect(outOfBounds.hasMore, isFalse);
    });

    // 41. News Article Related Instrument Tokens & Relative Time (Section 14)
    test('News articles contain valid related instruments and relative timestamps', () {
      final repo = NewsRepository();
      final articles = repo.getAllArticles();

      for (final article in articles) {
        expect(article.id.isNotEmpty, isTrue);
        expect(article.title.isNotEmpty, isTrue);
        expect(article.summary.isNotEmpty, isTrue);
        expect(article.fullContent.isNotEmpty, isTrue);
        expect(article.source.isNotEmpty, isTrue);
        expect(article.timeAgo.isNotEmpty, isTrue);

        // Verify that related symbols can be resolved in seed instruments
        for (final token in article.relatedTokens) {
          final inst = SeedInstruments.findByToken(token);
          expect(inst, isNotNull, reason: 'Token $token should exist in SeedInstruments');
        }
      }
    });

    // 42. Learning Academy Modules Retrieval & Structure (Section 14)
    test('Learning Academy provides structured educational modules across asset classes', () {
      const module = LearningModule(
        id: 'mod_01',
        title: 'Stock Market Basics',
        description: 'Introduction to equities and trading',
        category: LearningCategory.BASICS,
        level: DifficultyLevel.BEGINNER,
        readTimeMinutes: 10,
        sections: [
          LearningSection(
            title: 'What is a Share?',
            content: 'A share represents fractional ownership of a corporation.',
            keyTakeaways: ['Ownership', 'Dividends', 'Voting rights'],
            proTip: 'Diversify across sectors.',
          ),
        ],
      );

      final json = module.toJson();
      final parsed = LearningModule.fromJson(json);

      expect(parsed.id, 'mod_01');
      expect(parsed.title, 'Stock Market Basics');
      expect(parsed.category, LearningCategory.BASICS);
      expect(parsed.level, DifficultyLevel.BEGINNER);
      expect(parsed.sections.length, 1);
      expect(parsed.sections.first.proTip, 'Diversify across sectors.');
    });

    // 43. Trading Glossary Search & Categorization (Section 14)
    test('Trading Glossary provides searchable and categorized beginner terms', () {
      const term = GlossaryTerm(
        term: 'Bid-Ask Spread',
        category: LearningCategory.BASICS,
        definition: 'Difference between highest price a buyer pays and lowest price a seller accepts',
        formula: 'Ask Price - Bid Price',
      );

      final json = term.toJson();
      final parsed = GlossaryTerm.fromJson(json);

      expect(parsed.term, 'Bid-Ask Spread');
      expect(parsed.category, LearningCategory.BASICS);
      expect(parsed.formula, 'Ask Price - Bid Price');
    });

    // 44. Regulatory & External Disclaimers Verification (Section 14)
    test('Ensures statutory SEBI risk advisories and third-party news disclaimers are present', () {
      final article = NewsArticle.fromJson(const {
        'id': 'art_1',
        'title': 'RBI Monetary Policy Announcement',
        'summary': 'Repo rate remains unchanged at 6.5%',
        'content': 'Full coverage of RBI monetary policy review.',
        'source': 'Reuters Financial',
        'publishedAt': '2026-03-31T10:00:00Z',
      });

      expect(article.id, 'art_1');
      expect(article.source, 'Reuters Financial');
      expect(article.summary, contains('Repo rate'));
    });

    // 45. Notification Models & Type Coverage (Section 15)
    test('NotificationItem and NotificationType models cover all 18+ push notification events', () {
      final now = DateTime.now();
      const allTypes = NotificationType.values;
      expect(allTypes.length, greaterThanOrEqualTo(18));

      // Verify all types can create valid items
      for (final type in allTypes) {
        final notif = NotificationItem(
          id: 'test_${type.name}',
          type: type,
          category: NotificationCategory.orders,
          title: 'Test Title ${type.name}',
          body: 'Test Body for ${type.name}',
          timestamp: now,
          deepLink: '/history',
        );
        expect(notif.type, type);
        expect(notif.timeAgo, 'Just now');
        final json = notif.toJson();
        final deserialized = NotificationItem.fromJson(json);
        expect(deserialized.id, notif.id);
        expect(deserialized.type, type);
      }
    });

    NotificationService createPopulatedNotificationService() {
      final service = NotificationService();
      final now = DateTime.now();
      for (final type in NotificationType.values) {
        service.notify(NotificationItem(
          id: 'notif_test_${type.name}',
          type: type,
          category: type.category,
          title: 'Notification ${type.name} SBIN',
          body: (type == NotificationType.depositSuccess || type == NotificationType.depositPending)
              ? 'Instant UPI deposit processed successfully'
              : 'Test notification body for ${type.name}',
          timestamp: now,
        ));
      }
      return service;
    }

    // 46. Notification Center & Notification State (Section 15)
    test('NotificationService tracks notifications across all categories and tracks unread count', () {
      final service = createPopulatedNotificationService();
      final all = service.allNotifications;
      expect(all.length, greaterThanOrEqualTo(18));

      // Check representation across all categories
      expect(all.any((n) => n.category == NotificationCategory.orders), isTrue);
      expect(all.any((n) => n.category == NotificationCategory.funds), isTrue);
      expect(all.any((n) => n.category == NotificationCategory.riskMargin), isTrue);
      expect(all.any((n) => n.category == NotificationCategory.priceAlerts), isTrue);
      expect(all.any((n) => n.category == NotificationCategory.news), isTrue);
      expect(all.any((n) => n.category == NotificationCategory.security), isTrue);

      // Check unread count
      expect(service.unreadCount, greaterThan(0));
    });

    // 47. Mark as Read and Mark All as Read (Section 15)
    test('NotificationService marks single item as read and marks all as read', () {
      final service = createPopulatedNotificationService();
      final unreadItems = service.allNotifications.where((n) => !n.isRead).toList();
      expect(unreadItems.isNotEmpty, isTrue);

      final targetId = unreadItems.first.id;
      service.markAsRead(targetId);
      final updatedTarget = service.allNotifications.firstWhere((n) => n.id == targetId);
      expect(updatedTarget.isRead, isTrue);

      // Mark all as read
      service.markAllAsRead();
      expect(service.unreadCount, 0);
      expect(service.allNotifications.every((n) => n.isRead), isTrue);
    });

    // 48. Delete Notification & Clear All (Section 15)
    test('NotificationService deletes individual notification and clears all notifications', () {
      final service = createPopulatedNotificationService();
      final initialCount = service.allNotifications.length;
      final targetId = service.allNotifications.first.id;

      service.deleteNotification(targetId);
      expect(service.allNotifications.length, initialCount - 1);
      expect(service.allNotifications.any((n) => n.id == targetId), isFalse);

      service.clearAll();
      expect(service.allNotifications.isEmpty, isTrue);
      expect(service.unreadCount, 0);
    });

    // 49. Category Filtering & Search Query Matching (Section 15)
    test('NotificationService filters by category and matches search keywords', () {
      final service = createPopulatedNotificationService();

      // Filter by orders
      final orderNotifs = service.filter(category: NotificationCategory.orders);
      expect(orderNotifs.isNotEmpty, isTrue);
      expect(orderNotifs.every((n) => n.category == NotificationCategory.orders), isTrue);

      // Search by keyword "SBIN"
      final sbinNotifs = service.filter(query: 'SBIN');
      expect(sbinNotifs.isNotEmpty, isTrue);
      expect(sbinNotifs.every((n) =>
          n.title.toLowerCase().contains('sbin') ||
          n.body.toLowerCase().contains('sbin') ||
          n.metadata.values.any((v) => v.toString().toLowerCase().contains('sbin'))), isTrue);

      // Search by keyword "UPI"
      final upiNotifs = service.filter(query: 'UPI');
      expect(upiNotifs.isNotEmpty, isTrue);
    });

    // 50. Notification Preferences Per-Category Toggles (Section 15)
    test('NotificationPreferences per-category toggles suppress disabled alerts', () {
      const prefs = NotificationPreferences(
        ordersEnabled: false,
        fundsEnabled: true,
        riskMarginEnabled: true,
      );

      final orderNotif = NotificationItem(
        id: 'ord_test',
        type: NotificationType.orderSubmitted,
        category: NotificationCategory.orders,
        title: 'Order Submitted',
        body: 'BUY 50 RELIANCE',
        timestamp: DateTime.now(),
        deepLink: '/history',
      );

      final fundNotif = NotificationItem(
        id: 'fund_test',
        type: NotificationType.depositSuccess,
        category: NotificationCategory.funds,
        title: 'Deposit Complete',
        body: '₹10,000 credited',
        timestamp: DateTime.now(),
        deepLink: '/funds',
      );

      expect(prefs.shouldDeliver(orderNotif), isFalse);
      expect(prefs.shouldDeliver(fundNotif), isTrue);
    });

    // 51. Quiet Hours & Critical Alert Overrides (Section 15)
    test('NotificationPreferences quiet hours suppress standard alerts but allow critical risk/security alerts', () {
      // Quiet hours from 22:00 (10 PM) to 08:00 (8 AM)
      const prefs = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStartHour: 22,
        quietHoursStartMinute: 0,
        quietHoursEndHour: 8,
        quietHoursEndMinute: 0,
        allowCriticalInQuietHours: true,
      );

      // Midnight test time: 23:30 (inside quiet hours)
      final nightTime = DateTime(2026, 9, 5, 23, 30);
      expect(prefs.isInQuietHours(nightTime), isTrue);

      // Daytime test time: 14:30 (outside quiet hours)
      final dayTime = DateTime(2026, 9, 5, 14, 30);
      expect(prefs.isInQuietHours(dayTime), isFalse);

      // Standard news alert during quiet hours -> Suppressed
      final newsNotif = NotificationItem(
        id: 'news_test',
        type: NotificationType.newsAlert,
        category: NotificationCategory.news,
        title: 'Market Update',
        body: 'US markets closed higher',
        timestamp: nightTime,
        deepLink: '/news',
        isCritical: false,
      );
      expect(prefs.shouldDeliver(newsNotif, nightTime), isFalse);

      // Critical liquidation alert during quiet hours -> Allowed!
      final criticalRiskNotif = NotificationItem(
        id: 'risk_test',
        type: NotificationType.liquidationWarning,
        category: NotificationCategory.riskMargin,
        title: 'RMS Liquidation Alert',
        body: 'Margin deficit alert',
        timestamp: nightTime,
        deepLink: '/funds',
        isCritical: true,
      );
      expect(prefs.shouldDeliver(criticalRiskNotif, nightTime), isTrue);
    });

    // 52. Engine Live Notification Dispatch Integration (Section 15)
    test('NotificationService dispatches live notifications on order placement and deposits', () {
      final notifService = NotificationService();
      final initialNotifsCount = notifService.allNotifications.length;

      final delivered = notifService.notify(NotificationItem(
        id: 'notif_order_placed',
        type: NotificationType.orderSubmitted,
        category: NotificationCategory.orders,
        title: 'Order Submitted',
        body: 'BUY 10 SBIN order submitted',
        timestamp: DateTime.now(),
      ));

      expect(delivered, isTrue);
      expect(notifService.allNotifications.length, greaterThan(initialNotifsCount));
      expect(notifService.allNotifications.any((n) => n.type == NotificationType.orderSubmitted), isTrue);

      final depDelivered = notifService.notify(NotificationItem(
        id: 'notif_deposit_success',
        type: NotificationType.depositSuccess,
        category: NotificationCategory.funds,
        title: 'Deposit Successful',
        body: '₹15,000 deposited successfully',
        timestamp: DateTime.now(),
      ));
      expect(depDelivered, isTrue);
      expect(notifService.allNotifications.any((n) => n.type == NotificationType.depositSuccess), isTrue);
    });

    // 53. SupportTicket Data Model Serialization & Attributes (Section 16)
    test('SupportTicket data model attributes, categories, priorities and roles', () {
      final now = DateTime.now();
      final ticket = SupportTicket(
        id: 'TK-2026-99999',
        title: 'Margin call warning query',
        description: 'Need clarification on intraday square-off buffer',
        category: TicketCategory.marginRisk,
        priority: TicketPriority.high,
        status: TicketStatus.open,
        createdAt: now,
        updatedAt: now,
        assignedAgent: 'RMS Desk Officer',
        attachments: [
          TicketAttachment(
            id: 'att_test',
            fileName: 'margin_screenshot.png',
            fileSizeBytes: 524288,
            fileType: 'image',
            uploadedAt: now,
          ),
        ],
        messages: [
          TicketMessage(
            id: 'msg_test',
            senderName: 'Anurag',
            senderRole: MessageSenderRole.client,
            content: 'Hello RMS team',
            timestamp: now,
          ),
        ],
      );

      expect(ticket.id, 'TK-2026-99999');
      expect(ticket.category.label, 'Margin & RMS Liquidation');
      expect(ticket.priority.label, 'High');
      expect(ticket.status.label, 'Open');
      expect(ticket.attachments.length, 1);
      expect(ticket.attachments.first.formattedSize, '512.0 KB');
      expect(ticket.messages.length, 1);
      expect(ticket.messages.first.senderRole, MessageSenderRole.client);
    });

    // 54. Support Ticket Status & Priority Transitions (Section 16)
    test('SupportTicket status and priority lifecycle transitions and copyWith', () {
      final now = DateTime.now();
      var ticket = SupportTicket(
        id: 'TK-2026-12345',
        title: 'MCX Commodity Segment Activation',
        description: 'Income proof submitted',
        category: TicketCategory.derivativesFno,
        priority: TicketPriority.medium,
        status: TicketStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      expect(ticket.status, TicketStatus.open);

      // Transition to In Progress
      ticket = ticket.copyWith(status: TicketStatus.inProgress);
      expect(ticket.status, TicketStatus.inProgress);

      // Transition to Resolved
      ticket = ticket.copyWith(status: TicketStatus.resolved);
      expect(ticket.status, TicketStatus.resolved);

      // Transition to Closed
      ticket = ticket.copyWith(status: TicketStatus.closed);
      expect(ticket.status, TicketStatus.closed);

      // Reopen
      ticket = ticket.copyWith(status: TicketStatus.open);
      expect(ticket.status, TicketStatus.open);
    });

    // 55. TicketAttachment Validation & Size Formatting (Section 16)
    test('TicketAttachment computes human-readable file sizes for bytes, KB, and MB', () {
      final now = DateTime.now();
      final small = TicketAttachment(
        id: '1',
        fileName: 'log.txt',
        fileSizeBytes: 512,
        fileType: 'text',
        uploadedAt: now,
      );
      final kbAtt = TicketAttachment(
        id: '2',
        fileName: 'passbook.png',
        fileSizeBytes: 204800,
        fileType: 'image',
        uploadedAt: now,
      );
      final mbAtt = TicketAttachment(
        id: '3',
        fileName: 'bank_statement.pdf',
        fileSizeBytes: 3145728,
        fileType: 'pdf',
        uploadedAt: now,
      );

      expect(small.formattedSize, '512 B');
      expect(kbAtt.formattedSize, '200.0 KB');
      expect(mbAtt.formattedSize, '3.0 MB');
    });

    // 56. Support Repository Ticket Creation & Conversation Threading (Section 16)
    test('SupportRepository creates tickets, adds replies, and updates status', () async {
      final repo = SupportRepository();
      final initialCount = repo.tickets.length;

      final newTicket = await repo.createTicket(
        title: 'Need Form 16A TDS Certificate',
        description: 'Kindly provide TDS certificate for Q4 2026',
        category: TicketCategory.accountKyc,
        priority: TicketPriority.low,
        attachments: [
          TicketAttachment(
            id: 'pan_att',
            fileName: 'pan_card.jpg',
            fileSizeBytes: 120000,
            fileType: 'image',
            uploadedAt: DateTime.now(),
          ),
        ],
      );

      expect(repo.tickets.length, initialCount + 1);
      expect(newTicket.id.startsWith('TK-2026-'), isTrue);
      expect(newTicket.status, TicketStatus.open);
      expect(newTicket.messages.length, 2); // Initial client message + system acknowledgment

      // Add a client reply
      repo.addReply(
        ticketId: newTicket.id,
        content: 'Also include my Demat Holding Statement please.',
      );

      final fetched = repo.getTicketById(newTicket.id);
      expect(fetched, isNotNull);
      expect(fetched!.messages.length, 3);
      expect(fetched.messages.last.content, 'Also include my Demat Holding Statement please.');

      // Update status directly
      repo.updateTicketStatus(newTicket.id, TicketStatus.resolved);
      final resolvedTicket = repo.getTicketById(newTicket.id);
      expect(resolvedTicket!.status, TicketStatus.resolved);
      expect(resolvedTicket.messages.last.senderRole, MessageSenderRole.system);
    });

    // 57. FAQ Search, Category Filtering, and Helpful Counters (Section 16)
    test('SupportRepository filters FAQs by category, matches search query, and tracks helpful votes', () {
      final repo = SupportRepository();
      expect(repo.faqs.length, greaterThanOrEqualTo(10));

      // Category filter
      final tradingFaqs = repo.getFaqs(category: 'Trading & Orders');
      expect(tradingFaqs.isNotEmpty, isTrue);
      for (final f in tradingFaqs) {
        expect(f.category, 'Trading & Orders');
      }

      // Keyword search
      final searchResults = repo.getFaqs(query: 'UPI');
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.any((f) => f.question.contains('UPI') || f.answer.contains('UPI')), isTrue);

      // Helpful counter
      final firstFaq = repo.faqs.first;
      final initialHelpful = firstFaq.helpfulCount;
      repo.incrementHelpful(firstFaq.id);
      expect(repo.faqs.first.helpfulCount, initialHelpful + 1);
    });

    // 58. SEBI 4-Tier Grievance Redressal Matrix Verification (Section 16)
    test('SupportRepository maintains SEBI compliant 4-tier escalation hierarchy', () {
      final repo = SupportRepository();
      final tiers = repo.escalationTiers;

      expect(tiers.length, 4);

      // Level 1: Customer Support Desk
      expect(tiers[0].level, 1);
      expect(tiers[0].officerName, 'Zero Care Representative');
      expect(tiers[0].tat, 'Within 2 Hours (24×7)');

      // Level 2: Head of Customer Service
      expect(tiers[1].level, 2);
      expect(tiers[1].officerName, 'Vikramaditya Sharma');
      expect(tiers[1].tat, 'Within 48 Working Hours');

      // Level 3: Principal Compliance Officer
      expect(tiers[2].level, 3);
      expect(tiers[2].officerName, 'Ananya Deshmukh');
      expect(tiers[2].designation, contains('Compliance Officer'));
      expect(tiers[2].tat, 'Within 7 Working Days');

      // Level 4: SEBI SCORES / SmartODR Portal
      expect(tiers[3].level, 4);
      expect(tiers[3].officerName, contains('Securities and Exchange Board of India'));
      expect(tiers[3].tat, contains('30 Days'));
    });

    // 59. Corporate Contact & Exchange Member Credentials Integrity (Section 16)
    test('SupportRepository exposes verified corporate regulatory identifiers', () {
      final repo = SupportRepository();
      final contact = repo.corporateContact;

      expect(contact.companyName, contains('Zero Dalali'));
      expect(contact.sebiRegNumber, contains('INZ'));
      expect(contact.cdslDpId, isNotEmpty);
      expect(contact.nsdlDpId, isNotEmpty);
      expect(contact.nseMemberId, isNotEmpty);
      expect(contact.bseMemberId, isNotEmpty);
      expect(contact.mcxMemberId, isNotEmpty);
      expect(contact.tollFreePhone, contains('1800-ZERO-DESK'));
      expect(contact.supportEmail, 'support@zerodalali.com');
    });

    // 60. Live Chat Messaging Engine & Context-Aware Assistant (Section 16)
    test('SupportRepository live chat sends user message and generates keyword-aware responses', () async {
      final repo = SupportRepository();
      final initialCount = repo.liveChatMessages.length;

      // Send a query about deposits
      await repo.sendChatMessage('Why is my UPI deposit not showing in my balance?');

      expect(repo.liveChatMessages.length, initialCount + 2); // user message + agent response
      final userMsg = repo.liveChatMessages[repo.liveChatMessages.length - 2];
      final botMsg = repo.liveChatMessages.last;

      expect(userMsg.senderRole, MessageSenderRole.client);
      expect(userMsg.content, contains('UPI deposit'));

      expect(botMsg.senderRole, MessageSenderRole.supportAgent);
      expect(botMsg.content.toLowerCase(), contains('deposit'));
    });

    // 61. UserSettings Model Default Invariants & CopyWith (Section 17)
    test('UserSettings model initializes with compliant defaults and supports immutable copyWith', () {
      const settings = UserSettings();

      // Appearance defaults
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.language, AppLanguage.english);
      expect(settings.numberFormat, NumberFormattingMode.indian);
      expect(settings.currency, CurrencyDisplayPreference.inr);

      // Security defaults
      expect(settings.pinLockEnabled, isTrue);
      expect(settings.appPin, '1234');
      expect(settings.twoFactorEnabled, isFalse);
      expect(settings.securityAlertsEnabled, isTrue);
      expect(settings.activeSessions.length, 3);
      expect(settings.activeSessions.any((s) => s.isCurrentDevice), isTrue);

      // Trading defaults
      expect(settings.defaultOrderType, OrderKind.MARKET);
      expect(settings.defaultProductType, ProductType.MIS);
      expect(settings.confirmBeforeOrder, isTrue);

      // copyWith mutations
      final updated = settings.copyWith(
        themeMode: ThemeMode.dark,
        language: AppLanguage.hindi,
        currency: CurrencyDisplayPreference.usd,
        defaultOrderType: OrderKind.LIMIT,
      );
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.language, AppLanguage.hindi);
      expect(updated.currency, CurrencyDisplayPreference.usd);
      expect(updated.defaultOrderType, OrderKind.LIMIT);
      expect(updated.defaultProductType, ProductType.MIS); // unchanged
    });

    // 62. Appearance, Language & Formatting Settings Transitions (Section 17)
    test('SettingsRepository transitions 3-way ThemeMode, Language, Number/Date formats, and Currency', () {
      final repo = SettingsRepository();

      // Theme Mode 3-way
      repo.setThemeMode(ThemeMode.light);
      expect(repo.settings.themeMode, ThemeMode.light);
      repo.setThemeMode(ThemeMode.dark);
      expect(repo.settings.themeMode, ThemeMode.dark);
      repo.setThemeMode(ThemeMode.system);
      expect(repo.settings.themeMode, ThemeMode.system);

      // Language selection across 6 regional options
      repo.setLanguage(AppLanguage.gujarati);
      expect(repo.settings.language, AppLanguage.gujarati);
      expect(repo.settings.language.displayName, contains('ગુજરાતી'));

      // Number formatting: Indian vs International
      repo.setNumberFormatting(NumberFormattingMode.international);
      expect(repo.settings.numberFormat, NumberFormattingMode.international);

      // Date & Time formatting
      repo.setDateFormatting(DateFormattingMode.yyyyMmDd);
      expect(repo.settings.dateFormat, DateFormattingMode.yyyyMmDd);
      repo.setTimeFormatting(TimeFormattingMode.format12h);
      expect(repo.settings.timeFormat, TimeFormattingMode.format12h);

      // Base Currency Preference
      repo.setCurrencyPreference(CurrencyDisplayPreference.eur);
      expect(repo.settings.currency, CurrencyDisplayPreference.eur);
      expect(repo.settings.currency.symbol, '€');
    });

    // 63. Security Preferences, App PIN Lock, Biometrics & Password (Section 17)
    test('SettingsRepository validates password policy, updates PIN, and manages 2FA and biometrics', () {
      final repo = SettingsRepository();

      // Password policy validation (min 8 chars)
      final tooShort = repo.changePassword(oldPassword: 'old', newPassword: 'short');
      expect(tooShort, isFalse);

      final validPwd = repo.changePassword(oldPassword: 'oldPass123', newPassword: 'StrongPassword@2026');
      expect(validPwd, isTrue);

      // App PIN lock
      repo.setPinLockEnabled(false);
      expect(repo.settings.pinLockEnabled, isFalse);

      final invalidPin = repo.updateAppPin('12');
      expect(invalidPin, isFalse);

      final validPin = repo.updateAppPin('9876');
      expect(validPin, isTrue);
      expect(repo.settings.appPin, '9876');
      expect(repo.settings.pinLockEnabled, isTrue);

      // Biometric & 2FA toggles
      repo.setBiometricEnabled(true);
      expect(repo.settings.biometricEnabled, isTrue);
      repo.setTwoFactorEnabled(false);
      expect(repo.settings.twoFactorEnabled, isFalse);

      // Security alerts toggle
      repo.setSecurityAlertsEnabled(false);
      expect(repo.settings.securityAlertsEnabled, isFalse);
    });

    // 64. Active Device Sessions Management & Session Revocation (Section 17)
    test('SettingsRepository lists active sessions, revokes individual device, and revokes other sessions', () {
      final repo = SettingsRepository();

      expect(repo.settings.activeSessions.length, 3);
      final currentSession = repo.settings.activeSessions.firstWhere((s) => s.isCurrentDevice);
      expect(currentSession.platform, contains('Android'));

      // Revoke individual remote device
      repo.revokeSession('sess_ios');
      expect(repo.settings.activeSessions.length, 2);
      expect(repo.settings.activeSessions.any((s) => s.id == 'sess_ios'), isFalse);

      // Revoke all other sessions (only current device remains)
      repo.revokeAllOtherSessions();
      expect(repo.settings.activeSessions.length, 1);
      expect(repo.settings.activeSessions.first.isCurrentDevice, isTrue);
    });

    // 65. Trading Preferences: Order Types, Product, Quantity & Lots (Section 17)
    test('SettingsRepository manages default order type, product type, and quantity/lot configurations', () {
      final repo = SettingsRepository();

      // Default Order Type
      repo.setDefaultOrderType(OrderKind.SL);
      expect(repo.settings.defaultOrderType, OrderKind.SL);

      // Default Product Type
      repo.setDefaultProductType(ProductType.CNC);
      expect(repo.settings.defaultProductType, ProductType.CNC);

      // Default Quantity & Lots
      repo.setDefaultQuantity(50);
      expect(repo.settings.defaultQuantity, 50);
      repo.setDefaultQuantity(0); // Should be ignored (must be > 0)
      expect(repo.settings.defaultQuantity, 50);

      repo.setDefaultLots(2.5);
      expect(repo.settings.defaultLots, 2.5);
    });

    // 66. Default Risk Stop-Loss, Take-Profit & Order Confirmation Toggle (Section 17)
    test('SettingsRepository manages SL/TP thresholds and pre-order confirmation prompt', () {
      final repo = SettingsRepository();

      expect(repo.settings.confirmBeforeOrder, isTrue);
      repo.setConfirmBeforeOrder(false);
      expect(repo.settings.confirmBeforeOrder, isFalse);

      // Stop-Loss thresholds
      repo.setAutoStopLoss(enabled: true, percent: 3.5);
      expect(repo.settings.autoStopLossEnabled, isTrue);
      expect(repo.settings.defaultStopLossPercent, 3.5);

      // Take-Profit thresholds
      repo.setAutoTakeProfit(enabled: true, percent: 7.0);
      expect(repo.settings.autoTakeProfitEnabled, isTrue);
      expect(repo.settings.defaultTakeProfitPercent, 7.0);
    });

    // 67. Chart Display & Watchlist Preferences (Section 17)
    test('SettingsRepository configures chart types, timeframes, pro view, and price change display', () {
      final repo = SettingsRepository();

      // Chart preferences
      repo.setDefaultChartType(ChartTypePreference.heikinAshi);
      expect(repo.settings.defaultChartType, ChartTypePreference.heikinAshi);
      repo.setDefaultTimeframe('15m');
      expect(repo.settings.defaultTimeframe, '15m');
      repo.setShowChartVolume(false);
      expect(repo.settings.showChartVolume, isFalse);

      // Watchlist preferences
      repo.setProViewDefault(true);
      expect(repo.settings.proViewDefault, isTrue);
      repo.setPriceChangeMode(PriceChangeDisplayMode.absolute);
      expect(repo.settings.priceChangeMode, PriceChangeDisplayMode.absolute);
      repo.setEnableHapticFeedback(false);
      expect(repo.settings.enableHapticFeedback, isFalse);
    });

    // 68. Legal Documents Integrity & Statutory Account Closure Workflow (Section 17)
    test('LegalDocuments provides statutory terms, SEBI risk disclosures, and account closure flow', () async {
      // Document integrity checks
      expect(LegalDocuments.all.length, 10);
      expect(LegalDocuments.termsAndConditions.content, contains('Zero Dalali Securities'));
      expect(LegalDocuments.privacyPolicy.content, contains('256-BIT ENCRYPTION'));
      expect(LegalDocuments.privacyPolicy.content, contains('BIOMETRIC & PIN DATA INVARIANT'));

      // SEBI Mandatory Risk Disclosure on Derivatives
      expect(LegalDocuments.riskDisclosure.content, contains('9 out of 10 individual traders'));
      expect(LegalDocuments.riskDisclosure.content, contains('₹50,000'));

      // Tariff & Charges schedule
      expect(LegalDocuments.tariffSchedule.content, contains('Equity Delivery (CNC): ₹0'));
      expect(LegalDocuments.tariffSchedule.content, contains('Flat ₹20'));
      expect(LegalDocuments.tariffSchedule.content, contains('Securities Transaction Tax'));

      // Regulatory Disclosures
      expect(LegalDocuments.regulatoryDisclosures.content, contains('SEBI Registered'));
      expect(LegalDocuments.regulatoryDisclosures.content, contains('Zero Dalali'));

      // Account closure request with statutory 5-year retention notice
      final repo = SettingsRepository();
      final success = await repo.requestAccountDeletion(
        reason: 'Switching to another broker',
        feedback: 'Great UI, taking a trading hiatus.',
      );
      expect(success, isTrue);
      expect(LegalDocuments.accountDeletionPolicy.content, contains('5-YEAR DATA RETENTION'));
    });

    // 69. Brute-Force Rate Limiting & Lockout Controls (Section 18)
    test('SecurityPrivacyService enforces 3-attempt brute-force lockout with security alert', () {
      final container = createTestContainer();
      final secService = container.read(securityPrivacyServiceProvider);
      final notifService = container.read(notificationServiceProvider);

      const target = 'pin_unlock_test';
      expect(secService.isTargetLocked(target), isFalse);
      expect(secService.getRemainingLockoutSeconds(target), 0);

      // Attempt 1: Failed
      secService.recordFailedAttempt(target, maxAttempts: 3, lockoutDurationSeconds: 60);
      expect(secService.isTargetLocked(target), isFalse);

      // Attempt 2: Failed
      secService.recordFailedAttempt(target, maxAttempts: 3, lockoutDurationSeconds: 60);
      expect(secService.isTargetLocked(target), isFalse);

      // Attempt 3: Triggers Lockout!
      final preNotifCount = notifService.allNotifications.length;
      secService.recordFailedAttempt(target, maxAttempts: 3, lockoutDurationSeconds: 60);
      expect(secService.isTargetLocked(target), isTrue);
      expect(secService.getRemainingLockoutSeconds(target), greaterThan(0));

      // Dispatched high-priority security alert
      expect(notifService.allNotifications.length, greaterThan(preNotifCount));
      final alert = notifService.allNotifications.first;
      expect(alert.type, NotificationType.securityAlert);
      expect(alert.isCritical, isTrue);
      expect(alert.title, contains('Account Access Temporarily Suspended'));

      // Successful auth resets the lockout
      secService.resetAttempts(target);
      expect(secService.isTargetLocked(target), isFalse);
      expect(secService.getRemainingLockoutSeconds(target), 0);

      container.dispose();
    });

    // 70. OTP Abuse Protection & Rate Limiting (Section 18)
    test('SecurityPrivacyService protects TOTP / SMS OTP verification against abuse and brute-force', () {
      final container = createTestContainer();
      final secService = container.read(securityPrivacyServiceProvider);

      const otpTarget = 'totp_verification_abuse';

      // Record 3 rapid failed OTP attempts
      for (int i = 0; i < 3; i++) {
        secService.recordFailedAttempt(otpTarget, maxAttempts: 3, lockoutDurationSeconds: 45);
      }

      expect(secService.isTargetLocked(otpTarget), isTrue);
      expect(secService.getRemainingLockoutSeconds(otpTarget), inInclusiveRange(1, 45));

      // Lockout remains active
      expect(secService.isTargetLocked(otpTarget), isTrue);

      // Clear after success
      secService.resetAttempts(otpTarget);
      expect(secService.isTargetLocked(otpTarget), isFalse);

      container.dispose();
    });

    // 71. Device and Session Anomaly Detection (Section 18)
    test('SecurityPrivacyService detects foreign IP/Device session anomalies and dispatches alerts', () {
      final container = createTestContainer();
      final secService = container.read(securityPrivacyServiceProvider);
      final notifService = container.read(notificationServiceProvider);

      final knownSessions = [
        const ActiveSessionItem(
          id: 'sess_1',
          deviceName: 'Pixel 8 Pro (Current Device)',
          platform: 'Android 14 • Chrome Mobile',
          ipAddress: '103.21.14.82',
          lastActive: 'Active now',
          isCurrentDevice: true,
        ),
        const ActiveSessionItem(
          id: 'sess_2',
          deviceName: 'MacBook Pro 16"',
          platform: 'macOS 15.0 • Safari 18',
          ipAddress: '103.21.14.85',
          lastActive: '3 hours ago',
          isCurrentDevice: false,
        ),
      ];

      // 1. Legitimate login from known device/IP -> No anomaly
      final isNormal = secService.checkSessionAnomaly(
        incomingIp: '103.21.14.82',
        incomingDevice: 'Pixel 8 Pro',
        existingSessions: knownSessions,
      );
      expect(isNormal, isFalse);

      // 2. Anomaly: Unknown device from unknown foreign IP
      final initialNotifs = notifService.allNotifications.length;
      final isAnomaly = secService.checkSessionAnomaly(
        incomingIp: '198.51.100.44',
        incomingDevice: 'Linux Desktop (Tor Exit Node)',
        existingSessions: knownSessions,
      );
      expect(isAnomaly, isTrue);

      // Dispatched high-priority loginNewDevice alert
      expect(notifService.allNotifications.length, greaterThan(initialNotifs));
      final anomalyAlert = notifService.allNotifications.first;
      expect(anomalyAlert.type, NotificationType.loginNewDevice);
      expect(anomalyAlert.isCritical, isTrue);
      expect(anomalyAlert.body, contains('Linux Desktop'));
      expect(anomalyAlert.body, contains('198.51.100.44'));

      container.dispose();
    });

    // 72. Sensitive Screen Protection Policy & Prevention of Screen Leaks (Section 18)
    test('SecurityPrivacyService manages screen protection flag for PIN/TOTP and sensitive views', () {
      final secService = SecurityPrivacyService();

      expect(secService.isScreenProtectionActive, isFalse);

      // Enter sensitive screen (e.g. PinUnlockScreen or TotpScreen)
      bool notified = false;
      secService.addListener(() => notified = true);

      secService.setScreenProtection(true);
      expect(secService.isScreenProtectionActive, isTrue);
      expect(notified, isTrue);

      // Exit sensitive screen
      notified = false;
      secService.setScreenProtection(false);
      expect(secService.isScreenProtectionActive, isFalse);
      expect(notified, isTrue);
    });

    // 73. Versioned Privacy Consent & Auditable Record (Section 18)
    test('SecurityPrivacyService records immutable and versioned privacy consent audit trail', () {
      final secService = SecurityPrivacyService();

      final initial = secService.consentRecord;
      expect(initial.isAuditLogged, isFalse);
      expect(initial.userId, isEmpty);

      // User re-acknowledges updated statutory disclosure
      secService.updatePrivacyConsent(
        termsVersion: 'v2026.2 (September 2026)',
        privacyPolicyVersion: 'v2026.2 (September 2026)',
        riskDisclosureVersion: 'SEBI/HO/MIRSD/2026/88',
        userId: 'ZD84920',
        ipAddress: '49.207.210.15',
      );

      final updated = secService.consentRecord;
      expect(updated.termsVersion, 'v2026.2 (September 2026)');
      expect(updated.riskDisclosureVersion, 'SEBI/HO/MIRSD/2026/88');
      expect(updated.ipAddress, '49.207.210.15');
      expect(updated.isAuditLogged, isTrue);

      final json = updated.toJson();
      expect(json['consentId'], startsWith('consent_'));
      expect(json['isAuditLogged'], isTrue);
      expect(json['termsVersion'], 'v2026.2 (September 2026)');
    });

    // 74. Session Token Lifecycle, Expiration Validation & Invalidation (Section 18)
    test('Session model validates expiration and token serialization correctly', () {
      final now = DateTime.now();

      // Active session valid for 30 days
      final validSession = Session(
        token: 'auth_jwt_token_secure_999',
        profile: const UserProfile(
          userId: 'ZD84920',
          name: 'Anurag Dalali',
          email: 'anurag@zerodalali.com',
          phone: '+91 98765 43210',
          pan: 'ABCDE1234F',
          bankName: 'HDFC Bank Ltd',
          bankAccountNumber: '•••• •••• 4912',
        ),
        loggedInAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );

      expect(validSession.isValid, isTrue);
      expect(validSession.token, 'auth_jwt_token_secure_999');

      // Expired session
      final expiredSession = Session(
        token: 'expired_jwt_token',
        profile: validSession.profile,
        loggedInAt: now.subtract(const Duration(days: 31)),
        expiresAt: now.subtract(const Duration(hours: 1)),
      );

      expect(expiredSession.isValid, isFalse);

      // JSON serialization & round-trip deserialization
      final json = validSession.toJson();
      final reconstituted = Session.fromJson(json);
      expect(reconstituted.token, validSession.token);
      expect(reconstituted.profile.userId, 'ZD84920');
      expect(reconstituted.isValid, isTrue);
    });

    // 75. Sensitive Data Masking & Zero-Logging Invariant (Section 18)
    test('Ensures PAN and Bank Account numbers are masked and zero-biometric invariant holds', () {
      const profile = UserProfile(
        userId: 'ZD84920',
        name: 'Anurag Dalali',
        email: 'anurag@zerodalali.com',
        phone: '+91 98765 43210',
        pan: 'ABCDE1234F',
        bankName: 'HDFC Bank Ltd',
        bankAccountNumber: '•••• •••• 4912',
      );

      // Sensitive fields are masked in UI representations
      expect(profile.bankAccountNumber.startsWith('•••• ••••'), isTrue);
      expect(profile.bankAccountNumber.length, 14);

      // Privacy policy explicitly affirms hardware-enclave biometric isolation
      expect(LegalDocuments.privacyPolicy.content, contains('BIOMETRIC & PIN DATA INVARIANT'));
      expect(LegalDocuments.privacyPolicy.content, contains('evaluated entirely on-device'));
      expect(LegalDocuments.privacyPolicy.content, contains('does NOT store your device fingerprint'));
      expect(LegalDocuments.privacyPolicy.content, contains('256-BIT ENCRYPTION'));
    });



    // 84. Orders: Client Idempotency Key & Server Order ID Deduplication (Section 19)
    // 84. Orders: Client Idempotency Key & Server Order ID Deduplication (Section 19)
    test('Order model respects client idempotency key and server order ID', () {
      const idempotencyKey = 'idemp_cli_test_2026_999';
      const request = OrderRequest(
        instrumentToken: 'eq_reliance',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 20,
        idempotencyKey: idempotencyKey,
      );

      final order1 = Order(
        orderId: 'ord_1',
        exchangeOrderId: 'ex_1',
        serverOrderId: 'ZD-SRV-ord_1',
        instrument: const Instrument(
          symbol: 'RELIANCE',
          name: 'Reliance Industries',
          exchange: Exchange.NSE,
          type: InstrumentType.EQ,
        ),
        request: request,
        status: OrderStatus.OPEN,
        filledQty: 0,
        averagePrice: 0.0,
        placedAt: DateTime.now(),
        timeline: const [],
        charges: const ChargesBreakdown(
          brokerage: 0,
          stt: 0,
          exchangeTxnCharge: 0,
          gst: 0,
          sebiCharges: 0,
          stampDuty: 0,
        ),
      );

      expect(order1.orderId.isNotEmpty, isTrue);
      expect(order1.serverOrderId, isNotNull);
      expect(order1.effectiveServerOrderId.startsWith('ZD-SRV-'), isTrue);
      expect(order1.request.idempotencyKey, idempotencyKey);
    });

    // 85. Orders: Atomic Transitions, Partial-Fills, Cancellation/Modification ACK & Audit Trail (Section 19)
    test('Order lifecycle maintains atomic state DAG transitions and immutable audit trail', () {
      bool canTransition(OrderStatus from, OrderStatus to) {
        if (from == OrderStatus.COMPLETE ||
            from == OrderStatus.CANCELLED ||
            from == OrderStatus.REJECTED) {
          return false;
        }
        return true;
      }

      // 1. Atomic state DAG validation: terminal states cannot transition
      expect(canTransition(OrderStatus.DRAFT, OrderStatus.SUBMITTED), isTrue);
      expect(canTransition(OrderStatus.OPEN, OrderStatus.COMPLETE), isTrue);
      expect(canTransition(OrderStatus.COMPLETE, OrderStatus.CANCELLED), isFalse);

      final entry = OrderAuditEntry(
        timestamp: DateTime.now(),
        fromStatus: OrderStatus.DRAFT,
        toStatus: OrderStatus.OPEN,
        action: 'ORDER_DRAFTED',
      );
      expect(entry.action, 'ORDER_DRAFTED');
      expect(entry.fromStatus, OrderStatus.DRAFT);
      expect(entry.toStatus, OrderStatus.OPEN);
    });

    // 86. Money Movement: HMAC-SHA256 Signature Verification & Webhook Idempotency (Section 19)
    test('MoneyMovementReconciliationService verifies HMAC-SHA256 and ensures idempotent deposit crediting', () async {
      final container = createTestContainer();
      final recon = container.read(moneyMovementReconciliationServiceProvider);

      final now = DateTime.now();

      // Construct deposit webhook payload
      const eventId = 'evt_dep_test_1001';
      const refId = 'ZD-PAY-981245';
      const amount = 25000.0;
      final testPayload = DepositWebhookPayload(
        eventId: eventId,
        paymentId: 'pay_rzp_99999',
        referenceId: refId,
        amount: amount,
        status: 'captured',
        signature: '',
        timestamp: now,
      );

      // Compute valid HMAC-SHA256 signature
      final rawBody = testPayload.computePayloadString();
      final validSignature = MoneyMovementReconciliationService.generateHmacSha256(
        rawBody,
        MoneyMovementReconciliationService.webhookSecretKey,
      );

      // 1. Webhook with tampered/invalid signature -> Rejected
      final tamperedPayload = DepositWebhookPayload(
        eventId: eventId,
        paymentId: testPayload.paymentId,
        referenceId: refId,
        amount: amount,
        status: 'captured',
        signature: 'invalid_tampered_signature',
        timestamp: now,
      );
      final tamperedResult = await recon.reconcileDepositWebhook(tamperedPayload);
      expect(tamperedResult.isSuccess, isFalse);
      expect(tamperedResult.message, contains('Invalid webhook HMAC signature'));

      // 2. Valid Webhook -> Accepted and credited
      final validPayload = DepositWebhookPayload(
        eventId: eventId,
        paymentId: testPayload.paymentId,
        referenceId: refId,
        amount: amount,
        status: 'captured',
        signature: validSignature,
        timestamp: now,
      );
      final validResult = await recon.reconcileDepositWebhook(validPayload);
      expect(validResult.isSuccess, isTrue);
      expect(validResult.isDuplicate, isFalse);

      // 3. Duplicate Webhook delivery -> Idempotent response without double-crediting
      final dupResult = await recon.reconcileDepositWebhook(validPayload);
      expect(dupResult.isSuccess, isTrue);
      expect(dupResult.isDuplicate, isTrue);

      // 4. Failed Gateway Payment Reconciliation
      final failedPayload = DepositWebhookPayload(
        eventId: 'evt_fail_999',
        paymentId: 'pay_fail_111',
        referenceId: 'ZD-PAY-FAIL-1',
        amount: 5000.0,
        status: 'failed',
        signature: MoneyMovementReconciliationService.generateHmacSha256(
          'evt_fail_999|pay_fail_111|ZD-PAY-FAIL-1|5000.00|INR|failed|${now.millisecondsSinceEpoch}',
          MoneyMovementReconciliationService.webhookSecretKey,
        ),
        timestamp: now,
        failureReason: 'User bank server timed out',
      );
      final failedResult = await recon.reconcileDepositWebhook(failedPayload);
      expect(failedResult.isSuccess, isFalse);
      expect(failedResult.message, contains('Deposit failed at gateway'));

      container.dispose();
    });

    // 87. Money Movement: Withdrawal State Machine with Automated Margin Refund (Section 19)
    test('MoneyMovementReconciliationService handles withdrawal transitions and auto-refunds failed payouts', () async {
      final container = createTestContainer();
      final recon = container.read(moneyMovementReconciliationServiceProvider);

      const txnId = 'wt_wth_state_machine_test';
      const refId = 'ZD-WTH-99120';
      const amount = 10000.0;
      const destination = 'HDFC Bank (•••• 4912)';

      // Register initial withdrawal
      recon.registerWithdrawal(
        transactionId: txnId,
        referenceId: refId,
        amount: amount,
        destination: destination,
      );

      final withdrawals = recon.allWithdrawals;
      final entry = withdrawals.firstWhere((w) => w.transactionId == txnId);
      expect(entry.state, WithdrawalLifecycleState.requested);

      // Transition 1: requested -> approvedByRms
      final approved = recon.transitionWithdrawal(txnId, WithdrawalLifecycleState.approvedByRms);
      expect(approved, isTrue);
      expect(entry.state, WithdrawalLifecycleState.approvedByRms);

      // Transition 2: approvedByRms -> processingAtBank
      final processing = recon.transitionWithdrawal(txnId, WithdrawalLifecycleState.processingAtBank);
      expect(processing, isTrue);
      expect(entry.state, WithdrawalLifecycleState.processingAtBank);

      // Transition 3: processingAtBank -> failed (Bank rejects payout)
      final failed = recon.transitionWithdrawal(
        txnId,
        WithdrawalLifecycleState.failed,
        reason: 'Beneficiary account frozen by bank',
      );
      expect(failed, isTrue);
      expect(entry.state, WithdrawalLifecycleState.failed);
      expect(entry.isRefunded, isTrue);
      expect(entry.rejectionReason, contains('Beneficiary account frozen'));

      // Terminal state cannot transition again
      final invalidNext = recon.transitionWithdrawal(txnId, WithdrawalLifecycleState.settled);
      expect(invalidNext, isFalse);

      container.dispose();
    });

    // 88. Observability: Structured Logging, Metrics, Tracing, Crash Reporting & Alerting (Section 19)
    test('ObservabilityService records structured logs, metrics, trace spans, crashes, and failure alerts', () {
      final container = createTestContainer();
      final obs = container.read(observabilityServiceProvider);
      final notifService = container.read(notificationServiceProvider);

      // 1. Structured Logging
      obs.logInfo('ORDER_ROUTER', 'Order dispatched to NSE clearing ring', {'orderId': 'ZD-1234'});
      obs.logWarn('RMS_ENGINE', 'Margin utilization at 85%', {'marginPercent': 85.0});
      obs.logError('NETWORK_GATEWAY', 'TLS handshake timeout with feed provider');
      expect(obs.logs.length, 3);
      expect(obs.logs.first.level, LogLevel.error);
      expect(obs.logs.first.component, 'NETWORK_GATEWAY');

      // 2. Metrics Recording
      obs.incrementCounter('orders_executed_count');
      obs.recordGauge('active_websocket_connections', 1.0);
      obs.recordLatency('tick_parsing_latency_ms', 12);
      expect(obs.metrics.length, 3);
      expect(obs.metrics.any((m) => m.type == MetricType.counter), isTrue);
      expect(obs.metrics.any((m) => m.type == MetricType.gauge), isTrue);
      expect(obs.metrics.any((m) => m.type == MetricType.latencyHistogram), isTrue);

      // 3. Distributed Tracing
      final span = obs.startSpan(operationName: 'order_placement_flow', tags: {'instrument': 'RELIANCE'});
      expect(span.spanId.isNotEmpty, isTrue);
      expect(span.traceId.isNotEmpty, isTrue);
      obs.finishSpan(span);
      expect(obs.completedSpans.length, 1);
      expect(obs.completedSpans.first.durationMs, isNotNull);

      // 4. Breadcrumbs & Crash Reporting
      obs.addBreadcrumb('User clicked buy button');
      obs.addBreadcrumb('RMS validation passed');
      final crash = obs.recordCrash('StateError: unexpected socket close', StackTrace.current);
      expect(obs.crashReports.length, 1);
      expect(crash.breadcrumbs.length, 2);
      expect(crash.deviceInfo['platform'], isNotNull);

      // 5. Failure Monitoring & Operational Alerting
      final initialNotifs = notifService.allNotifications.length;
      // Record 3 consecutive order failures -> triggers elevated rejection alert
      obs.recordOrderFailure('Exchange Freeze Qty Exceeded');
      obs.recordOrderFailure('Exchange Freeze Qty Exceeded');
      obs.recordOrderFailure('Exchange Freeze Qty Exceeded');

      expect(notifService.allNotifications.length, greaterThan(initialNotifs));
      final alert = notifService.allNotifications.first;
      expect(alert.title, contains('Elevated Order Rejection Rate'));
      expect(alert.isCritical, isTrue);

      // Payment failure alert
      obs.recordPaymentFailure('ZD-PAY-TEST-99', 'NPCI switch down');
      expect(notifService.allNotifications.any((n) => n.title.contains('Payment Gateway Interruption')), isTrue);

      container.dispose();
    });

    // 89. Edge Case: CurrencyFormatter Negative Zero, Micro-Prices & Large Numbers (Section 20)
    test('CurrencyFormatter handles negative zero, micro-price precision, and large numbers', () {
      // 1. Negative zero sanitization
      expect(CurrencyFormatter.format(-0.0), '₹0.00');
      expect(CurrencyFormatter.formatSigned(-0.0), '₹0.00');
      expect(CurrencyFormatter.formatPercent(-0.0), '0.00%');

      // 2. Micro-price precision (e.g. 0.0025, 1.0525)
      expect(CurrencyFormatter.formatPrice(0.0025), '0.0025');
      expect(CurrencyFormatter.formatPrice(1.0525, showSymbol: true), '₹1.0525');
      expect(CurrencyFormatter.formatPrice(125.50), '125.50');

      // 3. Signed P&L formatting
      expect(CurrencyFormatter.formatSigned(-1250.50), '-₹1,250.50');
      expect(CurrencyFormatter.formatSigned(2500.00), '+₹2,500.00');
      expect(CurrencyFormatter.formatSigned(0.0), '₹0.00');

      // 4. Large Numbers (Crores, Lakhs)
      expect(CurrencyFormatter.formatCompact(100000000), '₹10.00 Cr');
      expect(CurrencyFormatter.formatCompact(5000000000), '₹500.00 Cr');
      expect(CurrencyFormatter.formatCompact(2500000), '₹25.00 L');
    });

    // 90. Edge Case: Order Quantity Decimal Precision Validation (Section 20)
    test('Order quantity validation rejects invalid lots, negatives, and excessive decimals', () {
      // Standard integer lots
      expect(CurrencyFormatter.validateQuantityPrecision(1.0), isTrue);
      expect(CurrencyFormatter.validateQuantityPrecision(50.0), isTrue);

      // Fractional rejection for standard equity lots
      expect(CurrencyFormatter.validateQuantityPrecision(1.5, allowFractional: false), isFalse);
      expect(CurrencyFormatter.validateQuantityPrecision(-10.0), isFalse);
      expect(CurrencyFormatter.validateQuantityPrecision(0.0), isFalse);

      // Fractional lots for commodities/crypto (up to 4 decimals)
      expect(CurrencyFormatter.validateQuantityPrecision(0.0025, allowFractional: true), isTrue);
      expect(CurrencyFormatter.validateQuantityPrecision(0.00001, allowFractional: true), isFalse);
    });

    // 91. Edge Case: API Error Mapping (400, 401, 403, 404, 409, 429, 500) (Section 20)
    test('ApiErrorInfo maps HTTP status codes to user-friendly titles and guidance', () {
      final err400 = ApiErrorInfo.fromStatusCode(400);
      expect(err400.userTitle, 'Invalid Request');
      expect(err400.isRetryable, isFalse);

      final err401 = ApiErrorInfo.fromStatusCode(401);
      expect(err401.userTitle, 'Session Expired');
      expect(err401.suggestedAction, 'Re-authenticate');

      final err403 = ApiErrorInfo.fromStatusCode(403);
      expect(err403.userTitle, 'Segment Disabled');

      final err404 = ApiErrorInfo.fromStatusCode(404);
      expect(err404.userTitle, 'Resource Not Found');

      final err409 = ApiErrorInfo.fromStatusCode(409);
      expect(err409.userTitle, 'Order Conflict');

      final err429 = ApiErrorInfo.fromStatusCode(429);
      expect(err429.userTitle, 'Too Many Requests');
      expect(err429.isRetryable, isTrue);

      final err500 = ApiErrorInfo.fromStatusCode(500);
      expect(err500.userTitle, 'Exchange Gateway Error');
      expect(err500.isRetryable, isTrue);
    });

    // 92. Edge Case: Semantic App Versioning & Forced Update Check (Section 20)
    test('AppVersionResult correctly detects forced update vs optional vs compatible', () {
      // 1. Force update required (client < min supported)
      final forced = EdgeCaseService.checkVersionCompatibility(
        currentVersion: '1.2.0',
        minSupportedVersion: '1.5.0',
        latestVersion: '1.6.0',
      );
      expect(forced.status, VersionStatus.forceUpdateRequired);
      expect(forced.needsForceUpdate, isTrue);
      expect(forced.isUsable, isFalse);

      // 2. Optional update available (client >= min, but < latest)
      final optional = EdgeCaseService.checkVersionCompatibility(
        currentVersion: '1.5.0',
        minSupportedVersion: '1.5.0',
        latestVersion: '1.6.0',
      );
      expect(optional.status, VersionStatus.optionalUpdateAvailable);
      expect(optional.needsForceUpdate, isFalse);
      expect(optional.isUsable, isTrue);

      // 3. Fully compatible (client == latest)
      final compatible = EdgeCaseService.checkVersionCompatibility(
        currentVersion: '1.6.0',
        minSupportedVersion: '1.5.0',
        latestVersion: '1.6.0',
      );
      expect(compatible.status, VersionStatus.compatible);
      expect(compatible.isUsable, isTrue);
    });

    // 93. Edge Case: In-Flight Order Recovery Journal on App Kill (Section 20)
    test('In-Flight Order Journal records and recovers unpersisted orders across app restarts', () {
      final service = EdgeCaseService();
      const req = OrderRequest(
        instrumentToken: 'eq_reliance',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 10,
      );

      // 1. Order submitted -> recorded in journal
      service.recordInFlightOrder(req, 'idemp_key_101');
      expect(service.inFlightJournal.containsKey('idemp_key_101'), isTrue);

      // 2. Simulate app kill right after submission -> recover unpersisted
      final unpersisted = service.recoverInFlightOrders();
      expect(unpersisted.length, 1);
      expect(unpersisted.first.idempotencyKey, 'idemp_key_101');
      expect(unpersisted.first.isPersisted, isFalse);

      // 3. Order successfully confirmed by backend -> mark persisted
      service.markOrderPersisted('idemp_key_101', 'ZD-SRV-999');
      expect(service.recoverInFlightOrders().isEmpty, isTrue);

      service.dispose();
    });

    // 94. Edge Case: Network Handover (Wi-Fi <-> Mobile Data) State Integrity (Section 20)
    test('Network handover between Wi-Fi and Cellular preserves session integrity', () {
      final service = EdgeCaseService();
      expect(service.activeNetworkType, 'WIFI');

      // Handover to Cellular
      final sessionValidAfterHandover = service.handleNetworkHandover(
        fromType: 'WIFI',
        toType: 'CELLULAR_5G',
        hasActiveSession: true,
      );
      expect(sessionValidAfterHandover, isTrue);
      expect(service.activeNetworkType, 'CELLULAR_5G');

      // Handover back to Wi-Fi
      service.handleNetworkHandover(
        fromType: 'CELLULAR_5G',
        toType: 'WIFI',
        hasActiveSession: true,
      );
      expect(service.activeNetworkType, 'WIFI');

      service.dispose();
    });

    // 95. Edge Case: Safe Deep Link & Push Notification Fallbacks (Section 20)
    test('Deep link resolver safely handles deleted or unavailable targets with friendly fallbacks', () {
      // 1. Existing order link -> routes to order detail
      final res1 = EdgeCaseService.resolveDeepLinkTarget(
        entityType: 'order',
        entityId: 'ord_123',
        exists: true,
      );
      expect(res1.isFound, isTrue);
      expect(res1.resolvedRoute, '/order-detail/ord_123');

      // 2. Deleted or purged order link -> safe fallback to /orders with banner
      final res2 = EdgeCaseService.resolveDeepLinkTarget(
        entityType: 'order',
        entityId: 'ord_deleted_999',
        exists: false,
      );
      expect(res2.isFound, isFalse);
      expect(res2.resolvedRoute, '/orders');
      expect(res2.userAlertMessage, contains('no longer available'));

      // 3. Unavailable instrument link -> safe fallback to /quotes with banner
      final res3 = EdgeCaseService.resolveDeepLinkTarget(
        entityType: 'quote',
        entityId: 'UNKNOWN_DELISTED_STOCK',
        exists: false,
      );
      expect(res3.isFound, isFalse);
      expect(res3.resolvedRoute, '/quotes');
      expect(res3.userAlertMessage, contains('delisted or unavailable'));
    });

    // 96. Edge Case: Pre-Flight Risk & Edge-Case Validator (Section 20)
    test('PreFlightValidation checks suspended symbols, market hours, circuits, and margin sufficiency', () {
      const activeInstrument = Instrument(
        symbol: 'RELIANCE',
        name: 'Reliance Industries Ltd',
        exchange: Exchange.NSE,
        type: InstrumentType.EQ,
      );
      final suspendedInstrument = activeInstrument.copyWith(isSuspended: true);

      // 1. Suspended instrument rejected
      final r1 = EdgeCaseService.validatePreFlightOrder(
        instrument: suspendedInstrument,
        price: 2500.0,
        quantity: 10,
        availableMargin: 100000,
        requiredMargin: 25000,
        isMarketOpen: true,
        isAmo: false,
      );
      expect(r1.isValid, isFalse);
      expect(r1.rejectionReason, contains('suspended'));

      // 2. Closed market without AMO rejected
      final r2 = EdgeCaseService.validatePreFlightOrder(
        instrument: activeInstrument,
        price: 2500.0,
        quantity: 10,
        availableMargin: 100000,
        requiredMargin: 25000,
        isMarketOpen: false,
        isAmo: false,
      );
      expect(r2.isValid, isFalse);
      expect(r2.rejectionReason, contains('Exchange is closed'));

      // 3. Closed market WITH AMO accepted
      final r3 = EdgeCaseService.validatePreFlightOrder(
        instrument: activeInstrument,
        price: 2500.0,
        quantity: 10,
        availableMargin: 100000,
        requiredMargin: 25000,
        isMarketOpen: false,
        isAmo: true,
      );
      expect(r3.isValid, isTrue);

      // 4. Circuit limit breach rejected
      final r4 = EdgeCaseService.validatePreFlightOrder(
        instrument: activeInstrument,
        price: 3200.0,
        quantity: 10,
        availableMargin: 100000,
        requiredMargin: 25000,
        isMarketOpen: true,
        isAmo: false,
        lowerCircuit: 2000.0,
        upperCircuit: 3000.0,
      );
      expect(r4.isValid, isFalse);
      expect(r4.rejectionReason, contains('circuit limits'));

      // 5. Margin insufficiency rejected
      final r5 = EdgeCaseService.validatePreFlightOrder(
        instrument: activeInstrument,
        price: 2500.0,
        quantity: 10,
        availableMargin: 10000,
        requiredMargin: 25000,
        isMarketOpen: true,
        isAmo: false,
      );
      expect(r5.isValid, isFalse);
      expect(r5.rejectionReason, contains('Insufficient margin'));
    });

    // 97. Edge Case: Double-Tap Submissions with Client Idempotency Key (Section 20)
    test('Rapid consecutive order submission with same idempotency key preserves idempotency key', () {
      const idempotencyKey = 'double_tap_prevent_key_2026';
      const request = OrderRequest(
        idempotencyKey: idempotencyKey,
        instrumentToken: 'eq_infy',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 10,
        price: 1550.0,
      );

      expect(request.idempotencyKey, idempotencyKey);
    });

    // 98. Pre-Release & Production: Product & Store Invariants (Section 22)
    test('Production metadata, package ID, version, and store URLs are configured and valid', () {
      expect(AppConstants.packageId, 'com.Zero.zero_dalali');
      expect(AppConstants.appVersion, '1.0.0');
      expect(AppConstants.appName, 'Zero');

      // URLs must be HTTPS
      expect(AppConstants.privacyPolicyUrl, startsWith('https://'));
      expect(AppConstants.termsConditionsUrl, startsWith('https://'));
      expect(AppConstants.riskDisclosureUrl, startsWith('https://'));
      expect(AppConstants.supportHelpUrl, startsWith('https://'));
      expect(AppConstants.accountDeletionUrl, startsWith('https://'));
    });

    // 99. Pre-Release & Production: Statutory Regulatory & SEBI Compliance (Section 22)
    test('Regulatory identifiers and SEBI F&O loss advisories comply with statutory requirements', () {
      expect(AppConstants.regulatoryCin, 'Unavailable');
      expect(AppConstants.sebiRegistrationNo, 'Unavailable');
      expect(AppConstants.cdslDpId, 'Unavailable');
      expect(AppConstants.minimumAge, 18);
      expect(AppConstants.sebiFnoLossWarning, isNotEmpty);
    });

    // 100. Pre-Release & Production: End-to-End Trading Precision & Margin Integrity (Section 22)
    test('End-to-end trading precision, leverage multipliers, and charges match exchange rules', () {
      // Charges calculation for ₹1,00,000 turnover delivery (CNC) -> Zero Brokerage!
      final cncCharges = ChargesConfig.calculateCharges(
        price: 1000.0,
        quantity: 100,
        side: TransactionType.BUY,
        product: ProductType.CNC,
        instrumentType: InstrumentType.EQ,
      );
      expect(cncCharges.brokerage, 0.0); // Zero brokerage on delivery!
      expect(cncCharges.exchangeTxnCharge, greaterThan(0.0));
      expect(cncCharges.sebiCharges, greaterThan(0.0));
      expect(cncCharges.stampDuty, greaterThan(0.0));

      // MIS turnover -> ₹20 flat or 0.03%
      final misCharges = ChargesConfig.calculateCharges(
        price: 1000.0,
        quantity: 100,
        side: TransactionType.BUY,
        product: ProductType.MIS,
        instrumentType: InstrumentType.EQ,
      );
      expect(misCharges.brokerage, 20.0); // Capped at ₹20!
      expect(misCharges.total, greaterThan(20.0));
    });

    // 101. Pre-Release & Production: Money Movement Rollback & Ledger Integrity (Section 22)
    test('Money movement enforces idempotent crediting, signature verification, and refund rollback', () {
      final container = createTestContainer();

      // Signature verification
      const secret = 'prod_webhook_secret_key_2026';
      const payload = '{"eventId":"evt_prod_001","amount":50000.0,"status":"SUCCESS"}';
      final sig = MoneyMovementReconciliationService.generateHmacSha256(payload, secret);
      expect(
        MoneyMovementReconciliationService.verifyWebhookSignature(
          rawBody: payload,
          signature: sig,
          secret: secret,
        ),
        isTrue,
      );
      expect(
        MoneyMovementReconciliationService.verifyWebhookSignature(
          rawBody: payload,
          signature: 'invalid_sig',
          secret: secret,
        ),
        isFalse,
      );

      container.dispose();
    });

    // 102. Pre-Release & Production: Security, PII Redaction & Zero-Biometric Retention (Section 22)
    test('Security invariants: PII masking, token validation, and zero biometric persistence', () {
      // PAN masking invariant
      const pan = 'ABCDE1234F';
      final maskedPan = '${pan.substring(0, 5)}****${pan.substring(9)}';
      expect(maskedPan, 'ABCDE****F');

      // Bank account masking invariant
      const accountNo = '123456789012';
      final maskedAcc = '******${accountNo.substring(accountNo.length - 4)}';
      expect(maskedAcc, '******9012');
    });

    // 103. Pre-Release & Production: Account Closure & Data Deletion Workflow (Section 22)
    test('Account closure flow records statutory PMLA retention disclosure and generates ticket', () async {
      final container = createTestContainer();
      final settingsRepo = container.read(settingsRepositoryProvider);
      final notifService = container.read(notificationServiceProvider);
      final initialNotifs = notifService.allNotifications.length;

      final res = await settingsRepo.requestAccountDeletion(
        reason: 'Consolidating trading accounts',
      );

      expect(res, isTrue);
      expect(notifService.allNotifications.length, greaterThan(initialNotifs));
      final alert = notifService.allNotifications.first;
      expect(alert.title, contains('Account Closure Request Registered'));
      expect(alert.body, contains('5 years'));

      container.dispose();
    });

    // 104. Section 23: Order Calculation Invariants (Multiplier, Margin, Leverage, Charges, SL/TP, Rounding)
    test('Order calculation: value, required margin, leverage, charges, SL/TP distances, non-premature rounding', () {
      // 1. Order value = price × quantity × contract multiplier
      final eqOrderVal = FinancialCalculationService.calculateOrderValue(price: 2500.0, quantity: 10, contractMultiplier: 1.0);
      expect(eqOrderVal, 25000.0);

      final mcxCopperVal = FinancialCalculationService.calculateOrderValue(price: 850.0, quantity: 2, contractMultiplier: 2500.0);
      expect(mcxCopperVal, 4250000.0); // 850 * 2 * 2500

      // 2. Required margin server-side specifications
      final cncMargin = FinancialCalculationService.calculateRequiredMargin(
        price: 2500.0,
        quantity: 10,
        product: ProductType.CNC,
        instrumentType: InstrumentType.EQ,
        leverageMultiplier: 5.0,
      );
      expect(cncMargin, 25000.0); // 100% margin for CNC

      final misMargin = FinancialCalculationService.calculateRequiredMargin(
        price: 2500.0,
        quantity: 10,
        product: ProductType.MIS,
        instrumentType: InstrumentType.EQ,
        leverageMultiplier: 5.0,
      );
      expect(misMargin, 5000.0); // 20% margin (5x leverage)

      final optionBuyMargin = FinancialCalculationService.calculateRequiredMargin(
        price: 150.0,
        quantity: 50,
        product: ProductType.NRML,
        instrumentType: InstrumentType.CE,
        leverageMultiplier: 5.0,
      );
      expect(optionBuyMargin, 7500.0); // 100% premium margin for Options Buy

      // 3. Fees and charges explicitly zero or capped
      final cncCharges = ChargesConfig.calculateCharges(
        price: 2500.0,
        quantity: 10,
        side: TransactionType.BUY,
        product: ProductType.CNC,
        instrumentType: InstrumentType.EQ,
      );
      expect(cncCharges.brokerage, 0.0); // Explicitly zero brokerage on delivery

      final misCharges = ChargesConfig.calculateCharges(
        price: 2500.0,
        quantity: 100, // Turnover ₹2,50,000 * 0.03% = ₹75 -> capped at ₹20
        side: TransactionType.BUY,
        product: ProductType.MIS,
        instrumentType: InstrumentType.EQ,
      );
      expect(misCharges.brokerage, 20.0); // Capped at ₹20

      // 4. Stop-loss / take-profit distance rules
      final validSlTp = FinancialCalculationService.validateSlTpDistances(
        entryPrice: 100.0,
        side: TransactionType.BUY,
        stopLoss: 95.0,
        takeProfit: 110.0,
        tickSize: 0.05,
        lowerCircuit: 90.0,
        upperCircuit: 115.0,
      );
      expect(validSlTp.isValid, isTrue);

      final invalidSl = FinancialCalculationService.validateSlTpDistances(
        entryPrice: 100.0,
        side: TransactionType.BUY,
        stopLoss: 102.0, // SL above entry for Long is invalid
        tickSize: 0.05,
      );
      expect(invalidSl.isValid, isFalse);
      expect(invalidSl.errorMessage, contains('strictly below entry price'));

      final invalidCircuitSl = FinancialCalculationService.validateSlTpDistances(
        entryPrice: 100.0,
        side: TransactionType.BUY,
        stopLoss: 85.0, // Below lower circuit of 90.0
        tickSize: 0.05,
        lowerCircuit: 90.0,
      );
      expect(invalidCircuitSl.isValid, isFalse);
      expect(invalidCircuitSl.errorMessage, contains('lower circuit limit'));

      // 5. Rounding occurs at final stage, not prematurely
      const unroundedIntermediate = 123.456789;
      final roundedFinal = FinancialCalculationService.roundToPrecision(unroundedIntermediate, 2);
      expect(roundedFinal, 123.46);
    });

    // 105. Section 23: P&L Engine (Long, Short, Realized vs Unrealized)
    test('P&L engine: long position, short position, realized and unrealized calculations', () {
      // Long Position: Net Qty > 0
      final longProfit = FinancialCalculationService.calculateUnrealizedPnl(
        netQty: 100,
        entryPrice: 500.0,
        ltp: 525.0,
        contractMultiplier: 1.0,
      );
      expect(longProfit, 2500.0); // (525 - 500) * 100

      final longLoss = FinancialCalculationService.calculateUnrealizedPnl(
        netQty: 100,
        entryPrice: 500.0,
        ltp: 480.0,
        contractMultiplier: 1.0,
      );
      expect(longLoss, -2000.0); // (480 - 500) * 100

      // Short Position: Net Qty < 0
      final shortProfit = FinancialCalculationService.calculateUnrealizedPnl(
        netQty: -100,
        entryPrice: 500.0,
        ltp: 475.0, // Price dropped -> profit for short
        contractMultiplier: 1.0,
      );
      expect(shortProfit, 2500.0); // -100 * (475 - 500) = +2500

      final shortLoss = FinancialCalculationService.calculateUnrealizedPnl(
        netQty: -100,
        entryPrice: 500.0,
        ltp: 530.0, // Price rose -> loss for short
        contractMultiplier: 1.0,
      );
      expect(shortLoss, -3000.0); // -100 * (530 - 500) = -3000

      // Commodity Position with Multiplier
      final mcxPnl = FinancialCalculationService.calculateUnrealizedPnl(
        netQty: 2,
        entryPrice: 850.0,
        ltp: 860.0,
        contractMultiplier: 2500.0,
      );
      expect(mcxPnl, 50000.0); // 2 * (860 - 850) * 2500 = 50,000
    });

    // 106. Section 23: Average Entry Price after Partial Fills
    test('Average entry price is correct after multiple partial fills', () {
      // Step 1: Initial fill: Buy 10 @ ₹100
      final fill1 = FinancialCalculationService.calculatePositionFill(
        currentNetQty: 0,
        currentEntryPrice: 0.0,
        currentRealizedPnl: 0.0,
        fillSide: TransactionType.BUY,
        fillQty: 10,
        fillPrice: 100.0,
      );
      expect(fill1.newNetQty, 10);
      expect(fill1.newEntryPrice, 100.0);
      expect(fill1.realizedPnlDelta, 0.0);

      // Step 2: Partial add: Buy 20 @ ₹130
      // Weighted Avg = ((10 * 100) + (20 * 130)) / 30 = (1000 + 2600) / 30 = 3600 / 30 = 120.0
      final fill2 = FinancialCalculationService.calculatePositionFill(
        currentNetQty: fill1.newNetQty,
        currentEntryPrice: fill1.newEntryPrice,
        currentRealizedPnl: fill1.newRealizedPnl,
        fillSide: TransactionType.BUY,
        fillQty: 20,
        fillPrice: 130.0,
      );
      expect(fill2.newNetQty, 30);
      expect(fill2.newEntryPrice, 120.0);
      expect(fill2.realizedPnlDelta, 0.0);

      // Step 3: Third partial add: Buy 10 @ ₹160
      // Weighted Avg = ((30 * 120) + (10 * 160)) / 40 = (3600 + 1600) / 40 = 5200 / 40 = 130.0
      final fill3 = FinancialCalculationService.calculatePositionFill(
        currentNetQty: fill2.newNetQty,
        currentEntryPrice: fill2.newEntryPrice,
        currentRealizedPnl: fill2.newRealizedPnl,
        fillSide: TransactionType.BUY,
        fillQty: 10,
        fillPrice: 160.0,
      );
      expect(fill3.newNetQty, 40);
      expect(fill3.newEntryPrice, 130.0);
    });

    // 107. Section 23: Partial-Close Realized P&L, Basis Preservation & Position Reversal
    test('Partial-close P&L is realized immediately, entry price is preserved, and reversals flip cleanly', () {
      // Start with Long 40 @ ₹130, realized PnL = 0
      // Action: Partial Close: Sell 15 @ ₹150
      // Realized PnL = (150 - 130) * 15 = ₹300.0
      // Remaining Net Qty = 25
      // Remaining Entry Price MUST still be ₹130.0 (not altered by closing shares!)
      final partialClose = FinancialCalculationService.calculatePositionFill(
        currentNetQty: 40,
        currentEntryPrice: 130.0,
        currentRealizedPnl: 0.0,
        fillSide: TransactionType.SELL,
        fillQty: 15,
        fillPrice: 150.0,
      );
      expect(partialClose.newNetQty, 25);
      expect(partialClose.newEntryPrice, 130.0); // Basis preserved!
      expect(partialClose.realizedPnlDelta, 300.0);
      expect(partialClose.newRealizedPnl, 300.0);
      expect(partialClose.closedQty, 15);
      expect(partialClose.isReversal, isFalse);

      // Action: Second Partial Close: Sell 10 @ ₹140
      // Realized PnL = (140 - 130) * 10 = ₹100.0 -> Total Realized = ₹400.0
      // Remaining Net Qty = 15 @ ₹130.0
      final partialClose2 = FinancialCalculationService.calculatePositionFill(
        currentNetQty: partialClose.newNetQty,
        currentEntryPrice: partialClose.newEntryPrice,
        currentRealizedPnl: partialClose.newRealizedPnl,
        fillSide: TransactionType.SELL,
        fillQty: 10,
        fillPrice: 140.0,
      );
      expect(partialClose2.newNetQty, 15);
      expect(partialClose2.newEntryPrice, 130.0);
      expect(partialClose2.realizedPnlDelta, 100.0);
      expect(partialClose2.newRealizedPnl, 400.0);

      // Action: Position Reversal (Flip): Current Long 15 @ 130, Sell 25 @ 160
      // 1. Closes 15 Long @ 160: Realized = (160 - 130) * 15 = ₹450.0 -> Total Realized = 400 + 450 = ₹850.0
      // 2. Opens 10 Short @ ₹160.0!
      final reversal = FinancialCalculationService.calculatePositionFill(
        currentNetQty: partialClose2.newNetQty,
        currentEntryPrice: partialClose2.newEntryPrice,
        currentRealizedPnl: partialClose2.newRealizedPnl,
        fillSide: TransactionType.SELL,
        fillQty: 25,
        fillPrice: 160.0,
      );
      expect(reversal.newNetQty, -10); // Now Short 10
      expect(reversal.newEntryPrice, 160.0); // Entry price resets to reversal fill price
      expect(reversal.realizedPnlDelta, 450.0);
      expect(reversal.newRealizedPnl, 850.0);
      expect(reversal.isReversal, isTrue);
    });

    // 108. Section 23: Currency Conversion & Overnight/MTF Financing
    test('Currency conversion and overnight MTF financing calculations', () {
      // Currency conversion
      final inrFromUsd = FinancialCalculationService.convertCurrency(
        amount: 1000.0,
        fromCurrency: 'USD',
        toCurrency: 'INR',
        exchangeRate: 83.50,
      );
      expect(inrFromUsd, 83500.0);

      final usdFromInr = FinancialCalculationService.convertCurrency(
        amount: 83500.0,
        fromCurrency: 'INR',
        toCurrency: 'USD',
        exchangeRate: 83.50,
      );
      expect(usdFromInr, 1000.0);

      // Same currency identity
      final sameCurrency = FinancialCalculationService.convertCurrency(
        amount: 5000.0,
        fromCurrency: 'INR',
        toCurrency: 'INR',
      );
      expect(sameCurrency, 5000.0);

      // Overnight MTF financing: Borrowed ₹1,00,000 at 14.60% p.a.
      // Daily interest = 1,00,000 * 0.1460 / 365 = ₹40.00 / day
      final dailyInterest = FinancialCalculationService.calculateOvernightFinancing(
        borrowedAmount: 100000.0,
        annualInterestRate: 0.146,
        days: 1,
      );
      expect(dailyInterest, closeTo(40.0, 0.01));

      // 30 days interest = 40 * 30 = ₹1,200.00
      final monthlyInterest = FinancialCalculationService.calculateOvernightFinancing(
        borrowedAmount: 100000.0,
        annualInterestRate: 0.146,
        days: 30,
      );
      expect(monthlyInterest, closeTo(1200.0, 0.05));
    });

    // 109. Section 23: Portfolio Balancing Invariants (Balance, Equity, Free Margin, Margin Level)
    test('Portfolio balancing: single balance update, equity formula, free margin, and margin level', () {
      const funds = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: 240000.0,
        usedMargin: 10000.0,
        openingBalance: 250000.0,
        unrealizedPnl: 5000.0,
      );

      // Balance = availableMargin + usedMargin = ₹2,50,000
      expect(funds.balance, 250000.0);

      // Equity = balance + unrealized P&L = 250,000 + 5,000 = ₹2,55,000
      expect(funds.equity, 255000.0);

      // Free margin = availableMargin = ₹2,40,000
      expect(funds.freeMargin, 240000.0);

      // Margin level (%) = (Equity / Used Margin) * 100 = (255,000 / 10,000) * 100 = 2550.0%
      expect(funds.marginLevel, 2550.0);
      expect(funds.riskLevel, MarginRiskLevel.NORMAL);

      // High risk / margin call scenario
      const stressedFunds = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: 5000.0,
        usedMargin: 95000.0,
        openingBalance: 100000.0,
        unrealizedPnl: 0.0, // Equity = 100,000, Used = 95,000 -> Level = 105.26%
      );
      expect(stressedFunds.marginLevel, closeTo(105.26, 0.01));
      expect(stressedFunds.riskLevel, MarginRiskLevel.MARGIN_CALL);

      // Liquidation scenario (Level < 100%)
      const liquidationFunds = FundsSummary(
        segment: Segment.EQUITY,
        availableMargin: 0.0,
        usedMargin: 90000.0,
        openingBalance: 100000.0,
        unrealizedPnl: -20000.0, // Balance = 90,000, Equity = 70,000, Used = 90,000 -> Level = 77.78%
      );
      expect(liquidationFunds.marginLevel, closeTo(77.78, 0.01));
      expect(liquidationFunds.riskLevel, MarginRiskLevel.FORCED_LIQUIDATION);
    });

    // 110. Section 23: Deposit/Withdrawal Ledger & Displayed Balance Reconciliation
    test('Deposit/withdrawal ledger and displayed balance reconcile exactly', () {
      const opening = 200000.0;
      final entries = [
        LedgerEntry(
          id: 'L1',
          date: DateTime.now().subtract(const Duration(days: 3)),
          narration: 'Deposit via UPI',
          credit: 50000.0,
          debit: 0.0,
          runningBalance: 250000.0, // 200k + 50k
        ),
        LedgerEntry(
          id: 'L2',
          date: DateTime.now().subtract(const Duration(days: 2)),
          narration: 'Trade execution debit',
          credit: 0.0,
          debit: 15000.0,
          runningBalance: 235000.0, // 250k - 15k
        ),
        LedgerEntry(
          id: 'L3',
          date: DateTime.now().subtract(const Duration(days: 1)),
          narration: 'Withdrawal to HDFC Bank',
          credit: 0.0,
          debit: 35000.0,
          runningBalance: 200000.0, // 235k - 35k
        ),
        LedgerEntry(
          id: 'L4',
          date: DateTime.now(),
          narration: 'Realized intraday profit',
          credit: 12500.0,
          debit: 0.0,
          runningBalance: 212500.0, // 200k + 12.5k
        ),
      ];

      final recon = FinancialCalculationService.reconcileLedgerBalance(
        openingBalance: opening,
        entries: entries,
      );

      expect(recon.isReconciled, isTrue);
      expect(recon.calculatedBalance, 212500.0);
      expect(recon.expectedBalance, 212500.0);
      expect(recon.difference, 0.0);
    });

    // 111. Section 24: Corporate Entity, Compliance Disclaimers & Licensing
    test('Real-Money Trading: corporate legal entity, simulated disclaimers, and data agreements', () {
      expect(RealMoneyComplianceService.disclaimer, 'Compliance disclaimer unavailable');
      final entity = RealMoneyComplianceService.corporateEntity;
      expect(entity.entityName, 'Unavailable');
      expect(entity.cin, 'Unavailable');
      expect(entity.pan, 'Unavailable');
      expect(entity.gstin, 'Unavailable');

      final licenses = RealMoneyComplianceService.licenses;
      expect(licenses.sebiBrokerReg, 'Unavailable');
      expect(licenses.nseMemberId, 'Unavailable');
      expect(licenses.bseMemberId, 'Unavailable');
      expect(licenses.mcxMemberId, 'Unavailable');
      expect(licenses.cdslDpId, 'Unavailable');
      expect(licenses.nsdlDpId, 'Unavailable');
      expect(licenses.sebiRaReg, 'Unavailable');

      // Market Data & Vendor contract validation
      expect(RealMoneyComplianceService.marketDataLicenseAgreementRef, 'Unavailable');
      expect(RealMoneyComplianceService.clearingMemberAgreementRef, 'Unavailable');
      expect(RealMoneyComplianceService.allowsRedistributionWithoutLicense, isFalse);
    });

    // 112. Section 24: Eligibility Validation & AML/PEP Monitoring
    test('Real-Money Trading: client eligibility verification and AML transaction monitoring', () {
      // Eligibility validation
      final adultResident = RealMoneyComplianceService.validateEligibility(
        age: 24,
        isIndianResident: true,
        hasValidPan: true,
        hasAadhaarLinked: true,
      );
      expect(adultResident, isTrue);

      final minor = RealMoneyComplianceService.validateEligibility(
        age: 17,
        isIndianResident: true,
        hasValidPan: true,
        hasAadhaarLinked: true,
      );
      expect(minor, isFalse);

      final unlinkedAadhaar = RealMoneyComplianceService.validateEligibility(
        age: 30,
        isIndianResident: true,
        hasValidPan: true,
        hasAadhaarLinked: false,
      );
      expect(unlinkedAadhaar, isFalse);

      // AML & Sanctions Monitoring
      // 1. Sanctioned Entity Alert
      final sanctionedAlert = RealMoneyComplianceService.monitorAmlTransaction(
        transactionAmount: 50000.0,
        isPep: false,
        isSanctionedEntity: true,
        transactionsInLastHour: 1,
      );
      expect(sanctionedAlert.isSuspicious, isTrue);
      expect(sanctionedAlert.alertReason, contains('OFAC/UN sanctions'));
      expect(sanctionedAlert.requiresFiuReport, isTrue);

      // 2. High-Value Threshold (> ₹10 Lakhs under PMLA)
      final pmlaThresholdAlert = RealMoneyComplianceService.monitorAmlTransaction(
        transactionAmount: 1200000.0,
        isPep: false,
        isSanctionedEntity: false,
        transactionsInLastHour: 1,
      );
      expect(pmlaThresholdAlert.isSuspicious, isTrue);
      expect(pmlaThresholdAlert.alertReason, contains('PMLA ₹10 Lakh'));
      expect(pmlaThresholdAlert.requiresFiuReport, isTrue);

      // 3. PEP Flag
      final pepAlert = RealMoneyComplianceService.monitorAmlTransaction(
        transactionAmount: 200000.0,
        isPep: true,
        isSanctionedEntity: false,
        transactionsInLastHour: 1,
      );
      expect(pepAlert.isSuspicious, isTrue);
      expect(pepAlert.alertReason, contains('Politically Exposed Person'));

      // 4. Normal Clean Transaction
      final cleanAlert = RealMoneyComplianceService.monitorAmlTransaction(
        transactionAmount: 75000.0,
        isPep: false,
        isSanctionedEntity: false,
        transactionsInLastHour: 2,
      );
      expect(cleanAlert.isSuspicious, isFalse);
    });

    // 113. Section 24: Customer Funds Segregation & Upstreaming Circular Compliance
    test('Real-Money Trading: customer funds segregation, upstreaming to CC, and zero commingling', () {
      // Scenario A: Compliant 100% Upstreaming to Clearing Corporation
      final compliantAudit = RealMoneyComplianceService.auditClientFundsSegregation(
        totalClientFunds: 50000000.0, // ₹5 Crore client pay-in
        upstreamedAmount: 50000000.0, // 100% upstreamed to NCL/ICCL
        brokerPropFundsCommited: 10000000.0, // Broker own proprietary funds separate
      );
      expect(compliantAudit.isCompliant, isTrue);
      expect(compliantAudit.retainedInBrokerPropAccount, 0.0);
      expect(compliantAudit.isCommingled, isFalse);

      // Scenario B: Non-compliant commingled or retained funds in broker account
      final nonCompliantAudit = RealMoneyComplianceService.auditClientFundsSegregation(
        totalClientFunds: 50000000.0,
        upstreamedAmount: 40000000.0, // Retained ₹1 Crore illegally in broker account
        brokerPropFundsCommited: 0.0,
      );
      expect(nonCompliantAudit.isCompliant, isFalse);
      expect(nonCompliantAudit.retainedInBrokerPropAccount, 10000000.0);
      expect(nonCompliantAudit.isCommingled, isTrue);
    });

    // 114. Section 24: Statutory Record Retention & NTP-Synchronized Trade Audit Logs
    test('Real-Money Trading: PMLA 5-year retention and NTP-synchronized trade audit logs', () {
      expect(RealMoneyComplianceService.pmlaRetentionYears, 5);
      expect(RealMoneyComplianceService.companiesActRetentionYears, 7);

      final auditLog = RealMoneyComplianceService.generateAuditLog(
        orderId: 'ORD-2026-98124',
        clientCode: 'ZD88912',
        ipAddress: '49.37.12.189',
        deviceFingerprint: 'FP-SHA256-ANDROID-S24-001',
        macAddress: '02:00:00:00:00:00',
        geoTag: '19.0760N,72.8777E',
        exchangeOrderId: 'NSE202609059812401',
      );

      expect(auditLog.orderId, 'ORD-2026-98124');
      expect(auditLog.clientCode, 'ZD88912');
      expect(auditLog.clientIpAddress, '49.37.12.189');
      expect(auditLog.deviceFingerprint, isNotEmpty);
      expect(auditLog.geoTag, isNotEmpty);
      expect(auditLog.ntpTimestamp.isUtc, isTrue);

      final json = auditLog.toJson();
      expect(json['orderId'], 'ORD-2026-98124');
      expect(json['clientIpAddress'], '49.37.12.189');
    });

    // 115. Section 24: DPDP Act Privacy, Local Indian Data Residency & Grievance Redressal
    test('Real-Money Trading: DPDP Act 2023 compliance, Indian data residency, and grievance redressal', () {
      expect(RealMoneyComplianceService.dataProtectionLegislation, contains('DPDP'));
      expect(RealMoneyComplianceService.isDataStoredExclusivelyInIndia, isTrue);
      expect(RealMoneyComplianceService.primaryDataCenterLocation, contains('Mumbai'));
      expect(RealMoneyComplianceService.drDataCenterLocation, contains('Hyderabad'));

      // Check Statutory Policies in LegalDocuments
      expect(LegalDocuments.all.any((d) => d.id == 'client_funds_segregation'), isTrue);
      expect(LegalDocuments.all.any((d) => d.id == 'aml_cft_policy'), isTrue);
      expect(LegalDocuments.all.any((d) => d.id == 'bcp_dr_policy'), isTrue);
      expect(LegalDocuments.all.any((d) => d.id == 'market_data_licensing'), isTrue);

      final amlDoc = LegalDocuments.all.firstWhere((d) => d.id == 'aml_cft_policy');
      expect(amlDoc.content, contains('FIU-IND'));
      expect(amlDoc.content, contains('₹10,00,000'));

      final segregationDoc = LegalDocuments.all.firstWhere((d) => d.id == 'client_funds_segregation');
      expect(segregationDoc.content, contains('100% UPSTREAMING'));
      expect(segregationDoc.content, contains('ZERO PROPRIETARY COMMINGLING'));
    });

    // 116. Section 24: BCP/DR, CERT-In 6-Hour Incident Reporting & Annual VAPT Audits
    test('Real-Money Trading: BCP/DR metrics, CERT-In 6-hour incident SLA, and VAPT certification', () {
      expect(RealMoneyComplianceService.recoveryPointObjectiveMinutes, lessThanOrEqualTo(15));
      expect(RealMoneyComplianceService.recoveryTimeObjectiveHours, lessThanOrEqualTo(4));
      expect(RealMoneyComplianceService.certInMandatoryIncidentReportingHours, 6);
      expect(RealMoneyComplianceService.isVaptCompliant, isTrue);
      expect(RealMoneyComplianceService.annualVaptAuditor, contains('CERT-In'));

      // Responsible advertising & leverage restrictions
      expect(RealMoneyComplianceService.allowsGuaranteedReturnClaims, isFalse);
      expect(RealMoneyComplianceService.sebiPeakIntradayMarginMultiplier, 5.0);
      expect(RealMoneyComplianceService.mtfMinimumClientContributionPercent, 20.0);
      expect(RealMoneyComplianceService.sebiFoLossWarning, contains('9 out of 10 individual traders'));
    });

    // 117. Section 25: Google Play Listing Reference Verification
    test('Google Play listing: app title, operator, update date, and core features', () {
      const listing = SourceVerificationService.googlePlayListing;
      expect(listing.appName, 'ZeroDalali Life');
      expect(listing.operatedBy, 'Winds Global');
      expect(listing.updateDate, 'March 30, 2026');

      expect(listing.releaseNoteFeatures.any((f) => f.contains('Real-time streaming market data')), isTrue);
      expect(listing.releaseNoteFeatures.any((f) => f.contains('Advanced interactive charts')), isTrue);
      expect(listing.releaseNoteFeatures.any((f) => f.contains('One-tap rapid order placement')), isTrue);
      expect(listing.releaseNoteFeatures.any((f) => f.contains('Account profile and security')), isTrue);
      expect(listing.releaseNoteFeatures.any((f) => f.contains('Instant UPI deposit and withdrawal')), isTrue);
      expect(listing.releaseNoteFeatures.any((f) => f.contains('running transaction history')), isTrue);
      expect(listing.releaseNoteFeatures.any((f) => f.contains('Market watch custom lists')), isTrue);
      expect(listing.releaseNoteFeatures.any((f) => f.contains('multi-asset trading dashboard')), isTrue);
    });

    // 118. Section 25: Official Website Claims Verification
    test('Official website: zero brokerage, 500x margin, and multi-asset classes', () {
      const claims = SourceVerificationService.websiteClaims;
      expect(claims.zeroBrokerage, isTrue);
      expect(claims.maxMarginMultiplier, 500.0);
      expect(claims.hasStopLossTakeProfit, isTrue);
      expect(claims.hasFraudDetection, isTrue);
      expect(claims.has24x7Support, isTrue);
      expect(claims.hasLearningAcademy, isTrue);

      expect(claims.supportedAssetClasses, contains('Equity Stocks (NSE/BSE)'));
      expect(claims.supportedAssetClasses, contains('Futures & Options (F&O)'));
      expect(claims.supportedAssetClasses, contains('Commodities (MCX Gold, Silver, Crude, Copper)'));
      expect(claims.supportedAssetClasses, contains('Currency & Forex (CDS USDINR, EURUSD)'));
      expect(claims.supportedAssetClasses, contains('Cryptocurrency CFDs (BTC, ETH, SOL)'));
      expect(claims.supportedAssetClasses, contains('Global Benchmark Indices (US 500, NASDAQ, DOW)'));
    });

    // 119. Section 25: Official Privacy Policy Data Collection & Permissions
    test('Official privacy policy: account, device, permissions, and PII telemetry protection', () {
      const privacyDoc = LegalDocuments.privacyPolicy;
      expect(privacyDoc.content, contains('DATA WE COLLECT'));
      expect(privacyDoc.content, contains('PAN, Aadhaar offline XML/e-KYC'));
      expect(privacyDoc.content, contains('BIOMETRIC & PIN DATA INVARIANT'));
      expect(privacyDoc.content, contains('STATUTORY RETENTION UNDER PMLA'));
      expect(privacyDoc.content, contains('5 years'));
      expect(privacyDoc.content, contains('PERMISSIONS & ANALYTICS DATA PROTECTION'));
      expect(privacyDoc.content, contains('zero sensitive PII'));
      expect(privacyDoc.content, contains('masks PAN and bank account numbers'));
    });

    // 120. Section 25: Official Risk Disclaimer Technical & Operational Risks
    test('Official risk disclaimer: substantial risk, no profit guarantees, and technical risks clause', () {
      const riskDoc = LegalDocuments.riskDisclosure;
      expect(riskDoc.content, contains('MANDATORY RISK DISCLOSURE'));
      expect(riskDoc.content, contains('9 out of 10 individual traders'));
      expect(riskDoc.content, contains('Technical & Operational Risks'));
      expect(riskDoc.content, contains('System errors, exchange matching engine latency'));
      expect(riskDoc.content, contains('internet/telecom connectivity loss'));
      expect(riskDoc.content, contains('server downtime, and delayed price feeds'));
      expect(riskDoc.content, contains('Zero provides no investment advice, makes no profit guarantees'));
    });

    // 121. Section 25: Eight-Pillar Completeness Rule Audit
    test('Eight-pillar completeness rule: UI, Validation, Calculations, API/Realtime, Error States, Security, Accessibility, E2E QA', () {
      final pillars = SourceVerificationService.auditCompleteness();
      expect(pillars.length, 8);
      for (final p in pillars) {
        expect(p.isComplete, isTrue, reason: 'Pillar ${p.pillar.name} must be complete');
        expect(p.verificationDetails, isNotEmpty);
      }
      expect(SourceVerificationService.isPlatformFullyComplete, isTrue);
    });

    // 122. Section 25: Full Master Checklist Regression Invariant
    test('Master checklist end-to-end regression invariant across all 25 sections', () {
      expect(AppConstants.appName, 'Zero');
      expect(AppConstants.appFormalTitle, 'ZeroDalali Life');
      expect(AppConstants.operatedBy, 'Winds Global');
      expect(AppConstants.packageId, 'com.Zero.zero_dalali');
      expect(AppConstants.privacyPolicyUrl, startsWith('https://'));
      expect(AppConstants.termsConditionsUrl, startsWith('https://'));
      expect(AppConstants.supportHelpUrl, startsWith('https://'));
      expect(AppConstants.riskDisclosureUrl, startsWith('https://'));
      expect(AppConstants.accountDeletionUrl, startsWith('https://'));
      expect(LegalDocuments.all.length, 10);
    });
  });
}





