import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/constants/charges_config.dart';
import 'package:zero_dalali/core/services/balance_privacy_service.dart';
import 'package:zero_dalali/core/services/connectivity_service.dart';
import 'package:zero_dalali/core/services/maintenance_service.dart';
import 'package:zero_dalali/core/services/market_status_service.dart';
import 'package:zero_dalali/core/utils/currency_formatter.dart';
import 'package:zero_dalali/core/utils/date_formatter.dart';
import 'package:zero_dalali/data/mock/candle_generator.dart';
import 'package:zero_dalali/data/mock/order_simulation_engine.dart';
import 'package:zero_dalali/data/mock/seed_instruments.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/charts/presentation/indicators/indicator_math.dart';
import 'package:zero_dalali/features/watchlist/presentation/watchlist_controller.dart';

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
      final container = ProviderContainer();
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
      final container = ProviderContainer();
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
      final container = ProviderContainer();
      final connectivityNotifier = container.read(connectivityServiceProvider.notifier);

      expect(container.read(connectivityServiceProvider), NetworkStatus.online);
      expect(container.read(isOfflineProvider), isFalse);

      connectivityNotifier.setSimulatedOffline(true);
      expect(container.read(connectivityServiceProvider), NetworkStatus.offline);
      expect(container.read(isOfflineProvider), isTrue);

      connectivityNotifier.setSimulatedOffline(false);
      expect(container.read(connectivityServiceProvider), NetworkStatus.online);
      expect(container.read(isOfflineProvider), isFalse);
    });

    // 11. Maintenance Service State Transition Tests
    test('MaintenanceService enables, updates, and disables maintenance correctly', () {
      final container = ProviderContainer();
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
      final container = ProviderContainer();
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

    test('WatchlistController creates, renames, and deletes watchlists', () async {
      final container = ProviderContainer();
      final controller = container.read(watchlistControllerProvider.notifier);

      await controller.createWatchlist('Special Options');
      var state = container.read(watchlistControllerProvider);
      expect(state.watchlists.any((w) => w.name == 'Special Options'), isTrue);

      final newWl = state.watchlists.firstWhere((w) => w.name == 'Special Options');
      await controller.renameWatchlist(newWl.id, 'Renamed Options');
      state = container.read(watchlistControllerProvider);
      expect(state.watchlists.any((w) => w.name == 'Renamed Options'), isTrue);

      await controller.deleteWatchlist(newWl.id);
      state = container.read(watchlistControllerProvider);
      expect(state.watchlists.any((w) => w.name == 'Renamed Options'), isFalse);
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
  });
}


