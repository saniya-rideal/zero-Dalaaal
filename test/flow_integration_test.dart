import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/mock/order_simulation_engine.dart';
import 'package:zero_dalali/data/mock/pinned_scripts_provider.dart';
import 'package:zero_dalali/data/mock/seed_instruments.dart';
import 'package:zero_dalali/data/mock/settings_repository.dart';
import 'package:zero_dalali/features/order_entry/presentation/order_entry_sheet.dart';
import 'package:zero_dalali/features/quotes/presentation/quotes_screen.dart';
import 'package:zero_dalali/shared_widgets/script_selector_bar.dart';

void main() {
  group('End-to-End Flow Integration Tests', () {
    testWidgets(
        'ScriptSelectorBar updates slot when script is pinned and displays symbol',
        (tester) async {
      final container = ProviderContainer();
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
        await tester.pump();

        expect(find.text('Press and hold to select script'), findsNWidgets(2));

        // Pin Nifty 50 to Left Slot
        final nifty = SeedInstruments.indices.first;
        container.read(pinnedScriptsProvider.notifier).setLeftScript(nifty);
        await tester.pump();

        expect(find.text(nifty.symbol), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('QuotesScreen dynamically respects showStickyScripts toggle',
        (tester) async {
      final container = ProviderContainer();
      try {
        // Ensure sticky scripts is ON
        container.read(settingsRepositoryProvider).setShowStickyScripts(true);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: QuotesScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ScriptSelectorBar), findsOneWidget);

        // Toggle sticky scripts to OFF
        container.read(settingsRepositoryProvider).setShowStickyScripts(false);
        await tester.pump();

        expect(find.byType(ScriptSelectorBar), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets(
        'QuotesScreen groups quotes by category when quotesGrouping is true',
        (tester) async {
      final container = ProviderContainer();
      try {
        // Enable quotesGrouping in settings
        container.read(settingsRepositoryProvider).setQuotesGrouping(true);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: QuotesScreen(),
            ),
          ),
        );
        await tester.pump();

        // Should find category headers
        expect(find.text('COMMODITIES'), findsWidgets);
        expect(find.textContaining('SCRIPTS'), findsWidgets);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('One-Click Trade in QuotesScreen executes order with defaultLots',
        (tester) async {
      final container = ProviderContainer();
      try {
        // Set default lots to 0.5 (within margin limit)
        container.read(settingsRepositoryProvider).setDefaultLots(0.5);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: QuotesScreen(),
            ),
          ),
        );
        await tester.pump();

        // One click trade label should show configured lots
        expect(find.text('One Click (0.5L)'), findsOneWidget);

        // Toggle One Click switch to ON (second switch after Pro View)
        final switchFinder = find.byType(Switch).last;
        await tester.ensureVisible(switchFinder);
        await tester.tap(switchFinder);
        await tester.pump();

        expect(tester.widget<Switch>(switchFinder).value, isTrue);

        // Tap quote item
        final quoteFinder = find.text('COPPER MCX Sep');
        expect(quoteFinder, findsOneWidget);
        await tester.tap(quoteFinder);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verify execution snackbar appeared
        expect(
            find.textContaining('Instant Market Buy executed: 0.5 lot(s) of COPPER MCX Sep'),
            findsOneWidget);

        // Verify order exists in order engine
        final orders = container.read(orderSimulationEngineProvider).orders;
        expect(orders.any((o) => o.instrument.symbol.contains('COPPER')), isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });

    testWidgets('OrderEntrySheet pre-fills lot with defaultLots from settings',
        (tester) async {
      final container = ProviderContainer();
      try {
        container.read(settingsRepositoryProvider).setDefaultLots(3.5);

        final instrument = SeedInstruments.all.first;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OrderEntrySheet(instrument: instrument),
              ),
            ),
          ),
        );
        await tester.pump();

        // The pre-filled lot in OrderEntrySheet should be 3.5
        expect(find.text('3.50'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        container.dispose();
      }
    });
  });
}
