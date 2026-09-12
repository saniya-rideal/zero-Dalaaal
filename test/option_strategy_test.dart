import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/models/enums.dart';
import 'package:zero_dalali/data/models/option_strategy.dart';
import 'package:zero_dalali/features/option_chain/presentation/payoff_graph_sheet.dart';
import 'package:zero_dalali/features/option_chain/presentation/widgets/payoff_chart.dart';

void main() {
  group('Option Strategy Payoff Engine Tests', () {
    test('Bull Call Spread engine calculations', () {
      final strategy = OptionStrategy.bullCallSpread(
        underlying: 'NIFTY',
        spot: 25150.0,
        expiry: '26-SEP-2026',
        atmPremium: 145.0,
        otmPremium: 72.0,
        lotSize: 25,
      );

      final analysis = strategy.analyze();

      // Net debit = (145 - 72) * 25 = 73 * 25 = 1825.0 -> maxLoss is -1825.0
      expect(analysis.maxLoss, closeTo(-1825.0, 10.0));

      // Max profit is positive
      expect(analysis.maxProfit, greaterThan(0));

      // Breakeven should exist
      expect(analysis.breakevens.length, equals(1));
      expect(analysis.breakevens.first, closeTo(25223.0, 5.0));

      // Risk reward ratio > 0
      expect(analysis.riskRewardRatio, greaterThan(0));
    });

    test('Long Call single leg payoff engine', () {
      const strategy = OptionStrategy(
        name: 'Long Call',
        underlying: 'BANKNIFTY',
        spotPrice: 51000.0,
        expiry: '26-SEP-2026',
        legs: [
          OptionStrategyLeg(
            side: TransactionType.BUY,
            type: StrategyLegType.ce,
            strike: 51000.0,
            premium: 350.0,
            quantity: 1,
            lotSize: 15,
          ),
        ],
      );

      final analysis = strategy.analyze();

      // Max loss = - (350 * 15) = -5250
      expect(analysis.maxLoss, closeTo(-5250.0, 1.0));
      // Breakeven = 51000 + 350 = 51350
      expect(analysis.breakevens.length, equals(1));
      expect(analysis.breakevens.first, closeTo(51350.0, 10.0));
    });

    test('Long Put single leg payoff engine', () {
      const strategy = OptionStrategy(
        name: 'Long Put',
        underlying: 'NIFTY',
        spotPrice: 25000.0,
        expiry: '26-SEP-2026',
        legs: [
          OptionStrategyLeg(
            side: TransactionType.BUY,
            type: StrategyLegType.pe,
            strike: 25000.0,
            premium: 120.0,
            quantity: 1,
            lotSize: 25,
          ),
        ],
      );

      final analysis = strategy.analyze();

      // Max loss = - (120 * 25) = -3000
      expect(analysis.maxLoss, closeTo(-3000.0, 1.0));
      // Breakeven = 25000 - 120 = 24880
      expect(analysis.breakevens.length, equals(1));
      expect(analysis.breakevens.first, closeTo(24880.0, 10.0));
    });

    test('Long Straddle payoff engine', () {
      final strategy = OptionStrategy.longStraddle(
        underlying: 'NIFTY',
        spot: 25000.0,
        expiry: '26-SEP-2026',
        callPremium: 150.0,
        putPremium: 130.0,
        lotSize: 25,
      );

      final analysis = strategy.analyze();

      // Max loss is negative
      expect(analysis.maxLoss, lessThan(0));
      // Breakevens should be present
      expect(analysis.breakevens, isNotEmpty);
    });

    test('Iron Condor payoff engine', () {
      final strategy = OptionStrategy.ironCondor(
        underlying: 'NIFTY',
        spot: 25000.0,
        expiry: '26-SEP-2026',
        lotSize: 25,
      );

      final analysis = strategy.analyze();

      expect(analysis.maxProfit, greaterThan(0));
      expect(analysis.breakevens, isNotEmpty);
    });

    test('Empty strategy returns zero metrics', () {
      const strategy = OptionStrategy(
        name: 'Empty',
        underlying: 'NONE',
        spotPrice: 100.0,
        expiry: 'N/A',
        legs: [],
      );

      final analysis = strategy.analyze();
      expect(analysis.maxProfit, equals(0.0));
      expect(analysis.maxLoss, equals(0.0));
      expect(analysis.breakevens, isEmpty);
    });
  });

  group('Option Strategy Widget Tests', () {
    testWidgets('PayoffGraphSheet renders correctly with strategy preset',
        (WidgetTester tester) async {
      final strategy = OptionStrategy.bullCallSpread(
        underlying: 'NIFTY',
        spot: 25150.0,
        expiry: '26-SEP-2026',
        atmPremium: 145.0,
        otmPremium: 72.0,
        lotSize: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayoffGraphSheet(strategy: strategy),
          ),
        ),
      );

      // Verify title & underlying text
      expect(find.text('Strategy Payoff'), findsWidgets);
      expect(find.textContaining('NIFTY'), findsWidgets);

      // Verify chart exists
      expect(find.byType(PayoffChart), findsOneWidget);

      // Verify key metric cards
      expect(find.text('Max Profit'), findsOneWidget);
      expect(find.text('Max Loss'), findsOneWidget);
      expect(find.text('Breakeven'), findsOneWidget);
      expect(find.text('Risk:Reward'), findsOneWidget);

      // Verify leg table details
      expect(find.text('Legs'), findsOneWidget);
      expect(find.textContaining('CE'), findsWidgets);
    });

    testWidgets('Switching strategy presets in PayoffGraphSheet updates UI',
        (WidgetTester tester) async {
      final strategy = OptionStrategy.bullCallSpread(
        underlying: 'NIFTY',
        spot: 25150.0,
        expiry: '26-SEP-2026',
        atmPremium: 145.0,
        otmPremium: 72.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayoffGraphSheet(strategy: strategy),
          ),
        ),
      );

      // Tap on 'Long Straddle' preset chip
      final straddleChip = find.text('Long Straddle');
      expect(straddleChip, findsOneWidget);
      await tester.tap(straddleChip);
      await tester.pumpAndSettle();

      // Check that strategy legs updated to Straddle legs (CE + PE)
      expect(find.textContaining('PE'), findsWidgets);
    });
  });
}
