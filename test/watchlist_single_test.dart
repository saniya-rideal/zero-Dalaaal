import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/market/data/real_market_repository.dart';
import 'package:zero_dalali/features/market/domain/market_repository.dart';
import 'package:zero_dalali/features/quotes/presentation/quotes_screen.dart';
import 'package:zero_dalali/features/watchlist/data/real_watchlist_repository.dart';
import 'package:zero_dalali/features/watchlist/presentation/watchlist_controller.dart';
import 'fixtures/fake_watchlist_repository.dart';

class MockMarketRepository implements MarketRepository {
  final List<Instrument> _instruments = [
    const Instrument(
      token: 'RELIANCE',
      symbol: 'RELIANCE',
      name: 'Reliance Industries Ltd',
      exchange: Exchange.NSE,
      type: InstrumentType.EQ,
      lotSize: 1,
    ),
    const Instrument(
      token: 'TCS',
      symbol: 'TCS',
      name: 'Tata Consultancy Services',
      exchange: Exchange.NSE,
      type: InstrumentType.EQ,
      lotSize: 1,
    ),
    const Instrument(
      token: 'INFY',
      symbol: 'INFY',
      name: 'Infosys Limited',
      exchange: Exchange.NSE,
      type: InstrumentType.EQ,
      lotSize: 1,
    ),
  ];

  @override
  List<Instrument> get cachedInstruments => _instruments;

  @override
  Future<List<Instrument>> getInstruments() async => _instruments;

  @override
  Instrument? findBySymbol(String symbol) {
    final clean = symbol.trim().toUpperCase();
    for (final inst in _instruments) {
      if (inst.symbol.toUpperCase() == clean || inst.token.toUpperCase() == clean) {
        return inst;
      }
    }
    return null;
  }

  @override
  Future<Map<String, Quote>> getQuotes({List<String>? symbols}) async => {};

  @override
  Future<Quote?> getQuote(String symbol) async => null;

  @override
  Future<List<Candle>> getCandles(String symbol,
      {String interval = '1m', int limit = 100, int? from, int? to}) async =>
      [];

  @override
  Future<List<Instrument>> searchInstruments(String query,
      {Exchange? exchange, InstrumentType? type}) async {
    final clean = query.trim().toUpperCase();
    return _instruments
        .where((i) => i.symbol.toUpperCase().contains(clean))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getMarketStatus() async => {'isOpen': true};

  @override
  Future<List<dynamic>> getMarketHolidays({int? year}) async => [];
}

void main() {
  group('WatchlistController Single Watchlist Architecture Tests', () {
    test('1. Loads the default watchlist with isDefault == true', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_custom',
          name: 'Custom',
          instrumentTokens: ['SBIN'],
          isDefault: false,
        ),
        const WatchlistGroup(
          id: 'wl_default_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE', 'TCS'],
          isDefault: true,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      container.read(watchlistControllerProvider);
      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));
      final loadedState = container.read(watchlistControllerProvider);

      expect(loadedState.watchlist, isNotNull);
      expect(loadedState.watchlist!.id, 'wl_default_1');
      expect(loadedState.watchlist!.isDefault, isTrue);
      expect(loadedState.watchlist!.instrumentTokens, ['RELIANCE', 'TCS']);
    });

    test('2. Creates single "Watchlist" if no default watchlist exists', () async {
      final fakeRepo = FakeWatchlistRepository([]);
      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(watchlistControllerProvider.notifier);
      await controller.loadWatchlist();
      final state = container.read(watchlistControllerProvider);

      expect(state.watchlist, isNotNull);
      expect(state.watchlist!.name, 'Watchlist');
      expect(state.watchlist!.isDefault, isTrue);
      expect(state.watchlist!.instrumentTokens, isEmpty);
    });

    test('3. Adding a script adds it to the TOP (index 0) and tracks lastAddedSymbol', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
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

      await Future.delayed(const Duration(milliseconds: 50));
      final controller = container.read(watchlistControllerProvider.notifier);

      final success = await controller.addInstrument('RELIANCE');
      expect(success, isTrue);

      final state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens.first, 'RELIANCE');
      expect(state.watchlist!.instrumentTokens, ['RELIANCE', 'TCS']);
      expect(state.lastAddedSymbol, 'RELIANCE');
    });

    test('4. Enforces 50-symbol limit and handles MAX_SYMBOLS_EXCEEDED error', () async {
      final fiftySymbols = List.generate(50, (i) => 'SYM_$i');
      final fakeRepo = FakeWatchlistRepository([
        WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: fiftySymbols,
          isDefault: true,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final controller = container.read(watchlistControllerProvider.notifier);

      final success = await controller.addInstrument('OVER_LIMIT_SYM');
      expect(success, isFalse);

      final state = container.read(watchlistControllerProvider);
      expect(state.errorMessage, 'MAX_SYMBOLS_EXCEEDED');
      expect(state.watchlist!.instrumentTokens.length, 50);
      expect(state.watchlist!.instrumentTokens.contains('OVER_LIMIT_SYM'), isFalse);
    });

    test('5. Adding script rolls back when backend throws error', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['TCS'],
          isDefault: true,
        ),
      ]);
      fakeRepo.shouldThrowOnAdd = true;

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final controller = container.read(watchlistControllerProvider.notifier);

      final success = await controller.addInstrument('INFY');
      expect(success, isFalse);

      final state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens, ['TCS']);
      expect(state.errorMessage, contains('Network error adding instrument'));
    });

    test('6. Removing a script awaits backend response and updates UI only on success', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE', 'TCS'],
          isDefault: true,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(watchlistControllerProvider.notifier);
      await controller.loadWatchlist();

      final success = await controller.removeInstrument('RELIANCE');
      expect(success, isTrue);

      final state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens, ['TCS']);
      expect(state.errorMessage, isNull);
    });

    test('7. Removing a script rolls back with error message when backend fails', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE', 'TCS'],
          isDefault: true,
        ),
      ]);
      fakeRepo.shouldThrowOnRemove = true;

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(watchlistControllerProvider.notifier);
      await controller.loadWatchlist();

      final success = await controller.removeInstrument('RELIANCE');
      expect(success, isFalse);

      final state = container.read(watchlistControllerProvider);
      // Still contains RELIANCE because removal failed
      expect(state.watchlist!.instrumentTokens, ['RELIANCE', 'TCS']);
      expect(state.errorMessage, contains('Network error removing instrument'));
    });

    test('8. Supports Undo action after removing a script', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE', 'TCS'],
          isDefault: true,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(watchlistControllerProvider.notifier);
      await controller.loadWatchlist();

      // Remove
      await controller.removeInstrument('RELIANCE');
      var state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens, ['TCS']);

      // Undo -> re-add
      final undoSuccess = await controller.addInstrument('RELIANCE');
      expect(undoSuccess, isTrue);

      state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens.contains('RELIANCE'), isTrue);
      expect(state.watchlist!.instrumentTokens.first, 'RELIANCE');
    });

    test('9. Empty state: does NOT re-add default instruments after user empties watchlist', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE'],
          isDefault: true,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(watchlistControllerProvider.notifier);
      await controller.loadWatchlist();

      // User removes the last instrument
      await controller.removeInstrument('RELIANCE');

      final state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens, isEmpty);

      // Calling loadWatchlist again should preserve empty watchlist
      await controller.loadWatchlist();
      final reloadedState = container.read(watchlistControllerProvider);
      expect(reloadedState.watchlist!.instrumentTokens, isEmpty);
    });

    test('10. Reordering by drag persists through backend and rolls back on failure', () async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE', 'TCS', 'INFY'],
          isDefault: true,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(watchlistControllerProvider.notifier);
      await controller.loadWatchlist();

      // Move INFY from index 2 to index 0
      final success = await controller.reorder(2, 0);
      expect(success, isTrue);

      var state = container.read(watchlistControllerProvider);
      expect(state.watchlist!.instrumentTokens, ['INFY', 'RELIANCE', 'TCS']);

      // Backend fails on reorder
      fakeRepo.shouldThrowOnReorder = true;
      final fail = await controller.reorder(0, 2);
      expect(fail, isFalse);

      state = container.read(watchlistControllerProvider);
      // Rolled back to previous state
      expect(state.watchlist!.instrumentTokens, ['INFY', 'RELIANCE', 'TCS']);
      expect(state.errorMessage, contains('Network error reordering'));
    });
  });

  group('QuotesScreen UI & Widget Tests', () {
    testWidgets('11. Screen title is "Watchlist" and shows "X / 50 symbols"', (tester) async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE'],
          isDefault: true,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(fakeRepo),
            marketRepositoryProvider.overrideWithValue(MockMarketRepository()),
          ],
          child: const MaterialApp(
            home: QuotesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Watchlist'), findsWidgets);
      expect(find.text('1 / 50 symbols'), findsOneWidget);
    });

    testWidgets('12. Shows "Your watchlist is empty" with "Add script" button when empty', (tester) async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: [],
          isDefault: true,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(fakeRepo),
            marketRepositoryProvider.overrideWithValue(MockMarketRepository()),
          ],
          child: const MaterialApp(
            home: QuotesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your watchlist is empty'), findsOneWidget);
      expect(find.text('Add script'), findsOneWidget);
      expect(find.text('0 / 50 symbols'), findsOneWidget);
    });

    testWidgets('13. Renders QuoteStatusBadge next to prices', (tester) async {
      final fakeRepo = FakeWatchlistRepository([
        const WatchlistGroup(
          id: 'wl_1',
          name: 'Watchlist',
          instrumentTokens: ['RELIANCE'],
          isDefault: true,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(fakeRepo),
            marketRepositoryProvider.overrideWithValue(MockMarketRepository()),
          ],
          child: const MaterialApp(
            home: QuotesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LIVE'), findsWidgets);
    });
  });
}
