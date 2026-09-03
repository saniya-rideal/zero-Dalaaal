import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../domain/watchlist_repository.dart';

class MockWatchlistRepository implements WatchlistRepository {
  final List<WatchlistGroup> _watchlists = [];

  MockWatchlistRepository() {
    _seedDefaultWatchlists();
  }

  void _seedDefaultWatchlists() {
    _watchlists.addAll([
      const WatchlistGroup(
        id: 'wl_1',
        name: 'Watchlist 1',
        instrumentTokens: [
          'eq_reliance',
          'eq_tcs',
          'eq_hdfcbank',
          'eq_icicibank',
          'eq_infy',
          'eq_itc',
          'eq_bhartiartl',
          'eq_sbin',
          'eq_tatamotors',
          'eq_lt',
          'eq_bajfinance',
          'eq_titan',
        ],
      ),
      const WatchlistGroup(
        id: 'wl_2',
        name: 'Momentum',
        instrumentTokens: [
          'eq_zomato',
          'eq_jiofin',
          'eq_suzlon',
          'eq_trent',
          'eq_irfc',
          'eq_rvnl',
          'eq_bel',
          'eq_hal',
          'eq_bse',
          'eq_cdsl',
          'eq_angelone',
          'eq_dmart',
        ],
      ),
      const WatchlistGroup(
        id: 'wl_3',
        name: 'Banking',
        instrumentTokens: [
          'eq_hdfcbank',
          'eq_icicibank',
          'eq_sbin',
          'eq_kotakbank',
          'eq_axisbank',
          'eq_indusindbk',
          'eq_yesbank',
        ],
      ),
      const WatchlistGroup(
        id: 'wl_4',
        name: 'Tech & Pharma',
        instrumentTokens: [
          'eq_tcs',
          'eq_infy',
          'eq_hcltech',
          'eq_wipro',
          'eq_techm',
          'eq_sunpharma',
          'eq_cipla',
          'eq_drreddy',
          'eq_divislab',
        ],
      ),
      const WatchlistGroup(
        id: 'wl_5',
        name: 'Auto & Metal',
        instrumentTokens: [
          'eq_tatamotors',
          'eq_maruti',
          'eq_mm',
          'eq_bajajauto',
          'eq_heromotoco',
          'eq_eichermot',
          'eq_tatasteel',
          'eq_jswsteel',
          'eq_hindalco',
          'eq_vedl',
        ],
      ),
    ]);
  }

  @override
  Future<List<WatchlistGroup>> getAllWatchlists() async {
    return List.unmodifiable(_watchlists);
  }

  @override
  Future<WatchlistGroup> createWatchlist(String name) async {
    final newGroup = WatchlistGroup(
      id: 'wl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      instrumentTokens: [],
    );
    _watchlists.add(newGroup);
    return newGroup;
  }

  @override
  Future<void> renameWatchlist(String id, String newName) async {
    final index = _watchlists.indexWhere((w) => w.id == id);
    if (index != -1) {
      _watchlists[index] = _watchlists[index].copyWith(name: newName);
    }
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    _watchlists.removeWhere((w) => w.id == id);
  }

  @override
  Future<void> addInstrument(String watchlistId, String token) async {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final current = _watchlists[index];
      if (!current.instrumentTokens.contains(token)) {
        final updatedTokens = List<String>.from(current.instrumentTokens)..add(token);
        _watchlists[index] = current.copyWith(instrumentTokens: updatedTokens);
      }
    }
  }

  @override
  Future<void> removeInstrument(String watchlistId, String token) async {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final current = _watchlists[index];
      final updatedTokens = List<String>.from(current.instrumentTokens)..remove(token);
      _watchlists[index] = current.copyWith(instrumentTokens: updatedTokens);
    }
  }

  @override
  Future<void> reorderInstruments(String watchlistId, int oldIndex, int newIndex) async {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final current = _watchlists[index];
      final list = List<String>.from(current.instrumentTokens);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _watchlists[index] = current.copyWith(instrumentTokens: list);
    }
  }
}

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return MockWatchlistRepository();
});
