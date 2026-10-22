import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/watchlist/domain/watchlist_repository.dart';

class FakeWatchlistRepository implements WatchlistRepository {
  final List<WatchlistGroup> _watchlists;
  bool shouldThrowOnAdd = false;
  bool shouldThrowOnRemove = false;
  bool shouldThrowOnReorder = false;

  FakeWatchlistRepository([List<WatchlistGroup>? initial])
      : _watchlists = initial != null
            ? List.from(initial)
            : [
                const WatchlistGroup(
                  id: 'wl_default',
                  name: 'Watchlist',
                  instrumentTokens: [],
                  isDefault: true,
                ),
              ];

  @override
  Future<List<WatchlistGroup>> getAllWatchlists() async => List.unmodifiable(_watchlists);

  @override
  Future<WatchlistGroup> createWatchlist(String name) async {
    final group = WatchlistGroup(
      id: 'wl_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isEmpty ? 'Watchlist' : name,
      instrumentTokens: const [],
      isDefault: true,
    );
    _watchlists.removeWhere((w) => w.id == 'wl_default' && w.instrumentTokens.isEmpty);
    _watchlists.add(group);
    return group;
  }

  @override
  Future<void> renameWatchlist(String id, String newName) async {
    final idx = _watchlists.indexWhere((w) => w.id == id);
    if (idx != -1) {
      _watchlists[idx] = _watchlists[idx].copyWith(name: newName);
    }
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    _watchlists.removeWhere((w) => w.id == id);
  }

  @override
  Future<void> addInstrument(String watchlistId, String instrumentToken) async {
    if (shouldThrowOnAdd) {
      throw Exception('Network error adding instrument');
    }
    final idx = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (idx != -1) {
      final tokens = List<String>.from(_watchlists[idx].instrumentTokens);
      final clean = instrumentToken.trim();
      if (!tokens.any((t) => t.toUpperCase() == clean.toUpperCase())) {
        if (tokens.length >= 50) {
          throw Exception('MAX_SYMBOLS_EXCEEDED');
        }
        tokens.insert(0, clean);
        _watchlists[idx] = _watchlists[idx].copyWith(instrumentTokens: tokens);
      }
    }
  }

  @override
  Future<void> removeInstrument(String watchlistId, String instrumentToken) async {
    if (shouldThrowOnRemove) {
      throw Exception('Network error removing instrument');
    }
    final idx = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (idx != -1) {
      final tokens = List<String>.from(_watchlists[idx].instrumentTokens);
      final clean = instrumentToken.trim().toUpperCase();
      tokens.removeWhere((t) => t.trim().toUpperCase() == clean);
      _watchlists[idx] = _watchlists[idx].copyWith(instrumentTokens: tokens);
    }
  }

  @override
  Future<void> reorderInstruments(String watchlistId, int oldIndex, int newIndex) async {
    if (shouldThrowOnReorder) {
      throw Exception('Network error reordering');
    }
    final idx = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (idx != -1) {
      final tokens = List<String>.from(_watchlists[idx].instrumentTokens);
      if (newIndex > oldIndex) newIndex -= 1;
      if (oldIndex < tokens.length && newIndex <= tokens.length) {
        final item = tokens.removeAt(oldIndex);
        tokens.insert(newIndex, item);
        _watchlists[idx] = _watchlists[idx].copyWith(instrumentTokens: tokens);
      }
    }
  }
}
