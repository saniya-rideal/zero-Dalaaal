import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/heatmap/data/heatmap_repository.dart';
import 'package:zero_dalali/features/heatmap/presentation/sector_heatmap_screen.dart';
import 'package:zero_dalali/features/heatmap/presentation/widgets/stock_quick_action_sheet.dart';

const sampleStock = HeatmapStockItem(
  token: 'eq_hdfcbank',
  symbol: 'HDFCBANK',
  name: 'HDFC Bank Ltd',
  sector: 'Banking & Financials',
  marketCap: 12.8,
  weight: 11.2,
  ltp: 1648.20,
  change: 18.40,
  changePercent: 1.13,
  changePercent1W: 2.40,
  changePercent1M: 4.80,
  changePercent1Y: 14.20,
  volume: 14850000,
  dayHigh: 1656.00,
  dayLow: 1635.50,
  isNifty50: true,
);

const sampleAutoStock = HeatmapStockItem(
  token: 'eq_tatamotors',
  symbol: 'TATAMOTORS',
  name: 'Tata Motors Ltd',
  sector: 'Automobiles',
  marketCap: 3.5,
  weight: 7.8,
  ltp: 950.00,
  change: 15.00,
  changePercent: 1.60,
  changePercent1W: 3.10,
  changePercent1M: 5.50,
  changePercent1Y: 25.00,
  volume: 8500000,
  dayHigh: 960.00,
  dayLow: 940.00,
  isNifty50: true,
);

final sampleSectors = [
  const SectorPerformance(
    name: 'Banking & Financials',
    indexSymbol: 'NIFTY BANK',
    weight: 11.2,
    avgChangePercent: 1.13,
    advancesCount: 8,
    declinesCount: 2,
    unchangedCount: 0,
    stocks: [sampleStock],
  ),
  const SectorPerformance(
    name: 'Automobiles',
    indexSymbol: 'NIFTY AUTO',
    weight: 7.8,
    avgChangePercent: 1.60,
    advancesCount: 4,
    declinesCount: 1,
    unchangedCount: 0,
    stocks: [sampleAutoStock],
  ),
];

Widget _wrapWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      rawSectorHeatmapProvider.overrideWith((ref) => sampleSectors),
      ...overrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sector Heatmap Unit Tests', () {
    test('HeatmapStockItem getEffectiveChange handles all timeframes', () {
      expect(sampleStock.getEffectiveChange(HeatmapTimeframe.oneDay), 1.13);
      expect(sampleStock.getEffectiveChange(HeatmapTimeframe.oneWeek), 2.40);
      expect(sampleStock.getEffectiveChange(HeatmapTimeframe.oneMonth), 4.80);
      expect(sampleStock.getEffectiveChange(HeatmapTimeframe.oneYear), 14.20);
    });

    test('HeatmapStockItem serialization roundtrip', () {
      final json = sampleStock.toJson();
      final parsed = HeatmapStockItem.fromJson(json);

      expect(parsed.symbol, 'HDFCBANK');
      expect(parsed.marketCap, 12.8);
      expect(parsed.ltp, 1648.20);
      expect(parsed.changePercent1W, 2.40);
      expect(parsed.isNifty50, isTrue);
    });

    test('SectorPerformance serialization roundtrip', () {
      const sector = SectorPerformance(
        name: 'Automobiles',
        indexSymbol: 'NIFTY AUTO',
        weight: 7.8,
        avgChangePercent: 1.78,
        advancesCount: 4,
        declinesCount: 1,
        unchangedCount: 0,
        stocks: [sampleStock],
      );

      final json = sector.toJson();
      final parsed = SectorPerformance.fromJson(json);

      expect(parsed.name, 'Automobiles');
      expect(parsed.indexSymbol, 'NIFTY AUTO');
      expect(parsed.weight, 7.8);
      expect(parsed.stocks.length, 1);
      expect(parsed.stocks.first.symbol, 'HDFCBANK');
    });

    test('SectorHeatmapDataProvider computes summary and breadth from sectors', () {
      final container = ProviderContainer(
        overrides: [
          rawSectorHeatmapProvider.overrideWith((ref) => sampleSectors),
        ],
      );
      addTearDown(container.dispose);

      final payload = container.read(sectorHeatmapDataProvider);
      expect(payload.sectors.length, 2);
      expect(payload.summary.totalAdvances, 12);
      expect(payload.summary.totalDeclines, 3);
      expect(payload.summary.topSectorName, 'Automobiles');
      expect(payload.summary.laggingSectorName, 'Banking & Financials');
    });

    test('SectorHeatmapFilterNotifier mutates state correctly', () {
      final notifier = SectorHeatmapFilterNotifier();

      expect(notifier.state.timeframe, HeatmapTimeframe.oneDay);
      expect(notifier.state.scope, HeatmapScope.allSectors);
      expect(notifier.state.viewMode, HeatmapViewMode.treemap);

      notifier.setTimeframe(HeatmapTimeframe.oneMonth);
      expect(notifier.state.timeframe, HeatmapTimeframe.oneMonth);

      notifier.setScope(HeatmapScope.nifty50);
      expect(notifier.state.scope, HeatmapScope.nifty50);

      notifier.setViewMode(HeatmapViewMode.sectorGrid);
      expect(notifier.state.viewMode, HeatmapViewMode.sectorGrid);

      notifier.selectSector('Banking & Financials');
      expect(notifier.state.selectedSectorName, 'Banking & Financials');

      // Tapping same sector again toggles off
      notifier.selectSector('Banking & Financials');
      expect(notifier.state.selectedSectorName, isNull);

      notifier.resetFilters();
      expect(notifier.state.timeframe, HeatmapTimeframe.oneDay);
      expect(notifier.state.scope, HeatmapScope.allSectors);
    });
  });

  group('Sector Heatmap Widget Tests', () {
    testWidgets('SectorHeatmapScreen renders banner, filters, and Treemap tiles',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapWidget(const SectorHeatmapScreen()));
      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('Market Heatmap'), findsOneWidget);

      // Check Market Breadth Summary
      expect(find.textContaining('Adv'), findsOneWidget);
      expect(find.textContaining('Dec'), findsOneWidget);

      // Check Timeframe pills
      expect(find.text('1D'), findsOneWidget);
      expect(find.text('1W'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);

      // Check Scope chips
      expect(find.text('All Sectors'), findsOneWidget);
      expect(find.text('Nifty 50'), findsOneWidget);

      // Check Sector titles in Treemap
      expect(find.text('Banking & Financials'), findsOneWidget);
      expect(find.text('HDFCBANK'), findsOneWidget);
    });

    testWidgets('SectorHeatmapScreen toggles between Treemap and Sector Grid',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapWidget(const SectorHeatmapScreen()));
      await tester.pumpAndSettle();

      // Initially in Treemap mode
      expect(find.text('Banking & Financials'), findsOneWidget);

      // Tap toggle button in AppBar
      await tester.tap(find.byTooltip('Switch to Sector Grid'));
      await tester.pumpAndSettle();

      // Now in Sector Grid mode - verify advances/declines labels inside cards
      expect(find.textContaining('Advances'), findsWidgets);
      expect(find.textContaining('Declines'), findsWidgets);
      expect(find.textContaining('NIFTY BANK'), findsOneWidget);

      // Toggle back to Treemap
      await tester.tap(find.byTooltip('Switch to Treemap'));
      await tester.pumpAndSettle();

      expect(find.text('Banking & Financials'), findsOneWidget);
    });

    testWidgets('Tapping stock tile opens StockQuickActionSheet with actions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapWidget(const SectorHeatmapScreen()));
      await tester.pumpAndSettle();

      // Tap HDFCBANK tile
      expect(find.text('HDFCBANK'), findsOneWidget);
      await tester.tap(find.text('HDFCBANK'));
      await tester.pumpAndSettle();

      // Verify StockQuickActionSheet opened
      expect(find.byType(StockQuickActionSheet), findsOneWidget);
      expect(find.textContaining('HDFC Bank Ltd'), findsOneWidget);
      expect(find.text("DAY'S RANGE"), findsOneWidget);
      expect(find.text('MARKET CAP'), findsOneWidget);
      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('SELL'), findsOneWidget);
      expect(find.text('Chart'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Options'), findsOneWidget);
    });

    testWidgets('Tapping timeframe switch updates selected timeframe',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapWidget(const SectorHeatmapScreen()));
      await tester.pumpAndSettle();

      // Tap 1M pill
      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      // Verify screen still intact and functional
      expect(find.text('Market Heatmap'), findsOneWidget);
      expect(find.text('Banking & Financials'), findsOneWidget);
    });
  });
}
